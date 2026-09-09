<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(LoginRequest $request)
    {
        $user = User::query()
            ->where('email', $request->validated('email'))
            ->first();

        if (! $user || ! Hash::check($request->validated('password'), $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if (! $user->is_active) {
            return response()->json(['message' => 'This staff account is inactive.'], 403);
        }

        $deviceName = $request->validated('device_name') ?: 'staff-device';
        $token = $user->createToken($deviceName)->plainTextToken;

        $user->load('restaurant');

        return response()->json([
            'data' => [
                'token' => $token,
                'tokenType' => 'Bearer',
                'user' => new UserResource($user),
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out.']);
    }

    public function me(Request $request)
    {
        $user = $request->user()->load('restaurant');

        return response()->json([
            'data' => new UserResource($user),
        ]);
    }
}
