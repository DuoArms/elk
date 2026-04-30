<?php
// database/migrations/2025_01_01_000009_create_store_types_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('store_types', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
        });
    }

    public function down()
    {
        Schema::dropIfExists('store_types');
    }
};