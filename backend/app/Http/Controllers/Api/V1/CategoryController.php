<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreCategoryRequest;
use App\Http\Requests\Api\V1\UpdateCategoryRequest;
use App\Http\Resources\Api\V1\MenuCategoryResource;
use App\Models\MenuCategory;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $categories = MenuCategory::query()
            ->where('restaurant_id', $request->user()->restaurant_id)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        return response()->json([
            'data' => MenuCategoryResource::collection($categories),
        ]);
    }

    public function store(StoreCategoryRequest $request)
    {
        $category = MenuCategory::query()->create([
            ...$request->validated(),
            'restaurant_id' => $request->user()->restaurant_id,
            'is_active' => $request->validated('is_active', true),
            'sort_order' => $request->validated('sort_order', 0),
        ]);

        return response()->json([
            'data' => new MenuCategoryResource($category),
            'message' => 'Category created.',
        ], 201);
    }

    public function show(Request $request, MenuCategory $category)
    {
        $this->assertRestaurant($request, $category);

        $category->load(['items' => fn ($q) => $q->orderBy('sort_order')]);

        return response()->json([
            'data' => new MenuCategoryResource($category),
        ]);
    }

    public function update(UpdateCategoryRequest $request, MenuCategory $category)
    {
        $this->assertRestaurant($request, $category);

        $category->update($request->validated());

        return response()->json([
            'data' => new MenuCategoryResource($category),
            'message' => 'Category updated.',
        ]);
    }

    public function destroy(Request $request, MenuCategory $category)
    {
        $this->assertRestaurant($request, $category);

        $category->update(['is_active' => false]);

        return response()->json(['message' => 'Category deactivated.']);
    }

    private function assertRestaurant(Request $request, MenuCategory $category): void
    {
        if ($category->restaurant_id !== $request->user()->restaurant_id) {
            abort(response()->json(['message' => 'Category not found.'], 404));
        }
    }
}
