<?php

namespace App\Models;

use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    protected $fillable = [
        'dining_session_id',
        'restaurant_id',
        'table_id',
        'status',
        'subtotal',
        'tax',
        'service_charge',
        'grand_total',
        'notes',
        'idempotency_key',
    ];

    protected function casts(): array
    {
        return [
            'status' => OrderStatus::class,
            'subtotal' => 'decimal:2',
            'tax' => 'decimal:2',
            'service_charge' => 'decimal:2',
            'grand_total' => 'decimal:2',
        ];
    }

    public function diningSession(): BelongsTo
    {
        return $this->belongsTo(DiningSession::class);
    }

    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }

    public function table(): BelongsTo
    {
        return $this->belongsTo(RestaurantTable::class, 'table_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
