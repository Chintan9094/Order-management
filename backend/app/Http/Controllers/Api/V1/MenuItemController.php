<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreMenuItemRequest;
use App\Http\Requests\Api\V1\UpdateMenuItemRequest;
use App\Http\Resources\Api\V1\MenuItemResource;
use App\Models\MenuItem;
use Illuminate\Http\Request;

class MenuItemController extends Controller
{
    public function index(Request $request)
    {
        $query = MenuItem::query()
            ->where('restaurant_id', $request->user()->restaurant_id)
            ->with('category')
            ->orderBy('sort_order')
            ->orderBy('id');

        if ($request->boolean('active_only')) {
            $query->where('is_active', true);
        }

        if ($categoryId = $request->query('category_id')) {
            $query->where('category_id', $categoryId);
        }

        return response()->json([
            'data' => MenuItemResource::collection($query->get()),
        ]);
    }

    public function store(StoreMenuItemRequest $request)
    {
        $item = MenuItem::query()->create([
            ...$request->validated(),
            'restaurant_id' => $request->user()->restaurant_id,
            'is_active' => $request->validated('is_active', true),
            'is_available' => $request->validated('is_available', true),
            'diet' => $request->validated('diet', 'unknown'),
            'sort_order' => $request->validated('sort_order', 0),
        ]);

        $item->load('category');

        return response()->json([
            'data' => new MenuItemResource($item),
            'message' => 'Menu item created.',
        ], 201);
    }

    public function show(Request $request, MenuItem $menuItem)
    {
        $this->assertRestaurant($request, $menuItem);
        $menuItem->load('category');

        return response()->json([
            'data' => new MenuItemResource($menuItem),
        ]);
    }

    public function update(UpdateMenuItemRequest $request, MenuItem $menuItem)
    {
        $this->assertRestaurant($request, $menuItem);

        $menuItem->update($request->validated());
        $menuItem->load('category');

        return response()->json([
            'data' => new MenuItemResource($menuItem),
            'message' => 'Menu item updated.',
        ]);
    }

    public function destroy(Request $request, MenuItem $menuItem)
    {
        $this->assertRestaurant($request, $menuItem);

        $menuItem->update([
            'is_active' => false,
            'is_available' => false,
        ]);

        return response()->json(['message' => 'Menu item deactivated.']);
    }

    private function assertRestaurant(Request $request, MenuItem $menuItem): void
    {
        if ($menuItem->restaurant_id !== $request->user()->restaurant_id) {
            abort(response()->json(['message' => 'Menu item not found.'], 404));
        }
    }
}
