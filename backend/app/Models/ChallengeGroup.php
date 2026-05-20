<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChallengeGroup extends Model
{
    use HasFactory;

    protected $fillable = [
        'challenge_session_id',
        'name',
        'score',
        'sort_order',
    ];

    protected $casts = [
        'score' => 'integer',
        'sort_order' => 'integer',
    ];

    public function challengeSession(): BelongsTo
    {
        return $this->belongsTo(ChallengeSession::class);
    }

    public function scoreEvents(): HasMany
    {
        return $this->hasMany(ScoreEvent::class, 'group_id');
    }

    public function addPoints(int $points): void
    {
        $this->increment('score', $points);
    }

    public function subtractPoints(int $points): void
    {
        $this->decrement('score', $points);
    }

    public function setScore(int $score): void
    {
        $this->update(['score' => $score]);
    }
}
