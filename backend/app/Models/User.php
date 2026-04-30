<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory;

    protected $table = 'users';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'phone', 'password_hash', 'full_name', 'role', 'is_active', 'created_at'
    ];

    protected $hidden = ['password_hash'];

    public function driver()
    {
        return $this->hasOne(Driver::class, 'user_id');
    }

    public function customer()
    {
        return $this->hasOne(Customer::class, 'user_id');
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class, 'user_id');
    }

    public function getAuthPassword()
    {
        return $this->password_hash;
    }
}