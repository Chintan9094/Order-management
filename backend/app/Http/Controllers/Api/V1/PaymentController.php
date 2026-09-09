<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\DiningSessionStatus;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\DiningSessionResource;
use App\Http\Resources\Api\V1\PaymentResource;
use App\Models\DiningSession;
use App\Models\Payment;
use App\Services\PaymentStatusMachine;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;

class PaymentController extends Controller
{
    public function markPaid(Request $request, Payment $payment, PaymentStatusMachine $machine)
    {
        $payment->load('diningSession');

        if ($payment->diningSession?->restaurant_id !== $request->user()->restaurant_id) {
            return response()->json(['message' => 'Payment not found.'], 404);
        }

        try {
            $machine->assertCanTransition($payment->status, PaymentStatus::Paid);
        } catch (InvalidArgumentException $e) {
            throw ValidationException::withMessages([
                'status' => [$e->getMessage()],
            ]);
        }

        $payment = DB::transaction(function () use ($payment, $request) {
            $payment->update([
                'status' => PaymentStatus::Paid,
                'amount_paid' => $payment->amount_due,
                'paid_at' => now(),
                'marked_by_staff_id' => $request->user()->id,
            ]);

            $payment->diningSession->update([
                'allows_new_orders' => false,
            ]);

            return $payment->fresh();
        });

        return response()->json([
            'data' => new PaymentResource($payment),
            'message' => 'Payment marked as paid.',
        ]);
    }

    public function closeSession(Request $request, DiningSession $session)
    {
        if ($session->restaurant_id !== $request->user()->restaurant_id) {
            return response()->json(['message' => 'Session not found.'], 404);
        }

        if ($session->status === DiningSessionStatus::Closed) {
            return response()->json(['message' => 'Session is already closed.'], 422);
        }

        $session->load('payment');

        if ($session->payment && $session->payment->status !== PaymentStatus::Paid) {
            if ((float) $session->payment->amount_due > 0) {
                return response()->json([
                    'message' => 'Cannot close session while payment is unpaid.',
                ], 422);
            }
        }

        $session = DB::transaction(function () use ($session) {
            $session->update([
                'status' => DiningSessionStatus::Closed,
                'allows_new_orders' => false,
                'closed_at' => now(),
            ]);

            return $session->fresh(['payment', 'orders.items', 'table']);
        });

        return response()->json([
            'data' => new DiningSessionResource($session),
            'message' => 'Session closed. Table is now available.',
        ]);
    }
}
