<?php

namespace App\Console\Commands;

use App\Models\RestaurantTable;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

class RotateTableTokens extends Command
{
    protected $signature = 'tables:rotate-tokens';

    protected $description = 'Replace all table public_token values with opaque secrets (invalidates old QR codes)';

    public function handle(): int
    {
        $rows = [];

        RestaurantTable::query()->orderBy('id')->each(function (RestaurantTable $table) use (&$rows) {
            $token = Str::lower(Str::random(40));
            $table->update(['public_token' => $token]);
            $rows[] = [$table->label, $token];
        });

        $this->info('Rotated '.count($rows).' table token(s). Reprint QRs from the staff app.');
        $this->table(['Label', 'Public token'], $rows);

        return self::SUCCESS;
    }
}
