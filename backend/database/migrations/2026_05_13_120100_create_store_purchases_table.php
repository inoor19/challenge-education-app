<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('store_purchases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('question_package_id')->constrained()->cascadeOnDelete();
            $table->string('store');
            $table->string('product_id');
            $table->string('transaction_id')->nullable();
            $table->text('purchase_token')->nullable();
            $table->text('signed_transaction')->nullable();
            $table->string('status')->default('pending');
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->json('raw_payload')->nullable();
            $table->timestamps();

            $table->unique(['store', 'transaction_id'], 'store_purchases_store_transaction_unique');
            $table->index(['user_id', 'status']);
            $table->index(['product_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('store_purchases');
    }
};
