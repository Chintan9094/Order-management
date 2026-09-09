<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Payment */
class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'diningSessionId' => $this->dining_session_id,
            'status' => $this->status?->value ?? $this->status,
            'amountDue' => (float) $this->amount_due,
            'amountPaid' => $this->amount_paid !== null ? (float) $this->amount_paid : null,
            'paidAt' => $this->paid_at?->toIso8601String(),
            'markedByStaffId' => $this->marked_by_staff_id,
        ];
    }
}
