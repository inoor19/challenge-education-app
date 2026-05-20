<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChallengeQuestion extends Model
{
    use HasFactory;

    protected $fillable = [
        'challenge_session_id',
        'question_id',
        'sequence_number',
        'is_used',
        'used_at',
        'selected_group_id',
        'last_dice_value',
        'awarded_points',
        'answer_status',
    ];

    protected $casts = [
        'is_used' => 'boolean',
        'used_at' => 'datetime',
        'sequence_number' => 'integer',
        'last_dice_value' => 'integer',
        'awarded_points' => 'integer',
    ];

    public function challengeSession(): BelongsTo
    {
        return $this->belongsTo(ChallengeSession::class);
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(Question::class);
    }

    public function selectedGroup(): BelongsTo
    {
        return $this->belongsTo(ChallengeGroup::class, 'selected_group_id');
    }

    public function markAsUsed(int $groupId, int $diceValue, int $awardedPoints, string $answerStatus): void
    {
        $this->update([
            'is_used' => true,
            'used_at' => now(),
            'selected_group_id' => $groupId,
            'last_dice_value' => $diceValue,
            'awarded_points' => $awardedPoints,
            'answer_status' => $answerStatus,
        ]);
    }
}
