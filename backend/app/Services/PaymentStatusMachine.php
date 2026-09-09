<?php

namespace App\Services;

use App\Enums\PaymentStatus;
use InvalidArgumentException;

class PaymentStatusMachine
{
    /**
     * @var array<string, list<string>>
     */
    private const TRANSITIONS = [
        PaymentStatus::Unpaid->value => [
            PaymentStatus::PaymentPending->value,
            PaymentStatus::Paid->value,
        ],
        PaymentStatus::PaymentPending->value => [
            PaymentStatus::Paid->value,
            PaymentStatus::Unpaid->value,
        ],
        PaymentStatus::Paid->value => [],
    ];

    public function canTransition(PaymentStatus $from, PaymentStatus $to): bool
    {
        $allowed = self::TRANSITIONS[$from->value] ?? [];

        return in_array($to->value, $allowed, true);
    }

    public function assertCanTransition(PaymentStatus $from, PaymentStatus $to): void
    {
        if (! $this->canTransition($from, $to)) {
            throw new InvalidArgumentException(
                "Cannot transition payment from {$from->value} to {$to->value}."
            );
        }
    }
}
