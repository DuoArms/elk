<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomerPhone extends Model
{
    protected $table = 'customer_phones';
    public $timestamps = false;

    protected $fillable = ['customer_id', 'phone'];

    public function customer()
    {
        return $this->belongsTo(Customer::class, 'customer_id');
    }
}