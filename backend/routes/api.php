<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DriverController;
use App\Http\Controllers\Api\StoreController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PaymentChangeRequestController;
use App\Http\Controllers\Api\DriverCommissionRuleController;
use App\Http\Controllers\Api\UnitController;
use App\Http\Controllers\Api\SizeController;
use App\Http\Controllers\Api\StoreTypeController;
use App\Http\Controllers\Api\DriverLocationLogController;
use App\Http\Controllers\Api\OrderStatusLogController;
use App\Http\Controllers\Api\AdminController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public login
Route::post('/login', [AuthController::class, 'login']);

// Routes protected by Sanctum
Route::middleware('auth:sanctum')->group(function () {

    // Common for all authenticated users
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Notifications
    Route::get('notifications', [NotificationController::class, 'index']);
    Route::match(['post', 'patch'], 'notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::match(['post', 'patch'], 'notifications/mark-all-read', [NotificationController::class, 'markAllRead']);
    Route::get('notifications/unread-count', [NotificationController::class, 'unreadCount']);

    // ========== Roles: admin + office ==========
    Route::middleware('role:admin,office')->group(function () {

        // Customers (custom routes before apiResource)
        Route::get('customers/inactive', [CustomerController::class, 'indexInactive']);
        Route::match(['put', 'patch', 'post'], 'customers/{id}/reactivate', [CustomerController::class, 'reactivate']);
        Route::post('customers/{customerId}/addresses', [CustomerController::class, 'addAddress']);
        Route::post('customers/{customerId}/phones', [CustomerController::class, 'addPhone']);
        Route::apiResource('customers', CustomerController::class);

        // Drivers
        Route::apiResource('drivers', DriverController::class);

        // Stores
        Route::apiResource('stores', StoreController::class);

        // Products
        Route::apiResource('products', ProductController::class);

        // Orders
        Route::apiResource('orders', OrderController::class)->except(['update']); // نضيف update يدويًا
        Route::put('orders/{order}', [OrderController::class, 'update']); // تمت الإضافة
        Route::post('orders/{id}/assign-driver', [OrderController::class, 'assignDriver']);
        Route::post('orders/{id}/items', [OrderController::class, 'addItems']);
        Route::post('orders/{id}/reject', [OrderController::class, 'rejectOrder']);
        Route::put('orders/{orderId}/items/{itemId}', [OrderController::class, 'updateOrderItem']); // للمكتب

        // Reports
        Route::get('reports/dashboard', [ReportController::class, 'dashboard']);
        Route::get('reports/driver-performance', [ReportController::class, 'driverPerformance']);
        Route::get('reports/store-orders', [ReportController::class, 'storeOrders']);
        Route::get('reports/profits', [ReportController::class, 'profits']);

        // Payment change requests
        Route::apiResource('payment-requests', PaymentChangeRequestController::class)->only(['index', 'store']);
        Route::post('payment-requests/{id}/approve', [PaymentChangeRequestController::class, 'approve']);

        // Driver commission rules
        Route::apiResource('driver-commission-rules', DriverCommissionRuleController::class);

        // Units, sizes, store types
        Route::apiResource('units', UnitController::class);
        Route::apiResource('sizes', SizeController::class);
        Route::apiResource('store-types', StoreTypeController::class);

        // Logs (read-only)
        Route::get('driver-location-logs', [DriverLocationLogController::class, 'index']);
        Route::get('driver-location-logs/{id}', [DriverLocationLogController::class, 'show']);
        Route::get('order-status-logs', [OrderStatusLogController::class, 'index']);
    });

    // ========== Role: driver ==========
    Route::middleware('role:driver')->group(function () {
        Route::get('driver/orders', [OrderController::class, 'driverOrders']);
        Route::post('driver/orders/{id}/accept', [OrderController::class, 'acceptOrder']);
        Route::post('driver/orders/{id}/reject', [OrderController::class, 'rejectOrder']);
        Route::put('driver/orders/{id}/status', [OrderController::class, 'updateStatus']);
        Route::post('driver/orders/{orderId}/store-total', [OrderController::class, 'addStoreTotal']);
        Route::put('driver/orders/{orderId}/items/{itemId}', [OrderController::class, 'updateOrderItem']);
        Route::get('driver/profile', [DriverController::class, 'profile']);
        Route::post('driver/location', [DriverController::class, 'updateLocation']);
        Route::post('driver/toggle-availability', [DriverController::class, 'toggleAvailability']);
    });

    // ========== Roles: admin + accountant (Accounting & Balances) ==========
    Route::middleware('role:admin,accountant')->prefix('accounting')->group(function () {
        // أرصدة الزبائن، السائقين، المتاجر
        Route::get('customers/balance', [AdminController::class, 'customersBalance']);
        Route::get('drivers/balance', [AdminController::class, 'driversBalance']);
        Route::get('stores/balance', [AdminController::class, 'storesBalance']);
        Route::get('stores/purchases', [AdminController::class, 'storePurchases']);
        Route::get('dashboard', [AdminController::class, 'accountantDashboard']);
        Route::apiResource('transactions', TransactionController::class);
        Route::get('reports/profits', [ReportController::class, 'profits']);
    });

    // ========== Role: admin (superuser) ==========
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/stats', [AdminController::class, 'stats']);

        // Driver management (additional admin methods)
        Route::post('/drivers', [AdminController::class, 'storeDriver']);
        Route::put('/drivers/{id}', [AdminController::class, 'updateDriver']);
        Route::delete('/drivers/{id}', [AdminController::class, 'destroyDriver']);
        Route::put('/admin/office-users/{id}', [AdminController::class, 'updateOfficeUser']);
        Route::delete('/admin/office-users/{id}', [AdminController::class, 'destroyOfficeUser']);
        // Office users management
        Route::get('/office-users', [AdminController::class, 'officeUsers']);
        Route::post('/office-users', [AdminController::class, 'storeOfficeUser']);
        Route::put('admin/office-users/{id}', [AdminController::class, 'updateOfficeUser']);
        Route::delete('admin/office-users/{id}', [AdminController::class, 'destroyOfficeUser']);
        // Admin order status update
        Route::put('/orders/{id}/status', [OrderController::class, 'adminUpdateStatus']);

        // Note: Balances are now under /accounting prefix shared with accountant
    });
});