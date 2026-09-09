<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateTableRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $tableId = $this->route('table')?->id ?? $this->route('table');

        return [
            'label' => ['sometimes', 'string', 'max:100'],
            'public_token' => [
                'sometimes',
                'string',
                'min:24',
                'max:64',
                'regex:/^[A-Za-z0-9\-_]+$/',
                Rule::unique('restaurant_tables', 'public_token')->ignore($tableId),
            ],
            'capacity' => ['nullable', 'integer', 'min:1', 'max:50'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
