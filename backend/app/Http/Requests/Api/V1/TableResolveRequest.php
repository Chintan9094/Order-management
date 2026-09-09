<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class TableResolveRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // Opaque QR tokens only — short guessable values like "table-2" are rejected.
            'token' => ['required', 'string', 'min:24', 'max:64', 'regex:/^[A-Za-z0-9\-_]+$/'],
        ];
    }
}
