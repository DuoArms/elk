<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DriverCommissionSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('driver_commission_rules')->insert([
            [
                'vehicle_ownership' => 'own',
                'commission_percentage' => 30.00,
                'is_active' => true,
                'created_at' => now(),
            ],
            [
                'vehicle_ownership' => 'company',
                'commission_percentage' => 20.00,
                'is_active' => true,
                'created_at' => now(),
            ],
        ]);
    }
}