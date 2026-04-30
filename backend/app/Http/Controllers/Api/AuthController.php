<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Driver;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    // تسجيل الدخول
    public function login(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('phone', $request->phone)->first();

        if (!$user || !Hash::check($request->password, $user->password_hash)) {
            throw ValidationException::withMessages([
                'phone' => ['بيانات الدخول غير صحيحة.'],
            ]);
        }

        if (!$user->is_active) {
            return response()->json(['message' => 'الحساب غير نشط. تواصل مع المدير'], 403);
        }

        $user->tokens()->delete();
        $abilities = $this->getAbilitiesByRole($user->role);
        $token = $user->createToken('auth_token', $abilities)->plainTextToken;

        $extra = [];
        if ($user->role === 'driver') {
            $driver = Driver::where('user_id', $user->id)->first();
            if ($driver) $extra['driver'] = $driver;
        } elseif ($user->role === 'customer') {
            $customer = Customer::where('user_id', $user->id)->first();
            if ($customer) $extra['customer'] = $customer;
        }

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'full_name' => $user->full_name,
                'phone' => $user->phone,
                'role' => $user->role,
                'is_active' => $user->is_active,
            ],
            'extra' => $extra
        ]);
    }

    // تسجيل الخروج
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'تم تسجيل الخروج بنجاح']);
    }

    // جلب بيانات المستخدم الحالي
    public function me(Request $request)
    {
        $user = $request->user();
        $extra = [];
        if ($user->role === 'driver') {
            $extra['driver'] = Driver::where('user_id', $user->id)->first();
        } elseif ($user->role === 'customer') {
            $extra['customer'] = Customer::where('user_id', $user->id)->first();
        }
        return response()->json(['user' => $user, 'extra' => $extra]);
    }

    // الصلاحيات حسب الدور
    private function getAbilitiesByRole($role)
    {
        return match ($role) {
            'admin' => ['*'],
            'office' => ['orders:create', 'orders:update', 'orders:assign-driver', 'customers:manage', 'drivers:view', 'reports:view', 'stores:manage', 'products:manage'],
            'driver' => ['orders:view-assigned', 'orders:accept', 'orders:update-status', 'location:update'],
            'accountant' => ['transactions:view', 'transactions:create', 'reports:financial'],
            'store' => ['products:manage', 'orders:view-store-orders'],
            default => [],
        };
    }
}