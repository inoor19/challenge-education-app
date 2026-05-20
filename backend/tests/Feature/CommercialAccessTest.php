<?php

namespace Tests\Feature;

use App\Models\Chapter;
use App\Models\ChallengeGroup;
use App\Models\ChallengeQuestion;
use App\Models\ChallengeSession;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\QuestionPackage;
use App\Models\Subject;
use App\Models\TeacherPackage;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CommercialAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_teacher_only_sees_content_from_free_or_owned_packages(): void
    {
        $teacher = $this->teacher();
        $free = $this->curriculumPackage('الصف المتاح', true);
        $locked = $this->curriculumPackage('الصف المقفل', false);

        Sanctum::actingAs($teacher);

        $this->getJson('/api/grades')
            ->assertOk()
            ->assertJsonFragment(['id' => $free['grade']->id])
            ->assertJsonMissing(['id' => $locked['grade']->id]);

        $this->getJson('/api/questions?lesson_ids[]=' . $locked['lesson']->id)
            ->assertOk()
            ->assertJsonCount(0);
    }

    public function test_verified_store_purchase_grants_package_access(): void
    {
        $teacher = $this->teacher();
        $locked = $this->curriculumPackage('الصف التجاري', false);

        Sanctum::actingAs($teacher);

        $this->postJson('/api/purchases/verify', [
            'question_package_id' => $locked['package']->id,
            'store' => 'android',
            'product_id' => $locked['package']->android_product_id,
            'transaction_id' => 'test_transaction_' . $locked['package']->id,
            'purchase_token' => 'test_token',
        ])->assertOk()
            ->assertJsonPath('purchase.status', 'verified');

        $this->assertDatabaseHas('teacher_packages', [
            'user_id' => $teacher->id,
            'question_package_id' => $locked['package']->id,
        ]);

        $this->getJson('/api/questions?lesson_ids[]=' . $locked['lesson']->id)
            ->assertOk()
            ->assertJsonCount(1);
    }

    public function test_challenge_creation_rejects_mismatched_hierarchy(): void
    {
        $teacher = $this->teacher();
        $owned = $this->curriculumPackage('الصف الأول', false);
        $other = $this->curriculumPackage('الصف الثاني', true);

        TeacherPackage::create([
            'user_id' => $teacher->id,
            'question_package_id' => $owned['package']->id,
            'purchased_at' => now(),
        ]);

        Sanctum::actingAs($teacher);

        $this->postJson('/api/challenges', [
            'grade_id' => $owned['grade']->id,
            'subject_id' => $other['subject']->id,
            'subject_part_id' => $owned['part']->id,
            'chapter_ids' => [$owned['chapter']->id],
            'lesson_ids' => [$owned['lesson']->id],
            'timer_seconds' => 60,
            'timer_enabled' => true,
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('subject_id');
    }

    public function test_answer_cannot_use_group_from_another_session(): void
    {
        $teacher = $this->teacher();
        $owned = $this->curriculumPackage('الصف النشط', false);

        TeacherPackage::create([
            'user_id' => $teacher->id,
            'question_package_id' => $owned['package']->id,
            'purchased_at' => now(),
        ]);

        Sanctum::actingAs($teacher);

        $session = ChallengeSession::create([
            'teacher_id' => $teacher->id,
            'grade_id' => $owned['grade']->id,
            'subject_id' => $owned['subject']->id,
            'subject_part_id' => $owned['part']->id,
            'timer_seconds' => 60,
            'timer_enabled' => true,
            'status' => 'active',
            'started_at' => now(),
        ]);
        $question = ChallengeQuestion::create([
            'challenge_session_id' => $session->id,
            'question_id' => $owned['question']->id,
            'sequence_number' => 1,
            'is_used' => false,
        ]);

        $otherSession = ChallengeSession::create([
            'teacher_id' => $teacher->id,
            'grade_id' => $owned['grade']->id,
            'subject_id' => $owned['subject']->id,
            'subject_part_id' => $owned['part']->id,
            'timer_seconds' => 60,
            'timer_enabled' => true,
            'status' => 'active',
            'started_at' => now(),
        ]);
        $otherGroup = ChallengeGroup::create([
            'challenge_session_id' => $otherSession->id,
            'name' => 'مجموعة خارجية',
            'score' => 0,
            'sort_order' => 1,
        ]);

        $this->postJson("/api/challenges/{$session->id}/questions/{$question->id}/mark-correct", [
            'group_id' => $otherGroup->id,
            'dice_value' => 2,
        ])->assertForbidden();
    }

    public function test_subject_creation_creates_two_default_parts(): void
    {
        $teacher = $this->teacher();
        Sanctum::actingAs($teacher);

        $grade = Grade::create([
            'name' => 'صف خاص',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        $this->postJson('/api/teacher/subjects', [
            'grade_id' => $grade->id,
            'name' => 'لغة عربية',
        ])->assertCreated();

        $subject = Subject::where('grade_id', $grade->id)->where('name', 'لغة عربية')->firstOrFail();

        $this->assertDatabaseHas('subject_parts', [
            'subject_id' => $subject->id,
            'part_number' => 1,
            'name' => 'الجزء الأول',
        ]);
        $this->assertDatabaseHas('subject_parts', [
            'subject_id' => $subject->id,
            'part_number' => 2,
            'name' => 'الجزء الثاني',
        ]);
    }

    public function test_teacher_private_questions_are_free_only_for_creator(): void
    {
        $owner = $this->teacher();
        $otherTeacher = $this->teacher();

        $grade = Grade::create([
            'name' => 'صف الأستاذ',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $owner->id,
            'visibility' => 'private',
        ]);
        $subject = Subject::create([
            'grade_id' => $grade->id,
            'name' => 'مهارات',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $owner->id,
            'visibility' => 'private',
        ]);
        $part = $subject->parts()->where('part_number', 1)->firstOrFail();
        $chapter = Chapter::create([
            'subject_part_id' => $part->id,
            'name' => 'فصل خاص',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $owner->id,
            'visibility' => 'private',
        ]);
        $lesson = Lesson::create([
            'chapter_id' => $chapter->id,
            'name' => 'درس خاص',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $owner->id,
            'visibility' => 'private',
        ]);
        $question = Question::create([
            'lesson_id' => $lesson->id,
            'question_text' => 'سؤال خاص',
            'question_type' => 'text',
            'correct_answer' => 'إجابة',
            'level' => 'easy',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $owner->id,
            'visibility' => 'private',
        ]);

        Sanctum::actingAs($owner);
        $this->getJson('/api/questions?lesson_ids[]=' . $lesson->id)
            ->assertOk()
            ->assertJsonFragment(['id' => $question->id]);

        Sanctum::actingAs($otherTeacher);
        $this->getJson('/api/questions?lesson_ids[]=' . $lesson->id)
            ->assertOk()
            ->assertJsonMissing(['id' => $question->id]);
    }

    public function test_challenge_creation_uses_selected_subject_part(): void
    {
        $teacher = $this->teacher();
        Sanctum::actingAs($teacher);

        $grade = Grade::create([
            'name' => 'صف الأجزاء',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
        ]);
        $subject = Subject::create([
            'grade_id' => $grade->id,
            'name' => 'علوم الأجزاء',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
        ]);
        $partTwo = $subject->parts()->where('part_number', 2)->firstOrFail();
        $chapter = Chapter::create([
            'subject_part_id' => $partTwo->id,
            'name' => 'فصل الجزء الثاني',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
        ]);
        $lesson = Lesson::create([
            'chapter_id' => $chapter->id,
            'name' => 'درس الجزء الثاني',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
        ]);
        Question::create([
            'lesson_id' => $lesson->id,
            'question_text' => 'سؤال الجزء الثاني',
            'question_type' => 'text',
            'correct_answer' => 'إجابة',
            'level' => 'easy',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
        ]);

        $this->postJson('/api/challenges', [
            'grade_id' => $grade->id,
            'subject_id' => $subject->id,
            'subject_part_id' => $partTwo->id,
            'chapter_ids' => [$chapter->id],
            'lesson_ids' => [$lesson->id],
            'timer_seconds' => 60,
            'timer_enabled' => true,
        ])->assertCreated()
            ->assertJsonPath('subject_part.id', $partTwo->id)
            ->assertJsonCount(1, 'questions');
    }

    public function test_challenge_creation_uses_only_selected_questions(): void
    {
        $teacher = $this->teacher();
        $owned = $this->curriculumPackage('صف اختيار الأسئلة', true);
        $secondQuestion = Question::create([
            'lesson_id' => $owned['lesson']->id,
            'question_text' => 'سؤال غير مختار',
            'question_type' => 'text',
            'correct_answer' => 'إجابة',
            'level' => 'hard',
            'sort_order' => 2,
            'is_active' => true,
        ]);
        $owned['package']->questions()->attach($secondQuestion);

        Sanctum::actingAs($teacher);

        $this->postJson('/api/challenges', [
            'grade_id' => $owned['grade']->id,
            'subject_id' => $owned['subject']->id,
            'subject_part_id' => $owned['part']->id,
            'chapter_ids' => [$owned['chapter']->id],
            'lesson_ids' => [$owned['lesson']->id],
            'question_ids' => [$secondQuestion->id],
            'timer_seconds' => 60,
            'timer_enabled' => true,
        ])->assertCreated()
            ->assertJsonCount(1, 'questions')
            ->assertJsonPath('questions.0.question.id', $secondQuestion->id);
    }

    public function test_challenge_creation_rejects_selected_question_outside_selected_lessons(): void
    {
        $teacher = $this->teacher();
        $owned = $this->curriculumPackage('صف الدرس الأول', true);
        $other = $this->curriculumPackage('صف الدرس الثاني', true);

        Sanctum::actingAs($teacher);

        $this->postJson('/api/challenges', [
            'grade_id' => $owned['grade']->id,
            'subject_id' => $owned['subject']->id,
            'subject_part_id' => $owned['part']->id,
            'chapter_ids' => [$owned['chapter']->id],
            'lesson_ids' => [$owned['lesson']->id],
            'question_ids' => [$other['question']->id],
            'timer_seconds' => 60,
            'timer_enabled' => true,
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('question_ids');
    }

    public function test_challenge_creation_rejects_selected_question_without_access(): void
    {
        $teacher = $this->teacher();
        $locked = $this->curriculumPackage('صف مقفل للسؤال المختار', false);

        Sanctum::actingAs($teacher);

        $this->postJson('/api/challenges', [
            'grade_id' => $locked['grade']->id,
            'subject_id' => $locked['subject']->id,
            'subject_part_id' => $locked['part']->id,
            'chapter_ids' => [$locked['chapter']->id],
            'lesson_ids' => [$locked['lesson']->id],
            'question_ids' => [$locked['question']->id],
            'timer_seconds' => 60,
            'timer_enabled' => true,
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('question_ids');
    }

    public function test_challenge_creation_keeps_legacy_all_questions_behavior_without_question_ids(): void
    {
        $teacher = $this->teacher();
        $owned = $this->curriculumPackage('صف السلوك القديم', true);
        $secondQuestion = Question::create([
            'lesson_id' => $owned['lesson']->id,
            'question_text' => 'سؤال إضافي',
            'question_type' => 'text',
            'correct_answer' => 'إجابة',
            'level' => 'easy',
            'sort_order' => 2,
            'is_active' => true,
        ]);
        $owned['package']->questions()->attach($secondQuestion);

        Sanctum::actingAs($teacher);

        $this->postJson('/api/challenges', [
            'grade_id' => $owned['grade']->id,
            'subject_id' => $owned['subject']->id,
            'subject_part_id' => $owned['part']->id,
            'chapter_ids' => [$owned['chapter']->id],
            'lesson_ids' => [$owned['lesson']->id],
            'timer_seconds' => 60,
            'timer_enabled' => true,
        ])->assertCreated()
            ->assertJsonCount(2, 'questions');
    }

    public function test_teacher_questions_endpoint_returns_valid_json_with_literal_backslashes(): void
    {
        $teacher = $this->teacher();
        Sanctum::actingAs($teacher);

        $grade = Grade::create([
            'name' => 'صف JSON',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
        ]);
        $subject = Subject::create([
            'grade_id' => $grade->id,
            'name' => 'اختبار JSON',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
        ]);
        $part = $subject->parts()->where('part_number', 1)->firstOrFail();
        $chapter = Chapter::create([
            'subject_part_id' => $part->id,
            'name' => 'فصل JSON',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
        ]);
        $lesson = Lesson::create([
            'chapter_id' => $chapter->id,
            'name' => 'درس JSON',
            'sort_order' => 1,
            'is_active' => true,
            'created_by_user_id' => $teacher->id,
            'visibility' => 'private',
        ]);

        $expectedQuestion = 'مسار \path ونص \u0633 قبلبعد';
        $expectedAnswer = 'إجابة \path';

        $this->postJson('/api/teacher/questions', [
            'lesson_id' => $lesson->id,
            'question_text' => "  مسار \\path ونص \\u0633 قبل\x00بعد  ",
            'question_type' => 'text',
            'correct_answer' => "  {$expectedAnswer}  ",
            'level' => 'easy',
            'explanation' => "شرح \\u0634 قبل\x07بعد",
        ])->assertCreated()
            ->assertJsonPath('question_text', $expectedQuestion)
            ->assertJsonPath('correct_answer', $expectedAnswer)
            ->assertJsonPath('explanation', 'شرح \u0634 قبلبعد');

        $response = $this->getJson('/api/teacher/questions')
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.question_text', $expectedQuestion);

        $this->assertJson($response->getContent());
        $this->assertStringNotContainsString('\\u0000', $response->getContent());
        $this->assertStringNotContainsString('\\u0007', $response->getContent());
    }

    private function teacher(): User
    {
        return User::create([
            'name' => 'معلم',
            'email' => fake()->unique()->safeEmail(),
            'password' => 'password',
            'role' => 'teacher',
            'is_active' => true,
        ]);
    }

    private function curriculumPackage(string $gradeName, bool $isFree): array
    {
        $grade = Grade::create(['name' => $gradeName, 'sort_order' => 1, 'is_active' => true]);
        $subject = Subject::create(['grade_id' => $grade->id, 'name' => 'علوم', 'sort_order' => 1, 'is_active' => true]);
        $part = $subject->parts()->where('part_number', 1)->firstOrFail();
        $chapter = Chapter::create(['subject_part_id' => $part->id, 'name' => 'الفصل الأول', 'sort_order' => 1, 'is_active' => true]);
        $lesson = Lesson::create(['chapter_id' => $chapter->id, 'name' => 'الدرس الأول', 'sort_order' => 1, 'is_active' => true]);
        $question = Question::create([
            'lesson_id' => $lesson->id,
            'question_text' => 'سؤال تجاري',
            'question_type' => 'multiple_choice',
            'option_a' => 'أ',
            'option_b' => 'ب',
            'correct_answer' => 'أ',
            'level' => 'easy',
            'sort_order' => 1,
            'is_active' => true,
        ]);
        $package = QuestionPackage::create([
            'title' => "حزمة {$gradeName}",
            'grade_id' => $grade->id,
            'subject_id' => $subject->id,
            'is_free' => $isFree,
            'price' => $isFree ? null : 19,
            'platform_product_id' => 'pack_' . $grade->id,
            'android_product_id' => 'pack_' . $grade->id . '_android',
            'ios_product_id' => 'pack_' . $grade->id . '_ios',
            'purchase_type' => 'non_consumable',
            'is_active' => true,
        ]);
        $package->questions()->attach($question);

        return compact('grade', 'subject', 'part', 'chapter', 'lesson', 'question', 'package');
    }
}
