<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SessionParticipant extends Model
{
    protected $fillable = [
        'dining_session_id',
        'client_session_id',
        'joined_at',
    ];

    protected function casts(): array
    {
        return [
            'joined_at' => 'datetime',
        ];
    }

    public function diningSession(): BelongsTo
    {
        return $this->belongsTo(DiningSession::class);
    }
}
