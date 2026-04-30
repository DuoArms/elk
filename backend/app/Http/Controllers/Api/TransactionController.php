<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\Customer;
use App\Models\Driver;
use App\Models\Store;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
{
    public function index(Request $request)
    {
        $query = Transaction::with(['customer', 'driver.user', 'store']);

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }
        if ($request->has('customer_id')) {
            $query->where('customer_id', $request->customer_id);
        }
        if ($request->has('driver_id')) {
            $query->where('driver_id', $request->driver_id);
        }
        if ($request->has('store_id')) {
            $query->where('store_id', $request->store_id);
        }

        $transactions = $query->orderBy('created_at', 'desc')->paginate(20);

        // تحويل amount إلى float لكل معاملة
        $transactions->getCollection()->transform(function ($transaction) {
            $transaction->amount = (float) $transaction->amount;
            return $transaction;
        });

        return response()->json($transactions);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'type'          => 'required|in:customer_debit,customer_credit,driver_debit,driver_credit,store_debit,store_credit',
            'customer_id'   => 'nullable|exists:customers,id',
            'driver_id'     => 'nullable|exists:drivers,id',
            'store_id'      => 'nullable|exists:stores,id',
            'amount'        => 'required|numeric|min:0.01',
            'notes'         => 'nullable|string',
        ]);

        DB::transaction(function () use ($validated) {
            $transaction = Transaction::create($validated);

            $amount = $validated['amount'];
            $type = $validated['type'];

            if (str_contains($type, 'customer')) {
                $customer = Customer::findOrFail($validated['customer_id']);
                $customer->balance += ($type === 'customer_credit') ? $amount : -$amount;
                $customer->save();
            } elseif (str_contains($type, 'driver')) {
                $driver = Driver::findOrFail($validated['driver_id']);
                $driver->balance += ($type === 'driver_credit') ? $amount : -$amount;
                $driver->save();
            } elseif (str_contains($type, 'store')) {
                $store = Store::findOrFail($validated['store_id']);
                $store->balance += ($type === 'store_credit') ? $amount : -$amount;
                $store->save();
            }
        });

        return response()->json(['message' => 'تم إنشاء المعاملة'], 201);
    }
}