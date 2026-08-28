<?php

namespace Tests\Feature;

use App\Models\ChallengeGroup;
use App\Models\ChallengeQuestion;
use App\Models\ChallengeSession;
use App\Models\Chapter;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ChallengeDeletionTest extends TestCase
{
    use RefreshDatabase;

    public function test_teacher_can_delete_own_challenge(): void
    {
        $teacher = User::factory()->create();
        $challenge = $this->challengeFor($teacher);

        Sanctum::actingAs($teacher);

        $this->deleteJson("/api/challenges/{$challenge->id}")
            ->assertNoContent();

        $this->assertDatabaseMissing('challenge_sessions', ['id' => $challenge->id]);
        $this->assertDatabaseMissing('challenge_groups', ['challenge_session_id' => $challenge->id]);
        $this->assertDatabaseMissing('challenge_questions', ['challenge_session_id' => $challenge->id]);
    }

    public function test_teacher_cannot_delete_another_teachers_challenge(): void
    {
        $owner = User::factory()->create();
        $otherTeacher = User::factory()->create();
        $challenge = $this->challengeFor($owner);

        Sanctum::actingAs($otherTeacher);

        $this->deleteJson("/api/challenges/{$challenge->id}")
            ->assertForbidden();

        $this->assertDatabaseHas('challenge_sessions', ['id' => $challenge->id]);
    }

    private function challengeFor(User $teacher): ChallengeSession
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
            'question_text' => 'سؤال تجريبي',
            'question_type' => 'text',
            'correct_answer' => 'إجابة',
            'level' => 'easy',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        $challenge = ChallengeSession::create([
            'teacher_id' => $teacher->id,
            'grade_id' => $grade->id,
            'grade_section' => 'أ',
            'subject_id' => $subject->id,
            'subject_part_id' => $part->id,
            'timer_seconds' => 60,
            'timer_enabled' => true,
            'status' => 'active',
            'started_at' => now(),
        ]);
        $challenge->chapters()->attach($chapter);
        $challenge->lessons()->attach($lesson);

        $group = ChallengeGroup::create([
            'challenge_session_id' => $challenge->id,
            'name' => 'الفريق الأول',
            'score' => 0,
            'sort_order' => 0,
        ]);
        ChallengeQuestion::create([
            'challenge_session_id' => $challenge->id,
            'question_id' => $question->id,
            'sequence_number' => 1,
            'is_used' => false,
            'selected_group_id' => $group->id,
        ]);

        return $challenge;
    }
}
