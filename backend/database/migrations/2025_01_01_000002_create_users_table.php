<?php
// database/migrations/2025_01_01_000002_create_users_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('phone', 20)->unique();
            $table->string('password_hash', 255);
            $table->string('full_name', 100);
            $table->string('role'); // سيتم التحقق من القيم عبر enum لاحقاً
            // بدلاً من استخدام enum في قاعدة البيانات، يمكنك ترك النص واستخدام التحقق في التطبيق
            $table->boolean('is_active')->default(true);
            $table->timestamp('created_at')->default(DB::raw('CURRENT_TIMESTAMP'));
        });
    }

    public function down()
    {
        Schema::dropIfExists('users');
    }
};