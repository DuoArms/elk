<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\User;
use App\Models\Order;
use App\Models\DriverLocationLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use MatanYadaev\EloquentSpatial\Objects\Point;

class DriverController extends Controller
{
    // قائمة السائقين (للمدير)
    public function index(Request $request)
    {
        $query = Driver::with('user');
        if ($request->has('is_available')) {
            $query->where('is_available', $request->boolean('is_available'));
        }
        $drivers = $query->orderBy('created_at', 'desc')->paginate(20);
        return response()->json($drivers);
    }

    // عرض سائق محدد
    public function show($id)
    {
        $driver = Driver::with('user', 'assignments.order')->findOrFail($id);
        return response()->json($driver);
    }

    // إنشاء سائق جديد (للمدير)
    public function store(Request $request)
    {
        $request->validate([
            'full_name'             => 'required|string|max:100',
            'phone'                 => 'required|string|unique:users,phone',
            'password'              => 'required|string|min:6',
            'vehicle_type'          => 'nullable|string|max:50',
            'vehicle_ownership'     => 'required|in:owner,company',   // ✅ تم التصحيح
            'current_location'      => 'nullable|array|min:2|max:2',
            'commission_percentage' => 'nullable|numeric|min:0|max:100',
        ]);

        DB::beginTransaction();
        try {
            $user = User::create([
                'phone'         => $request->phone,
                'password_hash' => Hash::make($request->password),
                'full_name'     => $request->full_name,
                'role'          => 'driver',
                'is_active'     => true,
            ]);

            $driverData = [
                'user_id'              => $user->id,
                'vehicle_type'         => $request->vehicle_type,
                'vehicle_ownership'    => $request->vehicle_ownership,
                'is_available'         => true,
                'balance'              => 0,
                'commission_percentage'=> $request->commission_percentage ?? 10,
            ];

            if ($request->has('current_location')) {
                $driverData['current_location'] = new Point($request->current_location[1], $request->current_location[0]);
            }

            $driver = Driver::create($driverData);

            DB::commit();
            return response()->json($driver->load('user'), 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ أثناء إنشاء السائق', 'error' => $e->getMessage()], 500);
        }
    }

    // تحديث سائق (للمدير)
    public function update(Request $request, $id)
    {
        $driver = Driver::findOrFail($id);
        $user = $driver->user;

        $request->validate([
            'full_name'             => 'sometimes|string|max:100',
            'phone'                 => 'sometimes|string|unique:users,phone,' . $user->id,
            'vehicle_type'          => 'nullable|string|max:50',
            'vehicle_ownership'     => 'sometimes|in:owner,company',   // ✅ تم التصحيح
            'is_available'          => 'sometimes|boolean',
            'is_active'             => 'sometimes|boolean',
            'current_location'      => 'nullable|array|min:2|max:2',
            'commission_percentage' => 'nullable|numeric|min:0|max:100',
        ]);

        if ($request->has('full_name')) $user->full_name = $request->full_name;
        if ($request->has('phone')) $user->phone = $request->phone;
        if ($request->has('is_active')) $user->is_active = $request->is_active;
        $user->save();

        if ($request->has('vehicle_type')) $driver->vehicle_type = $request->vehicle_type;
        if ($request->has('vehicle_ownership')) $driver->vehicle_ownership = $request->vehicle_ownership;
        if ($request->has('is_available')) $driver->is_available = $request->is_available;
        if ($request->has('commission_percentage')) $driver->commission_percentage = $request->commission_percentage;
        if ($request->has('current_location')) {
            $driver->current_location = new Point($request->current_location[1], $request->current_location[0]);
        }
        $driver->save();

        return response()->json($driver->load('user'));
    }

    // حذف سائق (للمدير)
    public function destroy($id)
    {
        $driver = Driver::findOrFail($id);
        $user = $driver->user;
        $driver->delete();
        if ($user) $user->delete();
        return response()->json(['message' => 'تم حذف السائق بنجاح']);
    }

    // عرض طلبات السائق الحالي
    public function myOrders()
    {
        $user = auth()->user();
        $driver = Driver::where('user_id', $user->id)->first();
        if (!$driver) {
            return response()->json(['message' => 'السائق غير موجود'], 404);
        }

        $orders = Order::where('driver_id', $driver->id)
            ->with([
                'items' => function ($query) {
                    $query->orderBy('sort_order');
                },
                'items.product',
                'items.store',
                'items.unit',
                'items.size',
                'customer',
            ])
            ->orderBy('created_at', 'desc')
            ->get();

        $orders->transform(function ($order) {
            $order->customer_name = $order->customer ? $order->customer->name : null;
            foreach ($order->items as $item) {
                $item->product_name = $item->product ? $item->product->name : null;
                $item->store_name = $item->store ? $item->store->name : null;
                $item->unit_name = $item->unit ? $item->unit->name : null;
                $item->size_name = $item->size ? $item->size->name : null;
            }
            return $order;
        });

        return response()->json($orders);
    }

    // عرض الملف الشخصي للسائق الحالي
    public function profile()
    {
        $user = auth()->user();
        $driver = $user->driver;
        if (!$driver) {
            return response()->json(['message' => 'السائق غير موجود'], 404);
        }
        $driver->load('user');
        return response()->json($driver);
    }

    // تبديل حالة التوفر للسائق الحالي
    public function toggleAvailability()
    {
        $user = auth()->user();
        $driver = $user->driver;
        if (!$driver) {
            return response()->json(['message' => 'السائق غير موجود'], 404);
        }
        $driver->is_available = !$driver->is_available;
        $driver->save();
        return response()->json(['is_available' => $driver->is_available]);
    }

    // تحديث موقع السائق الحالي
    public function updateLocation(Request $request)
    {
        $request->validate([
            'location'   => 'required|array|min:2|max:2',
            'location.*' => 'numeric',
        ]);

        $driver = Driver::where('user_id', auth()->id())->firstOrFail();
        $oldLocation = $driver->current_location;
        $newLocation = new Point($request->location[1], $request->location[0]);

        DriverLocationLog::create([
            'driver_id'  => $driver->id,
            'location'   => $oldLocation ?: $newLocation,
            'created_at' => now(),
        ]);

        $driver->current_location = $newLocation;
        $driver->save();

        return response()->json(['message' => 'تم تحديث الموقع بنجاح']);
    }
}