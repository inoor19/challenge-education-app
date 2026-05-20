<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeacherPackage extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'question_package_id', 'purchased_at'];

    protected $casts = [
        'purchased_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function questionPackage(): BelongsTo
    {
        return $this->belongsTo(QuestionPackage::class);
    }
}
