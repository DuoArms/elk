<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriverCommissionRule;
use Illuminate\Http\Request;

class DriverCommissionRuleController extends Controller
{
    public function index()
    {
        $rules = DriverCommissionRule::orderBy('id')->paginate(20);
        return response()->json($rules);
    }

    public function store(Request $request)
    {
        $request->validate([
            'vehicle_ownership' => 'required|in:own,company',
            'commission_percentage' => 'required|numeric|min:0|max:100',
            'is_active' => 'boolean',
        ]);

        $rule = DriverCommissionRule::create($request->all());
        return response()->json($rule, 201);
    }

    public function show($id)
    {
        $rule = DriverCommissionRule::findOrFail($id);
        return response()->json($rule);
    }

    public function update(Request $request, $id)
    {
        $rule = DriverCommissionRule::findOrFail($id);
        $request->validate([
            'commission_percentage' => 'sometimes|numeric|min:0|max:100',
            'is_active' => 'sometimes|boolean',
        ]);
        $rule->update($request->all());
        return response()->json($rule);
    }

    public function destroy($id)
    {
        $rule = DriverCommissionRule::findOrFail($id);
        $rule->delete();
        return response()->json(['message' => 'تم حذف القاعدة']);
    }
}