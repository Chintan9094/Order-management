<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Restaurant extends Model
{
    protected $fillable = [
        'name',
        'currency_code',
        'tax_rate',
        'service_charge_rate',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'tax_rate' => 'decimal:4',
            'service_charge_rate' => 'decimal:4',
            'is_active' => 'boolean',
        ];
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function tables(): HasMany
    {
        return $this->hasMany(RestaurantTable::class);
    }

    public function categories(): HasMany
    {
        return $this->hasMany(MenuCategory::class);
    }

    public function menuItems(): HasMany
    {
        return $this->hasMany(MenuItem::class);
    }

    public function diningSessions(): HasMany
    {
        return $this->hasMany(DiningSession::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
