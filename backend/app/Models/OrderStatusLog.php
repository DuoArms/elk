<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderStatusLog extends Model
{
    protected $table = 'order_status_logs';
    public $timestamps = true;

    const CREATED_AT = 'created_at';
    const UPDATED_AT = null;

    protected $fillable = [
        'order_id', 'status', 'changed_by'
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function changedBy()
    {
        return $this->belongsTo(User::class, 'changed_by');
    }
}