# Spice Garden API

Laravel 13 REST API for restaurant QR ordering (staff + customer session flows).

## Run locally

```bash
cd backend
composer install
cp .env.example .env   # if needed
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Base URL: `http://localhost:8000/api/v1`

Auth: Sanctum bearer tokens (`Authorization: Bearer <token>`).

Customer session: send `X-Session-Token` (from table resolve) and `X-Client-Session` (stable device/browser id) where noted.

## Seeded staff (password: `password`)

| Email | Role |
|---|---|
| `admin@gmail.com` | admin |
| `manager@gmail.com` | manager |
| `waiter@gmail.com` | waiter |
| `kitchen@gmail.com` | kitchen |

Restaurant: **Spice Garden** (INR, 5% tax).

## Table QR tokens

Table URLs use **opaque secrets** (40+ random characters), not guessable values like `table-1`.

- Customer link: `http://<host>:8000/t/<public_token>`
- Get tokens / QR from the staff app: **Tables → QR** (or after `php artisan migrate:fresh --seed`, the seed output prints them once)
- Changing the path to another guessed token returns 404 — you cannot hop tables by editing the URL

Example resolve (replace the token with a real one from seed/staff QR):

```bash
curl -X POST http://localhost:8000/api/v1/tables/resolve \
  -H "Content-Type: application/json" \
  -H "X-Client-Session: demo-device-1" \
  -d '{"token":"<opaque-public-token-from-qr>"}'
```

To rotate all table QR secrets without wiping other data:

```bash
php artisan tables:rotate-tokens
```

Then reprint every table QR from the staff app.

## Useful endpoints

| Method | Path | Auth |
|---|---|---|
| POST | `/auth/login` | public |
| GET | `/auth/me` | staff |
| GET | `/dashboard` | staff |
| GET | `/restaurants/{id}/menu` | public |
| POST | `/tables/resolve` | public (+ `X-Client-Session`) |
| GET/POST | `/sessions/{id}` / `/sessions/{id}/orders` | customer (`X-Session-Token`) |
| PATCH | `/orders/{id}/status` | staff |
| POST | `/payments/{id}/mark-paid` | staff |
| POST | `/sessions/{id}/close` | staff |

CORS allows all origins for local Flutter web (`localhost` any port).
