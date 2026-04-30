<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Driver;
use App\Models\Customer;
use App\Models\Store;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Transaction;
use App\Models\OrderStoreTotal;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AdminController extends Controller
{
    /**
     * Get general statistics for admin dashboard.
     */
    public function stats()
    {
        $today = now()->toDateString();

        return response()->json([
            'today_orders'    => Order::whereDate('created_at', $today)->count(),
            'total_revenue'   => (float) Order::where('status', 'delivered')->sum('delivery_fee'),
            'pending_orders'  => Order::where('status', 'pending')->count(),
        ]);
    }

    /**
     * Get accounting dashboard statistics.
     */
    public function accountantDashboard()
    {
        $totalRevenue = (float) Order::where('status', 'delivered')->sum('delivery_fee');
        $totalDriverPayouts = (float) Transaction::where('type', 'driver_credit')->sum('amount');
        $totalStorePurchases = (float) OrderStoreTotal::sum('total_amount');
        $baseBalance = (float) Customer::sum('balance');

        $ordersDebt = 0;
        $creditPartialOrders = Order::whereIn('payment_status', ['credit', 'partial'])->get(['id', 'delivery_fee', 'paid_amount']);
        foreach ($creditPartialOrders as $order) {
            $productsTotal = (float) OrderItem::where('order_id', $order->id)
                ->where('item_type', 'product')
                ->sum(DB::raw('COALESCE(actual_price, estimated_price, 0) * quantity'));
            $totalDue = $productsTotal + $order->delivery_fee;
            $debt = $totalDue - $order->paid_amount;
            if ($debt > 0) {
                $ordersDebt += $debt;
            }
        }

        $customersDebt = $baseBalance + $ordersDebt;
        $netProfit = $totalRevenue - $totalDriverPayouts;
        $totalOrders = Order::count();
        $completedOrders = Order::where('status', 'delivered')->count();

        return response()->json([
            'total_revenue'          => $totalRevenue,
            'total_driver_payouts'   => $totalDriverPayouts,
            'total_store_purchases'  => $totalStorePurchases,
            'customers_debt'         => $customersDebt,
            'net_profit'             => $netProfit,
            'total_orders'           => $totalOrders,
            'completed_orders'       => $completedOrders,
        ]);
    }

    /**
     * Store a newly created driver.
     */
    public function storeDriver(Request $request)
    {
        $request->validate([
            'full_name'             => 'required|string|max:100',
            'phone'                 => 'required|string|unique:users,phone',
            'password'              => 'required|string|min:6',
            'vehicle_type'          => 'nullable|string|max:50',
            'vehicle_ownership'     => 'required|in:owner,company',   // ✅ تم التصحيح
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

            $driver = Driver::create([
                'user_id'              => $user->id,
                'vehicle_type'         => $request->vehicle_type,
                'vehicle_ownership'    => $request->vehicle_ownership,
                'is_available'         => true,
                'balance'              => 0,
                'commission_percentage'=> $request->commission_percentage ?? 10,
            ]);

            DB::commit();
            return response()->json($driver->load('user'), 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ أثناء إنشاء السائق', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Update the specified driver.
     */
    public function updateDriver(Request $request, $id)
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
        $driver->save();

        return response()->json($driver->load('user'));
    }

    /**
     * Remove the specified driver.
     */
    public function destroyDriver($id)
    {
        $driver = Driver::findOrFail($id);
        $user = $driver->user;
        $driver->delete();
        if ($user) $user->delete();
        return response()->json(['message' => 'تم حذف السائق بنجاح']);
    }

    /**
     * List all office users.
     */
    public function officeUsers()
    {
        $users = User::where('role', 'office')
            ->get(['id', 'full_name', 'phone', 'is_active', 'created_at']);

        return response()->json($users);
    }

    /**
     * Create a new office user.
     */
    public function storeOfficeUser(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:100',
            'phone'     => 'required|string|unique:users,phone',
            'password'  => 'required|string|min:6',
        ]);

        $user = User::create([
            'full_name'     => $request->full_name,
            'phone'         => $request->phone,
            'password_hash' => Hash::make($request->password),
            'role'          => 'office',
            'is_active'     => true,
        ]);

        return response()->json($user, 201);
    }

    /**
     * Get all customers with their current balance (including orders debt).
     */
    public function customersBalance()
    {
        $customers = Customer::with('user')->get(['id', 'user_id', 'name', 'balance']);

        $result = $customers->map(function ($customer) {
            $orders = Order::where('customer_id', $customer->id)
                ->whereIn('payment_status', ['credit', 'partial'])
                ->get(['id', 'delivery_fee', 'paid_amount']);

            $totalOrdersDebt = 0;
            foreach ($orders as $order) {
                $productsTotal = (float) OrderItem::where('order_id', $order->id)
                    ->where('item_type', 'product')
                    ->sum(DB::raw('COALESCE(actual_price, estimated_price, 0) * quantity'));
                $totalDue = $productsTotal + $order->delivery_fee;
                $debt = $totalDue - $order->paid_amount;
                if ($debt > 0) {
                    $totalOrdersDebt += $debt;
                }
            }

            $actualBalance = (float) $customer->balance + $totalOrdersDebt;

            return [
                'id'           => $customer->id,
                'name'         => $customer->name,
                'phone'        => $customer->user->phone ?? '',
                'balance'      => $actualBalance,
                'base_balance' => (float) $customer->balance,
                'orders_debt'  => $totalOrdersDebt,
            ];
        });

        return response()->json($result);
    }

    /**
     * Get all drivers with their commission balance.
     */
    public function driversBalance()
    {
        $drivers = Driver::with('user')->get(['id', 'user_id', 'balance', 'commission_percentage']);

        $result = $drivers->map(function ($driver) {
            return [
                'id'                    => $driver->id,
                'name'                  => $driver->user->full_name ?? 'سائق ' . $driver->id,
                'phone'                 => $driver->user->phone ?? '',
                'commission_balance'    => (float) $driver->balance,
                'commission_percentage' => (float) $driver->commission_percentage,
            ];
        });

        return response()->json($result);
    }

    /**
     * Get total purchases per store.
     */
    public function storePurchases()
    {
        $stores = Store::select('id', 'name')
            ->withSum('orderStoreTotals as total_purchases', 'total_amount')
            ->get()
            ->map(function ($store) {
                return [
                    'id' => $store->id,
                    'name' => $store->name,
                    'total_purchases' => (float) ($store->total_purchases ?? 0),
                ];
            });

        return response()->json($stores);
    }

    /**
     * Get all stores with their balance.
     */
    public function storesBalance()
    {
        $stores = Store::select('id', 'name', 'phone', 'balance')->get();

        $stores->transform(function ($store) {
            $store->balance = (float) $store->balance;
            return $store;
        });

        return response()->json($stores);
    }

    // ======================= الدفعات المستقلة للزبائن =======================

    /**
     * إضافة رصيد للزبون (تسديد دين) – مستقلة عن الطلبات.
     */
    public function addCustomerBalance(Request $request)
    {
        $request->validate([
            'customer_id' => 'required|exists:customers,id',
            'amount'      => 'required|numeric|min:0.01',
            'notes'       => 'nullable|string',
        ]);

        DB::beginTransaction();
        try {
            $customer = Customer::findOrFail($request->customer_id);
            $customer->increment('balance', $request->amount);

            Transaction::create([
                'type'        => 'customer_credit',
                'customer_id' => $customer->id,
                'amount'      => $request->amount,
                'notes'       => $request->notes ?? 'تسديد يدوي من الإدارة',
            ]);

            DB::commit();
            return response()->json(['message' => 'تم إضافة الرصيد بنجاح', 'new_balance' => $customer->balance]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * خصم رصيد من الزبون (استدانة إضافية) – مستقلة عن الطلبات.
     */
    public function deductCustomerBalance(Request $request)
    {
        $request->validate([
            'customer_id' => 'required|exists:customers,id',
            'amount'      => 'required|numeric|min:0.01',
            'notes'       => 'nullable|string',
        ]);

        DB::beginTransaction();
        try {
            $customer = Customer::findOrFail($request->customer_id);
            if ($customer->balance < $request->amount) {
                return response()->json(['message' => 'رصيد الزبون غير كافٍ'], 422);
            }
            $customer->decrement('balance', $request->amount);

            Transaction::create([
                'type'        => 'customer_debit',
                'customer_id' => $customer->id,
                'amount'      => $request->amount,
                'notes'       => $request->notes ?? 'خصم يدوي من الإدارة',
            ]);

            DB::commit();
            return response()->json(['message' => 'تم خصم الرصيد بنجاح', 'new_balance' => $customer->balance]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * عرض سجل معاملات الزبون (الدفعات المستقلة + المرتبطة بالطلبات).
     */
    public function customerTransactions($customerId)
    {
        $customer = Customer::findOrFail($customerId);
        $transactions = Transaction::where('customer_id', $customerId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'customer'      => $customer->name,
            'balance'       => $customer->balance,
            'transactions'  => $transactions,
        ]);
    }
    public function updateOfficeUser(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $request->validate([
            'full_name' => 'sometimes|string|max:100',
            'phone'     => 'sometimes|string|unique:users,phone,' . $id,
        ]);
        if ($request->has('full_name')) $user->full_name = $request->full_name;
        if ($request->has('phone')) $user->phone = $request->phone;
        $user->save();
        return response()->json($user);
    }
    
    public function destroyOfficeUser($id)
    {
        $user = User::findOrFail($id);
        $user->delete();
        return response()->json(['message' => 'تم حذف المستخدم بنجاح']);
    }
}