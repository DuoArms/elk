<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoreType extends Model
{
    protected $table = 'store_types';
    public $timestamps = false;

    protected $fillable = ['name'];

    public function stores()
    {
        return $this->hasMany(Store::class, 'store_type_id');
    }

    public function units()
    {
        return $this->hasMany(Unit::class, 'store_type_id');
    }

    public function sizes()
    {
        return $this->hasMany(Size::class, 'store_type_id');
    }

    public function products()
    {
        return $this->hasMany(Product::class, 'store_type_id');
    }
}