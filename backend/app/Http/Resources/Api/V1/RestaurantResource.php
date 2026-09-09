<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Restaurant */
class RestaurantResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'currencyCode' => $this->currency_code,
            'taxRate' => (float) $this->tax_rate,
            'serviceChargeRate' => (float) $this->service_charge_rate,
            'isActive' => (bool) $this->is_active,
        ];
    }
}
