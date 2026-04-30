<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\DriverAssignment;
use App\Models\DriverCommissionRule;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatusLog;
use App\Models\OrderStoreTotal;
use App\Models\Transaction;
use App\Models\Notification;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use MatanYadaev\EloquentSpatial\Objects\Point;
use Illuminate\Support\Facades\Log;

class OrderController extends Controller
{
    // قائمة الطلبات مع فلترة
    public function index(Request $request)
    {
        $query = Order::with([
            'customer',
            'driver.user',
            'officeUser',
            'items.product',
            'items.unit',
            'customerAddress'
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->customer_id);
        }
        if ($request->filled('driver_id')) {
            $query->where('driver_id', $request->driver_id);
        }

        $orders = $query->orderBy('created_at', 'desc')->paginate(20);
        return response()->json($orders);
    }

    // عرض طلب محدد مع العلاقات
    public function show($id)
    {
        $order = Order::with([
            'customer',
            'driver.user',
            'officeUser',
            'items.store',
            'items.product',
            'items.unit',
            'assignments.driver.user',
            'customerAddress'
        ])->findOrFail($id);

        return response()->json($order);
    }

    // إنشاء طلب جديد (يدعم منتجات، توصيل، فواتير) - مع المعالجة المالية الصحيحة
    public function store(Request $request)
    {
        $validated = $request->validate([
            'customer_id'         => ['required', 'exists:customers,id'],
            'office_user_id'      => ['nullable', 'exists:users,id'],
            'delivery_fee'        => ['required', 'numeric', 'min:0'],
            'paid_amount'         => ['nullable', 'numeric', 'min:0'],
            'remaining_amount'    => ['nullable', 'numeric', 'min:0'],
            'payment_status'      => ['nullable', Rule::in(['cash', 'credit', 'partial'])],
            'pickup_location'     => ['nullable', 'array'],
            'pickup_location.*'   => ['numeric'],
            'delivery_location'   => ['nullable', 'array'],
            'delivery_location.*' => ['numeric'],
            'notes'               => ['nullable', 'string'],
            'driver_id'           => ['nullable', 'exists:drivers,id'],
            'customer_address_id' => ['nullable', 'integer', 'exists:customer_addresses,id'],
            'order_phones'        => ['nullable', 'string'],
            'items'               => ['required', 'array', 'min:1'],
            'items.*.item_type'   => ['nullable', Rule::in(['product', 'delivery', 'invoice'])],
            'items.*.store_id'    => ['nullable', 'exists:stores,id'],
            'items.*.product_id'  => ['nullable', 'exists:products,id'],
            'items.*.unit_id'     => ['nullable', 'exists:units,id'],
            'items.*.description' => ['nullable', 'string'],
            'items.*.quantity'    => ['nullable', 'numeric', 'min:0.01'],
            'items.*.estimated_price' => ['nullable', 'numeric', 'min:0'],
            'items.*.estimated_fee'   => ['nullable', 'numeric', 'min:0'],
            'items.*.estimated_total' => ['nullable', 'numeric', 'min:0'],
            'items.*.due_date'        => ['nullable', 'date'],
            'items.*.pickup_address'  => ['nullable', 'string'],
            'items.*.pickup_phone'    => ['nullable', 'string', 'max:20'],
            'items.*.pickup_contact_name' => ['nullable', 'string', 'max:100'],
            'items.*.delivery_address'=> ['nullable', 'string'],
            'items.*.delivery_phone'  => ['nullable', 'string', 'max:20'],
            'items.*.delivery_contact_name' => ['nullable', 'string', 'max:100'],
            'items.*.invoice_type'    => ['nullable', 'string', 'max:50'],
            'items.*.company_name'    => ['nullable', 'string', 'max:150'],
            'items.*.notes'           => ['nullable', 'string'],
            'items.*.sort_order'      => ['nullable', 'integer', 'min:0'],
            'items.*.is_available'    => ['nullable', 'boolean'],
            'items.*.size_id'         => ['nullable', 'exists:sizes,id'],
        ]);

        if (empty($validated['items'])) {
            return response()->json(['message' => 'يجب إضافة عنصر واحد على الأقل'], 422);
        }

        // التحقق من صحة كل عنصر حسب نوعه
        foreach ($validated['items'] as $index => $item) {
            $type = $item['item_type'] ?? 'product';

            if (!in_array($type, ['product', 'delivery', 'invoice'], true)) {
                return response()->json([
                    'message' => 'نوع عنصر غير صحيح',
                    'errors'  => ["items.$index.item_type" => ['نوع العنصر غير صحيح']],
                ], 422);
            }

            if ($type === 'product') {
                if (empty($item['store_id'])) {
                    return response()->json([
                        'message' => 'بيانات غير مكتملة',
                        'errors'  => ["items.$index.store_id" => ['store_id مطلوب لعنصر product']],
                    ], 422);
                }
                if (empty($item['product_id'])) {
                    return response()->json([
                        'message' => 'بيانات غير مكتملة',
                        'errors'  => ["items.$index.product_id" => ['product_id مطلوب لعنصر product']],
                    ], 422);
                }
            }

            if ($type === 'delivery') {
                if (empty($item['pickup_address'])) {
                    return response()->json([
                        'message' => 'بيانات غير مكتملة',
                        'errors'  => ["items.$index.pickup_address" => ['pickup_address مطلوب لعنصر delivery']],
                    ], 422);
                }
                if (empty($item['delivery_address'])) {
                    return response()->json([
                        'message' => 'بيانات غير مكتملة',
                        'errors'  => ["items.$index.delivery_address" => ['delivery_address مطلوب لعنصر delivery']],
                    ], 422);
                }
            }

            if ($type === 'invoice' && empty($item['company_name'])) {
                return response()->json([
                    'message' => 'بيانات غير مكتملة',
                    'errors'  => ["items.$index.company_name" => ['company_name مطلوب لعنصر invoice']],
                ], 422);
            }
        }

        $officeUserId = $this->resolveOfficeUserId($request, $validated);
        $paymentStatus = $validated['payment_status'] ?? 'cash';
        $deliveryFee = (float) $validated['delivery_fee'];
        $paidAmount = (float) ($validated['paid_amount'] ?? 0);

        if ($paymentStatus === 'credit' || $paymentStatus === 'partial') {
            $remainingAmount = (float) ($validated['remaining_amount'] ?? 0);
        } else {
            $remainingAmount = 0;
        }

        $totalDebt = ($remainingAmount + $deliveryFee) - $paidAmount;

        DB::beginTransaction();

        try {
            $orderNumber = 'ORD-' . strtoupper(uniqid());

            $order = Order::create([
                'order_number'        => $orderNumber,
                'customer_id'         => $validated['customer_id'],
                'office_user_id'      => $officeUserId,
                'driver_id'           => $validated['driver_id'] ?? null,
                'status'              => 'pending',
                'delivery_fee'        => $deliveryFee,
                'payment_status'      => $paymentStatus,
                'paid_amount'         => $paidAmount,
                'remaining_amount'    => $remainingAmount,
                'pickup_location'     => $this->pointFromArray($validated['pickup_location'] ?? null),
                'delivery_location'   => $this->pointFromArray($validated['delivery_location'] ?? null),
                'notes'               => $validated['notes'] ?? null,
                'customer_address_id' => $validated['customer_address_id'] ?? null,
                'order_phones'        => $validated['order_phones'] ?? null,
            ]);

            // تحديث رصيد الزبون إذا كان هناك دين
            if ($paymentStatus !== 'cash' && $totalDebt > 0) {
                $customer = Customer::find($validated['customer_id']);
                $customer->increment('balance', $totalDebt);
            }

            OrderStatusLog::create([
                'order_id'   => $order->id,
                'status'     => 'pending',
                'changed_by' => $officeUserId,
            ]);

            foreach ($validated['items'] as $index => $item) {
                $this->createOrderItem($order, $item, $index);
            }

            $driverId = $validated['driver_id'] ?? null;

            // تعيين أقرب سائق إذا لم يحدد سائق وكان هناك موقع استلام
            if (!$driverId && !empty($validated['pickup_location'])) {
                $point = $this->pointFromArray($validated['pickup_location']);
                if ($point) {
                    $nearestDriver = Driver::where('is_available', true)
                        ->orderByRaw('current_location <-> ST_SetSRID(ST_MakePoint(?, ?), 4326)', [
                            $point->longitude,
                            $point->latitude,
                        ])
                        ->first();
                    if ($nearestDriver) {
                        $driverId = $nearestDriver->id;
                    }
                }
            }

            if ($driverId) {
                DriverAssignment::create([
                    'order_id'     => $order->id,
                    'driver_id'    => $driverId,
                    'status'       => 'pending',
                    'assigned_at'  => now(),
                ]);

                $order->update([
                    'status'    => 'assigned',
                    'driver_id' => $driverId,
                ]);

                OrderStatusLog::create([
                    'order_id'   => $order->id,
                    'status'     => 'assigned',
                    'changed_by' => $officeUserId,
                ]);

                $driverModel = Driver::find($driverId);
                if ($driverModel && $driverModel->user_id) {
                    Notification::create([
                        'user_id'     => $driverModel->user_id,
                        'sender_id'   => $officeUserId,
                        'type'        => 'new_order',
                        'order_id'    => $order->id,
                        'driver_id'   => $driverId,
                        'title'       => 'طلب جديد',
                        'body'        => "تم تعيين طلب جديد #{$order->order_number} إليك. يرجى مراجعة التفاصيل.",
                    ]);
                }

                Notification::create([
                    'user_id'     => $officeUserId,
                    'sender_id'   => $officeUserId,
                    'type'        => 'order_assigned',
                    'order_id'    => $order->id,
                    'driver_id'   => $driverId,
                    'title'       => 'تم تعيين سائق للطلب',
                    'body'        => "تم تعيين السائق {$driverModel->user->full_name} للطلب #{$order->order_number}.",
                ]);
            }

            DB::commit();

            return response()->json(
                $order->load([
                    'customer',
                    'driver.user',
                    'officeUser',
                    'items.store',
                    'items.product',
                    'items.unit',
                ]),
                201
            );
        } catch (ValidationException $e) {
            DB::rollBack();
            throw $e;
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Order creation failed: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'message' => 'حدث خطأ أثناء إنشاء الطلب',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * تحديث طلب موجود (بيانات أساسية + عناصر)
     * مع دعم تغيير الحالة إلى assigned تلقائياً عند تعيين سائق جديد والطلب pending
     */
    public function update(Request $request, $id)
    {
        $order = Order::findOrFail($id);

        $user = auth('sanctum')->user();
        $isOfficeOrAdmin = in_array($user->role, ['office', 'admin']);
        if (!$isOfficeOrAdmin) {
            return response()->json(['message' => 'غير مصرح'], 403);
        }

        $validated = $request->validate([
            'delivery_fee'        => ['nullable', 'numeric', 'min:0'],
            'paid_amount'         => ['nullable', 'numeric', 'min:0'],
            'remaining_amount'    => ['nullable', 'numeric', 'min:0'],
            'payment_status'      => ['nullable', Rule::in(['cash', 'credit', 'partial'])],
            'notes'               => ['nullable', 'string'],
            'driver_id'           => ['nullable', 'exists:drivers,id'],
            'customer_address_id' => ['nullable', 'integer', 'exists:customer_addresses,id'],
            'order_phones'        => ['nullable', 'string'],
            'items'               => ['nullable', 'array'],
            'items.*.id'          => ['nullable', 'integer'],
            'items.*.item_type'   => ['required', Rule::in(['product', 'delivery', 'invoice'])],
            'items.*.store_id'    => ['nullable', 'exists:stores,id'],
            'items.*.product_id'  => ['nullable', 'exists:products,id'],
            'items.*.unit_id'     => ['nullable', 'exists:units,id'],
            'items.*.size_id'     => ['nullable', 'exists:sizes,id'],
            'items.*.quantity'    => ['nullable', 'numeric', 'min:0.01'],
            'items.*.estimated_price' => ['nullable', 'numeric', 'min:0'],
            'items.*.estimated_fee'   => ['nullable', 'numeric', 'min:0'],
            'items.*.estimated_total' => ['nullable', 'numeric', 'min:0'],
            'items.*.description' => ['nullable', 'string'],
            'items.*.pickup_address'  => ['nullable', 'string'],
            'items.*.delivery_address'=> ['nullable', 'string'],
            'items.*.pickup_phone'    => ['nullable', 'string'],
            'items.*.delivery_phone'  => ['nullable', 'string'],
            'items.*.company_name'    => ['nullable', 'string'],
            'items.*.due_date'        => ['nullable', 'date'],
            'items.*.notes'           => ['nullable', 'string'],
            'items.*.sort_order'      => ['nullable', 'integer'],
        ]);

        DB::beginTransaction();
        try {
            $oldProductsTotal = OrderItem::where('order_id', $order->id)
                ->where('item_type', 'product')
                ->sum(DB::raw('COALESCE(actual_price, estimated_price, 0) * quantity'));
            $oldDebt = ($order->remaining_amount + $order->delivery_fee) - $order->paid_amount;

            $customer = Customer::find($order->customer_id);

            $oldDriverId = $order->driver_id;

            $order->delivery_fee        = $validated['delivery_fee'] ?? $order->delivery_fee;
            $order->paid_amount         = $validated['paid_amount'] ?? $order->paid_amount;
            $order->payment_status      = $validated['payment_status'] ?? $order->payment_status;
            $order->notes               = $validated['notes'] ?? $order->notes;
            $order->driver_id           = $validated['driver_id'] ?? $order->driver_id;
            $order->customer_address_id = $validated['customer_address_id'] ?? $order->customer_address_id;
            $order->order_phones        = $validated['order_phones'] ?? $order->order_phones;

            if ($request->has('remaining_amount')) {
                $order->remaining_amount = (float) $request->remaining_amount;
            }

            if (isset($validated['items']) && is_array($validated['items'])) {
                $incomingIds = collect($validated['items'])->pluck('id')->filter()->toArray();
                OrderItem::where('order_id', $order->id)
                    ->whereNotIn('id', $incomingIds)
                    ->delete();

                foreach ($validated['items'] as $itemData) {
                    if (isset($itemData['id']) && $itemData['id']) {
                        $item = OrderItem::where('id', $itemData['id'])->where('order_id', $order->id)->firstOrFail();
                        $item->fill($this->mapItemData($itemData));
                        $item->save();
                    } else {
                        $this->createOrderItem($order, $itemData, $itemData['sort_order'] ?? 0);
                    }
                }
            }

            // ✅ تغيير الحالة إلى assigned عند تعيين سائق جديد والطلب pending
            if ($request->has('driver_id') && $order->driver_id != $oldDriverId) {
                if ($order->status === 'pending') {
                    $order->status = 'assigned';

                    DriverAssignment::create([
                        'order_id'    => $order->id,
                        'driver_id'   => $order->driver_id,
                        'status'      => 'pending',
                        'assigned_at' => now(),
                    ]);

                    OrderStatusLog::create([
                        'order_id'   => $order->id,
                        'status'     => 'assigned',
                        'changed_by' => auth('sanctum')->id(),
                    ]);

                    $driverModel = Driver::find($order->driver_id);
                    if ($driverModel && $driverModel->user_id) {
                        Notification::create([
                            'user_id'     => $driverModel->user_id,
                            'sender_id'   => auth('sanctum')->id(),
                            'type'        => 'new_order',
                            'order_id'    => $order->id,
                            'driver_id'   => $order->driver_id,
                            'title'       => 'طلب جديد (مُحدّث)',
                            'body'        => "تم تعيينك على الطلب #{$order->order_number} بعد تعديله.",
                        ]);
                    }

                    if ($order->office_user_id) {
                        Notification::create([
                            'user_id'     => $order->office_user_id,
                            'sender_id'   => auth('sanctum')->id(),
                            'type'        => 'order_assigned',
                            'order_id'    => $order->id,
                            'driver_id'   => $order->driver_id,
                            'title'       => 'تم تعيين سائق جديد للطلب',
                            'body'        => "تم تعيين السائق {$driverModel->user->full_name} على الطلب #{$order->order_number}.",
                        ]);
                    }
                }
            }

            $order->save();

            $newDebt = ($order->remaining_amount + $order->delivery_fee) - $order->paid_amount;

            if ($customer) {
                $customer->balance = $customer->balance - $oldDebt + $newDebt;
                $customer->save();
            }

            DB::commit();
            $order->load(['customer', 'driver.user', 'officeUser', 'items.store', 'items.product', 'items.unit']);
            return response()->json($order);
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Order update failed: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json(['message' => 'حدث خطأ أثناء تحديث الطلب', 'error' => $e->getMessage()], 500);
        }
    }

    // قبول الطلب من قبل السائق
    public function acceptOrder($id)
    {
        $driver = auth('sanctum')->user()?->driver;
        if (!$driver) {
            return response()->json(['message' => 'غير مصرح'], 403);
        }

        $order = Order::where('id', $id)->where('driver_id', $driver->id)->firstOrFail();
        if ($order->status !== 'assigned') {
            return response()->json(['message' => 'لا يمكن قبول هذا الطلب'], 400);
        }

        DB::beginTransaction();
        try {
            $assignment = DriverAssignment::where('order_id', $order->id)
                ->where('driver_id', $driver->id)
                ->first();

            if ($assignment && now()->diffInMinutes($assignment->assigned_at) > 5) {
                $assignment->update(['status' => 'timeout']);
                DB::commit();
                return response()->json(['message' => 'انتهى وقت قبول الطلب'], 400);
            }

            $order->update(['status' => 'accepted', 'accepted_at' => now()]);

            if ($assignment) {
                $assignment->update(['status' => 'accepted', 'responded_at' => now()]);
            }

            OrderStatusLog::create([
                'order_id'   => $order->id,
                'status'     => 'accepted',
                'changed_by' => auth('sanctum')->id(),
            ]);

            if ($order->office_user_id) {
                Notification::create([
                    'user_id'     => $order->office_user_id,
                    'sender_id'   => auth('sanctum')->id(),
                    'type'        => 'driver_accepted',
                    'order_id'    => $order->id,
                    'driver_id'   => $driver->id,
                    'title'       => 'سائق قبل الطلب',
                    'body'        => "السائق {$driver->user->full_name} قبل الطلب #{$order->order_number}.",
                ]);
            }

            DB::commit();
            return response()->json(['message' => 'تم قبول الطلب', 'order' => $order]);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ'], 500);
        }
    }

    // رفض الطلب من قبل السائق
    public function rejectOrder($id)
    {
        $driver = auth('sanctum')->user()?->driver;
        if (!$driver) {
            return response()->json(['message' => 'غير مصرح'], 403);
        }

        $order = Order::where('id', $id)->where('driver_id', $driver->id)->firstOrFail();
        if ($order->status !== 'assigned') {
            return response()->json(['message' => 'لا يمكن رفض هذا الطلب'], 400);
        }

        DB::beginTransaction();
        try {
            DriverAssignment::where('order_id', $order->id)
                ->where('driver_id', $driver->id)
                ->update(['status' => 'rejected', 'responded_at' => now()]);

            $order->update(['driver_id' => null, 'status' => 'pending']);

            OrderStatusLog::create([
                'order_id'   => $order->id,
                'status'     => 'pending',
                'changed_by' => auth('sanctum')->id(),
            ]);

            if ($order->office_user_id) {
                Notification::create([
                    'user_id'     => $order->office_user_id,
                    'sender_id'   => auth('sanctum')->id(),
                    'type'        => 'driver_rejected',
                    'order_id'    => $order->id,
                    'driver_id'   => $driver->id,
                    'title'       => 'سائق رفض الطلب',
                    'body'        => "السائق {$driver->user->full_name} رفض الطلب #{$order->order_number}. يرجى إعادة تعيينه.",
                ]);
            }

            DB::commit();
            return response()->json(['message' => 'تم رفض الطلب']);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ'], 500);
        }
    }

    // تحديث حالة الطلب من قبل السائق
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => ['required', Rule::in(['on_the_way', 'items_purchased', 'delivered', 'cancelled'])],
        ]);

