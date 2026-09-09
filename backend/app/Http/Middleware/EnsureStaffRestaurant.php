<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureStaffRestaurant
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user || ! $user->is_active) {
            return response()->json(['message' => 'Unauthenticated or inactive staff account.'], 401);
        }

        if (! $user->restaurant_id) {
            return response()->json(['message' => 'Staff is not assigned to a restaurant.'], 403);
        }

        $request->attributes->set('restaurant_id', $user->restaurant_id);

        return $next($request);
    }
}
