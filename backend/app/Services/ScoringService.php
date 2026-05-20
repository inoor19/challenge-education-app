<?php

namespace App\Services;

use App\Models\ChallengeGroup;
use App\Models\ChallengeQuestion;
use App\Models\ChallengeSession;
use App\Models\AppSetting;
use App\Models\ScoreEvent;
use Illuminate\Support\Facades\DB;

class ScoringService
{
    /**
     * Calculate points based on dice value and question level.
     * Easy: dice value as-is. Hard: dice value × 2.
     */
    public function calculatePoints(int $diceValue, string $questionLevel): int
    {
        return $questionLevel === 'hard' ? $diceValue * 2 : $diceValue;
    }

    /**
     * Roll the dice — returns a random value between 1 and 3.
     */
    public function rollDice(): int
    {
        $min = AppSetting::get('dice_min_value', 1);
        $max = AppSetting::get('dice_max_value', 3);

        return random_int((int) $min, (int) $max);
    }

    /**
     * Mark a challenge question as correctly answered, award points, and log the score event.
     */
    public function markCorrect(
        ChallengeSession $session,
        ChallengeQuestion $challengeQuestion,
        int $groupId,
        int $diceValue,
        int $createdBy
    ): array {
        return DB::transaction(function () use ($session, $challengeQuestion, $groupId, $diceValue, $createdBy) {
            $question = $challengeQuestion->question;
            $points = $this->calculatePoints($diceValue, $question->level);

            $group = ChallengeGroup::findOrFail($groupId);
            abort_if($group->challenge_session_id !== $session->id, 403);
            $group->addPoints($points);

            $challengeQuestion->markAsUsed($groupId, $diceValue, $points, 'correct');

            ScoreEvent::create([
                'challenge_session_id' => $session->id,
                'group_id' => $groupId,
                'question_id' => $question->id,
                'type' => 'auto_correct_answer',
                'points' => $points,
                'dice_value' => $diceValue,
                'question_level' => $question->level,
                'created_by' => $createdBy,
            ]);

            return [
                'points_awarded' => $points,
                'group' => $group->fresh(),
            ];
        });
    }

    /**
     * Mark a challenge question as wrongly answered with no automatic point change.
     */
    public function markWrong(
        ChallengeSession $session,
        ChallengeQuestion $challengeQuestion,
        int $groupId,
        int $diceValue
    ): void {
        $group = ChallengeGroup::findOrFail($groupId);
        abort_if($group->challenge_session_id !== $session->id, 403);

        $challengeQuestion->markAsUsed($groupId, $diceValue, 0, 'wrong');
    }

    /**
     * Manually add points to a group.
     */
    public function manualAdd(
        ChallengeSession $session,
        ChallengeGroup $group,
        int $points,
        int $createdBy,
        ?string $note = null
    ): ChallengeGroup {
        return DB::transaction(function () use ($session, $group, $points, $createdBy, $note) {
            $group->addPoints($points);

            ScoreEvent::create([
                'challenge_session_id' => $session->id,
                'group_id' => $group->id,
                'type' => 'manual_add',
                'points' => $points,
                'note' => $note,
                'created_by' => $createdBy,
            ]);

            return $group->fresh();
        });
    }

    /**
     * Manually subtract points from a group.
     */
    public function manualSubtract(
        ChallengeSession $session,
        ChallengeGroup $group,
        int $points,
        int $createdBy,
        ?string $note = null
    ): ChallengeGroup {
        return DB::transaction(function () use ($session, $group, $points, $createdBy, $note) {
            $group->subtractPoints($points);

            ScoreEvent::create([
                'challenge_session_id' => $session->id,
                'group_id' => $group->id,
                'type' => 'manual_subtract',
                'points' => -$points,
                'note' => $note,
                'created_by' => $createdBy,
            ]);

            return $group->fresh();
        });
    }

    /**
     * Correct/override a group's score to an exact value.
     */
    public function correctScore(
        ChallengeSession $session,
        ChallengeGroup $group,
        int $newScore,
        int $createdBy,
        ?string $note = null
    ): ChallengeGroup {
        return DB::transaction(function () use ($session, $group, $newScore, $createdBy, $note) {
            $oldScore = $group->score;
            $diff = $newScore - $oldScore;
            $group->setScore($newScore);

            ScoreEvent::create([
                'challenge_session_id' => $session->id,
                'group_id' => $group->id,
                'type' => 'correction',
                'points' => $diff,
                'note' => $note ?? "تصحيح النقاط من {$oldScore} إلى {$newScore}",
                'created_by' => $createdBy,
            ]);

            return $group->fresh();
        });
    }
}
