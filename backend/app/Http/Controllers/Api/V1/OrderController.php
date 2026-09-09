<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\UpdateOrderStatusRequest;
use App\Http\Resources\Api\V1\OrderResource;
use App\Models\Order;
use App\Services\OrderStatusMachine;
use App\Services\PlaceOrderService;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $restaurantId = $request->user()->restaurant_id;

        $query = Order::query()
            ->where('restaurant_id', $restaurantId)
            ->with(['items', 'table'])
            ->latest('id');

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        if ($sessionId = $request->query('session_id')) {
            $query->where('dining_session_id', $sessionId);
        }

        if ($tableId = $request->query('table_id')) {
            $query->where('table_id', $tableId);
        }

        $orders = $query->paginate((int) $request->query('per_page', 50));

        return OrderResource::collection($orders);
    }

    public function updateStatus(
        UpdateOrderStatusRequest $request,
        Order $order,
        OrderStatusMachine $machine,
        PlaceOrderService $placeOrderService,
    ) {
        if ($order->restaurant_id !== $request->user()->restaurant_id) {
            return response()->json(['message' => 'Order not found.'], 404);
        }

        $to = OrderStatus::from($request->validated('status'));

        try {
            $machine->assertCanTransition($order->status, $to, $request->user());
        } catch (InvalidArgumentException $e) {
            throw ValidationException::withMessages([
                'status' => [$e->getMessage()],
            ]);
        }

        $order->update(['status' => $to]);

        if ($to === OrderStatus::Cancelled) {
            $placeOrderService->recalculatePaymentDue($order->diningSession);
        }

        $order->load(['items', 'table']);

        return response()->json([
            'data' => new OrderResource($order),
            'message' => 'Order status updated.',
        ]);
    }
}
