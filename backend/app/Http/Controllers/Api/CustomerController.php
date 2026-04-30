<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\CustomerAddress;
use App\Models\CustomerPhone;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use MatanYadaev\EloquentSpatial\Objects\Point;

class CustomerController extends Controller
{
    // قائمة الزبائن النشطين (مع إضافة primary_phone من user)
    public function index(Request $request)
    {
        $query = Customer::with(['user', 'addresses', 'phones']);

        if ($request->has('is_active')) {
            $isActive = filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN);
            $query->whereHas('user', function ($q) use ($isActive) {
                $q->where('is_active', $isActive);
            });
        } else {
            $query->whereHas('user', function ($q) {
                $q->where('is_active', true);
            });
        }

        $customers = $query->orderBy('name', 'asc')->paginate(20);

        // إضافة حقل primary_phone من جدول users
        $customers->getCollection()->transform(function ($customer) {
            $customer->primary_phone = $customer->user->phone ?? null;
            $customer->is_active = $customer->user->is_active;
            return $customer;
        });

        return response()->json($customers);
    }

    // قائمة الزبائن المعطلين
    public function indexInactive(Request $request)
    {
        $customers = Customer::with(['user', 'addresses', 'phones'])
            ->whereHas('user', function ($query) {
                $query->where('is_active', false);
            })
            ->orderBy('name', 'asc')
            ->paginate(20);

        $customers->getCollection()->transform(function ($customer) {
            $customer->primary_phone = $customer->user->phone ?? null;
            $customer->is_active = false;
            return $customer;
        });

        return response()->json($customers);
    }

    // عرض زبون محدد
    public function show($id)
    {
        $customer = Customer::with(['user', 'addresses', 'phones', 'orders'])
            ->findOrFail($id);
        $customer->primary_phone = $customer->user->phone ?? null;
        $customer->is_active = $customer->user->is_active;
        return response()->json($customer);
    }

    // إنشاء زبون جديد (مع فصل الرقم الأساسي والأرقام الإضافية)
    public function store(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:100',
            'primary_phone' => 'required|string|unique:users,phone',
            'password' => 'required|string|min:6',
            'name' => 'required|string|max:100',
            'notes' => 'nullable|string',
            'balance' => 'nullable|numeric',
            'additional_phones' => 'nullable|array',
            'additional_phones.*.phone' => 'required_with:additional_phones|string|max:20',
            'addresses' => 'nullable|array',
            'addresses.*.address' => 'required_with:addresses|string',
            'addresses.*.label' => 'nullable|string|max:50',
            'addresses.*.location' => 'nullable|array|min:2',
        ]);

        DB::beginTransaction();
        try {
            // 1. إنشاء مستخدم جديد (user) بالرقم الأساسي
            $user = User::create([
                'phone' => $request->primary_phone,
                'password_hash' => Hash::make($request->password),
                'full_name' => $request->full_name,
                'role' => 'customer',
                'is_active' => true,
            ]);

            // 2. إنشاء سجل الزبون مرتبط بالمستخدم
            $customer = Customer::create([
                'user_id' => $user->id,
                'name' => $request->name,
                'notes' => $request->notes,
                'balance' => $request->balance ?? 0,
            ]);

            // 3. إضافة الأرقام الإضافية إلى جدول customer_phones
            if ($request->has('additional_phones')) {
                foreach ($request->additional_phones as $phoneData) {
                    if (!empty($phoneData['phone'])) {
                        CustomerPhone::create([
                            'customer_id' => $customer->id,
                            'phone' => $phoneData['phone'],
                        ]);
                    }
                }
            }

            // 4. إضافة العناوين إلى جدول customer_addresses
            if ($request->has('addresses')) {
                foreach ($request->addresses as $addr) {
                    $addressData = [
                        'customer_id' => $customer->id,
                        'address' => $addr['address'],
                        'label' => $addr['label'] ?? null,
                    ];
                    if (isset($addr['location']) && is_array($addr['location']) && count($addr['location']) >= 2) {
                        $addressData['location'] = new Point($addr['location'][1], $addr['location'][0]);
                    }
                    CustomerAddress::create($addressData);
                }
            }

            DB::commit();

            // إعادة تحميل العلاقات وإضافة primary_phone
            $customer->load(['user', 'addresses', 'phones']);
            $customer->primary_phone = $user->phone;
            $customer->is_active = true;

            return response()->json($customer, 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'حدث خطأ أثناء إنشاء الزبون',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // تحديث زبون (بما في ذلك تحديث الرقم الأساسي، والأرقام الإضافية، والعناوين)
    public function update(Request $request, $id)
    {
        $customer = Customer::findOrFail($id);
        $user = $customer->user;

        $rules = [
            'full_name' => 'sometimes|string|max:100',
            'primary_phone' => 'sometimes|string|unique:users,phone,' . $user->id,
            'name' => 'sometimes|string|max:100',
            'notes' => 'nullable|string',
            'balance' => 'nullable|numeric',
            'is_active' => 'sometimes|boolean',
            'phones' => 'nullable|array',               // قائمة كاملة بالأرقام الإضافية
            'phones.*.phone' => 'required_with:phones|string|max:20',
            'addresses' => 'nullable|array',           // قائمة كاملة بالعناوين
            'addresses.*.address' => 'required_with:addresses|string',
            'addresses.*.label' => 'nullable|string|max:50',
            'addresses.*.location' => 'nullable|array|min:2',
        ];

        $request->validate($rules);

        DB::beginTransaction();
        try {
            // 1. تحديث بيانات المستخدم (الرقم الأساسي والاسم الكامل والحالة)
            if ($request->has('primary_phone')) {
                $user->phone = $request->primary_phone;
            }
            if ($request->has('full_name')) {
                $user->full_name = $request->full_name;
            }
            if ($request->has('is_active')) {
                $user->is_active = $request->is_active;
            }
            $user->save();

            // 2. تحديث بيانات الزبون
            if ($request->has('name')) {
                $customer->name = $request->name;
            }
            if ($request->has('notes')) {
                $customer->notes = $request->notes;
            }
            if ($request->has('balance')) {
                $customer->balance = $request->balance;
            }
            $customer->save();

            // 3. مزامنة الأرقام الإضافية (حذف القديمة وإضافة الجديدة)
            if ($request->has('phones')) {
                // حذف جميع الأرقام الإضافية الحالية
                CustomerPhone::where('customer_id', $customer->id)->delete();
                // إضافة القائمة الجديدة
                foreach ($request->phones as $phoneData) {
                    if (!empty($phoneData['phone'])) {
                        CustomerPhone::create([
                            'customer_id' => $customer->id,
                            'phone' => $phoneData['phone'],
                        ]);
                    }
                }
            }

            // 4. مزامنة العناوين (حذف القديمة وإضافة الجديدة)
            if ($request->has('addresses')) {
                // حذف جميع العناوين الحالية
                CustomerAddress::where('customer_id', $customer->id)->delete();
                // إضافة القائمة الجديدة
                foreach ($request->addresses as $addr) {
                    $addressData = [
                        'customer_id' => $customer->id,
                        'address' => $addr['address'],
                        'label' => $addr['label'] ?? null,
                    ];
                    if (isset($addr['location']) && is_array($addr['location']) && count($addr['location']) >= 2) {
                        $addressData['location'] = new Point($addr['location'][1], $addr['location'][0]);
                    }
                    CustomerAddress::create($addressData);
                }
            }

            DB::commit();

            // إعادة تحميل البيانات وتجهيز الـ response
            $customer->load(['user', 'addresses', 'phones']);
            $customer->primary_phone = $user->phone;
            $customer->is_active = $user->is_active;

            return response()->json($customer);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'حدث خطأ أثناء تحديث الزبون',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // تعطيل زبون (حذف منطقي)
    public function destroy($id)
    {
        $customer = Customer::findOrFail($id);
        $user = $customer->user;
        if ($user) {
            $user->is_active = false;
            $user->save();
        }
        return response()->json(['message' => 'تم تعطيل الزبون بنجاح']);
    }

    // إعادة تفعيل زبون
    public function reactivate($id)
    {
        $customer = Customer::findOrFail($id);
        $user = $customer->user;
        if ($user) {
            $user->is_active = true;
            $user->save();
        }
        return response()->json(['message' => 'تم إعادة تنشيط الزبون']);
    }

    // إضافة عنوان (تبقى للاستخدام الفردي إذا احتجت)
    public function addAddress(Request $request, $customerId)
    {
        $request->validate([
            'address' => 'required|string',
            'location' => 'nullable|array|min:2|max:2',
            'location.*' => 'numeric',
            'label' => 'nullable|string|max:50',
        ]);

        $addressData = [
            'customer_id' => $customerId,
            'address' => $request->address,
            'label' => $request->label,
        ];
        if ($request->has('location') && is_array($request->location) && count($request->location) >= 2) {
            $addressData['location'] = new Point($request->location[1], $request->location[0]);
        }

        $address = CustomerAddress::create($addressData);
        return response()->json($address, 201);
    }

    // إضافة هاتف (تبقى للاستخدام الفردي)
    public function addPhone(Request $request, $customerId)
    {
        $request->validate([
            'phone' => 'required|string|max:20',
        ]);

        $phone = CustomerPhone::create([
            'customer_id' => $customerId,
            'phone' => $request->phone,
        ]);

        return response()->json($phone, 201);
    }
}