<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use MatanYadaev\EloquentSpatial\Objects\Point;

class CustomerAddress extends Model
{
    protected $table = 'customer_addresses';
    public $timestamps = false;

    protected $fillable = [
        'customer_id', 'address', 'location', 'label'
    ];

    protected $casts = [
        'location' => Point::class,
    ];

    public function customer()
    {
        return $this->belongsTo(Customer::class, 'customer_id');
    }
}