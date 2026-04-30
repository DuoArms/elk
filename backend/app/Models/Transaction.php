<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $table = 'transactions';
    public $timestamps = true;

    const CREATED_AT = 'created_at';
    const UPDATED_AT = null;

    protected $fillable = [
        'type', 'reference_id', 'reference_type', 'customer_id',
        'driver_id', 'store_id', 'amount', 'notes', 'created_at'
    ];

    public function customer()
    {
        return $this->belongsTo(Customer::class, 'customer_id');
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }

    public function store()
    {
        return $this->belongsTo(Store::class, 'store_id');
    }
}