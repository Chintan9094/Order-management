<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Ensures Flutter web (Chrome) can call the API from localhost origins,
 * including CORS preflight and Private Network Access checks.
 */
class EnsureApiCors
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->getMethod() === 'OPTIONS') {
            return response('', 204)->withHeaders($this->headers($request));
        }

        /** @var Response $response */
        $response = $next($request);

        foreach ($this->headers($request) as $key => $value) {
            $response->headers->set($key, $value);
        }

        return $response;
    }

    /**
     * @return array<string, string>
     */
    private function headers(Request $request): array
    {
        $origin = $request->headers->get('Origin', '*');
        $requestHeaders = $request->headers->get(
            'Access-Control-Request-Headers',
            'Content-Type, Accept, Authorization, X-Client-Session, X-Session-Token',
        );

        return [
            'Access-Control-Allow-Origin' => $origin === 'null' ? '*' : $origin,
            'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
            'Access-Control-Allow-Headers' => $requestHeaders,
            'Access-Control-Allow-Private-Network' => 'true',
            'Access-Control-Max-Age' => '86400',
            'Vary' => 'Origin, Access-Control-Request-Method, Access-Control-Request-Headers',
        ];
    }
}
