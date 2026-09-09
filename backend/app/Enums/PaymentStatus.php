<?php

namespace App\Enums;

enum PaymentStatus: string
{
    case Unpaid = 'unpaid';
    case PaymentPending = 'payment_pending';
    case Paid = 'paid';
}
