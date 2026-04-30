<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaymentChangeRequest;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PaymentChangeRequestController extends Controller
{
    public function index()
    {
        $requests = PaymentChangeRequest::with(['order', 'requester', 'approver'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);
        return response()->json($requests);
    }

    public function store(Request $request)
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'requested_status' => 'required|in:cash,credit,partial',
            'paid_amount' => 'required_if:requested_status,partial|nullable|numeric|min:0',
            'note' => 'nullable|string',
        ]);

        $changeRequest = PaymentChangeRequest::create([
            'order_id' => $request->order_id,
            'requested_by' => auth()->id(),
            'requested_status' => $request->requested_status,
            'paid_amount' => $request->paid_amount,
            'note' => $request->note,
            'status' => 'pending',
        ]);

        return response()->json($changeRequest, 201);
    }

    public function approve(Request $request, $id)
    {
        $request->validate(['approved' => 'required|boolean']);
        $changeRequest = PaymentChangeRequest::findOrFail($id);
        if ($changeRequest->status !== 'pending') {
            return response()->json(['message' => 'تم معالجة هذا الطلب مسبقاً'], 400);
        }

        DB::beginTransaction();
        try {
            $order = Order::find($changeRequest->order_id);
            $customer = Customer::find($order->customer_id);

            // حساب الدين القديم (قيمة المنتجات الفعلية من order_items)
            $productsTotal = OrderItem::where('order_id', $order->id)
                ->where('item_type', 'product')
                ->sum(DB::raw('COALESCE(actual_price, estimated_price, 0) * quantity'));
            $oldDebt = ($productsTotal + $order->delivery_fee) - $order->paid_amount;

            $changeRequest->status = $request->approved ? 'approved' : 'rejected';
            $changeRequest->approved_by = auth()->id();
            $changeRequest->save();

            if ($request->approved) {
                $order->payment_status = $changeRequest->requested_status;

                if ($changeRequest->requested_status === 'partial') {
                    $order->paid_amount = $changeRequest->paid_amount;
                    // remaining_amount يبقى كما هو (قيمة المنتجات)
                } elseif ($changeRequest->requested_status === 'credit') {
                    $order->paid_amount = 0;
                } else { // cash
                    $order->paid_amount = $productsTotal + $order->delivery_fee;
                    $order->remaining_amount = 0;
                }
                $order->save();

                // حساب الدين الجديد
                $newProductsTotal = OrderItem::where('order_id', $order->id)
                    ->where('item_type', 'product')
                    ->sum(DB::raw('COALESCE(actual_price, estimated_price, 0) * quantity'));
                $newDebt = ($newProductsTotal + $order->delivery_fee) - $order->paid_amount;

                if ($customer) {
                    $customer->balance = $customer->balance - $oldDebt + $newDebt;
                    $customer->save();
                }
            }

            DB::commit();
            return response()->json(['message' => 'تمت معالجة الطلب']);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ أثناء معالجة الطلب', 'error' => $e->getMessage()], 500);
        }
    }
}