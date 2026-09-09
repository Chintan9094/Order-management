<?php

namespace App\Models;

use App\Enums\DiningSessionStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class RestaurantTable extends Model
{
    protected $fillable = [
        'restaurant_id',
        'label',
        'public_token',
        'capacity',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'capacity' => 'integer',
        ];
    }

    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }

    public function diningSessions(): HasMany
    {
        return $this->hasMany(DiningSession::class, 'table_id');
    }

    public function openSession(): HasOne
    {
        return $this->hasOne(DiningSession::class, 'table_id')
            ->ofMany(['id' => 'max'], function ($query) {
                $query->where('status', DiningSessionStatus::Open);
            });
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'table_id');
    }
}
