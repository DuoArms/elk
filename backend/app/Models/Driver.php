<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Driver extends Model
{
    /**
     * تعطيل التواريخ التلقائية لأن الجدول لا يحتوي على عمود updated_at.
     * (سيظل عمود created_at يُملأ تلقائياً من قبل قاعدة البيانات DEFAULT CURRENT_TIMESTAMP).
     */
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'vehicle_type',
        'vehicle_ownership',
        'is_available',
        'current_location',
        'balance',
        'commission_percentage',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function assignments()
    {
        return $this->hasMany(DriverAssignment::class);
    }
}