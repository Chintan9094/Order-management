<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\OrderItem */
class OrderItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'orderId' => $this->order_id,
            'menuItemId' => $this->menu_item_id,
            'name' => $this->name_snapshot,
            'unitPrice' => (float) $this->unit_price_snapshot,
            'quantity' => $this->quantity,
            'lineTotal' => (float) $this->line_total,
            'note' => $this->note,
        ];
    }
}
