<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\User */
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'restaurantId' => $this->restaurant_id,
            'role' => $this->role?->value ?? $this->role,
            'isActive' => (bool) $this->is_active,
            'restaurant' => RestaurantResource::make($this->whenLoaded('restaurant')),
        ];
    }
}
