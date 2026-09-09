<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreTableRequest;
use App\Http\Requests\Api\V1\UpdateTableRequest;
use App\Http\Resources\Api\V1\RestaurantTableResource;
use App\Models\RestaurantTable;
use App\Services\TableStatusDeriver;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class TableController extends Controller
{
    public function index(Request $request, TableStatusDeriver $tableStatusDeriver)
    {
        $tables = RestaurantTable::query()
            ->where('restaurant_id', $request->user()->restaurant_id)
            ->with(['openSession.orders', 'openSession.payment'])
            ->orderBy('label')
            ->get()
            ->map(function (RestaurantTable $table) use ($tableStatusDeriver) {
                $table->derived_status = $tableStatusDeriver->derive($table);
                $table->qr_payload = $this->qrPayload($table);

                return $table;
            });

        return response()->json([
            'data' => RestaurantTableResource::collection($tables),
        ]);
    }

    public function store(StoreTableRequest $request)
    {
        $data = $request->validated();
        $data['restaurant_id'] = $request->user()->restaurant_id;
        // Never derive tokens from labels (e.g. table-2) — use opaque secrets only.
        $data['public_token'] = $data['public_token'] ?? Str::lower(Str::random(40));
        $data['is_active'] = $data['is_active'] ?? true;

        $table = RestaurantTable::query()->create($data);
        $table->qr_payload = $this->qrPayload($table);
        $table->derived_status = 'available';

        return response()->json([
            'data' => new RestaurantTableResource($table),
            'message' => 'Table created.',
        ], 201);
    }

    public function show(Request $request, RestaurantTable $table, TableStatusDeriver $tableStatusDeriver)
    {
        $this->assertRestaurant($request, $table);

        $table->load(['openSession.orders', 'openSession.payment']);
        $table->derived_status = $tableStatusDeriver->derive($table);
        $table->qr_payload = $this->qrPayload($table);

        return response()->json([
            'data' => new RestaurantTableResource($table),
        ]);
    }

    public function update(UpdateTableRequest $request, RestaurantTable $table)
    {
        $this->assertRestaurant($request, $table);

        $table->update($request->validated());
        $table->qr_payload = $this->qrPayload($table);

        return response()->json([
            'data' => new RestaurantTableResource($table),
            'message' => 'Table updated.',
        ]);
    }

    public function destroy(Request $request, RestaurantTable $table)
    {
        $this->assertRestaurant($request, $table);

        $table->update(['is_active' => false]);

        return response()->json(['message' => 'Table deactivated.']);
    }

    public function qr(Request $request, RestaurantTable $table)
    {
        $this->assertRestaurant($request, $table);

        return response()->json([
            'data' => [
                'tableId' => $table->id,
                'label' => $table->label,
                'publicToken' => $table->public_token,
                'qrPayload' => $this->qrPayload($table),
            ],
        ]);
    }

    private function qrPayload(RestaurantTable $table): string
    {
        $base = rtrim((string) config('app.qr_public_base_url'), '/');

        return $base.'/t/'.$table->public_token;
    }

    private function assertRestaurant(Request $request, RestaurantTable $table): void
    {
        if ($table->restaurant_id !== $request->user()->restaurant_id) {
            abort(response()->json(['message' => 'Table not found.'], 404));
        }
    }
}
