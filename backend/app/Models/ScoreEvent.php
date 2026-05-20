<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ScoreEvent extends Model
{
    use HasFactory;

    protected $fillable = [
        'challenge_session_id',
        'group_id',
        'question_id',
        'type',
        'points',
        'dice_value',
        'question_level',
        'note',
        'created_by',
    ];

    protected $casts = [
        'points' => 'integer',
        'dice_value' => 'integer',
    ];

    public function challengeSession(): BelongsTo
    {
        return $this->belongsTo(ChallengeSession::class);
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(ChallengeGroup::class, 'group_id');
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(Question::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
