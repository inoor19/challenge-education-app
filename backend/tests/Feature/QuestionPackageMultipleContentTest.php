<?php

namespace Tests\Feature;

use App\Filament\Resources\QuestionPackageResource\Pages\CreateQuestionPackage;
use App\Filament\Resources\QuestionPackageResource\QuestionPackageResource as FilamentQuestionPackageResource;
use App\Models\Chapter;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\QuestionPackage;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\Sanctum;
use Livewire\Livewire;
use Tests\TestCase;

class QuestionPackageMultipleContentTest extends TestCase
{
    use RefreshDatabase;

    public function test_package_api_returns_multiple_chapters_and_lessons_with_legacy_fields(): void
    {
        $fixture = $this->makePackageFixture();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/packages')
            ->assertOk()
            ->assertJsonPath('0.chapter.id', $fixture['chapters'][0]->id)
            ->assertJsonPath('0.lesson.id', $fixture['lessons'][0]->id)
            ->assertJsonCount(2, '0.chapters')
            ->assertJsonCount(2, '0.lessons')
            ->assertJsonPath('0.chapters.1.id', $fixture['chapters'][1]->id)
            ->assertJsonPath('0.lessons.1.id', $fixture['lessons'][1]->id);
    }

    public function test_admin_can_create_package_with_multiple_content_from_filament_form(): void
    {
        $fixture = $this->makePackageFixture();
        $fixture['package']->delete();
        $this->actingAs(User::factory()->admin()->create());

        Livewire::test(CreateQuestionPackage::class)
            ->fillForm([
                'title' => 'حزمة من لوحة الإدارة',
                'grade_id' => $fixture['grade']->id,
                'subject_id' => $fixture['subject']->id,
                'chapters' => collect($fixture['chapters'])->pluck('id')->map(fn ($id) => (string) $id)->all(),
                'lessons' => collect($fixture['lessons'])->pluck('id')->map(fn ($id) => (string) $id)->all(),
                'questions' => collect($fixture['questions'])->pluck('id')->map(fn ($id) => (string) $id)->all(),
                'is_free' => true,
                'purchase_type' => 'non_consumable',
                'is_active' => true,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $package = QuestionPackage::where('title', 'حزمة من لوحة الإدارة')->firstOrFail();

        $this->assertCount(2, $package->chapters);
        $this->assertCount(2, $package->lessons);
        $this->assertCount(2, $package->questions);
        $this->assertSame($fixture['chapters'][0]->id, $package->chapter_id);
        $this->assertSame($fixture['lessons'][0]->id, $package->lesson_id);
    }

    public function test_package_content_validation_rejects_items_outside_the_selected_hierarchy(): void
    {
        $fixture = $this->makePackageFixture();
        $otherSubject = Subject::create([
            'grade_id' => $fixture['grade']->id,
            'visibility' => 'official',
            'name' => 'علوم',
            'sort_order' => 2,
            'is_active' => true,
        ]);
        $otherChapter = Chapter::create([
            'subject_id' => $otherSubject->id,
            'subject_part_id' => $otherSubject->parts()->first()->id,
            'visibility' => 'official',
            'name' => 'فصل خارجي',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        try {
            FilamentQuestionPackageResource::validateContentSelection([
                'grade_id' => $fixture['grade']->id,
                'subject_id' => $fixture['subject']->id,
                'chapters' => [$fixture['chapters'][0]->id, $otherChapter->id],
                'lessons' => collect($fixture['lessons'])->pluck('id')->all(),
                'questions' => collect($fixture['questions'])->pluck('id')->all(),
            ]);

            $this->fail('Expected package hierarchy validation to fail.');
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey('chapters', $exception->errors());
        }
    }

    public function test_legacy_chapter_and_lesson_are_synchronized_to_first_selection(): void
    {
        $fixture = $this->makePackageFixture();
        $package = $fixture['package'];

        FilamentQuestionPackageResource::syncLegacyContent($package, [
            'chapters' => [$fixture['chapters'][1]->id, $fixture['chapters'][0]->id],
            'lessons' => [$fixture['lessons'][1]->id, $fixture['lessons'][0]->id],
        ]);

        $this->assertSame($fixture['chapters'][1]->id, $package->fresh()->chapter_id);
        $this->assertSame($fixture['lessons'][1]->id, $package->fresh()->lesson_id);
    }

    private function makePackageFixture(): array
    {
        $grade = Grade::create([
            'visibility' => 'official',
            'name' => 'الأول الابتدائي',
            'sort_order' => 1,
            'is_active' => true,
        ]);
        $subject = Subject::create([
            'grade_id' => $grade->id,
            'visibility' => 'official',
            'name' => 'رياضيات',
            'sort_order' => 1,
            'is_active' => true,
        ]);
        $part = $subject->parts()->first();
        $chapters = collect(['الجمع والطرح', 'الهندسة'])->map(
            fn (string $name, int $index) => Chapter::create([
                'subject_id' => $subject->id,
                'subject_part_id' => $part->id,
                'visibility' => 'official',
                'name' => $name,
                'sort_order' => $index + 1,
                'is_active' => true,
            ])
        )->values();
        $lessons = $chapters->map(
            fn (Chapter $chapter, int $index) => Lesson::create([
                'chapter_id' => $chapter->id,
                'visibility' => 'official',
                'name' => $index === 0 ? 'جمع الأعداد' : 'الأشكال الهندسية',
                'sort_order' => 1,
                'is_active' => true,
            ])
        );
        $questions = $lessons->map(
            fn (Lesson $lesson, int $index) => Question::create([
                'lesson_id' => $lesson->id,
                'visibility' => 'official',
                'question_text' => 'السؤال '.($index + 1),
                'question_type' => 'true_false',
                'option_a' => 'صح',
                'option_b' => 'خطأ',
                'correct_answer' => 'صح',
                'level' => 'easy',
                'sort_order' => 1,
                'is_active' => true,
            ])
        );
        $package = QuestionPackage::create([
            'title' => 'حزمة متعددة',
            'grade_id' => $grade->id,
            'subject_id' => $subject->id,
            'chapter_id' => $chapters[0]->id,
            'lesson_id' => $lessons[0]->id,
            'is_free' => true,
            'is_active' => true,
        ]);
        $package->chapters()->attach($chapters->pluck('id'));
        $package->lessons()->attach($lessons->pluck('id'));
        $package->questions()->attach($questions->pluck('id'));

        return compact('grade', 'subject', 'chapters', 'lessons', 'questions', 'package');
    }
}
