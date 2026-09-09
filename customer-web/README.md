# Customer Web (QR ordering)

Customers **do not** use the Flutter app. They scan a table QR and order in the browser.

## URL

`http://<LAN-IP>:8000/t/{tableToken}`

Example: `http://192.168.1.10:8000/t/<opaque-token-from-staff-qr>`

Tokens are long random secrets (not `table-1`). Guessing another table in the URL returns 404.

## Features

- Resolve table / dining session
- Browse menu by category
- Cart + place order
- Bill / order status (pay at counter)

## Files

| Path | Purpose |
|------|---------|
| `customer-web/app.js` | Ordering UI logic |
| `customer-web/styles.css` | Styles |
| `backend/public/customer-web/*` | Published assets served by Laravel |
| `backend/resources/views/customer-app.blade.php` | Page shell |

After editing JS/CSS, copy into public:

```bash
cp customer-web/app.js customer-web/styles.css backend/public/customer-web/
```

## Run

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

Staff Flutter app generates QR codes pointing at this URL.
