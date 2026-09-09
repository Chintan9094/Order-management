<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Order */
class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'diningSessionId' => $this->dining_session_id,
            'restaurantId' => $this->restaurant_id,
            'tableId' => $this->table_id,
            'status' => $this->status?->value ?? $this->status,
            'subtotal' => (float) $this->subtotal,
            'tax' => (float) $this->tax,
            'serviceCharge' => (float) $this->service_charge,
            'grandTotal' => (float) $this->grand_total,
            'notes' => $this->notes,
            'createdAt' => $this->created_at?->toIso8601String(),
            'updatedAt' => $this->updated_at?->toIso8601String(),
            'items' => OrderItemResource::collection($this->whenLoaded('items')),
            'table' => RestaurantTableResource::make($this->whenLoaded('table')),
        ];
    }
}
