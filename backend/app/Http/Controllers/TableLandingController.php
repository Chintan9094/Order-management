<?php

namespace App\Http\Controllers;

use App\Models\RestaurantTable;
use Illuminate\View\View;

class TableLandingController extends Controller
{
    public function show(string $token): View
    {
        $table = RestaurantTable::query()
            ->with('restaurant')
            ->where('public_token', $token)
            ->where('is_active', true)
            ->first();

        if (! $table || ! $table->restaurant?->is_active) {
            abort(404, 'This table QR is invalid or inactive.');
        }

        return view('customer-app', [
            'token' => $token,
            // Relative path so phone uses the same host as the QR (not localhost).
            'apiBase' => '/api/v1',
            'restaurantName' => $table->restaurant->name,
            'tableLabel' => $table->label,
        ]);
    }
}
