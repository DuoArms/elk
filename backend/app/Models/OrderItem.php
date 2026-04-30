<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    protected $table = 'order_items';
    public $timestamps = false;

    protected $fillable = [
        'order_id',
        'store_id',
        'description',
        'quantity',
        'unit_id',
        'product_id',
        'estimated_price',
        'actual_price',
        'is_available',
        'unavailable_reason',
        'created_at',
        'item_type',
        'sort_order',
        'pickup_address',
        'pickup_location',
        'pickup_phone',
        'pickup_contact_name',
        'delivery_address',
        'delivery_location',
        'delivery_phone',
        'delivery_contact_name',
        'estimated_fee',
        'actual_fee',
        'invoice_type',
        'company_name',
        'estimated_total',
        'due_date',
        'actual_invoice_amount',
        'notes',
        'size_id',
    ];

    protected $casts = [
        'is_available'        => 'boolean',
        'quantity'            => 'decimal:2',
        'estimated_price'     => 'decimal:2',
        'actual_price'        => 'decimal:2',
        'estimated_fee'       => 'decimal:2',
        'actual_fee'          => 'decimal:2',
        'estimated_total'     => 'decimal:2',
        'actual_invoice_amount'=> 'decimal:2',
        'due_date'            => 'date',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    public function store()
    {
        return $this->belongsTo(Store::class, 'store_id');
    }

    public function unit()
    {
        return $this->belongsTo(Unit::class, 'unit_id');
    }

    public function size()
    {
        return $this->belongsTo(Size::class, 'size_id');
    }
}