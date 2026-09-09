# Spice Garden — Restaurant QR Ordering

- **Flutter app** = staff only (orders, tables/QR, menu, payments)
- **Customer web** = browser ordering from table QR
- Payment is at the counter only (no online payments)

## Quick start

### 1. Backend + customer web

```bash
cd backend
composer install
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

| What | URL |
|------|-----|
| API | `http://192.168.1.10:8000/api/v1` |
| Customer order page | `http://192.168.1.10:8000/t/table-1` |

After editing customer UI source:

```bash
cp customer-web/app.js customer-web/styles.css backend/public/customer-web/
```

### 2. Staff Flutter app

```bash
flutter pub get
flutter run
```

Set LAN IP in `.env` / `.env.development`:

- `API_BASE_URL=http://192.168.1.10:8000/api/v1`
- `QR_PUBLIC_BASE_URL=http://192.168.1.10:8000`

## Demo credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@gmail.com` | `password` |
| Manager | `manager@gmail.com` | `password` |
| Waiter | `waiter@gmail.com` | `password` |
| Kitchen | `kitchen@gmail.com` | `password` |

**Tables:** `table-1` … `table-8`

## How to try it

1. Start Laravel on `0.0.0.0:8000`
2. Staff app → sign in → **Tables → QR** (prints `http://…/t/table-X`)
3. Phone camera scans QR → customer web opens (menu → cart → order → bill)
4. Staff app → accept / prepare / ready / served / complete → **Mark paid**

Phone and PC must be on the same Wi‑Fi.
