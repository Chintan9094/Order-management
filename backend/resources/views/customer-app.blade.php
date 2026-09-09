<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <title>{{ $restaurantName }} · {{ $tableLabel }}</title>
  <link rel="stylesheet" href="{{ asset('customer-web/styles.css') }}?v={{ filemtime(public_path('customer-web/styles.css')) }}" />
</head>
<body>
  <div id="app">
    <div class="boot">Opening your table…</div>
  </div>
  <script>
    window.__CUSTOMER__ = {
      tableToken: @json($token),
      apiBase: @json($apiBase),
      restaurantName: @json($restaurantName),
      tableLabel: @json($tableLabel),
    };
  </script>
  <script src="{{ asset('customer-web/app.js') }}?v={{ filemtime(public_path('customer-web/app.js')) }}" defer></script>
</body>
</html>
