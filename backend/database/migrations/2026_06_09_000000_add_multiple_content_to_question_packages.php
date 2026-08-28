<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('question_package_chapters', function (Blueprint $table) {
            $table->id();
            $table->foreignId('question_package_id')->constrained()->cascadeOnDelete();
            $table->foreignId('chapter_id')->constrained()->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['question_package_id', 'chapter_id']);
        });

        Schema::create('question_package_lessons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('question_package_id')->constrained()->cascadeOnDelete();
            $table->foreignId('lesson_id')->constrained()->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['question_package_id', 'lesson_id']);
        });

        $now = now();

        DB::table('question_packages')
            ->whereNotNull('chapter_id')
            ->orderBy('id')
            ->chunkById(500, function ($packages) use ($now) {
                DB::table('question_package_chapters')->insertOrIgnore(
                    $packages->map(fn ($package) => [
                        'question_package_id' => $package->id,
                        'chapter_id' => $package->chapter_id,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ])->all()
                );
            });

        DB::table('question_packages')
            ->whereNotNull('lesson_id')
            ->orderBy('id')
            ->chunkById(500, function ($packages) use ($now) {
                DB::table('question_package_lessons')->insertOrIgnore(
                    $packages->map(fn ($package) => [
                        'question_package_id' => $package->id,
                        'lesson_id' => $package->lesson_id,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ])->all()
                );
            });
    }

    public function down(): void
    {
        Schema::dropIfExists('question_package_lessons');
        Schema::dropIfExists('question_package_chapters');
    }
};
