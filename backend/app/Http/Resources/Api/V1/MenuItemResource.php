<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\MenuItem */
class MenuItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'restaurantId' => $this->restaurant_id,
            'categoryId' => $this->category_id,
            'name' => $this->name,
            'description' => $this->description,
            'price' => (float) $this->price,
            'imageUrl' => $this->image_url,
            'diet' => $this->diet,
            'prepMinutes' => $this->prep_minutes,
            'sortOrder' => $this->sort_order,
            'isAvailable' => (bool) $this->is_available,
            'isActive' => (bool) $this->is_active,
            'category' => MenuCategoryResource::make($this->whenLoaded('category')),
        ];
    }
}
