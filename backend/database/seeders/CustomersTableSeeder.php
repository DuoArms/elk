<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CustomersTableSeeder extends Seeder
{
    public function run(): void
    {
        // إدراج زبون مرتبط بمستخدم (user_id = 3)
        $customerId = DB::table('customers')->insertGetId([
            'user_id' => 3, // المستخدم الزبون
            'name' => 'أحمد محمد',
            'notes' => 'زبون دائم',
            'balance' => 0,
            'created_at' => now(),
        ]);

        // إضافة عنوان للزبون
        DB::table('customer_addresses')->insert([
            'customer_id' => $customerId,
            'address' => 'شارع النيل، القاهرة',
            'location' => DB::raw("ST_GeomFromText('POINT(31.2357 30.0444)', 4326)"), // خط الطول ثم خط العرض
            'label' => 'المنزل',
        ]);

        // إضافة هاتف إضافي
        DB::table('customer_phones')->insert([
            'customer_id' => $customerId,
            'phone' => '01111111111',
        ]);
    }
}