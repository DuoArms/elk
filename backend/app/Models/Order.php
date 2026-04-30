<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use MatanYadaev\EloquentSpatial\Objects\Point;

class Order extends Model
{
    protected $table = 'orders';
    public $timestamps = false;

    protected $fillable = [
        'order_number',
        'customer_id',
        'office_user_id',
        'driver_id',
        'status',
        'delivery_fee',
        'payment_status',
        'paid_amount',
        'remaining_amount',
        'pickup_location',
        'delivery_location',
        'notes',
        'created_at',
        'accepted_at',
        'picked_up_at',
        'delivered_at',
        'customer_address_id',
        'order_phones',
    ];

    protected $casts = [
        'delivery_fee'     => 'decimal:2',
        'paid_amount'      => 'decimal:2',
        'remaining_amount' => 'decimal:2',
        'created_at'       => 'datetime',
        'accepted_at'      => 'datetime',
        'picked_up_at'     => 'datetime',
        'delivered_at'     => 'datetime',
        'pickup_location'  => Point::class,
        'delivery_location'=> Point::class,
    ];

    public function customer()
    {
        return $this->belongsTo(Customer::class, 'customer_id');
    }

    public function officeUser()
    {
        return $this->belongsTo(User::class, 'office_user_id');
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class, 'order_id');
    }

    public function assignments()
    {
        return $this->hasMany(DriverAssignment::class, 'order_id');
    }

    public function statusLogs()
    {
        return $this->hasMany(OrderStatusLog::class, 'order_id');
    }

    public function customerAddress()
    {
        return $this->belongsTo(CustomerAddress::class, 'customer_address_id');
    }

    public function orderStoreTotals()
    {
        return $this->hasMany(OrderStoreTotal::class, 'order_id');
    }

    // Aliases for consistency
    public function driverAssignments()
    {
        return $this->assignments();
    }

    public function storeTotals()
    {
        return $this->orderStoreTotals();
    }
}