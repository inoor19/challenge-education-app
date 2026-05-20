<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('challenge_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teacher_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('grade_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subject_id')->constrained()->cascadeOnDelete();
            $table->unsignedSmallInteger('timer_seconds')->default(60);
            $table->boolean('timer_enabled')->default(true);
            $table->enum('status', ['active', 'completed', 'cancelled'])->default('active');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();
        });

        Schema::create('challenge_session_chapters', function (Blueprint $table) {
            $table->id();
            $table->foreignId('challenge_session_id')->constrained()->cascadeOnDelete();
            $table->foreignId('chapter_id')->constrained()->cascadeOnDelete();

            $table->unique(['challenge_session_id', 'chapter_id'], 'csc_session_chapter_unique');
        });

        Schema::create('challenge_session_lessons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('challenge_session_id')->constrained()->cascadeOnDelete();
            $table->foreignId('lesson_id')->constrained()->cascadeOnDelete();

            $table->unique(['challenge_session_id', 'lesson_id']);
        });

        Schema::create('challenge_groups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('challenge_session_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->integer('score')->default(0);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('challenge_questions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('challenge_session_id')->constrained()->cascadeOnDelete();
            $table->foreignId('question_id')->constrained()->cascadeOnDelete();
            $table->unsignedSmallInteger('sequence_number');
            $table->boolean('is_used')->default(false);
            $table->timestamp('used_at')->nullable();
            $table->foreignId('selected_group_id')->nullable()->constrained('challenge_groups')->nullOnDelete();
            $table->unsignedTinyInteger('last_dice_value')->nullable();
            $table->integer('awarded_points')->nullable();
            $table->enum('answer_status', ['correct', 'wrong'])->nullable();
            $table->timestamps();

            $table->unique(['challenge_session_id', 'question_id']);
            $table->unique(['challenge_session_id', 'sequence_number']);
        });

        Schema::create('score_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('challenge_session_id')->constrained()->cascadeOnDelete();
            $table->foreignId('group_id')->constrained('challenge_groups')->cascadeOnDelete();
            $table->foreignId('question_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('type', ['auto_correct_answer', 'manual_add', 'manual_subtract', 'correction']);
            $table->integer('points');
            $table->unsignedTinyInteger('dice_value')->nullable();
            $table->enum('question_level', ['easy', 'hard'])->nullable();
            $table->text('note')->nullable();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('score_events');
        Schema::dropIfExists('challenge_questions');
        Schema::dropIfExists('challenge_groups');
        Schema::dropIfExists('challenge_session_lessons');
        Schema::dropIfExists('challenge_session_chapters');
        Schema::dropIfExists('challenge_sessions');
    }
};
