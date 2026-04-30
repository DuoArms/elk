<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $table = 'products';
    public $timestamps = false;

    protected $fillable = [
        'store_type_id',
        'name',
        'unit_id',
        'price',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'price' => 'decimal:2',
    ];

    // العلاقة مع نوع المتجر (StoreType)
    public function storeType()
    {
        return $this->belongsTo(StoreType::class, 'store_type_id');
    }

    // العلاقة مع الوحدة (Unit)
    public function unit()
    {
        return $this->belongsTo(Unit::class, 'unit_id');
    }

    // العلاقة مع عناصر الطلبات (OrderItem)
    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'product_id');
    }
}