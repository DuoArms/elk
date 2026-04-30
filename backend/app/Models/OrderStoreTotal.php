<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderStoreTotal extends Model
{
    use HasFactory;

    protected $fillable = ['order_id', 'store_id', 'total_amount', 'notes'];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }
}