<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateMenuItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $restaurantId = $this->user()?->restaurant_id;

        return [
            'category_id' => [
                'sometimes',
                'integer',
                Rule::exists('menu_categories', 'id')->where('restaurant_id', $restaurantId),
            ],
            'name' => ['sometimes', 'string', 'max:160'],
            'description' => ['nullable', 'string'],
            'price' => ['sometimes', 'numeric', 'min:0'],
            'image_url' => ['nullable', 'string', 'max:500'],
            'diet' => ['sometimes', 'string', 'max:16'],
            'prep_minutes' => ['nullable', 'integer', 'min:0', 'max:600'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
            'is_available' => ['sometimes', 'boolean'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
