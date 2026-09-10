<?php

namespace App\Services;

use App\Enums\OrderStatus;
use App\Enums\StaffRole;
use App\Models\User;
use InvalidArgumentException;

class OrderStatusMachine
{
    /**
     * Allowed forward transitions (excluding cancel).
     *
     * @var array<string, list<string>>
     */
    private const TRANSITIONS = [
        OrderStatus::Pending->value => [OrderStatus::Accepted->value],
        OrderStatus::Accepted->value => [OrderStatus::Preparing->value],
        // Primary kitchen flow: Prepare → Serve (skip Ready in staff UI).
        OrderStatus::Preparing->value => [OrderStatus::Served->value, OrderStatus::Ready->value],
        OrderStatus::Ready->value => [OrderStatus::Served->value],
        OrderStatus::Served->value => [OrderStatus::Completed->value],
        OrderStatus::Completed->value => [],
        OrderStatus::Cancelled->value => [],
    ];

    public function canTransition(OrderStatus $from, OrderStatus $to, User $actor): bool
    {
        if ($to === OrderStatus::Cancelled) {
            return $this->canCancel($from, $actor);
        }

        $allowed = self::TRANSITIONS[$from->value] ?? [];

        return in_array($to->value, $allowed, true);
    }

    public function assertCanTransition(OrderStatus $from, OrderStatus $to, User $actor): void
    {
        if (! $this->canTransition($from, $to, $actor)) {
            throw new InvalidArgumentException(
                "Cannot transition order from {$from->value} to {$to->value}."
            );
        }
    }

    public function canCancel(OrderStatus $from, User $actor): bool
    {
        $role = $actor->role instanceof StaffRole
            ? $actor->role
            : StaffRole::tryFrom((string) $actor->role);

        if ($from === OrderStatus::Pending) {
            return $role !== null;
        }

        if ($from === OrderStatus::Accepted) {
            return $role?->isManagerOrAbove() ?? false;
        }

        return false;
    }

    /**
     * @return list<string>
     */
    public function allowedTargets(OrderStatus $from, User $actor): array
    {
        $targets = self::TRANSITIONS[$from->value] ?? [];

        if ($this->canCancel($from, $actor)) {
            $targets[] = OrderStatus::Cancelled->value;
        }

        return $targets;
    }
}
