<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriverLocationLog;
use Illuminate\Http\Request;

class DriverLocationLogController extends Controller
{
    public function index(Request $request)
    {
        $query = DriverLocationLog::with('driver');
        if ($request->has('driver_id')) {
            $query->where('driver_id', $request->driver_id);
        }
        $logs = $query->orderBy('created_at', 'desc')->paginate(20);
        return response()->json($logs);
    }

    public function show($id)
    {
        $log = DriverLocationLog::findOrFail($id);
        return response()->json($log);
    }
}