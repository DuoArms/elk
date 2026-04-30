<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    /**
     * عرض قائمة المنتجات.
     * يمكن فلترتها حسب store_type_id (مثال: /api/products?store_type_id=1)
     */
    public function index(Request $request)
    {
        $query = Product::with('storeType', 'unit');

        if ($request->has('store_type_id')) {
            $query->where('store_type_id', $request->store_type_id);
        }

        $products = $query->get();

        return response()->json($products);
    }

    /**
     * عرض منتج محدد مع العلاقات.
     */
    public function show($id)
    {
        $product = Product::with('storeType', 'unit')->findOrFail($id);
        return response()->json($product);
    }

    /**
     * إنشاء منتج جديد.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'store_type_id' => 'required|exists:store_types,id',
            'name'          => 'required|string|max:150',
            'unit_id'       => 'nullable|exists:units,id',
            'price'         => 'nullable|numeric|min:0',
            'is_active'     => 'boolean',
        ]);

        $product = Product::create($validated);

        return response()->json($product, 201);
    }

    /**
     * تحديث منتج موجود.
     */
    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);

        $validated = $request->validate([
            'store_type_id' => 'sometimes|exists:store_types,id',
            'name'          => 'sometimes|string|max:150',
            'unit_id'       => 'nullable|exists:units,id',
            'price'         => 'nullable|numeric|min:0',
            'is_active'     => 'boolean',
        ]);

        $product->update($validated);

        return response()->json($product);
    }

    /**
     * حذف منتج.
     */
    public function destroy($id)
    {
        $product = Product::findOrFail($id);
        $product->delete();

        return response()->json(['message' => 'تم حذف المنتج بنجاح']);
    }
}