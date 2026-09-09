<?php

namespace App\Models;

use App\Enums\DiningSessionStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class DiningSession extends Model
{
    protected $fillable = [
        'restaurant_id',
        'table_id',
        'status',
        'access_token',
        'allows_new_orders',
        'started_at',
        'closed_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => DiningSessionStatus::class,
            'allows_new_orders' => 'boolean',
            'started_at' => 'datetime',
            'closed_at' => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (DiningSession $session): void {
            if (empty($session->access_token)) {
                $session->access_token = Str::random(64);
            }
        });
    }

    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }

    public function table(): BelongsTo
    {
        return $this->belongsTo(RestaurantTable::class, 'table_id');
    }

    public function participants(): HasMany
    {
        return $this->hasMany(SessionParticipant::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function payment(): HasOne
    {
        return $this->hasOne(Payment::class);
    }
}
