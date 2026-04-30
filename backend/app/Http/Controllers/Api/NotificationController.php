<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $user = auth('sanctum')->user();
        if (!$user) return response()->json(['message' => 'Unauthenticated'], 401);

        $query = Notification::where('user_id', $user->id)
            ->with([
                'order' => function ($q) {
                    $q->with([
                        'items.product',
                        'items.unit',
                        'items.store',
                        'customer',              // ✅ عرض بيانات الزبون
                        'customerAddress'        // ✅ عرض العنوان
                    ]);
                },
                'driver.user',
                'sender',
                'product',
                'store',
            ])
            ->orderBy('created_at', 'desc');

        $notifications = $query->paginate(50);
        return response()->json($notifications);
    }

    public function markAsRead($id)
    {
        $notification = Notification::where('id', $id)
            ->where('user_id', auth('sanctum')->id())
            ->firstOrFail();
        $notification->update(['is_read' => true]);
        return response()->json(['message' => 'تم التحديد كمقروء']);
    }

    public function markAllRead()
    {
        Notification::where('user_id', auth('sanctum')->id())
            ->where('is_read', false)
            ->update(['is_read' => true]);
        return response()->json(['message' => 'تم تحديد الكل كمقروء']);
    }

    public function unreadCount()
    {
        $count = Notification::where('user_id', auth('sanctum')->id())
            ->where('is_read', false)
            ->count();
        return response()->json(['count' => $count]);
    }
}