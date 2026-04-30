<?php
// database/migrations/2025_01_01_000010_create_stores_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('stores', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('store_type_id');
            $table->foreign('store_type_id')->references('id')->on('store_types');
            $table->string('name', 150);
            $table->string('phone', 20)->nullable();
            $table->text('address')->nullable();
            $table->geography('location', 'point', 4326)->nullable();
            $table->decimal('commission_percentage', 5, 2)->nullable();
            $table->boolean('is_active')->default(true);
        });
    }

    public function down()
    {
        Schema::dropIfExists('stores');
    }
};