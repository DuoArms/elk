<?php
// database/migrations/2025_01_01_000001_create_enums.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        DB::statement("CREATE TYPE user_role AS ENUM ('admin','office','driver','accountant','store','customer')");
        DB::statement("CREATE TYPE order_status AS ENUM ('pending','assigned','accepted','rejected','timeout','on_the_way','items_purchased','delivered','cancelled')");
        DB::statement("CREATE TYPE payment_status AS ENUM ('cash','credit','partial')");
        DB::statement("CREATE TYPE assignment_status AS ENUM ('pending','accepted','rejected','timeout')");
        DB::statement("CREATE TYPE transaction_type AS ENUM ('customer_debit','customer_credit','driver_debit','driver_credit','store_debit','store_credit')");
    }

    public function down()
    {
        DB::statement("DROP TYPE IF EXISTS transaction_type");
        DB::statement("DROP TYPE IF EXISTS assignment_status");
        DB::statement("DROP TYPE IF EXISTS payment_status");
        DB::statement("DROP TYPE IF EXISTS order_status");
        DB::statement("DROP TYPE IF EXISTS user_role");
    }
};