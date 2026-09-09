<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\DiningSessionStatus;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\TableResolveRequest;
use App\Http\Resources\Api\V1\DiningSessionResource;
use App\Http\Resources\Api\V1\PaymentResource;
use App\Http\Resources\Api\V1\RestaurantResource;
use App\Http\Resources\Api\V1\RestaurantTableResource;
use App\Models\DiningSession;
use App\Models\Payment;
use App\Models\RestaurantTable;
use App\Models\SessionParticipant;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TableResolveController extends Controller
{
    public function store(TableResolveRequest $request)
    {
        $clientSession = $request->header('X-Client-Session');

        if (! $clientSession) {
            return response()->json(['message' => 'X-Client-Session header is required.'], 422);
        }

        $table = RestaurantTable::query()
            ->with('restaurant')
            ->where('public_token', $request->validated('token'))
            ->where('is_active', true)
            ->first();

        if (! $table || ! $table->restaurant?->is_active) {
            return response()->json(['message' => 'Table not found.'], 404);
        }

        $result = DB::transaction(function () use ($table, $clientSession) {
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

            SessionParticipant::query()->firstOrCreate(
                [
                    'dining_session_id' => $session->id,
                    'client_session_id' => $clientSession,
                ],
                ['joined_at' => now()]
            );

            $payment = Payment::query()->firstOrCreate(
                ['dining_session_id' => $session->id],
                [
                    'status' => PaymentStatus::Unpaid,
                    'amount_due' => 0,
                ]
            );

            // Always return live orders so a customer can leave and re-scan
            // without losing what they already placed.
            $session->load(['orders.items', 'payment', 'table']);

            return compact('session', 'payment');
        });

        return response()->json([
            'data' => [
                'restaurant' => new RestaurantResource($table->restaurant),
                'table' => new RestaurantTableResource($table),
                'session' => new DiningSessionResource($result['session']),
                'sessionToken' => $result['session']->access_token,
                'payment' => new PaymentResource($result['session']->payment ?? $result['payment']),
            ],
        ]);
    }
}
