<?php
// database/migrations/2025_01_01_000004_create_customer_addresses_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('customer_addresses', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('customer_id');
            $table->foreign('customer_id')->references('id')->on('customers')->onDelete('cascade');
            $table->text('address');
            $table->geography('location', 'point', 4326);
            $table->string('label', 50)->nullable();
        });
    }

    public function down()
    {
        Schema::dropIfExists('customer_addresses');
    }
};