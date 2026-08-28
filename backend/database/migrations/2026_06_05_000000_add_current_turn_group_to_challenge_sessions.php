<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('challenge_sessions', function (Blueprint $table) {
            $table->foreignId('current_turn_group_id')
                ->nullable()
                ->after('status');
        });
    }

    public function down(): void
    {
        Schema::table('challenge_sessions', function (Blueprint $table) {
            $table->dropColumn('current_turn_group_id');
        });
    }
};
