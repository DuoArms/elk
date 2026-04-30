<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Store;
use Illuminate\Http\Request;
use MatanYadaev\EloquentSpatial\Objects\Point;
use App\Models\OrderStoreTotal;
use Illuminate\Support\Facades\DB;

class StoreController extends Controller
{
    public function index(Request $request)
    {
        $query = Store::query();
        if ($request->has('store_type_id')) {
            $query->where('store_type_id', $request->store_type_id);
        }
        return $query->get();
    }

    public function show($id)
    {
        $store = Store::with('storeType', 'products')->findOrFail($id);
        return response()->json($store);
    }

    public function store(Request $request)
    {
        $request->validate([
            'store_type_id' => 'required|exists:store_types,id',
            'name'          => 'required|string|max:150',
            'phone'         => 'nullable|string|max:20',
            'address'       => 'nullable|string',
            'location'      => 'nullable|array|min:2|max:2',
            'commission_percentage' => 'nullable|numeric|min:0|max:100',
            'is_active'     => 'boolean',
        ]);

        $data = $request->only(['store_type_id', 'name', 'phone', 'address', 'commission_percentage', 'is_active']);
        if ($request->has('location')) {
            $data['location'] = new Point($request->location[1], $request->location[0]);
        }
        $store = Store::create($data);
        return response()->json($store, 201);
    }

    public function update(Request $request, $id)
    {
        $store = Store::findOrFail($id);
        $request->validate([
            'store_type_id' => 'sometimes|exists:store_types,id',
            'name'          => 'sometimes|string|max:150',
            'phone'         => 'nullable|string|max:20',
            'address'       => 'nullable|string',
            'location'      => 'nullable|array|min:2|max:2',
            'commission_percentage' => 'nullable|numeric|min:0|max:100',
            'is_active'     => 'boolean',
        ]);

        if ($request->has('location')) {
            $request->merge(['location' => new Point($request->location[1], $request->location[0])]);
        }
        $store->update($request->all());
        return response()->json($store);
    }

    public function destroy($id)
    {
        $store = Store::findOrFail($id);
        $store->delete();
        return response()->json(['message' => 'تم حذف المتجر']);
    }
    public function totalPurchases()
{
    $stores = Store::withSum('orderStoreTotals as total_purchases', 'total_amount')->get();
    return response()->json($stores);
}

public function monthlyPurchases($storeId, Request $request)
{
    $month = $request->query('month', now()->month);
    $year = $request->query('year', now()->year);

    $total = OrderStoreTotal::where('store_id', $storeId)
        ->whereYear('created_at', $year)
        ->whereMonth('created_at', $month)
        ->sum('total_amount');

    return response()->json(['total_purchases' => $total]);
}
}