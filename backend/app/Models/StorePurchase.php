<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StorePurchase extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'question_package_id',
        'store',
        'product_id',
        'transaction_id',
        'purchase_token',
        'signed_transaction',
        'status',
        'verified_at',
        'expires_at',
        'raw_payload',
    ];

    protected $casts = [
        'verified_at' => 'datetime',
        'expires_at' => 'datetime',
        'raw_payload' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function questionPackage(): BelongsTo
    {
        return $this->belongsTo(QuestionPackage::class);
    }

    public function isVerified(): bool
    {
        return $this->status === 'verified';
    }
}
