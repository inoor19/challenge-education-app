<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Question extends Model
{
    use HasFactory;

    protected $fillable = [
        'lesson_id',
        'created_by_user_id',
        'visibility',
        'question_text',
        'question_type',
        'option_a',
        'option_b',
        'option_c',
        'option_d',
        'correct_answer',
        'level',
        'explanation',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    public function lesson(): BelongsTo
    {
        return $this->belongsTo(Lesson::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function challengeQuestions(): HasMany
    {
        return $this->hasMany(ChallengeQuestion::class);
    }

    public function packages(): BelongsToMany
    {
        return $this->belongsToMany(QuestionPackage::class, 'question_package_items');
    }

    public function isEasy(): bool
    {
        return $this->level === 'easy';
    }

    public function isHard(): bool
    {
        return $this->level === 'hard';
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeVisibleTo($query, User $user)
    {
        return $query->where(function ($query) use ($user) {
            $query->where('visibility', 'official')
                ->orWhere('created_by_user_id', $user->id);
        });
    }

    public function scopeForLessons($query, array $lessonIds)
    {
        return $query->whereIn('lesson_id', $lessonIds);
    }
}
