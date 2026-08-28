<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChallengeSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'teacher_id',
        'grade_id',
        'grade_section',
        'subject_id',
        'subject_part_id',
        'timer_seconds',
        'timer_enabled',
        'status',
        'current_turn_group_id',
        'started_at',
        'ended_at',
    ];

    protected $casts = [
        'timer_enabled' => 'boolean',
        'timer_seconds' => 'integer',
        'current_turn_group_id' => 'integer',
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
    ];

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(User::class, 'teacher_id');
    }

    public function grade(): BelongsTo
    {
        return $this->belongsTo(Grade::class);
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function subjectPart(): BelongsTo
    {
        return $this->belongsTo(SubjectPart::class);
    }

    public function currentTurnGroup(): BelongsTo
    {
        return $this->belongsTo(ChallengeGroup::class, 'current_turn_group_id');
    }

    public function chapters(): BelongsToMany
    {
        return $this->belongsToMany(Chapter::class, 'challenge_session_chapters');
    }

    public function lessons(): BelongsToMany
    {
        return $this->belongsToMany(Lesson::class, 'challenge_session_lessons');
    }

    public function groups(): HasMany
    {
        return $this->hasMany(ChallengeGroup::class)->orderBy('sort_order');
    }

    public function challengeQuestions(): HasMany
    {
        return $this->hasMany(ChallengeQuestion::class)->orderBy('sequence_number');
    }

    public function scoreEvents(): HasMany
    {
        return $this->hasMany(ScoreEvent::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }
}
