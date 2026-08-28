<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class QuestionPackage extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'grade_id',
        'subject_id',
        'chapter_id',
        'lesson_id',
        'is_free',
        'price',
        'platform_product_id',
        'android_product_id',
        'ios_product_id',
        'purchase_type',
        'is_active',
    ];

    protected $casts = [
        'is_free' => 'boolean',
        'is_active' => 'boolean',
        'price' => 'decimal:2',
    ];

    public function grade(): BelongsTo
    {
        return $this->belongsTo(Grade::class);
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function chapter(): BelongsTo
    {
        return $this->belongsTo(Chapter::class);
    }

    public function lesson(): BelongsTo
    {
        return $this->belongsTo(Lesson::class);
    }

    public function chapters(): BelongsToMany
    {
        return $this->belongsToMany(Chapter::class, 'question_package_chapters')
            ->withTimestamps();
    }

    public function lessons(): BelongsToMany
    {
        return $this->belongsToMany(Lesson::class, 'question_package_lessons')
            ->withTimestamps();
    }

    public function questions(): BelongsToMany
    {
        return $this->belongsToMany(Question::class, 'question_package_items')
            ->withTimestamps();
    }

    public function teacherPackages(): HasMany
    {
        return $this->hasMany(TeacherPackage::class);
    }

    public function storePurchases(): HasMany
    {
        return $this->hasMany(StorePurchase::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function productIdForStore(string $store): ?string
    {
        return match ($store) {
            'android' => $this->android_product_id ?: $this->platform_product_id,
            'ios' => $this->ios_product_id ?: $this->platform_product_id,
            default => $this->platform_product_id,
        };
    }
}
