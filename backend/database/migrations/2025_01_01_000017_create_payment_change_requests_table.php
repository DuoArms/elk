<?php
// database/migrations/2025_01_01_000017_create_payment_change_requests_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('payment_change_requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
            $table->unsignedBigInteger('requested_by');
            $table->foreign('requested_by')->references('id')->on('users');
            $table->string('requested_status'); // payment_status enum
            $table->decimal('paid_amount', 10, 2)->nullable();
            $table->text('note')->nullable();
            $table->string('status')->default('pending'); // 'pending','approved','rejected'
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->foreign('approved_by')->references('id')->on('users');
            $table->timestamp('created_at')->default(DB::raw('CURRENT_TIMESTAMP'));
        });
    }

    public function down()
    {
        Schema::dropIfExists('payment_change_requests');
    }
};