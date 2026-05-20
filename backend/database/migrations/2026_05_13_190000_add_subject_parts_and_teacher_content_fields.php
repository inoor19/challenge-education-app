<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('grades', function (Blueprint $table) {
            $table->foreignId('created_by_user_id')->nullable()->after('id')->constrained('users')->nullOnDelete();
            $table->string('visibility')->default('official')->after('created_by_user_id');
        });

        Schema::table('subjects', function (Blueprint $table) {
            $table->foreignId('created_by_user_id')->nullable()->after('id')->constrained('users')->nullOnDelete();
            $table->string('visibility')->default('official')->after('created_by_user_id');
        });

        Schema::create('subject_parts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('subject_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->unsignedTinyInteger('part_number');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['subject_id', 'part_number']);
        });

        foreach (DB::table('subjects')->select('id')->get() as $subject) {
            foreach ([1 => 'الجزء الأول', 2 => 'الجزء الثاني'] as $number => $name) {
                DB::table('subject_parts')->updateOrInsert(
                    ['subject_id' => $subject->id, 'part_number' => $number],
                    [
                        'name' => $name,
                        'sort_order' => $number,
                        'is_active' => true,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }
        }

        Schema::table('chapters', function (Blueprint $table) {
            $table->foreignId('subject_part_id')->nullable()->after('subject_id')->constrained('subject_parts')->nullOnDelete();
            $table->foreignId('created_by_user_id')->nullable()->after('subject_part_id')->constrained('users')->nullOnDelete();
            $table->string('visibility')->default('official')->after('created_by_user_id');
        });

        foreach (DB::table('chapters')->select('id', 'subject_id')->get() as $chapter) {
            $partId = DB::table('subject_parts')
                ->where('subject_id', $chapter->subject_id)
                ->where('part_number', 1)
                ->value('id');

            DB::table('chapters')
                ->where('id', $chapter->id)
                ->update(['subject_part_id' => $partId]);
        }

        Schema::table('lessons', function (Blueprint $table) {
            $table->foreignId('created_by_user_id')->nullable()->after('chapter_id')->constrained('users')->nullOnDelete();
            $table->string('visibility')->default('official')->after('created_by_user_id');
        });

        Schema::table('questions', function (Blueprint $table) {
            $table->foreignId('created_by_user_id')->nullable()->after('lesson_id')->constrained('users')->nullOnDelete();
            $table->string('visibility')->default('official')->after('created_by_user_id');
        });

        Schema::table('challenge_sessions', function (Blueprint $table) {
            $table->foreignId('subject_part_id')->nullable()->after('subject_id')->constrained('subject_parts')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('challenge_sessions', function (Blueprint $table) {
            $table->dropConstrainedForeignId('subject_part_id');
        });

        Schema::table('questions', function (Blueprint $table) {
            $table->dropConstrainedForeignId('created_by_user_id');
            $table->dropColumn('visibility');
        });

        Schema::table('lessons', function (Blueprint $table) {
            $table->dropConstrainedForeignId('created_by_user_id');
            $table->dropColumn('visibility');
        });

        Schema::table('chapters', function (Blueprint $table) {
            $table->dropConstrainedForeignId('subject_part_id');
            $table->dropConstrainedForeignId('created_by_user_id');
            $table->dropColumn('visibility');
        });

        Schema::dropIfExists('subject_parts');

        Schema::table('subjects', function (Blueprint $table) {
            $table->dropConstrainedForeignId('created_by_user_id');
            $table->dropColumn('visibility');
        });

        Schema::table('grades', function (Blueprint $table) {
            $table->dropConstrainedForeignId('created_by_user_id');
            $table->dropColumn('visibility');
        });
    }
};
