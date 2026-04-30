<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PaymentChangeRequest extends Model
{
    protected $table = 'payment_change_requests';
    public $timestamps = false;

    protected $fillable = [
        'order_id', 'requested_by', 'requested_status', 'paid_amount',
        'note', 'status', 'approved_by', 'created_at'
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function requester()
    {
        return $this->belongsTo(User::class, 'requested_by');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}