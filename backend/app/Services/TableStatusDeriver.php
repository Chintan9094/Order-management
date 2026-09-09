<?php

namespace App\Services;

use App\Enums\DiningSessionStatus;
use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Models\DiningSession;
use App\Models\RestaurantTable;

class TableStatusDeriver
{
    public function derive(RestaurantTable $table): string
    {
        $session = $table->relationLoaded('diningSessions')
            ? $table->diningSessions
                ->where('status', DiningSessionStatus::Open)
                ->sortByDesc('id')
                ->first()
            : $table->openSession()->with(['orders', 'payment'])->first();

        if (! $session instanceof DiningSession) {
            return 'available';
        }

        $session->loadMissing(['orders', 'payment']);

        $paymentStatus = $session->payment?->status;

        if ($paymentStatus === PaymentStatus::Paid) {
            return 'paid';
        }

        if ($paymentStatus === PaymentStatus::PaymentPending) {
            return 'payment_pending';
        }

        $orders = $session->orders->filter(
            fn ($order) => $order->status !== OrderStatus::Cancelled
        );

        if ($orders->isEmpty()) {
            return 'occupied';
        }

        $priority = [
            OrderStatus::Pending->value => 1,
            OrderStatus::Accepted->value => 2,
            OrderStatus::Preparing->value => 3,
            OrderStatus::Ready->value => 4,
            OrderStatus::Served->value => 5,
            OrderStatus::Completed->value => 6,
        ];

        $active = $orders
            ->reject(fn ($order) => $order->status === OrderStatus::Completed)
            ->sortByDesc(fn ($order) => $priority[$order->status->value] ?? 0)
            ->first();

        if ($active === null) {
            return 'awaiting_payment';
        }

        return match ($active->status) {
            OrderStatus::Pending => 'pending_orders',
            OrderStatus::Accepted => 'accepted',
            OrderStatus::Preparing => 'preparing',
            OrderStatus::Ready => 'ready',
            OrderStatus::Served => 'served',
            default => 'occupied',
        };
    }
}
