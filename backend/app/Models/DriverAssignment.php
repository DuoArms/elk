<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DriverAssignment extends Model
{
    protected $table = 'driver_assignments';
    public $timestamps = false;

    protected $fillable = [
        'order_id', 'driver_id', 'status', 'assigned_at', 'responded_at'
    ];

    protected $casts = [
        'assigned_at' => 'datetime',
        'responded_at' => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }
}