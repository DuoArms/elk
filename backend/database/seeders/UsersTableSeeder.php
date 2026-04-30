<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UsersTableSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('users')->insert([
            [
                'phone' => '01000000004',
                'password_hash' => Hash::make('123456'),
                'full_name' => 'مدير النظام',
                'role' => 'admin',
                'is_active' => true,
                'created_at' => now(),
            ],
            [
                'phone' => '01000000005',
                'password_hash' => Hash::make('123456'),
                'full_name' => 'موظف مكتب',
                'role' => 'office',
                'is_active' => true,
                'created_at' => now(),
            ],
            [
                'phone' => '01000000006',
                'password_hash' => Hash::make('123456'),
                'full_name' => 'زبون تجريبي',
                'role' => 'customer',
                'is_active' => true,
                'created_at' => now(),
            ],
        ]);
    }
}