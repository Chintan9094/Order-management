<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\DiningSession */
class DiningSessionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'restaurantId' => $this->restaurant_id,
            'tableId' => $this->table_id,
            'status' => $this->status?->value ?? $this->status,
            'allowsNewOrders' => (bool) $this->allows_new_orders,
            'startedAt' => $this->started_at?->toIso8601String(),
            'closedAt' => $this->closed_at?->toIso8601String(),
            'table' => RestaurantTableResource::make($this->whenLoaded('table')),
            'orders' => OrderResource::collection($this->whenLoaded('orders')),
            'payment' => PaymentResource::make($this->whenLoaded('payment')),
        ];
    }
}
