<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class StoresTableSeeder extends Seeder
{
    public function run(): void
    {
        // الحصول على store_type_id للمطعم وسوبرماركت
        $restaurantTypeId = DB::table('store_types')->where('name', 'مطعم')->value('id');
        $supermarketTypeId = DB::table('store_types')->where('name', 'سوبرماركت')->value('id');

        DB::table('stores')->insert([
            [
                'store_type_id' => $restaurantTypeId,
                'name' => 'مطعم الأندلس',
                'phone' => '0223456789',
                'address' => 'شارع الأندلس، القاهرة',
                'location' => DB::raw("ST_GeomFromText('POINT(31.2330 30.0430)', 4326)"),
                'commission_percentage' => 10.00,
                'is_active' => true,
            ],
            [
                'store_type_id' => $supermarketTypeId,
                'name' => 'سوبر ماركت النيل',
                'phone' => '0229876543',
                'address' => 'شارع النيل، الجيزة',
                'location' => DB::raw("ST_GeomFromText('POINT(31.2100 30.0200)', 4326)"),
                'commission_percentage' => 5.00,
                'is_active' => true,
            ],
        ]);
    }
}