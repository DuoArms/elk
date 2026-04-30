<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ProductsTableSeeder extends Seeder
{
    public function run(): void
    {
        $storeId = DB::table('stores')->where('name', 'مطعم الأندلس')->value('id');
        $unitId = DB::table('units')->where('name', 'قطعة')->value('id');

        DB::table('products')->insert([
            [
                'store_id' => $storeId,
                'name' => 'شاورما عربي',
                'unit_id' => $unitId,
                'price' => 45.00,
                'is_active' => true,
            ],
            [
                'store_id' => $storeId,
                'name' => 'وجبة برجر',
                'unit_id' => $unitId,
                'price' => 60.00,
                'is_active' => true,
            ],
        ]);
    }
}