(() => {
  const cfg = window.__CUSTOMER__ || {};
  // Always same host as the page (works on phone LAN IP, not localhost).
  const API = (cfg.apiBase || "/api/v1").replace(/\/$/, "");
  const TOKEN = cfg.tableToken;

  function uuid() {
    if (globalThis.crypto && typeof crypto.randomUUID === "function") {
      try {
        return crypto.randomUUID();
      } catch (_) {
        /* insecure context on some mobile browsers */
      }
    }
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      const v = c === "x" ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  function readCookie(name) {
    const match = document.cookie.match(
      new RegExp("(?:^|; )" + name.replace(/[$()*+.?[\\\]^{|}]/g, "\\$&") + "=([^;]*)")
    );
    return match ? decodeURIComponent(match[1]) : null;
  }

  function writeCookie(name, value) {
    document.cookie =
      name +
      "=" +
      encodeURIComponent(value) +
      "; path=/; max-age=31536000; SameSite=Lax";
  }

  function persistClientId(id) {
    try {
      localStorage.setItem("sg_client_id", id);
    } catch (_) {}
    try {
      writeCookie("sg_client_id", id);
    } catch (_) {}
  }

  function loadClientId() {
    let id = null;
    try {
      id = localStorage.getItem("sg_client_id");
    } catch (_) {}
    if (!id) id = readCookie("sg_client_id");
    if (!id) id = uuid();
    persistClientId(id);
    return id;
  }

  // Session tokens are scoped to this QR token only — never reuse another table's secret.
  const sessionKey = TOKEN ? "sg_session_token_" + TOKEN : null;

  function loadSessionToken() {
    if (!sessionKey) return null;
    try {
      return localStorage.getItem(sessionKey) || readCookie(sessionKey);
    } catch (_) {
      return readCookie(sessionKey);
    }
  }

  function persistSessionToken(token) {
    if (!sessionKey || !token) return;
    try {
      localStorage.setItem(sessionKey, token);
    } catch (_) {}
    try {
      writeCookie(sessionKey, token);
    } catch (_) {}
  }

  const state = {
    clientId: loadClientId(),
    sessionToken: loadSessionToken(),
    restaurant: null,
    table: null,
    session: null,
    payment: null,
    menu: { categories: [], items: [] },
    selectedCategoryId: null,
    cart: [],
    orders: [],
    view: "menu", // menu | cart | bill
    loading: true,
    error: null,
    placing: false,
  };

  const el = document.getElementById("app");

  function money(n) {
    const v = Number(n || 0);
    return "₹" + (Number.isInteger(v) ? v.toString() : v.toFixed(2));
  }

  function toast(msg) {
    let t = document.querySelector(".toast");
    if (!t) {
      t = document.createElement("div");
      t.className = "toast";
      document.body.appendChild(t);
    }
    t.textContent = msg;
    t.classList.add("show");
    setTimeout(() => t.classList.remove("show"), 1400);
  }

  function activeOrderCount() {
    return state.orders.filter((o) => o.status !== "cancelled").length;
  }

  function applySessionDetail(detail) {
    if (!detail) return;
    state.session = detail;
    const orders = Array.isArray(detail.orders) ? detail.orders.slice() : [];
    orders.sort((a, b) => Number(b.id) - Number(a.id));
    state.orders = orders;
    if (detail.payment) state.payment = detail.payment;
    if (detail.table) state.table = detail.table;
  }

  async function api(path, options = {}) {
    const headers = {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-Client-Session": state.clientId,
      ...(options.headers || {}),
    };
    if (state.sessionToken) headers["X-Session-Token"] = state.sessionToken;

    let res;
    try {
      res = await fetch(API + path, { ...options, headers, cache: "no-store" });
    } catch (networkErr) {
      throw new Error(
        "Unable to reach the server. Check Wi‑Fi and that Laravel is running."
      );
    }

    const json = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new Error(json.message || "Request failed (" + res.status + ")");
    }
    return json.data !== undefined ? json.data : json;
  }

  function cartCount() {
    return state.cart.reduce((s, l) => s + l.quantity, 0);
  }

  function cartSubtotal() {
    return state.cart.reduce((s, l) => s + l.unitPrice * l.quantity, 0);
  }

  function cartTax() {
    const rate = Number(state.restaurant?.taxRate || 0);
    return cartSubtotal() * rate;
  }

  function cartTotal() {
    return cartSubtotal() + cartTax();
  }

  function addToCart(item) {
    const existing = state.cart.find((l) => l.menuItemId === String(item.id));
    if (existing) existing.quantity += 1;
    else {
      state.cart.push({
        menuItemId: String(item.id),
        name: item.name,
        unitPrice: Number(item.price),
        quantity: 1,
      });
    }
    toast(item.name + " added");
    render();
  }

  function setQty(menuItemId, qty) {
    if (qty <= 0) {
      state.cart = state.cart.filter((l) => l.menuItemId !== menuItemId);
    } else {
      const line = state.cart.find((l) => l.menuItemId === menuItemId);
      if (line) line.quantity = qty;
    }
    render();
  }

  async function bootstrap() {
    try {
      state.loading = true;
      state.error = null;
      render();

      const resolved = await api("/tables/resolve", {
        method: "POST",
        body: JSON.stringify({ token: TOKEN }),
      });

      if (!resolved.table?.publicToken || resolved.table.publicToken !== TOKEN) {
        throw new Error("Table token mismatch. Scan the QR again.");
      }

      state.restaurant = resolved.restaurant;
      state.table = resolved.table;
      state.payment = resolved.payment;
      state.sessionToken = resolved.sessionToken;
      persistSessionToken(state.sessionToken);
      applySessionDetail(resolved.session);

      const menu = await api("/restaurants/" + state.restaurant.id + "/menu");
      const categories = menu.categories || [];
      const items = [];
      categories.forEach((c) => {
        (c.items || []).forEach((i) => items.push(i));
      });
      state.menu = { categories, items };
      state.selectedCategoryId = categories[0]?.id ?? null;

      try {
        await refreshBill(false);
      } catch (_) {
        // Resolve already restored orders if the follow-up fetch fails.
      }

      // Returning customers with live orders land on bill, not empty menu.
      if (activeOrderCount() > 0) {
        state.view = "bill";
      }

      state.loading = false;
      render();
    } catch (e) {
      state.loading = false;
      state.error = e.message || "Unable to open this table.";
      render();
    }
  }

  async function refreshBill(showLoader = true) {
    if (!state.session?.id) return;
    if (showLoader) {
      /* soft refresh */
    }
    const detail = await api("/sessions/" + state.session.id);
    applySessionDetail(detail);
  }

  async function placeOrder() {
    if (!state.cart.length || state.placing) return;
    state.placing = true;
    render();
    try {
      await api("/sessions/" + state.session.id + "/orders", {
        method: "POST",
        body: JSON.stringify({
          items: state.cart.map((l) => ({
            menu_item_id: Number(l.menuItemId),
            quantity: l.quantity,
          })),
          idempotency_key: uuid(),
        }),
      });
      state.cart = [];
      await refreshBill(false);
      state.view = "bill";
      toast("Order placed");
    } catch (e) {
      toast(e.message || "Could not place order");
    } finally {
      state.placing = false;
      render();
    }
  }

  function statusBadge(status) {
    const s = String(status || "pending");
    return `<span class="badge ${s}">${s.charAt(0).toUpperCase() + s.slice(1)}</span>`;
  }

  function renderMenu() {
    const cats = state.menu.categories;
    const items = state.menu.items.filter(
      (i) =>
        !state.selectedCategoryId ||
        String(i.categoryId) === String(state.selectedCategoryId)
    );
    const orderCount = activeOrderCount();

    return `
      ${
        orderCount > 0
          ? `<button class="orders-banner" data-go="bill">
              <span>You have ${orderCount} active order${orderCount > 1 ? "s" : ""}</span>
              <strong>View bill →</strong>
            </button>`
          : ""
      }
      <div class="tabs">
        ${cats
          .map(
            (c) => `
          <button class="chip ${c.id === state.selectedCategoryId ? "active" : ""}" data-cat="${c.id}">
            ${escapeHtml(c.name)}
          </button>`
          )
          .join("")}
      </div>
      ${
        items.length === 0
          ? `<div class="empty-box"><h2>No items</h2><p>This category is empty.</p></div>`
          : items
              .map((item) => {
                const dietClass =
                  item.diet === "veg" || item.diet === "vegan"
                    ? "veg"
                    : item.diet === "nonveg"
                      ? "nonveg"
                      : "";
                return `
            <div class="card item-row">
              <div class="thumb">🍽</div>
              <div>
                <p class="item-name">
                  ${dietClass ? `<span class="diet ${dietClass}"></span>` : ""}
                  ${escapeHtml(item.name)}
                </p>
                ${item.description ? `<p class="item-desc">${escapeHtml(item.description)}</p>` : ""}
                <div class="item-price">${money(item.price)}</div>
              </div>
              <button class="add-btn" data-add="${item.id}">Add</button>
            </div>`;
              })
              .join("")
      }
      ${
        cartCount() > 0
          ? `<button class="cart-bar" data-go="cart">
              <span class="cart-count">${cartCount()}</span>
              <span>View cart</span>
              <strong>${money(cartTotal())}</strong>
            </button>`
          : ""
      }
    `;
  }

  function renderCart() {
    if (!state.cart.length) {
      return `
        <h2 class="panel-title">Your cart</h2>
        <div class="empty-box">
          <h2>Cart is empty</h2>
          <p>Add dishes from the menu.</p>
          <button class="primary-btn" data-go="menu">Browse menu</button>
        </div>`;
    }

    const taxRate = Number(state.restaurant?.taxRate || 0);
    return `
      <h2 class="panel-title">Your cart</h2>
      ${state.cart
        .map(
          (l) => `
        <div class="card" style="display:flex;align-items:center;gap:12px;">
          <div style="flex:1">
            <p class="item-name">${escapeHtml(l.name)}</p>
            <p class="muted">${money(l.unitPrice)} each</p>
          </div>
          <div class="qty">
            <button data-qty="${l.menuItemId}" data-delta="-1">−</button>
            <span>${l.quantity}</span>
            <button data-qty="${l.menuItemId}" data-delta="1">+</button>
          </div>
          <strong>${money(l.unitPrice * l.quantity)}</strong>
        </div>`
        )
        .join("")}
      <div class="card totals">
        <div class="totals-row"><span>Subtotal</span><span>${money(cartSubtotal())}</span></div>
        ${
          taxRate > 0
            ? `<div class="totals-row"><span>Tax (${(taxRate * 100).toFixed(0)}%)</span><span>${money(cartTax())}</span></div>`
            : ""
        }
        <div class="totals-row grand"><span>Total</span><span>${money(cartTotal())}</span></div>
      </div>
      <button class="primary-btn" data-place ${state.placing ? "disabled" : ""}>
        ${state.placing ? "Placing…" : "Place order · " + money(cartTotal())}
      </button>
      <button class="secondary-btn" data-go="menu">Back to menu</button>
    `;
  }

  function renderBill() {
    const payable =
      Number(state.payment?.amountDue ?? 0) ||
      state.orders
        .filter((o) => o.status !== "cancelled")
        .reduce((s, o) => s + Number(o.grandTotal || 0), 0);
    const paid = state.payment?.status === "paid";

    return `
      <div class="bill-hero ${paid ? "paid" : ""}">
        <div class="label">${paid ? "Payment received" : "Total payable"}</div>
        <div class="amount">${money(payable)}</div>
        <div class="pill">${paid ? "Thank you — enjoy your meal" : "Please pay at the counter"}</div>
      </div>
      <h2 class="panel-title">Orders</h2>
      ${
        state.orders.length === 0
          ? `<div class="card muted">No orders yet. Browse the menu to get started.</div>`
          : state.orders
              .map(
                (o) => `
          <div class="card">
            <div style="display:flex;justify-content:space-between;align-items:center;gap:8px;">
              <strong>Order #${o.id}</strong>
              ${statusBadge(o.status)}
            </div>
            <div style="margin-top:10px;">
              ${(o.items || [])
                .map(
                  (i) =>
                    `<div class="muted">${i.quantity}× ${escapeHtml(i.name || i.nameSnapshot || "Item")}</div>`
                )
                .join("")}
            </div>
            <div style="margin-top:10px;font-weight:700;color:var(--saffron-dark)">${money(o.grandTotal)}</div>
          </div>`
              )
              .join("")
      }
      <button class="primary-btn" data-go="menu">Order more</button>
      <button class="secondary-btn" data-refresh>Refresh status</button>
    `;
  }

  function escapeHtml(str) {
    return String(str ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  function render() {
    if (state.loading) {
      el.innerHTML = `<div class="boot">Opening your table…</div>`;
      return;
    }
    if (state.error) {
      el.innerHTML = `
        <div class="app-shell">
          <div class="error-box">
            <h2>Can't open table</h2>
            <p>${escapeHtml(state.error)}</p>
            <button class="primary-btn" data-retry>Try again</button>
          </div>
        </div>`;
      return;
    }

    const restaurantName = state.restaurant?.name || cfg.restaurantName || "Restaurant";
    const tableLabel = state.table?.label || cfg.tableLabel || "Table";

    const count = cartCount();
    const orderCount = activeOrderCount();
    el.innerHTML = `
      <div class="app-shell">
        <div class="topbar">
          <button type="button" class="brand brand-home" title="Back to menu" data-home>
            <div class="logo">🍽</div>
            <div>
              <h1>${escapeHtml(restaurantName)}</h1>
              <p>${escapeHtml(tableLabel)}</p>
            </div>
          </button>
          <div class="topbar-actions">
            <button class="icon-btn ${state.view === "cart" ? "active" : ""}" title="Cart" data-go="cart">
              🛒
              ${count > 0 ? `<span class="icon-badge">${count}</span>` : ""}
            </button>
            <button class="icon-btn ${state.view === "bill" ? "active" : ""}" title="Bill & orders" data-go="bill">
              🧾
              ${orderCount > 0 ? `<span class="icon-badge">${orderCount}</span>` : ""}
            </button>
          </div>
        </div>
        ${
          state.view === "menu"
            ? renderMenu()
            : state.view === "cart"
              ? renderCart()
              : renderBill()
        }
      </div>
    `;
  }

  el.addEventListener("click", async (e) => {
    const t = e.target.closest("[data-cat],[data-add],[data-go],[data-qty],[data-place],[data-retry],[data-refresh],[data-home]");
    if (!t) return;

    if (t.hasAttribute("data-home")) {
      state.view = "menu";
      render();
      return;
    }

    if (t.dataset.cat) {
      state.selectedCategoryId = Number(t.dataset.cat) || t.dataset.cat;
      render();
      return;
    }
    if (t.dataset.add) {
      const item = state.menu.items.find((i) => String(i.id) === String(t.dataset.add));
      if (item) addToCart(item);
      return;
    }
    if (t.dataset.go) {
      state.view = t.dataset.go;
      if (state.view === "bill") {
        try {
          await refreshBill(false);
        } catch (_) {}
      }
      render();
      return;
    }
    if (t.dataset.qty) {
      const line = state.cart.find((l) => l.menuItemId === t.dataset.qty);
      if (!line) return;
      setQty(line.menuItemId, line.quantity + Number(t.dataset.delta));
      return;
    }
    if (t.hasAttribute("data-place")) {
      await placeOrder();
      return;
    }
    if (t.hasAttribute("data-retry")) {
      bootstrap();
      return;
    }
    if (t.hasAttribute("data-refresh")) {
      try {
        await refreshBill(false);
        toast("Updated");
        render();
      } catch (err) {
        toast(err.message || "Refresh failed");
      }
    }
  });

  // Poll bill quietly while on bill view
  setInterval(async () => {
    if (state.view !== "bill" || !state.session?.id || state.loading) return;
    try {
      await refreshBill(false);
      render();
    } catch (_) {}
  }, 12000);

  // Re-join after browser back-forward cache restores a blank stale page.
  window.addEventListener("pageshow", (event) => {
    if (event.persisted && TOKEN && TOKEN.length >= 24) {
      bootstrap();
    }
  });

  if (!TOKEN) {
    state.loading = false;
    state.error = "Missing table token in the QR link.";
    render();
  } else if (TOKEN.length < 24) {
    state.loading = false;
    state.error =
      "This QR link is invalid or outdated. Ask staff for a new table QR.";
    render();
  } else {
    bootstrap();
  }
})();
