<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\MenuCategoryResource;
use App\Models\MenuCategory;
use App\Models\Restaurant;

class MenuController extends Controller
{
    public function show(Restaurant $restaurant)
    {
        if (! $restaurant->is_active) {
            return response()->json(['message' => 'Restaurant not found.'], 404);
        }

        $categories = MenuCategory::query()
            ->where('restaurant_id', $restaurant->id)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->with(['items' => function ($query) {
                $query->where('is_active', true)
                    ->where('is_available', true)
                    ->orderBy('sort_order')
                    ->orderBy('id');
            }])
            ->get()
            ->filter(fn (MenuCategory $category) => $category->items->isNotEmpty())
            ->values();

        return response()->json([
            'data' => [
                'restaurantId' => $restaurant->id,
                'currencyCode' => $restaurant->currency_code,
                'categories' => MenuCategoryResource::collection($categories),
            ],
        ]);
    }
}
