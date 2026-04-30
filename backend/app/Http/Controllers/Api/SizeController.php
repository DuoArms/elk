<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Size;
use Illuminate\Http\Request;

class SizeController extends Controller
{
    /**
     * عرض قائمة القياسات.
     * يمكن فلترتها حسب store_type_id (مثال: /api/sizes?store_type_id=1)
     * يدعم paginate عبر ?paginate=1
     */
    public function index(Request $request)
    {
        $query = Size::query();

        if ($request->has('store_type_id')) {
            $query->where('store_type_id', $request->store_type_id);
        }

        if ($request->boolean('paginate')) {
            $sizes = $query->paginate(20);
        } else {
            $sizes = $query->get();
        }

        return response()->json($sizes);
    }

    public function show($id)
    {
        $size = Size::findOrFail($id);
        return response()->json($size);
    }

    public function store(Request $request)
    {
        $request->validate([
            'store_type_id' => 'nullable|exists:store_types,id',
            'name'          => 'required|string|max:50',
        ]);

        $size = Size::create($request->only(['name', 'store_type_id']));
        return response()->json($size, 201);
    }

    public function update(Request $request, $id)
    {
        $size = Size::findOrFail($id);
        $request->validate([
            'name'          => 'sometimes|string|max:50',
            'store_type_id' => 'nullable|exists:store_types,id',
        ]);
        $size->update($request->only(['name', 'store_type_id']));
        return response()->json($size);
    }

    public function destroy($id)
    {
        $size = Size::findOrFail($id);
        $size->delete();
        return response()->json(['message' => 'تم حذف القياس بنجاح']);
    }
}