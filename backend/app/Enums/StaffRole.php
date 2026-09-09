<?php

namespace App\Enums;

enum StaffRole: string
{
    case Admin = 'admin';
    case Manager = 'manager';
    case Waiter = 'waiter';
    case Kitchen = 'kitchen';

    public function isManagerOrAbove(): bool
    {
        return in_array($this, [self::Admin, self::Manager], true);
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
