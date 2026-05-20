<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('question_packages', function (Blueprint $table) {
            $table->string('android_product_id')->nullable()->after('platform_product_id');
            $table->string('ios_product_id')->nullable()->after('android_product_id');
            $table->string('purchase_type')->default('non_consumable')->after('ios_product_id');
        });
    }

    public function down(): void
    {
        Schema::table('question_packages', function (Blueprint $table) {
            $table->dropColumn(['android_product_id', 'ios_product_id', 'purchase_type']);
        });
    }
};
