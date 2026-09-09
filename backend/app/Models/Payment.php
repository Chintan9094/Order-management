<?php

namespace App\Models;

use App\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    protected $fillable = [
        'dining_session_id',
        'status',
        'amount_due',
        'amount_paid',
        'paid_at',
        'marked_by_staff_id',
    ];

    protected function casts(): array
    {
        return [
            'status' => PaymentStatus::class,
            'amount_due' => 'decimal:2',
            'amount_paid' => 'decimal:2',
            'paid_at' => 'datetime',
        ];
    }

    public function diningSession(): BelongsTo
    {
        return $this->belongsTo(DiningSession::class);
    }

    public function markedByStaff(): BelongsTo
    {
        return $this->belongsTo(User::class, 'marked_by_staff_id');
    }
}
