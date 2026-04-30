<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class UnitsTableSeeder extends Seeder
{
    public function run(): void
    {
        // وحدات عامة (بدون store_type_id)
        DB::table('units')->insert([
            ['store_type_id' => null, 'name' => 'كيلو'],
            ['store_type_id' => null, 'name' => 'قطعة'],
            ['store_type_id' => null, 'name' => 'علبة'],
            ['store_type_id' => null, 'name' => 'لتر'],
        ]);
    }
}