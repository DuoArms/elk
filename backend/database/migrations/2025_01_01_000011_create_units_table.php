<?php
// database/migrations/2025_01_01_000011_create_units_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('units', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('store_type_id')->nullable();
            $table->foreign('store_type_id')->references('id')->on('store_types');
            $table->string('name', 50);
        });
    }

    public function down()
    {
        Schema::dropIfExists('units');
    }
};
