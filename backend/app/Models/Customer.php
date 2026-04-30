<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    protected $table = 'customers';
    public $timestamps = false;

    protected $fillable = ['user_id', 'name', 'notes', 'balance', 'created_at'];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function addresses()
    {
        return $this->hasMany(CustomerAddress::class, 'customer_id');
    }

    public function phones()
    {
        return $this->hasMany(CustomerPhone::class, 'customer_id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'customer_id');
    }
}