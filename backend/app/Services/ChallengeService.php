<?php

namespace App\Services;

use App\Models\ChallengeGroup;
use App\Models\ChallengeQuestion;
use App\Models\ChallengeSession;
use App\Models\Question;
use Illuminate\Support\Facades\DB;

class ChallengeService
{
    /**
     * Create a new challenge session and assign questions from the selected lessons.
     */
    public function createSession(array $data, int $teacherId): ChallengeSession
    {
        return DB::transaction(function () use ($data, $teacherId) {
            $session = ChallengeSession::create([
                'teacher_id' => $teacherId,
                'grade_id' => $data['grade_id'],
                'subject_id' => $data['subject_id'],
                'subject_part_id' => $data['subject_part_id'],
                'timer_seconds' => $data['timer_seconds'] ?? 60,
                'timer_enabled' => $data['timer_enabled'] ?? true,
                'status' => 'active',
                'started_at' => now(),
            ]);

            $session->chapters()->attach($data['chapter_ids']);
            $session->lessons()->attach($data['lesson_ids']);

            $this->assignQuestions($session, $data['lesson_ids'], $data['question_ids'] ?? null);

            return $session->load(['grade', 'subject', 'subjectPart', 'chapters.subjectPart', 'lessons', 'challengeQuestions.question.lesson.chapter']);
        });
    }

    /**
     * Fetch active questions from the selected lessons and assign them to the session
     * with sequential grid numbers.
     */
    private function assignQuestions(ChallengeSession $session, array $lessonIds, ?array $questionIds = null): void
    {
        $questions = Question::active()
            ->forLessons($lessonIds)
            ->whereIn('id', app(EntitlementService::class)->accessibleQuestionIds($session->teacher))
            ->when($questionIds !== null, fn ($query) => $query->whereIn('id', $questionIds))
            ->orderBy('lesson_id')
            ->orderBy('sort_order')
            ->get();

        abort_if($questions->isEmpty(), 422, 'لا توجد أسئلة متاحة ضمن الحزم المفعلة لهذه الدروس.');

        $sequence = 1;
        foreach ($questions as $question) {
            ChallengeQuestion::create([
                'challenge_session_id' => $session->id,
                'question_id' => $question->id,
                'sequence_number' => $sequence++,
                'is_used' => false,
            ]);
        }
    }

    /**
     * Add a group to an active challenge session.
     */
    public function addGroup(ChallengeSession $session, string $name, int $sortOrder = 0): ChallengeGroup
    {
        return $session->groups()->create([
            'name' => $name,
            'score' => 0,
            'sort_order' => $sortOrder,
        ]);
    }

    /**
     * Complete a challenge session.
     */
    public function completeSession(ChallengeSession $session): ChallengeSession
    {
        $session->update([
            'status' => 'completed',
            'ended_at' => now(),
        ]);

        return $session->fresh();
    }
}
