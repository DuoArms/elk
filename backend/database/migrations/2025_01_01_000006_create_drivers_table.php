<?php
// database/migrations/2025_01_01_000006_create_drivers_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('drivers', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->unique();
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->string('vehicle_type', 50)->nullable();
            $table->string('vehicle_ownership', 20)->check("vehicle_ownership IN ('own','company')");
            $table->boolean('is_available')->default(true);
            $table->geography('current_location', 'point', 4326)->nullable();
            $table->decimal('balance', 10, 2)->default(0);
            $table->timestamp('created_at')->default(DB::raw('CURRENT_TIMESTAMP'));
        });
    }

    public function down()
    {
        Schema::dropIfExists('drivers');
    }
};