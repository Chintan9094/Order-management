<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\DiningSessionResource;
use App\Models\DiningSession;
use Illuminate\Http\Request;

class SessionController extends Controller
{
    public function show(Request $request, DiningSession $session)
    {
        /** @var DiningSession $tokenSession */
        $tokenSession = $request->attributes->get('dining_session');

        if ($tokenSession->id !== $session->id) {
            return response()->json(['message' => 'Session token does not match requested session.'], 403);
        }

        $session->load(['orders.items', 'payment', 'table']);

        return response()->json([
            'data' => new DiningSessionResource($session),
        ]);
    }
}
