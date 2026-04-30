<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Size extends Model
{
    protected $table = 'sizes';
    public $timestamps = false;

    protected $fillable = ['store_type_id', 'name'];

    public function storeType()
    {
        return $this->belongsTo(StoreType::class, 'store_type_id');
    }
}

