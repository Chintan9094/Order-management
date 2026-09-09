<?php

namespace App\Http\Middleware;

use App\Enums\StaffRole;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckPermission
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $userRole = $user->role instanceof StaffRole
            ? $user->role->value
            : (string) $user->role;

        if ($roles !== [] && ! in_array($userRole, $roles, true)) {
            return response()->json(['message' => 'Insufficient permissions.'], 403);
        }

        return $next($request);
    }
}
