<?php

namespace App\Http\Middleware;

use App\Models\DiningSession;
use App\Models\SessionParticipant;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureCustomerSession
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->header('X-Session-Token');
        $clientSession = $request->header('X-Client-Session');

        if (! $token) {
            return response()->json(['message' => 'X-Session-Token header is required.'], 401);
        }

        if (! $clientSession) {
            return response()->json(['message' => 'X-Client-Session header is required.'], 401);
        }

        $session = DiningSession::query()
            ->where('access_token', $token)
            ->first();

        if (! $session) {
            return response()->json(['message' => 'Invalid session token.'], 401);
        }

        $isParticipant = SessionParticipant::query()
            ->where('dining_session_id', $session->id)
            ->where('client_session_id', $clientSession)
            ->exists();

        // Valid session token is enough to rejoin — phone browsers often get a
        // new client id after closing the QR tab. Re-attach automatically.
        if (! $isParticipant) {
            SessionParticipant::query()->firstOrCreate(
                [
                    'dining_session_id' => $session->id,
                    'client_session_id' => $clientSession,
                ],
                ['joined_at' => now()]
            );
        }

        // Route model binding must match the authenticated session.
        $routeSession = $request->route('session');
        if ($routeSession instanceof DiningSession && $routeSession->id !== $session->id) {
            return response()->json([
                'message' => 'Session token does not match requested session.',
            ], 403);
        }

        $request->attributes->set('dining_session', $session);
        $request->attributes->set('dining_session_id', $session->id);

        return $next($request);
    }
}
