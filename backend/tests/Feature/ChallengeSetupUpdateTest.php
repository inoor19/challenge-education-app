<?php

namespace Tests\Feature;

use App\Models\ChallengeGroup;
use App\Models\ChallengeQuestion;
use App\Models\ChallengeSession;
use App\Models\Chapter;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\ScoreEvent;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ChallengeSetupUpdateTest extends TestCase
{
    use RefreshDatabase;

    public function test_teacher_can_replace_used_questions_without_resetting_scores(): void
    {
        $teacher = User::factory()->create();
        $fixture = $this->challengeFixture($teacher);
        $fixture['challenge']->update(['current_turn_group_id' => $fixture['nextGroup']->id]);

        Sanctum::actingAs($teacher);

        $this->patchJson("/api/challenges/{$fixture['challenge']->id}", [
            'subject_part_id' => $fixture['part']->id,
            'chapter_ids' => [$fixture['nextChapter']->id],
            'lesson_ids' => [$fixture['nextLesson']->id],
            'question_ids' => [$fixture['nextQuestion']->id],
        ])
            ->assertOk()
            ->assertJsonPath('status', 'active')
            ->assertJsonPath('current_turn_group_id', $fixture['nextGroup']->id)
            ->assertJsonPath('groups.0.score', 7)
            ->assertJsonPath('questions.0.question.id', $fixture['nextQuestion']->id)
            ->assertJsonPath('questions.0.is_used', false);

        $this->assertDatabaseMissing('challenge_questions', [
            'challenge_session_id' => $fixture['challenge']->id,
            'question_id' => $fixture['usedQuestion']->id,
        ]);
        $this->assertDatabaseHas('challenge_questions', [
            'challenge_session_id' => $fixture['challenge']->id,
            'question_id' => $fixture['nextQuestion']->id,
            'sequence_number' => 1,
            'is_used' => false,
        ]);
        $this->assertDatabaseHas('challenge_groups', [
            'id' => $fixture['group']->id,
            'score' => 7,
        ]);
        $this->assertDatabaseHas('score_events', [
            'challenge_session_id' => $fixture['challenge']->id,
            'group_id' => $fixture['group']->id,
            'question_id' => $fixture['usedQuestion']->id,
            'points' => 7,
        ]);
        $this->assertDatabaseHas('challenge_sessions', [
            'id' => $fixture['challenge']->id,
            'current_turn_group_id' => $fixture['nextGroup']->id,
        ]);
    }

    public function test_editing_completed_challenge_reopens_it_and_keeps_scores(): void
    {
        $teacher = User::factory()->create();
        $fixture = $this->challengeFixture($teacher, 'completed');

        Sanctum::actingAs($teacher);

        $this->patchJson("/api/challenges/{$fixture['challenge']->id}", [
            'subject_part_id' => $fixture['part']->id,
            'chapter_ids' => [$fixture['nextChapter']->id],
            'lesson_ids' => [$fixture['nextLesson']->id],
            'question_ids' => [$fixture['nextQuestion']->id],
        ])
            ->assertOk()
            ->assertJsonPath('status', 'active')
            ->assertJsonPath('groups.0.score', 7);

        $this->assertDatabaseHas('challenge_sessions', [
            'id' => $fixture['challenge']->id,
            'status' => 'active',
            'ended_at' => null,
        ]);
    }

    public function test_teacher_question_answer_must_match_question_type(): void
    {
        $teacher = User::factory()->create();
        $fixture = $this->curriculumFixture($teacher);

        Sanctum::actingAs($teacher);

        $this->postJson('/api/teacher/questions', [
            'lesson_id' => $fixture['lesson']->id,
            'question_text' => 'هل العبارة صحيحة؟',
            'question_type' => 'true_false',
            'correct_answer' => 'نعم',
            'level' => 'easy',
        ])->assertUnprocessable();

        $this->postJson('/api/teacher/questions', [
            'lesson_id' => $fixture['lesson']->id,
            'question_text' => 'هل العبارة صحيحة؟',
            'question_type' => 'true_false',
            'correct_answer' => 'صح',
            'level' => 'easy',
        ])->assertCreated();

        $this->postJson('/api/teacher/questions', [
            'lesson_id' => $fixture['lesson']->id,
            'question_text' => 'اختر الإجابة',
            'question_type' => 'multiple_choice',
            'option_a' => 'أ',
            'option_b' => 'ب',
            'correct_answer' => 'ج',
            'level' => 'easy',
        ])->assertUnprocessable();

        $this->postJson('/api/teacher/questions', [
            'lesson_id' => $fixture['lesson']->id,
            'question_text' => 'اذكر مثالاً',
            'question_type' => 'text',
            'correct_answer' => '',
            'level' => 'easy',
        ])->assertCreated();

        $this->assertDatabaseHas('questions', [
            'question_text' => 'اذكر مثالاً',
            'question_type' => 'text',
            'correct_answer' => '',
        ]);

        $this->postJson('/api/teacher/questions', [
            'lesson_id' => $fixture['lesson']->id,
            'question_text' => 'اختر الإجابة',
            'question_type' => 'multiple_choice',
            'option_a' => 'أ',
            'option_b' => 'ب',
            'correct_answer' => '',
            'level' => 'easy',
        ])->assertUnprocessable();
    }

    public function test_marking_correct_advances_and_persists_current_turn_group(): void
    {
        $teacher = User::factory()->create();
        $fixture = $this->challengeFixture($teacher, usedQuestion: false);

        Sanctum::actingAs($teacher);

        $this->postJson("/api/challenges/{$fixture['challenge']->id}/questions/{$fixture['challengeQuestion']->id}/mark-correct", [
            'group_id' => $fixture['group']->id,
            'dice_value' => 2,
        ])->assertOk();

        $this->assertDatabaseHas('challenge_sessions', [
            'id' => $fixture['challenge']->id,
            'current_turn_group_id' => $fixture['nextGroup']->id,
        ]);
    }

    public function test_marking_wrong_advances_and_persists_current_turn_group(): void
    {
        $teacher = User::factory()->create();
        $fixture = $this->challengeFixture($teacher, usedQuestion: false);

        Sanctum::actingAs($teacher);

        $this->postJson("/api/challenges/{$fixture['challenge']->id}/questions/{$fixture['challengeQuestion']->id}/mark-wrong", [
            'group_id' => $fixture['group']->id,
            'dice_value' => 2,
        ])->assertOk();

        $this->assertDatabaseHas('challenge_sessions', [
            'id' => $fixture['challenge']->id,
            'current_turn_group_id' => $fixture['nextGroup']->id,
        ]);
    }

    private function challengeFixture(User $teacher, string $status = 'active', bool $usedQuestion = true): array
    {
        $fixture = $this->curriculumFixture($teacher);

        $nextChapter = Chapter::create([
            'subject_part_id' => $fixture['part']->id,
            'name' => 'الفصل الثاني',
            'sort_order' => 2,
            'is_active' => true,
        ]);
        $nextLesson = Lesson::create([
            'chapter_id' => $nextChapter->id,
            'name' => 'الدرس الثاني',
            'sort_order' => 2,
            'is_active' => true,
        ]);
        $nextQuestion = Question::create([
            'lesson_id' => $nextLesson->id,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
            'question_text' => 'سؤال جديد',
            'question_type' => 'text',
            'correct_answer' => 'إجابة جديدة',
            'level' => 'easy',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        $challenge = ChallengeSession::create([
            'teacher_id' => $teacher->id,
            'grade_id' => $fixture['grade']->id,
            'grade_section' => 'أ',
            'subject_id' => $fixture['subject']->id,
            'subject_part_id' => $fixture['part']->id,
            'timer_seconds' => 60,
            'timer_enabled' => true,
            'status' => $status,
            'started_at' => now(),
            'ended_at' => $status === 'completed' ? now() : null,
        ]);
        $challenge->chapters()->attach($fixture['chapter']->id);
        $challenge->lessons()->attach($fixture['lesson']->id);

        $group = ChallengeGroup::create([
            'challenge_session_id' => $challenge->id,
            'name' => 'الفريق الأول',
            'score' => $usedQuestion ? 7 : 0,
            'sort_order' => 0,
        ]);
        $nextGroup = ChallengeGroup::create([
            'challenge_session_id' => $challenge->id,
            'name' => 'الفريق الثاني',
            'score' => 0,
            'sort_order' => 1,
        ]);

        $challengeQuestion = ChallengeQuestion::create([
            'challenge_session_id' => $challenge->id,
            'question_id' => $fixture['question']->id,
            'sequence_number' => 1,
            'is_used' => $usedQuestion,
            'used_at' => $usedQuestion ? now() : null,
            'selected_group_id' => $usedQuestion ? $group->id : null,
            'last_dice_value' => $usedQuestion ? 2 : null,
            'awarded_points' => $usedQuestion ? 7 : null,
            'answer_status' => $usedQuestion ? 'correct' : null,
        ]);

        if ($usedQuestion) {
            ScoreEvent::create([
                'challenge_session_id' => $challenge->id,
                'group_id' => $group->id,
                'question_id' => $fixture['question']->id,
                'type' => 'auto_correct_answer',
                'points' => 7,
                'dice_value' => 2,
                'question_level' => 'hard',
                'created_by' => $teacher->id,
            ]);
        }

        return [
            ...$fixture,
            'challenge' => $challenge,
            'group' => $group,
            'nextGroup' => $nextGroup,
            'challengeQuestion' => $challengeQuestion,
            'usedQuestion' => $fixture['question'],
            'nextChapter' => $nextChapter,
            'nextLesson' => $nextLesson,
            'nextQuestion' => $nextQuestion,
        ];
    }

    private function curriculumFixture(User $teacher): array
    {
        $grade = Grade::create([
            'name' => 'صف الاختبار',
            'sort_order' => 1,
            'is_active' => true,
        ]);
        $subject = Subject::create([
            'grade_id' => $grade->id,
            'name' => 'رياضيات',
            'sort_order' => 1,
            'is_active' => true,
        ]);
        $part = $subject->parts()->where('part_number', 1)->firstOrFail();
        $chapter = Chapter::create([
            'subject_part_id' => $part->id,
            'name' => 'الفصل الأول',
            'sort_order' => 1,
            'is_active' => true,
        ]);
        $lesson = Lesson::create([
            'chapter_id' => $chapter->id,
            'name' => 'الدرس الأول',
            'sort_order' => 1,
            'is_active' => true,
        ]);
        $question = Question::create([
            'lesson_id' => $lesson->id,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
            'question_text' => 'سؤال قديم',
            'question_type' => 'text',
            'correct_answer' => 'إجابة',
            'level' => 'hard',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        return compact('grade', 'subject', 'part', 'chapter', 'lesson', 'question');
    }
}
