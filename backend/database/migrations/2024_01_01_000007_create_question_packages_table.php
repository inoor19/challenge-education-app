<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('question_packages', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->foreignId('grade_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('subject_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('chapter_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('lesson_id')->nullable()->constrained()->nullOnDelete();
            $table->boolean('is_free')->default(true);
            $table->decimal('price', 8, 2)->nullable();
            $table->string('platform_product_id')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('question_package_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('question_package_id')->constrained()->cascadeOnDelete();
            $table->foreignId('question_id')->constrained()->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['question_package_id', 'question_id']);
        });

        Schema::create('teacher_packages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('question_package_id')->constrained()->cascadeOnDelete();
            $table->timestamp('purchased_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'question_package_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('teacher_packages');
        Schema::dropIfExists('question_package_items');
        Schema::dropIfExists('question_packages');
    }
};
