<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CategoryController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\MenuController;
use App\Http\Controllers\Api\V1\MenuItemController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\SessionController;
use App\Http\Controllers\Api\V1\SessionOrderController;
use App\Http\Controllers\Api\V1\StaffTableOrderController;
use App\Http\Controllers\Api\V1\TableController;
use App\Http\Controllers\Api\V1\TableResolveController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Public customer endpoints
    Route::post('tables/resolve', [TableResolveController::class, 'store']);
    Route::get('restaurants/{restaurant}/menu', [MenuController::class, 'show']);

    Route::middleware('customer.session')->group(function () {
        Route::get('sessions/{session}', [SessionController::class, 'show']);
        Route::get('sessions/{session}/orders', [SessionOrderController::class, 'index']);
        Route::post('sessions/{session}/orders', [SessionOrderController::class, 'store']);
    });

    // Staff auth
    Route::post('auth/login', [AuthController::class, 'login']);

    Route::middleware(['auth:sanctum', 'staff.restaurant'])->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('auth/me', [AuthController::class, 'me']);

        Route::get('dashboard', [DashboardController::class, 'index']);

        Route::get('orders', [OrderController::class, 'index']);
        Route::patch('orders/{order}/status', [OrderController::class, 'updateStatus']);
        Route::post('tables/{table}/orders', [StaffTableOrderController::class, 'store'])
            ->middleware('permission:admin,manager,waiter');

        Route::get('tables', [TableController::class, 'index']);
        Route::post('tables', [TableController::class, 'store'])
            ->middleware('permission:admin,manager');
        Route::get('tables/{table}', [TableController::class, 'show']);
        Route::put('tables/{table}', [TableController::class, 'update'])
            ->middleware('permission:admin,manager');
        Route::patch('tables/{table}', [TableController::class, 'update'])
            ->middleware('permission:admin,manager');
        Route::delete('tables/{table}', [TableController::class, 'destroy'])
            ->middleware('permission:admin,manager');
        Route::get('tables/{table}/qr', [TableController::class, 'qr']);

        Route::get('categories', [CategoryController::class, 'index']);
        Route::post('categories', [CategoryController::class, 'store'])
            ->middleware('permission:admin,manager');
        Route::get('categories/{category}', [CategoryController::class, 'show']);
        Route::put('categories/{category}', [CategoryController::class, 'update'])
            ->middleware('permission:admin,manager');
        Route::patch('categories/{category}', [CategoryController::class, 'update'])
            ->middleware('permission:admin,manager');
        Route::delete('categories/{category}', [CategoryController::class, 'destroy'])
            ->middleware('permission:admin,manager');

        Route::get('menu-items', [MenuItemController::class, 'index']);
        Route::post('menu-items', [MenuItemController::class, 'store'])
            ->middleware('permission:admin,manager');
        Route::get('menu-items/{menuItem}', [MenuItemController::class, 'show']);
        Route::put('menu-items/{menuItem}', [MenuItemController::class, 'update'])
            ->middleware('permission:admin,manager');
        Route::patch('menu-items/{menuItem}', [MenuItemController::class, 'update'])
            ->middleware('permission:admin,manager');
        Route::delete('menu-items/{menuItem}', [MenuItemController::class, 'destroy'])
            ->middleware('permission:admin,manager');

        Route::post('payments/{payment}/mark-paid', [PaymentController::class, 'markPaid'])
            ->middleware('permission:admin,manager,waiter');
        Route::post('sessions/{session}/close', [PaymentController::class, 'closeSession'])
            ->middleware('permission:admin,manager,waiter');
    });
});
