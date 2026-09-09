<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreTableRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'label' => ['required', 'string', 'max:100'],
            'public_token' => [
                'nullable',
                'string',
                'min:24',
                'max:64',
                'regex:/^[A-Za-z0-9\-_]+$/',
                'unique:restaurant_tables,public_token',
            ],
            'capacity' => ['nullable', 'integer', 'min:1', 'max:50'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
