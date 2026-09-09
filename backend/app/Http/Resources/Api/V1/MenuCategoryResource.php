<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\MenuCategory */
class MenuCategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'restaurantId' => $this->restaurant_id,
            'name' => $this->name,
            'sortOrder' => $this->sort_order,
            'isActive' => (bool) $this->is_active,
            'items' => MenuItemResource::collection($this->whenLoaded('items')),
        ];
    }
}
