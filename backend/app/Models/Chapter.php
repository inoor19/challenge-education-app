<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Chapter extends Model
{
    use HasFactory;

    protected $fillable = ['subject_id', 'subject_part_id', 'created_by_user_id', 'visibility', 'name', 'sort_order', 'is_active'];

    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    protected static function booted(): void
    {
        static::saving(function (Chapter $chapter) {
            if ($chapter->subject_part_id) {
                $chapter->subject_id = SubjectPart::whereKey($chapter->subject_part_id)->value('subject_id') ?? $chapter->subject_id;
            }
        });
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function subjectPart(): BelongsTo
    {
        return $this->belongsTo(SubjectPart::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function lessons(): HasMany
    {
        return $this->hasMany(Lesson::class)->orderBy('sort_order');
    }

    public function challengeSessions(): BelongsToMany
    {
        return $this->belongsToMany(ChallengeSession::class, 'challenge_session_chapters');
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true)->orderBy('sort_order');
    }

    public function scopeVisibleTo($query, User $user)
    {
        return $query->where(function ($query) use ($user) {
            $query->where('visibility', 'official')
                ->orWhere('created_by_user_id', $user->id);
        });
    }
}
