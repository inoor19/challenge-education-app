<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('app_settings')) {
            return;
        }

        DB::table('app_settings')
            ->where('key', 'app_name')
            ->update([
                'value' => 'ساحة التنافس',
                'updated_at' => now(),
            ]);
    }

    public function down(): void
    {
        if (! Schema::hasTable('app_settings')) {
            return;
        }

        DB::table('app_settings')
            ->where('key', 'app_name')
            ->update([
                'value' => 'ساحة التحدي التعليمي',
                'updated_at' => now(),
            ]);
    }
};
