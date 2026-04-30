<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DriverCommissionRule extends Model
{
    protected $table = 'driver_commission_rules';
    public $timestamps = false;

    protected $fillable = [
        'vehicle_ownership', 'commission_percentage', 'is_active', 'created_at'
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'commission_percentage' => 'decimal:2',
    ];
}