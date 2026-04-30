<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use MatanYadaev\EloquentSpatial\Objects\Point;

class Store extends Model
{
    protected $table = 'stores';
    public $timestamps = false;

    protected $fillable = [
        'store_type_id', 'name', 'phone', 'address', 'location',
        'commission_percentage', 'is_active'
    ];

    protected $casts = [
        'location' => Point::class,
        'is_active' => 'boolean',
    ];

    public function storeType()
    {
        return $this->belongsTo(StoreType::class, 'store_type_id');
    }

    public function products()
    {
        return $this->hasMany(Product::class, 'store_id');
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'store_id');
    }

    public function orderStoreTotals()
    {
        return $this->hasMany(OrderStoreTotal::class, 'store_id');
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}