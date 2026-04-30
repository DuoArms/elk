<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Unit;
use Illuminate\Http\Request;

class UnitController extends Controller
{
    public function index(Request $request)
    {
        $query = Unit::with('storeType');
        
        if ($request->has('store_type_id')) {
            $query->where('store_type_id', $request->store_type_id);
        }
        
        if ($request->boolean('paginate')) {
            $units = $query->paginate(20);
        } else {
            $units = $query->get();
        }
        
        return response()->json($units);
    }

    public function store(Request $request)
    {
        $request->validate([
            'store_type_id' => 'nullable|exists:store_types,id',
            'name'          => 'required|string|max:50',
        ]);
        $unit = Unit::create($request->all());
        return response()->json($unit, 201);
    }

    public function show($id)
    {
        $unit = Unit::findOrFail($id);
        return response()->json($unit);
    }

    public function update(Request $request, $id)
    {
        $unit = Unit::findOrFail($id);
        $request->validate([
            'name'          => 'sometimes|string|max:50',
            'store_type_id' => 'nullable|exists:store_types,id',
        ]);
        $unit->update($request->all());
        return response()->json($unit);
    }

    public function destroy($id)
    {
        $unit = Unit::findOrFail($id);
        $unit->delete();
        return response()->json(['message' => 'تم حذف الوحدة']);
    }
}