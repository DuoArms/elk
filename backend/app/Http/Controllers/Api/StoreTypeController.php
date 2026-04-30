<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StoreType;
use Illuminate\Http\Request;

class StoreTypeController extends Controller
{
    public function index(Request $request)
    {
        $query = StoreType::with('stores');
        
        if ($request->boolean('paginate')) {
            $types = $query->paginate(20);
        } else {
            $types = $query->get();
        }
        
        return response()->json($types);
    }

    public function store(Request $request)
    {
        $request->validate(['name' => 'required|string|max:100']);
        $type = StoreType::create($request->all());
        return response()->json($type, 201);
    }

    public function show($id)
    {
        $type = StoreType::with('stores')->findOrFail($id);
        return response()->json($type);
    }

    public function update(Request $request, $id)
    {
        $type = StoreType::findOrFail($id);
        $request->validate(['name' => 'sometimes|string|max:100']);
        $type->update($request->all());
        return response()->json($type);
    }

    public function destroy($id)
    {
        $type = StoreType::findOrFail($id);
        $type->delete();
        return response()->json(['message' => 'تم حذف نوع المتجر']);
    }
}