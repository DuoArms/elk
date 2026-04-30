<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class StoreTypesSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('store_types')->insert([
            ['name' => 'مطعم'],
            ['name' => 'سوبرماركت'],
            ['name' => 'صيدلية'],
        ]);
    }
}