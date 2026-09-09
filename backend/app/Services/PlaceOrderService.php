<?php

namespace App\Services;

use App\Enums\DiningSessionStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Models\DiningSession;
use App\Models\MenuItem;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class PlaceOrderService
{
    /**
     * @param  list<array{menu_item_id:int, quantity:int, note?:string|null}>  $items
     */
    public function place(DiningSession $session, array $items, ?string $notes = null, ?string $idempotencyKey = null): Order
    {
        if ($session->status !== DiningSessionStatus::Open) {
            throw ValidationException::withMessages([
                'session' => ['This dining session is closed.'],
            ]);
        }

        if (! $session->allows_new_orders) {
            throw ValidationException::withMessages([
                'session' => ['This session no longer accepts new orders.'],
            ]);
        }

        $session->loadMissing(['restaurant', 'payment']);

        if ($session->payment?->status === PaymentStatus::Paid) {
            throw ValidationException::withMessages([
                'session' => ['Payment is already completed for this session.'],
            ]);
        }

        if ($idempotencyKey) {
            $existing = Order::query()
                ->where('dining_session_id', $session->id)
                ->where('idempotency_key', $idempotencyKey)
                ->first();

            if ($existing) {
                return $existing->load('items');
            }
        }

        $menuItemIds = collect($items)->pluck('menu_item_id')->unique()->values()->all();

        $menuItems = MenuItem::query()
            ->where('restaurant_id', $session->restaurant_id)
            ->whereIn('id', $menuItemIds)
            ->get()
            ->keyBy('id');

        $linePayloads = [];
        $subtotal = 0.0;

        foreach ($items as $index => $line) {
            $menuItem = $menuItems->get($line['menu_item_id']);

            if (! $menuItem) {
                throw ValidationException::withMessages([
                    "items.$index.menu_item_id" => ['Menu item was not found for this restaurant.'],
                ]);
            }

            if (! $menuItem->is_active || ! $menuItem->is_available) {
                throw ValidationException::withMessages([
                    "items.$index.menu_item_id" => ["{$menuItem->name} is not available."],
                ]);
            }

            $quantity = (int) $line['quantity'];
            $unitPrice = (float) $menuItem->price;
            $lineTotal = round($unitPrice * $quantity, 2);
            $subtotal += $lineTotal;

            $linePayloads[] = [
                'menu_item_id' => $menuItem->id,
                'name_snapshot' => $menuItem->name,
                'unit_price_snapshot' => $unitPrice,
                'quantity' => $quantity,
                'line_total' => $lineTotal,
                'note' => $line['note'] ?? null,
            ];
        }

        $restaurant = $session->restaurant;
        $tax = round($subtotal * (float) $restaurant->tax_rate, 2);
        $serviceCharge = round($subtotal * (float) $restaurant->service_charge_rate, 2);
        $grandTotal = round($subtotal + $tax + $serviceCharge, 2);

        return DB::transaction(function () use ($session, $linePayloads, $subtotal, $tax, $serviceCharge, $grandTotal, $notes, $idempotencyKey) {
            $order = Order::query()->create([
                'dining_session_id' => $session->id,
                'restaurant_id' => $session->restaurant_id,
                'table_id' => $session->table_id,
                'status' => OrderStatus::Pending,
                'subtotal' => $subtotal,
                'tax' => $tax,
                'service_charge' => $serviceCharge,
                'grand_total' => $grandTotal,
                'notes' => $notes,
                'idempotency_key' => $idempotencyKey,
            ]);

            foreach ($linePayloads as $payload) {
                OrderItem::query()->create([
                    'order_id' => $order->id,
                    ...$payload,
                ]);
            }

            $this->recalculatePaymentDue($session);

            return $order->load('items');
        });
    }

    public function recalculatePaymentDue(DiningSession $session): Payment
    {
        $amountDue = (float) Order::query()
            ->where('dining_session_id', $session->id)
            ->where('status', '!=', OrderStatus::Cancelled->value)
            ->sum('grand_total');

        $payment = Payment::query()->firstOrCreate(
            ['dining_session_id' => $session->id],
            [
                'status' => PaymentStatus::Unpaid,
                'amount_due' => 0,
            ]
        );

        if ($payment->status !== PaymentStatus::Paid) {
            $payment->update(['amount_due' => round($amountDue, 2)]);
        }

        return $payment->fresh();
    }
}
