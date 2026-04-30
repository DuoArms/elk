<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Unit extends Model
{
    protected $table = 'units';
    public $timestamps = false;

    protected $fillable = ['store_type_id', 'name'];

    public function storeType()
    {
        return $this->belongsTo(StoreType::class, 'store_type_id');
    }

    public function products()
    {
        return $this->hasMany(Product::class, 'unit_id');
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'unit_id');
    }
}