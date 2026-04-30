<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderStorePurchase extends Model
{
    protected $table = 'order_store_purchases';
    public $timestamps = true;

    protected $fillable = [
        'order_id',
        'store_id',
        'driver_id',
        'total_amount',
        'notes',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }
}