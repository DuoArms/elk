<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OrderStatusLog;
use Illuminate\Http\Request;

class OrderStatusLogController extends Controller
{
    public function index(Request $request)
    {
        $query = OrderStatusLog::with('order', 'user');
        if ($request->has('order_id')) {
            $query->where('order_id', $request->order_id);
        }
        $logs = $query->orderBy('created_at', 'desc')->paginate(20);
        return response()->json($logs);
    }
}
