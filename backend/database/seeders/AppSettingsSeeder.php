<?php

namespace Database\Seeders;

use App\Models\AppSetting;
use Illuminate\Database\Seeder;

class AppSettingsSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            ['key' => 'default_timer_seconds', 'value' => '60', 'type' => 'integer', 'label' => 'وقت المؤقت الافتراضي (ثانية)'],
            ['key' => 'dice_min_value', 'value' => '1', 'type' => 'integer', 'label' => 'أدنى قيمة للنرد'],
            ['key' => 'dice_max_value', 'value' => '3', 'type' => 'integer', 'label' => 'أعلى قيمة للنرد'],
            ['key' => 'app_name', 'value' => 'ساحة التنافس', 'type' => 'string', 'label' => 'اسم التطبيق'],
        ];

        foreach ($settings as $setting) {
            AppSetting::updateOrCreate(['key' => $setting['key']], $setting);
        }
    }
}
