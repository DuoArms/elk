<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Driver;
use App\Models\Customer;
use App\Models\Store;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    // إحصائيات عامة
    public function dashboard()
    {
        $today = now()->toDateString();
        $monthStart = now()->startOfMonth();

        $stats = [
            'total_orders_today' => Order::whereDate('created_at', $today)->count(),
            'total_orders_month' => Order::where('created_at', '>=', $monthStart)->count(),
            'total_delivery_fee_today' => Order::whereDate('created_at', $today)->sum('delivery_fee'),
            'total_delivery_fee_month' => Order::where('created_at', '>=', $monthStart)->sum('delivery_fee'),
            'pending_orders' => Order::where('status', 'pending')->count(),
            'active_drivers' => Driver::where('is_available', true)->count(),
            'total_customers' => Customer::count(),
            'total_stores' => Store::count(),
        ];
        return response()->json($stats);
    }

    // أداء السائقين
    public function driverPerformance(Request $request)
    {
        $query = Driver::select('drivers.id', 'users.full_name', DB::raw('COUNT(orders.id) as total_orders'), DB::raw('SUM(orders.delivery_fee) as total_revenue'))
            ->join('users', 'drivers.user_id', '=', 'users.id')
            ->leftJoin('orders', 'drivers.id', '=', 'orders.driver_id')
            ->groupBy('drivers.id', 'users.full_name');

        if ($request->has('from_date')) {
            $query->whereDate('orders.created_at', '>=', $request->from_date);
        }
        if ($request->has('to_date')) {
            $query->whereDate('orders.created_at', '<=', $request->to_date);
        }

        $performance = $query->get();
        return response()->json($performance);
    }

    // تقارير الطلبات حسب المتجر
    public function storeOrders(Request $request)
    {
        $query = Store::select('stores.id', 'stores.name', DB::raw('COUNT(order_items.id) as total_items'), DB::raw('SUM(order_items.actual_price) as total_sales'))
            ->leftJoin('order_items', 'stores.id', '=', 'order_items.store_id')
            ->groupBy('stores.id', 'stores.name');

        $data = $query->get();
        return response()->json($data);
    }

    // الأرباح والعموالت
    public function profits(Request $request)
    {
        $query = Order::select(DB::raw('DATE(created_at) as date'), DB::raw('SUM(delivery_fee) as total_fees'), DB::raw('COUNT(id) as orders_count'))
            ->groupBy('date')
            ->orderBy('date', 'desc');

        if ($request->has('from_date')) {
            $query->whereDate('created_at', '>=', $request->from_date);
        }
        if ($request->has('to_date')) {
            $query->whereDate('created_at', '<=', $request->to_date);
        }

        $profits = $query->paginate(30);
        return response()->json($profits);
    }
}