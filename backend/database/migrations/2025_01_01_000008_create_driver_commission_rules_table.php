<?php
// database/migrations/2025_01_01_000008_create_driver_commission_rules_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('driver_commission_rules', function (Blueprint $table) {
            $table->id();
            $table->string('vehicle_ownership', 20)->check("vehicle_ownership IN ('own','company')");
            $table->decimal('commission_percentage', 5, 2);
            $table->boolean('is_active')->default(true);
            $table->timestamp('created_at')->default(DB::raw('CURRENT_TIMESTAMP'));
        });
    }

    public function down()
    {
        Schema::dropIfExists('driver_commission_rules');
    }
};