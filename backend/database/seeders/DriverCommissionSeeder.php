use Illuminate\Support\Facades\DB;

public function run(): void
{
    DB::table('driver_commission_rules')->insert([
        [
            'vehicle_ownership' => 'own',
            'commission_percentage' => 30,
        ],
        [
            'vehicle_ownership' => 'company',
            'commission_percentage' => 20,
        ],
    ]);
}
