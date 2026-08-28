<?php

namespace App\Services;

use App\Models\ChallengeGroup;
use App\Models\ChallengeQuestion;
use App\Models\ChallengeSession;
use App\Models\Question;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use App\Services\EntitlementService;

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
                'grade_section' => $data['grade_section'],
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
     * Update editable challenge settings without resetting questions or scores.
     */
    public function updateSettings(ChallengeSession $session, array $data): ChallengeSession
    {
        return DB::transaction(function () use ($session, $data) {
            $session->update([
                'timer_seconds' => $data['timer_seconds'] ?? $session->timer_seconds,
                'timer_enabled' => $data['timer_enabled'] ?? $session->timer_enabled,
            ]);

            if (array_key_exists('groups', $data)) {
                $this->syncGroups($session, collect($data['groups']));
            }

            if (
                array_key_exists('subject_part_id', $data)
                || array_key_exists('chapter_ids', $data)
                || array_key_exists('lesson_ids', $data)
                || array_key_exists('question_ids', $data)
            ) {
                $this->syncSetupContent($session, $data);
            }

            return $session->fresh()
                ->load(['grade', 'subject', 'subjectPart', 'chapters.subjectPart', 'lessons', 'groups', 'challengeQuestions.question.lesson.chapter']);
        });
    }

    private function syncSetupContent(ChallengeSession $session, array $data): void
    {
        $session->loadMissing(['teacher', 'chapters', 'lessons', 'challengeQuestions']);

        $nextSubjectPartId = $data['subject_part_id'] ?? $session->subject_part_id;
        $chapterIds = $data['chapter_ids'] ?? $session->chapters->pluck('id')->all();
        $lessonIds = $data['lesson_ids'] ?? $session->lessons->pluck('id')->all();

        $questionIdsFilter = array_key_exists('question_ids', $data)
            ? $data['question_ids']
            : null;

        // Fetch ordered questions (same ordering as createSession)
        $questions = Question::active()
            ->forLessons($lessonIds)
            ->whereIn('id', app(EntitlementService::class)->accessibleQuestionIds($session->teacher))
            ->when($questionIdsFilter !== null, fn ($query) => $query->whereIn('id', $questionIdsFilter))
            ->orderBy('lesson_id')
            ->orderBy('sort_order')
            ->get(['id', 'lesson_id', 'sort_order']);

        abort_if($questions->isEmpty(), 422, 'لا توجد أسئلة متاحة ضمن الحزم المفعلة لهذه الدروس.');

        $desiredQuestionIds = $questions->pluck('id')->all();

        $existing = $session->challengeQuestions()
            ->get()
            ->keyBy('question_id');

        $toKeep = array_fill_keys($desiredQuestionIds, true);

        /** @var EloquentCollection<int, ChallengeQuestion> $toDelete */
        $toDelete = $existing->filter(fn (ChallengeQuestion $cq) => ! isset($toKeep[$cq->question_id]));

        // Sync session core selections
        if ((int) $session->subject_part_id !== (int) $nextSubjectPartId) {
            $session->update(['subject_part_id' => $nextSubjectPartId]);
        }
        $session->chapters()->sync($chapterIds);
        $session->lessons()->sync($lessonIds);

        // Apply challenge_questions changes (preserve used state for kept questions)
        foreach ($toDelete as $cq) {
            $cq->delete();
        }

        $keptExisting = $existing->filter(fn (ChallengeQuestion $cq) => isset($toKeep[$cq->question_id]));
        $temporarySequence = max(
            (int) $session->challengeQuestions()->max('sequence_number'),
            count($desiredQuestionIds)
        ) + 1;

        abort_if(
            $temporarySequence + $keptExisting->count() > 65535,
            422,
            'عدد الأسئلة كبير جداً لإعادة ترتيب التحدي.'
        );

        foreach ($keptExisting->values() as $index => $cq) {
            $cq->update(['sequence_number' => $temporarySequence + $index]);
        }

        $sequence = 1;
        foreach ($desiredQuestionIds as $questionId) {
            /** @var ChallengeQuestion|null $current */
            $current = $keptExisting->get($questionId);
            if ($current) {
                $current->update(['sequence_number' => $sequence++]);
                continue;
            }
            ChallengeQuestion::create([
                'challenge_session_id' => $session->id,
                'question_id' => $questionId,
                'sequence_number' => $sequence++,
                'is_used' => false,
            ]);
        }

        // If session was completed but now has editable fresh content, reopen it.
        if ($session->status === 'completed') {
            $session->update([
                'status' => 'active',
                'ended_at' => null,
            ]);
        }
    }

    /**
     * Restart the same challenge session (reset questions only).
     */
    public function restartSession(ChallengeSession $session): ChallengeSession
    {
        return DB::transaction(function () use ($session) {
            $session->load(['chapters', 'lessons', 'groups', 'challengeQuestions']);

            $session->update([
                'status' => 'active',
                'started_at' => now(),
                'ended_at' => null,
                'current_turn_group_id' => null,
            ]);

            // Keep group scores as-is. Reset questions state only.
            $session->challengeQuestions()->update([
                'is_used' => false,
                'used_at' => null,
                'selected_group_id' => null,
                'last_dice_value' => null,
                'awarded_points' => null,
                'answer_status' => null,
            ]);

            return $session->fresh()->load([
                'grade',
                'subject',
                'subjectPart',
                'chapters.subjectPart',
                'lessons',
                'groups',
                'challengeQuestions.question.lesson.chapter',
            ]);
        });
    }

    private function syncGroups(ChallengeSession $session, Collection $groups): void
    {
        $sentIds = $groups
            ->pluck('id')
            ->filter()
            ->map(fn ($id) => (int) $id)
            ->values();

        $session->groups()
            ->whereNotIn('id', $sentIds)
            ->get()
            ->each(function (ChallengeGroup $group) {
                $isReferenced = $group->scoreEvents()->exists()
                    || $group->challengeSession->challengeQuestions()
                        ->where('selected_group_id', $group->id)
                        ->exists()
                    || $group->score !== 0;

                abort_if($isReferenced, 422, 'لا يمكن حذف مجموعة لديها نقاط أو إجابات محفوظة.');

                $group->delete();
            });

        foreach ($groups->values() as $index => $groupData) {
            $payload = [
                'name' => trim($groupData['name']),
                'sort_order' => $groupData['sort_order'] ?? $index,
            ];

            if (! empty($groupData['id'])) {
                $group = $session->groups()->whereKey($groupData['id'])->firstOrFail();
                $group->update($payload);
                continue;
            }

            $session->groups()->create([
                ...$payload,
                'score' => 0,
            ]);
        }
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
