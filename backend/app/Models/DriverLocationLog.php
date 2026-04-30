<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use MatanYadaev\EloquentSpatial\Objects\Point;

class DriverLocationLog extends Model
{
    protected $table = 'driver_location_logs';
    public $timestamps = false;

    protected $fillable = [
        'driver_id', 'location', 'created_at'
    ];

    protected $casts = [
        'location' => Point::class,
    ];

    public function driver()
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }
}