        $driver = auth('sanctum')->user()?->driver;
        if (!$driver) {
            return response()->json(['message' => 'غير مصرح'], 403);
        }

        $order = Order::where('id', $id)->where('driver_id', $driver->id)->firstOrFail();

        $allowed = [
            'accepted'       => ['on_the_way'],
            'on_the_way'     => ['items_purchased'],
            'items_purchased'=> ['delivered'],
        ];

        if ($request->status === 'cancelled') {
            if (!in_array($order->status, ['pending', 'assigned', 'accepted'])) {
                return response()->json(['message' => 'لا يمكن إلغاء الطلب'], 400);
            }
        } else {
            if (!isset($allowed[$order->status]) || !in_array($request->status, $allowed[$order->status])) {
                return response()->json(['message' => 'تغيير الحالة غير مسموح'], 400);
            }
        }

        DB::beginTransaction();
        try {
            $update = ['status' => $request->status];

            if ($request->status === 'on_the_way') {
                $update['picked_up_at'] = now();
            }

            if ($request->status === 'delivered') {
                $update['delivered_at'] = now();

                // ✅ استخدام نسبة العمولة الخاصة بالسائق مباشرة
                $commissionPercentage = $driver->commission_percentage ?? 10;
                $commission = $order->delivery_fee * ($commissionPercentage / 100);

                Transaction::create([
                    'type'           => 'driver_credit',
                    'driver_id'      => $driver->id,
                    'amount'         => $commission,
                    'notes'          => 'عمولة توصيل الطلب #' . $order->order_number,
                    'reference_id'   => $order->id,
                    'reference_type' => 'order',
                ]);

                $driver->increment('balance', $commission);
            }

            $order->update($update);

            OrderStatusLog::create([
                'order_id'   => $order->id,
                'status'     => $request->status,
                'changed_by' => auth('sanctum')->id(),
            ]);

            if ($order->office_user_id) {
                Notification::create([
                    'user_id'     => $order->office_user_id,
                    'sender_id'   => auth('sanctum')->id(),
                    'type'        => 'status_changed',
                    'order_id'    => $order->id,
                    'driver_id'   => $driver->id,
                    'title'       => 'تم تحديث حالة الطلب',
                    'body'        => "السائق {$driver->user->full_name} قام بتغيير حالة الطلب #{$order->number} إلى {$request->status}.",
                ]);
            }

            DB::commit();
            return response()->json(['message' => 'تم تحديث الحالة', 'order' => $order]);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ'], 500);
        }
    }

    // تعيين سائق للطلب (للمدير)
    public function assignDriver(Request $request, $id)
    {
        $request->validate(['driver_id' => 'required|exists:drivers,id']);

        $order = Order::findOrFail($id);
        if (!in_array($order->status, ['pending', 'assigned'])) {
            return response()->json(['message' => 'لا يمكن تغيير السائق'], 400);
        }

        DB::beginTransaction();
        try {
            DriverAssignment::create([
                'order_id'     => $order->id,
                'driver_id'    => $request->driver_id,
                'status'       => 'pending',
                'assigned_at'  => now(),
            ]);

            $order->update(['driver_id' => $request->driver_id, 'status' => 'assigned']);

            OrderStatusLog::create([
                'order_id'   => $order->id,
                'status'     => 'assigned',
                'changed_by' => auth('sanctum')->id(),
            ]);

            $driver = Driver::find($request->driver_id);
            if ($driver && $driver->user_id) {
                Notification::create([
                    'user_id'     => $driver->user_id,
                    'sender_id'   => auth('sanctum')->id(),
                    'type'        => 'order_assigned',
                    'order_id'    => $order->id,
                    'driver_id'   => $driver->id,
                    'title'       => 'طلب جديد',
                    'body'        => "تم تعيين الطلب #{$order->order_number} إليك. يرجى مراجعة التفاصيل.",
                ]);
            }

            DB::commit();
            return response()->json(['message' => 'تم تعيين السائق']);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ'], 500);
        }
    }

    // إضافة عناصر جديدة لطلب قائم
    public function addItems(Request $request, $id)
    {
        $request->validate([
            'items' => 'required|array|min:1',
            'items.*.item_type' => ['nullable', Rule::in(['product', 'delivery', 'invoice'])],
            'items.*.store_id'  => 'nullable|exists:stores,id',
            'items.*.product_id'=> 'nullable|exists:products,id',
            'items.*.unit_id'   => 'nullable|exists:units,id',
            'items.*.size_id'   => 'nullable|exists:sizes,id',
            'items.*.description'=> 'nullable|string',
            'items.*.quantity'   => 'nullable|numeric|min:0.01',
            'items.*.estimated_price'=> 'nullable|numeric|min:0',
            'items.*.estimated_fee'  => 'nullable|numeric|min:0',
            'items.*.estimated_total'=> 'nullable|numeric|min:0',
            'items.*.due_date'       => 'nullable|date',
            'items.*.pickup_address' => 'nullable|string',
            'items.*.pickup_phone'   => 'nullable|string|max:20',
            'items.*.pickup_contact_name' => 'nullable|string|max:100',
            'items.*.delivery_address'=> 'nullable|string',
            'items.*.delivery_phone'  => 'nullable|string|max:20',
            'items.*.delivery_contact_name' => 'nullable|string|max:100',
            'items.*.invoice_type'   => 'nullable|string|max:50',
            'items.*.company_name'   => 'nullable|string|max:150',
            'items.*.notes'          => 'nullable|string',
            'items.*.sort_order'     => 'nullable|integer|min:0',
            'items.*.is_available'   => 'nullable|boolean',
        ]);

        $order = Order::findOrFail($id);

        DB::beginTransaction();
        try {
            foreach ($request->items as $index => $item) {
                $this->createOrderItem($order, $item, $index);
            }

            DB::commit();
            return response()->json(['message' => 'تم إضافة العناصر']);
        } catch (ValidationException $e) {
            DB::rollBack();
            throw $e;
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ', 'error' => $e->getMessage()], 500);
        }
    }

    public function updateOrderItem(Request $request, $orderId, $itemId)
    {
        $request->validate([
            'is_available' => 'sometimes|boolean',
            'unavailable_reason' => 'required_if:is_available,false|nullable|string',
            'quantity' => 'nullable|numeric|min:0.01',
            'estimated_price' => 'nullable|numeric|min:0',
            'actual_price' => 'nullable|numeric|min:0',
            'description' => 'nullable|string',
            'pickup_address' => 'nullable|string',
            'delivery_address' => 'nullable|string',
            'pickup_phone' => 'nullable|string|max:20',
            'delivery_phone' => 'nullable|string|max:20',
            'estimated_fee' => 'nullable|numeric|min:0',
            'company_name' => 'nullable|string|max:150',
            'estimated_total' => 'nullable|numeric|min:0',
            'due_date' => 'nullable|date',
            'notes' => 'nullable|string',
            'invoice_type' => 'nullable|string|max:50',
            'store_id' => ['nullable', 'exists:stores,id'],
        ]);

        $order = Order::findOrFail($orderId);
        $user = auth('sanctum')->user();

        $isDriver = $user->driver && $order->driver_id === $user->driver->id;
        $isOfficeOrAdmin = in_array($user->role, ['office', 'admin']) && $order->office_user_id === $user->id;

        if (!$isDriver && !$isOfficeOrAdmin) {
            return response()->json(['message' => 'غير مصرح'], 403);
        }

        $item = OrderItem::where('id', $itemId)->where('order_id', $orderId)->firstOrFail();

        DB::beginTransaction();
        try {
            $oldStoreId = $item->store_id;
            $item->fill($request->only([
                'quantity', 'estimated_price', 'description', 'actual_price',
                'is_available', 'unavailable_reason', 'pickup_address', 'delivery_address',
                'pickup_phone', 'delivery_phone', 'estimated_fee', 'company_name',
                'estimated_total', 'due_date', 'notes', 'invoice_type', 'store_id'
            ]));
            $item->save();

            if ($request->has('is_available') && $request->is_available === false) {
                $productName = $item->product->name ?? 'منتج';
                $storeName = $item->store->name ?? 'متجر';
                $storeTypeId = $item->store->store_type_id ?? null;

                if ($order->office_user_id) {
                    Notification::create([
                        'user_id'     => $order->office_user_id,
                        'sender_id'   => auth('sanctum')->id(),
                        'type'        => 'product_unavailable',
                        'order_id'    => $order->id,
                        'driver_id'   => $order->driver_id,
                        'product_id'  => $item->product_id,
                        'store_id'    => $item->store_id,
                        'item_id'     => $item->id,
                        'store_type_id' => $storeTypeId,
                        'title'       => 'منتج غير متوفر',
                        'body'        => "تم الإبلاغ أن المنتج '{$productName}' غير متوفر في '{$storeName}' للطلب #{$order->order_number}. يرجى تعديل الطلب.",
                    ]);
                }
            }

            if ($request->has('store_id') && $isOfficeOrAdmin && $order->driver_id) {
                $newStoreName = $item->store->name ?? 'المتجر الجديد';
                $productName = $item->product->name ?? 'المنتج';

                $order->load(['items.product', 'items.unit', 'items.store']);

                Notification::create([
                    'user_id'     => $order->driver->user_id,
                    'sender_id'   => auth('sanctum')->id(),
                    'type'        => 'item_store_changed',
                    'order_id'    => $order->id,
                    'driver_id'   => $order->driver_id,
                    'product_id'  => $item->product_id,
                    'store_id'    => $item->store_id,
                    'item_id'     => $item->id,
                    'title'       => 'تم تغيير متجر المنتج',
                    'body'        => "تم تغيير متجر المنتج '{$productName}' إلى '{$newStoreName}' للطلب #{$order->order_number}.",
                    'order'       => $order->toArray(),
                ]);
            }

            DB::commit();
            $item->load(['product', 'unit', 'store']);
            return response()->json(['message' => 'تم تحديث العنصر', 'item' => $item]);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'حدث خطأ'], 500);
        }
    }

    // حذف طلب بالكامل
    public function destroy($id)
    {
        try {
            $order = Order::findOrFail($id);

            DB::beginTransaction();

            $order->items()->delete();
            $order->statusLogs()->delete();
            $order->assignments()->delete();
            $order->delete();

            DB::commit();

            return response()->json([
                'message' => 'تم حذف الطلب بنجاح'
            ], 200);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'فشل حذف الطلب',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    // إضافة إجمالي مشتريات المتجر (يستخدمها السائق)
    public function addStoreTotal(Request $request, $orderId)
    {
        $order = Order::findOrFail($orderId);
        $driver = Driver::where('user_id', auth()->id())->first();

        if (!$driver || $order->driver_id !== $driver->id) {
            return response()->json(['message' => 'غير مصرح لك بهذا الطلب'], 403);
        }

        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'store_id' => 'required|exists:stores,id',
            'total_amount' => 'required|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $storeTotal = OrderStoreTotal::updateOrCreate(
            [
                'order_id' => $order->id,
                'store_id' => $request->store_id,
            ],
            [
                'total_amount' => $request->total_amount,
                'notes' => $request->notes,
            ]
        );

        return response()->json(['message' => 'تم حفظ إجمالي المتجر بنجاح', 'data' => $storeTotal]);
    }

    // تحديث حالة الطلب بواسطة المدير
    public function adminUpdateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => ['required', Rule::in(['pending', 'assigned', 'accepted', 'rejected', 'timeout', 'on_the_way', 'items_purchased', 'delivered', 'cancelled'])],
        ]);

        $order = Order::findOrFail($id);
        $order->status = $request->status;
        $order->save();

        OrderStatusLog::create([
            'order_id'   => $order->id,
            'status'     => $request->status,
            'changed_by' => auth('sanctum')->id() ?? $request->user()?->id,
        ]);

        return response()->json(['message' => 'تم تحديث الحالة', 'order' => $order]);
    }

    // قائمة طلبات السائق الحالي
    public function driverOrders(Request $request)
    {
        $user = auth('sanctum')->user();
        $driver = $user?->driver;

        if (!$driver) {
            return response()->json(['message' => 'يجب أن تكون سائقاً'], 403);
        }

        $query = Order::with([
            'customer',
            'items.product',
            'items.unit',
            'items.store',
            'customerAddress'   // ✅ عرض العنوان للسائق
        ])->where('driver_id', $driver->id);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $orders = $query->orderBy('created_at', 'desc')->paginate(20);
        return response()->json($orders);
    }

    // ========== دوال مساعدة ==========

    protected function pointFromArray(?array $coordinates): ?Point
    {
        if (!is_array($coordinates) || count($coordinates) < 2) {
            return null;
        }

        if (isset($coordinates['coordinates']) && is_array($coordinates['coordinates'])) {
            $coordinates = $coordinates['coordinates'];
        }

        if (count($coordinates) < 2) {
            return null;
        }

        $lat = $coordinates[0];
        $lng = $coordinates[1];

        if (!is_numeric($lat) || !is_numeric($lng)) {
            return null;
        }

        return new Point((float) $lng, (float) $lat);
    }

    protected function resolveOfficeUserId(Request $request, array $validated): int
    {
        $officeUserId = auth('sanctum')->id();

        if (!$officeUserId && !empty($validated['office_user_id'])) {
            $officeUserId = (int) $validated['office_user_id'];
        }
        if (!$officeUserId && $request->filled('office_user_id')) {
            $officeUserId = (int) $request->input('office_user_id');
        }

        if (!$officeUserId) {
            throw ValidationException::withMessages([
                'office_user_id' => 'يجب تسجيل الدخول كموظف مكتب أو مدير',
            ]);
        }

        return $officeUserId;
    }

    protected function createOrderItem(Order $order, array $item, int $sortOrder = 0): OrderItem
    {
        $itemType = $item['item_type'] ?? 'product';

        if (!in_array($itemType, ['product', 'delivery', 'invoice'], true)) {
            throw ValidationException::withMessages([
                'items' => 'نوع العنصر غير صحيح: ' . $itemType,
            ]);
        }

        $base = [
            'order_id'     => $order->id,
            'item_type'    => $itemType,
            'sort_order'   => $item['sort_order'] ?? ($sortOrder + 1),
            'is_available' => $item['is_available'] ?? true,
            'quantity'     => $item['quantity'] ?? 1,
        ];

        if ($itemType === 'product') {
            if (empty($item['store_id'])) {
                throw ValidationException::withMessages(['items' => 'store_id مطلوب']);
            }
            if (empty($item['product_id'])) {
                throw ValidationException::withMessages(['items' => 'product_id مطلوب']);
            }

            return OrderItem::create(array_merge($base, [
                'store_id'        => $item['store_id'],
                'description'     => $item['description'] ?? null,
                'unit_id'         => $item['unit_id'] ?? null,
                'size_id'         => $item['size_id'] ?? null,
                'product_id'      => $item['product_id'],
                'estimated_price' => $item['estimated_price'] ?? null,
            ]));
        }

        if ($itemType === 'delivery') {
            if (empty($item['pickup_address']) || empty($item['delivery_address'])) {
                throw ValidationException::withMessages(['items' => 'pickup_address و delivery_address مطلوبان']);
            }

            return OrderItem::create(array_merge($base, [
                'description'           => $item['description'] ?? null,
                'pickup_address'        => $item['pickup_address'],
                'pickup_phone'          => $item['pickup_phone'] ?? null,
                'pickup_contact_name'   => $item['pickup_contact_name'] ?? null,
                'delivery_address'      => $item['delivery_address'],
                'delivery_phone'        => $item['delivery_phone'] ?? null,
                'delivery_contact_name' => $item['delivery_contact_name'] ?? null,
                'estimated_fee'         => $item['estimated_fee'] ?? null,
                'notes'                 => $item['notes'] ?? null,
            ]));
        }

        // invoice
        if (empty($item['company_name'])) {
            throw ValidationException::withMessages(['items' => 'company_name مطلوب']);
        }

        return OrderItem::create(array_merge($base, [
            'invoice_type'    => $item['invoice_type'] ?? null,
            'company_name'    => $item['company_name'],
            'estimated_total' => $item['estimated_total'] ?? null,
            'due_date'        => $item['due_date'] ?? null,
            'notes'           => $item['notes'] ?? null,
        ]));
    }

    private function mapItemData(array $data): array
    {
        $fields = [
            'store_id', 'description', 'quantity', 'unit_id', 'size_id', 'product_id',
            'estimated_price', 'actual_price', 'is_available', 'unavailable_reason',
            'item_type', 'sort_order', 'pickup_address', 'pickup_phone', 'pickup_contact_name',
            'delivery_address', 'delivery_phone', 'delivery_contact_name', 'estimated_fee',
            'actual_fee', 'invoice_type', 'company_name', 'estimated_total', 'due_date',
            'actual_invoice_amount', 'notes'
        ];
        $mapped = [];
        foreach ($fields as $field) {
            if (array_key_exists($field, $data)) {
                $mapped[$field] = $data[$field];
            }
        }
        return $mapped;
    }
}