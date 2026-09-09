<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\PlaceOrderRequest;
use App\Http\Resources\Api\V1\OrderResource;
use App\Models\DiningSession;
use App\Services\PlaceOrderService;
use Illuminate\Http\Request;

class SessionOrderController extends Controller
{
    public function index(Request $request, DiningSession $session)
    {
        /** @var DiningSession $tokenSession */
        $tokenSession = $request->attributes->get('dining_session');

        if ($tokenSession->id !== $session->id) {
            return response()->json(['message' => 'Session token does not match requested session.'], 403);
        }

        $orders = $session->orders()->with('items')->latest('id')->get();

        return response()->json([
            'data' => OrderResource::collection($orders),
        ]);
    }

    public function store(PlaceOrderRequest $request, DiningSession $session, PlaceOrderService $placeOrderService)
    {
        /** @var DiningSession $tokenSession */
        $tokenSession = $request->attributes->get('dining_session');

        if ($tokenSession->id !== $session->id) {
            return response()->json(['message' => 'Session token does not match requested session.'], 403);
        }

        $order = $placeOrderService->place(
            $session,
            $request->validated('items'),
            $request->validated('notes'),
            $request->validated('idempotency_key'),
        );

        return response()->json([
            'data' => new OrderResource($order),
            'message' => 'Order placed successfully.',
        ], 201);
    }
}
