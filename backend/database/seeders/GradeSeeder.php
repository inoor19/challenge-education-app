<?php

namespace Database\Seeders;

use App\Models\ChallengeGroup;
use App\Models\ChallengeQuestion;
use App\Models\ChallengeSession;
use App\Models\Chapter;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\QuestionPackage;
use App\Models\ScoreEvent;
use App\Models\Subject;
use App\Models\TeacherPackage;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class GradeSeeder extends Seeder
{
    public function run(): void
    {
        DB::transaction(function () {
            $subjects = $this->seedCurriculum();
            $this->seedPackages($subjects);
            $this->seedDemoChallenge($subjects);
        });
    }

    private function seedCurriculum(): array
    {
        $seededSubjects = [];

        foreach ($this->curriculum() as $gradeIndex => $gradeData) {
            $grade = Grade::updateOrCreate(
                ['name' => $gradeData['name']],
                ['sort_order' => $gradeData['sort_order'], 'is_active' => true]
            );

            foreach ($gradeData['subjects'] as $subjectIndex => $subjectData) {
                $subject = Subject::updateOrCreate(
                    ['grade_id' => $grade->id, 'name' => $subjectData['name']],
                    [
                        'background_theme' => $subjectData['theme'],
                        'sort_order' => $subjectIndex + 1,
                        'is_active' => true,
                    ]
                );
                $subject->ensureDefaultParts();
                $defaultPart = $subject->parts()->where('part_number', 1)->first();

                $seededSubjects[$gradeData['name']][$subjectData['name']] = $subject;

                foreach ($subjectData['chapters'] as $chapterIndex => $chapterData) {
                    $chapter = Chapter::updateOrCreate(
                        ['subject_id' => $subject->id, 'name' => $chapterData['name']],
                        [
                            'subject_part_id' => $defaultPart?->id,
                            'sort_order' => $chapterIndex + 1,
                            'is_active' => true,
                        ]
                    );

                    foreach ($chapterData['lessons'] as $lessonIndex => $lessonName) {
                        $lesson = Lesson::updateOrCreate(
                            ['chapter_id' => $chapter->id, 'name' => $lessonName],
                            ['sort_order' => $lessonIndex + 1, 'is_active' => true]
                        );

                        $this->seedQuestions($lesson, $subjectData['name'], $gradeIndex + 1);
                    }
                }
            }
        }

        return $seededSubjects;
    }

    private function seedQuestions(Lesson $lesson, string $subjectName, int $gradeMultiplier): void
    {
        $questions = [
            [
                'question_text' => "ما الفكرة الأساسية في درس {$lesson->name}؟",
                'question_type' => 'multiple_choice',
                'option_a' => 'فهم المفهوم ثم تطبيقه',
                'option_b' => 'حفظ العنوان فقط',
                'option_c' => 'تجاهل الأمثلة',
                'option_d' => 'اختيار إجابة عشوائية',
                'correct_answer' => 'فهم المفهوم ثم تطبيقه',
                'level' => 'easy',
                'explanation' => 'الفهم ثم التطبيق يساعدان الطالب على حل أسئلة التحدي بثقة.',
            ],
            [
                'question_text' => "أي اختيار يناسب مراجعة {$subjectName} قبل التحدي؟",
                'question_type' => 'multiple_choice',
                'option_a' => 'قراءة السؤال بعناية',
                'option_b' => 'تخطي المعطيات',
                'option_c' => 'الإجابة قبل التفكير',
                'option_d' => 'نسيان خطوات الحل',
                'correct_answer' => 'قراءة السؤال بعناية',
                'level' => 'easy',
                'explanation' => 'قراءة السؤال بعناية تكشف المطلوب وتقلل الأخطاء.',
            ],
            [
                'question_text' => "إذا تغيّرت معطيات مسألة من درس {$lesson->name}، فما أفضل تصرف؟",
                'question_type' => 'multiple_choice',
                'option_a' => 'تطبيق القاعدة المناسبة على المعطيات الجديدة',
                'option_b' => 'استخدام الإجابة القديمة كما هي',
                'option_c' => 'ترك السؤال بلا محاولة',
                'option_d' => 'اختيار أول إجابة متاحة',
                'correct_answer' => 'تطبيق القاعدة المناسبة على المعطيات الجديدة',
                'level' => 'hard',
                'explanation' => 'الأسئلة الصعبة تختبر نقل الفكرة إلى موقف جديد.',
            ],
            [
                'question_text' => "يمكن حل أسئلة {$lesson->name} بصورة أفضل عند تحديد المطلوب أولا.",
                'question_type' => 'true_false',
                'option_a' => 'صح',
                'option_b' => 'خطأ',
                'option_c' => null,
                'option_d' => null,
                'correct_answer' => 'صح',
                'level' => 'easy',
                'explanation' => 'تحديد المطلوب ينظم التفكير قبل الحل.',
            ],
            [
                'question_text' => "اكتب مثالا قصيرا يوضح ما تعلمته في درس {$lesson->name}.",
                'question_type' => 'text',
                'option_a' => null,
                'option_b' => null,
                'option_c' => null,
                'option_d' => null,
                'correct_answer' => "مثال صحيح مرتبط بدرس {$lesson->name} مع شرح خطوة الحل.",
                'level' => $gradeMultiplier === 1 ? 'hard' : 'easy',
                'explanation' => 'تقبل الإجابة النصية عندما تعرض مثالا صحيحا وسببا واضحا.',
            ],
        ];

        foreach ($questions as $index => $question) {
            Question::updateOrCreate(
                ['lesson_id' => $lesson->id, 'sort_order' => $index + 1],
                array_merge($question, ['is_active' => true])
            );
        }
    }

    private function seedPackages(array $subjects): void
    {
        $teacher = User::where('email', 'teacher@example.com')->first();

        foreach ($subjects as $gradeName => $subjectMap) {
            foreach ($subjectMap as $subjectName => $subject) {
                $questions = Question::whereHas(
                    'lesson.chapter.subject',
                    fn ($query) => $query->whereKey($subject->id)
                )->orderBy('lesson_id')->orderBy('sort_order')->pluck('id');

                $freePackage = QuestionPackage::updateOrCreate(
                    ['title' => "حزمة {$subjectName} {$gradeName} المجانية"],
                    [
                        'description' => "أسئلة تدريبية مجانية لاختبار {$subjectName} في {$gradeName}.",
                        'grade_id' => $subject->grade_id,
                        'subject_id' => $subject->id,
                        'chapter_id' => null,
                        'lesson_id' => null,
                        'is_free' => true,
                        'price' => null,
                        'platform_product_id' => null,
                        'android_product_id' => null,
                        'ios_product_id' => null,
                        'purchase_type' => 'non_consumable',
                        'is_active' => true,
                    ]
                );
                $freePackage->questions()->sync($questions->take(20)->all());

                $paidPackage = QuestionPackage::updateOrCreate(
                    ['title' => "حزمة {$subjectName} {$gradeName} المتقدمة"],
                    [
                        'description' => "حزمة موسعة بأسئلة سهلة وصعبة لاختبار سيناريو الشراء والوصول.",
                        'grade_id' => $subject->grade_id,
                        'subject_id' => $subject->id,
                        'chapter_id' => null,
                        'lesson_id' => null,
                        'is_free' => false,
                        'price' => 19.00,
                        'platform_product_id' => 'demo_' . $subject->id,
                        'android_product_id' => 'challenge_pack_' . $subject->id . '_android',
                        'ios_product_id' => 'challenge_pack_' . $subject->id . '_ios',
                        'purchase_type' => 'non_consumable',
                        'is_active' => true,
                    ]
                );
                $paidPackage->questions()->sync($questions->all());

                if ($teacher) {
                    TeacherPackage::updateOrCreate(
                        ['user_id' => $teacher->id, 'question_package_id' => $paidPackage->id],
                        ['purchased_at' => now()]
                    );
                }
            }
        }
    }

    private function seedDemoChallenge(array $subjects): void
    {
        $teacher = User::where('email', 'teacher@example.com')->first();
        $subject = $subjects['الصف الثاني']['علوم'] ?? null;

        if (! $teacher || ! $subject) {
            return;
        }

        $grade = $subject->grade;
        $chapters = $subject->chapters()->orderBy('sort_order')->take(2)->get();
        $lessons = Lesson::whereIn('chapter_id', $chapters->pluck('id'))
            ->orderBy('chapter_id')
            ->orderBy('sort_order')
            ->get();
        $questions = Question::whereIn('lesson_id', $lessons->pluck('id'))
            ->orderBy('lesson_id')
            ->orderBy('sort_order')
            ->take(12)
            ->get();

        $session = ChallengeSession::updateOrCreate(
            [
                'teacher_id' => $teacher->id,
                'grade_id' => $grade->id,
                'subject_id' => $subject->id,
                'subject_part_id' => $subject->parts()->where('part_number', 1)->value('id'),
                'status' => 'active',
            ],
            [
                'timer_seconds' => 60,
                'timer_enabled' => true,
                'started_at' => now()->subMinutes(15),
                'ended_at' => null,
            ]
        );

        $session->chapters()->sync($chapters->pluck('id')->all());
        $session->lessons()->sync($lessons->pluck('id')->all());

        ScoreEvent::where('challenge_session_id', $session->id)->delete();
        ChallengeQuestion::where('challenge_session_id', $session->id)->delete();
        ChallengeGroup::where('challenge_session_id', $session->id)->delete();

        $groups = collect([
            ['name' => 'فريق الإبداع', 'score' => 0, 'sort_order' => 1],
            ['name' => 'فريق المعرفة', 'score' => 0, 'sort_order' => 2],
            ['name' => 'فريق النجوم', 'score' => 0, 'sort_order' => 3],
        ])->map(fn ($group) => ChallengeGroup::create([
            'challenge_session_id' => $session->id,
            ...$group,
        ]));

        $challengeQuestions = $questions->values()->map(fn ($question, $index) => ChallengeQuestion::create([
            'challenge_session_id' => $session->id,
            'question_id' => $question->id,
            'sequence_number' => $index + 1,
            'is_used' => false,
        ]));

        $this->seedDemoScore($session, $groups->values(), $challengeQuestions->values(), $teacher);
    }

    private function seedDemoScore(ChallengeSession $session, $groups, $challengeQuestions, User $teacher): void
    {
        if ($groups->count() < 3 || $challengeQuestions->count() < 3) {
            return;
        }

        $firstQuestion = $challengeQuestions[0];
        $secondQuestion = $challengeQuestions[1];
        $thirdQuestion = $challengeQuestions[2];

        $firstQuestion->markAsUsed($groups[0]->id, 3, 3, 'correct');
        $groups[0]->increment('score', 3);
        ScoreEvent::create([
            'challenge_session_id' => $session->id,
            'group_id' => $groups[0]->id,
            'question_id' => $firstQuestion->question_id,
            'type' => 'auto_correct_answer',
            'points' => 3,
            'dice_value' => 3,
            'question_level' => 'easy',
            'note' => 'إجابة صحيحة ضمن بيانات التجربة.',
            'created_by' => $teacher->id,
        ]);

        $secondQuestion->markAsUsed($groups[1]->id, 2, 0, 'wrong');

        $thirdQuestion->markAsUsed($groups[1]->id, 2, 4, 'correct');
        $groups[1]->increment('score', 4);
        ScoreEvent::create([
            'challenge_session_id' => $session->id,
            'group_id' => $groups[1]->id,
            'question_id' => $thirdQuestion->question_id,
            'type' => 'auto_correct_answer',
            'points' => 4,
            'dice_value' => 2,
            'question_level' => 'hard',
            'note' => 'سؤال صعب بنقاط مضاعفة.',
            'created_by' => $teacher->id,
        ]);

        $groups[2]->increment('score', 2);
        ScoreEvent::create([
            'challenge_session_id' => $session->id,
            'group_id' => $groups[2]->id,
            'type' => 'manual_add',
            'points' => 2,
            'note' => 'نقاط مشاركة تجريبية.',
            'created_by' => $teacher->id,
        ]);

        $groups[0]->decrement('score', 1);
        ScoreEvent::create([
            'challenge_session_id' => $session->id,
            'group_id' => $groups[0]->id,
            'type' => 'manual_subtract',
            'points' => -1,
            'note' => 'خصم تجريبي لاختبار سجل النقاط.',
            'created_by' => $teacher->id,
        ]);
    }

    private function curriculum(): array
    {
        return [
            [
                'name' => 'الصف الثاني',
                'sort_order' => 2,
                'subjects' => [
                    [
                        'name' => 'علوم',
                        'theme' => 'science',
                        'chapters' => [
                            ['name' => 'الفصل الأول: المادة والطاقة', 'lessons' => ['المادة وخصائصها', 'حالات المادة']],
                            ['name' => 'الفصل الثاني: الكائنات الحية', 'lessons' => ['النباتات من حولنا', 'الحيوانات وبيئاتها']],
                        ],
                    ],
                    [
                        'name' => 'رياضيات',
                        'theme' => 'math',
                        'chapters' => [
                            ['name' => 'الفصل الأول: الأعداد', 'lessons' => ['القيمة المنزلية', 'المقارنة والترتيب']],
                            ['name' => 'الفصل الثاني: العمليات', 'lessons' => ['الجمع بإعادة التجميع', 'الطرح بإعادة التجميع']],
                        ],
                    ],
                ],
            ],
            [
                'name' => 'الصف الثالث',
                'sort_order' => 3,
                'subjects' => [
                    [
                        'name' => 'علوم',
                        'theme' => 'science',
                        'chapters' => [
                            ['name' => 'الفصل الأول: الأرض والفضاء', 'lessons' => ['طبقات الأرض', 'دورة الماء']],
                            ['name' => 'الفصل الثاني: القوى والحركة', 'lessons' => ['القوة وتأثيرها', 'الاحتكاك والحركة']],
                        ],
                    ],
                    [
                        'name' => 'رياضيات',
                        'theme' => 'math',
                        'chapters' => [
                            ['name' => 'الفصل الأول: الضرب', 'lessons' => ['مفهوم الضرب', 'حقائق الضرب']],
                            ['name' => 'الفصل الثاني: القسمة', 'lessons' => ['مفهوم القسمة', 'القسمة والباقي']],
                        ],
                    ],
                ],
            ],
        ];
    }
}
