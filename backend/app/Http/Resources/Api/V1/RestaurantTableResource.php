<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\RestaurantTable */
class RestaurantTableResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'restaurantId' => $this->restaurant_id,
            'label' => $this->label,
            'publicToken' => $this->public_token,
            'capacity' => $this->capacity,
            'isActive' => (bool) $this->is_active,
            'status' => $this->when(isset($this->derived_status), $this->derived_status),
            'qrPayload' => $this->when(isset($this->qr_payload), $this->qr_payload),
            'openSession' => DiningSessionResource::make($this->whenLoaded('openSession')),
        ];
    }
}
