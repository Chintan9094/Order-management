<?php

use App\Http\Controllers\TableLandingController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'app' => 'Spice Garden',
        'message' => 'Staff use the mobile app. Customers scan a table QR.',
    ]);
});

// Customer ordering web app (opened by phone camera QR)
Route::get('/t/{token}', [TableLandingController::class, 'show'])
    ->where('token', '[A-Za-z0-9\\-_]+');
