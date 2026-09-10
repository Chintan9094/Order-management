<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\DiningSessionStatus;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\PlaceOrderRequest;
use App\Http\Resources\Api\V1\OrderResource;
use App\Models\DiningSession;
use App\Models\Payment;
use App\Models\RestaurantTable;
use App\Models\SessionParticipant;
use App\Services\PlaceOrderService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class StaffTableOrderController extends Controller
{
    /**
     * Staff places an order on behalf of a guest at a table.
     * Opens a dining session if the table does not have one yet.
     */
    public function store(
        PlaceOrderRequest $request,
        RestaurantTable $table,
        PlaceOrderService $placeOrderService,
    ) {
        $this->assertRestaurant($request, $table);

        if (! $table->is_active) {
            return response()->json(['message' => 'This table is inactive.'], 422);
        }

        $session = DB::transaction(function () use ($request, $table) {
            $session = DiningSession::query()
                ->where('table_id', $table->id)
                ->where('status', DiningSessionStatus::Open)
                ->lockForUpdate()
                ->first();

            if (! $session) {
                $session = DiningSession::query()->create([
                    'restaurant_id' => $table->restaurant_id,
                    'table_id' => $table->id,
                    'status' => DiningSessionStatus::Open,
                    'access_token' => Str::random(64),
                    'allows_new_orders' => true,
                    'started_at' => now(),
                ]);
            }

            Payment::query()->firstOrCreate(
                ['dining_session_id' => $session->id],
                [
                    'status' => PaymentStatus::Unpaid,
                    'amount_due' => 0,
                ]
            );

            $staffClientId = 'staff-'.$request->user()->id;
            SessionParticipant::query()->firstOrCreate(
                [
                    'dining_session_id' => $session->id,
                    'client_session_id' => $staffClientId,
                ],
                ['joined_at' => now()]
            );

            return $session;
        });

        $order = $placeOrderService->place(
            $session,
            $request->validated('items'),
            $request->validated('notes'),
            $request->validated('idempotency_key'),
        );

        $order->load('items');

        return response()->json([
            'data' => new OrderResource($order),
            'message' => 'Order placed for '.$table->label.'.',
        ], 201);
    }

    private function assertRestaurant(Request $request, RestaurantTable $table): void
    {
        if ($table->restaurant_id !== $request->user()->restaurant_id) {
            abort(response()->json(['message' => 'Table not found.'], 404));
        }
    }
}
