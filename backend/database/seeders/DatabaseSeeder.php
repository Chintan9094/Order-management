<?php

namespace Database\Seeders;

use App\Enums\StaffRole;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\Restaurant;
use App\Models\RestaurantTable;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $restaurant = Restaurant::query()->create([
            'name' => 'Spice Garden',
            'currency_code' => 'INR',
            'tax_rate' => 0.0500,
            'service_charge_rate' => 0.0000,
            'is_active' => true,
        ]);

        $staff = [
            ['name' => 'Admin User', 'email' => 'admin@gmail.com', 'role' => StaffRole::Admin],
            ['name' => 'Manager User', 'email' => 'manager@gmail.com', 'role' => StaffRole::Manager],
            ['name' => 'Waiter User', 'email' => 'waiter@gmail.com', 'role' => StaffRole::Waiter],
            ['name' => 'Kitchen User', 'email' => 'kitchen@gmail.com', 'role' => StaffRole::Kitchen],
        ];

        foreach ($staff as $row) {
            User::query()->create([
                'restaurant_id' => $restaurant->id,
                'name' => $row['name'],
                'email' => $row['email'],
                'password' => Hash::make('password'),
                'role' => $row['role'],
                'is_active' => true,
            ]);
        }

        $tableRows = [];
        for ($i = 1; $i <= 8; $i++) {
            // Opaque unguessable token — never use table-1, table-2, etc.
            $token = Str::lower(Str::random(40));
            RestaurantTable::query()->create([
                'restaurant_id' => $restaurant->id,
                'label' => "Table {$i}",
                'public_token' => $token,
                'capacity' => $i <= 4 ? 4 : 6,
                'is_active' => true,
            ]);
            $tableRows[] = ["Table {$i}", $token];
        }

        $categoryDefs = [
            'Starters' => [
                ['name' => 'Paneer Tikka', 'price' => 220.00, 'diet' => 'veg', 'prep_minutes' => 15],
                ['name' => 'Chicken 65', 'price' => 260.00, 'diet' => 'nonveg', 'prep_minutes' => 18],
                ['name' => 'Veg Spring Rolls', 'price' => 180.00, 'diet' => 'veg', 'prep_minutes' => 12],
            ],
            'Main Course' => [
                ['name' => 'Butter Chicken', 'price' => 320.00, 'diet' => 'nonveg', 'prep_minutes' => 25],
                ['name' => 'Paneer Butter Masala', 'price' => 280.00, 'diet' => 'veg', 'prep_minutes' => 20],
                ['name' => 'Dal Tadka', 'price' => 190.00, 'diet' => 'veg', 'prep_minutes' => 18],
            ],
            'Breads' => [
                ['name' => 'Butter Naan', 'price' => 60.00, 'diet' => 'veg', 'prep_minutes' => 8],
                ['name' => 'Garlic Naan', 'price' => 70.00, 'diet' => 'veg', 'prep_minutes' => 8],
            ],
            'Drinks' => [
                ['name' => 'Masala Chaas', 'price' => 50.00, 'diet' => 'veg', 'prep_minutes' => 5],
                ['name' => 'Sweet Lassi', 'price' => 80.00, 'diet' => 'veg', 'prep_minutes' => 5],
                ['name' => 'Fresh Lime Soda', 'price' => 60.00, 'diet' => 'veg', 'prep_minutes' => 4],
            ],
            'Desserts' => [
                ['name' => 'Gulab Jamun (2 pcs)', 'price' => 90.00, 'diet' => 'veg', 'prep_minutes' => 5],
            ],
        ];

        $sortCategory = 1;
        foreach ($categoryDefs as $categoryName => $items) {
            $category = MenuCategory::query()->create([
                'restaurant_id' => $restaurant->id,
                'name' => $categoryName,
                'sort_order' => $sortCategory++,
                'is_active' => true,
            ]);

            $sortItem = 1;
            foreach ($items as $item) {
                MenuItem::query()->create([
                    'restaurant_id' => $restaurant->id,
                    'category_id' => $category->id,
                    'name' => $item['name'],
                    'description' => null,
                    'price' => $item['price'],
                    'diet' => $item['diet'],
                    'prep_minutes' => $item['prep_minutes'],
                    'sort_order' => $sortItem++,
                    'is_available' => true,
                    'is_active' => true,
                ]);
            }
        }

        $this->command?->info('Spice Garden seeded.');
        $this->command?->info('Staff password for all users: password');
        $this->command?->table(
            ['Email', 'Role'],
            [
                ['admin@gmail.com', 'admin'],
                ['manager@gmail.com', 'manager'],
                ['waiter@gmail.com', 'waiter'],
                ['kitchen@gmail.com', 'kitchen'],
            ]
        );
        $this->command?->warn('Table QR tokens are secret — print from Staff → Tables → QR');
        $this->command?->table(['Label', 'Public token'], $tableRows);
    }
}
