<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class OrdersSeeder extends Seeder
{
    public function run(): void
    {
        // الحصول على IDs المطلوبة
        $customerId = DB::table('customers')->value('id');
        $officeUserId = DB::table('users')->where('role', 'office')->value('id');
        $driverId = DB::table('drivers')->value('id');
        $storeId = DB::table('stores')->value('id');
        $unitId = DB::table('units')->value('id');

        // إنشاء طلب
        $orderId = DB::table('orders')->insertGetId([
            'order_number' => 'ORD-1001',
            'customer_id' => $customerId,
            'office_user_id' => $officeUserId,
            'driver_id' => $driverId,
            'status' => 'pending',
            'delivery_fee' => 5000,
            'payment_status' => 'cash',
            'paid_amount' => 0,
            'remaining_amount' => 5000,
            'pickup_location' => DB::raw("ST_GeomFromText('POINT(31.2330 30.0430)', 4326)"),
            'delivery_location' => DB::raw("ST_GeomFromText('POINT(31.2357 30.0444)', 4326)"),
            'notes' => 'يرجى الاتصال قبل الوصول',
            'created_at' => now(),
        ]);

        // إضافة عنصر طلب
        DB::table('order_items')->insert([
            'order_id' => $orderId,
            'store_id' => $storeId,
            'description' => 'شاورما عربي',
            'quantity' => 2,
            'unit_id' => $unitId,
            'estimated_price' => 45.00,
            'is_available' => true,
            'created_at' => now(),
        ]);

        // تسجيل حالة الطلب
        DB::table('order_status_logs')->insert([
            'order_id' => $orderId,
            'status' => 'pending',
            'changed_by' => $officeUserId,
            'created_at' => now(),
        ]);
    }
}