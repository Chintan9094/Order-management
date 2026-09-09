<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\DiningSessionStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\OrderResource;
use App\Http\Resources\Api\V1\RestaurantTableResource;
use App\Models\DiningSession;
use App\Models\Order;
use App\Models\RestaurantTable;
use App\Services\TableStatusDeriver;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request, TableStatusDeriver $tableStatusDeriver)
    {
        $restaurantId = $request->user()->restaurant_id;

        $tables = RestaurantTable::query()
            ->where('restaurant_id', $restaurantId)
            ->where('is_active', true)
            ->with(['openSession.orders', 'openSession.payment'])
            ->orderBy('label')
            ->get()
            ->map(function (RestaurantTable $table) use ($tableStatusDeriver) {
                $table->derived_status = $tableStatusDeriver->derive($table);

                return $table;
            });

        $openSessions = DiningSession::query()
            ->where('restaurant_id', $restaurantId)
            ->where('status', DiningSessionStatus::Open)
            ->count();

        $activeOrders = Order::query()
            ->where('restaurant_id', $restaurantId)
            ->whereNotIn('status', [
                OrderStatus::Completed->value,
                OrderStatus::Cancelled->value,
            ])
            ->count();

        $unpaidSessions = DiningSession::query()
            ->where('restaurant_id', $restaurantId)
            ->where('status', DiningSessionStatus::Open)
            ->whereHas('payment', function ($query) {
                $query->whereIn('status', [
                    PaymentStatus::Unpaid->value,
                    PaymentStatus::PaymentPending->value,
                ]);
            })
            ->count();

        $recentOrders = Order::query()
            ->where('restaurant_id', $restaurantId)
            ->with(['items', 'table'])
            ->latest('id')
            ->limit(10)
            ->get();

        return response()->json([
            'data' => [
                'stats' => [
                    'openSessions' => $openSessions,
                    'activeOrders' => $activeOrders,
                    'unpaidSessions' => $unpaidSessions,
                    'tables' => $tables->count(),
                ],
                'tables' => RestaurantTableResource::collection($tables),
                'recentOrders' => OrderResource::collection($recentOrders),
            ],
        ]);
    }
}
