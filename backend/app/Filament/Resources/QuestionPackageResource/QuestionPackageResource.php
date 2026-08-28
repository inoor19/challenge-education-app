<?php

namespace App\Filament\Resources\QuestionPackageResource;

use App\Filament\Resources\QuestionPackageResource\Pages\CreateQuestionPackage;
use App\Filament\Resources\QuestionPackageResource\Pages\EditQuestionPackage;
use App\Filament\Resources\QuestionPackageResource\Pages\ListQuestionPackages;
use App\Models\Chapter;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\QuestionPackage;
use App\Models\Subject;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Get;
use Filament\Forms\Set;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Validation\ValidationException;

class QuestionPackageResource extends Resource
{
    protected static ?string $model = QuestionPackage::class;

    protected static ?string $navigationIcon = 'heroicon-o-archive-box';

    protected static ?string $navigationLabel = 'حزم الأسئلة';

    protected static ?string $modelLabel = 'حزمة أسئلة';

    protected static ?string $pluralModelLabel = 'حزم الأسئلة';

    protected static ?int $navigationSort = 6;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('title')
                ->label('العنوان')
                ->required()
                ->maxLength(255),
            Forms\Components\Textarea::make('description')
                ->label('الوصف')
                ->rows(3),
            Forms\Components\Select::make('grade_id')
                ->label('الصف الدراسي')
                ->options(Grade::query()->orderBy('sort_order')->pluck('name', 'id'))
                ->searchable()
                ->live()
                ->afterStateUpdated(function (Set $set) {
                    $set('subject_id', null);
                    $set('chapters', []);
                    $set('lessons', []);
                    $set('questions', []);
                })
                ->required(),
            Forms\Components\Select::make('subject_id')
                ->label('المادة')
                ->options(fn (Get $get) => Subject::query()
                    ->where('grade_id', $get('grade_id'))
                    ->orderBy('name')
                    ->pluck('name', 'id'))
                ->searchable()
                ->live()
                ->afterStateUpdated(function (Set $set) {
                    $set('chapters', []);
                    $set('lessons', []);
                    $set('questions', []);
                })
                ->required()
                ->disabled(fn (Get $get) => blank($get('grade_id'))),
            Forms\Components\CheckboxList::make('chapters')
                ->label('الفصول داخل الحزمة')
                ->relationship(
                    'chapters',
                    'name',
                    fn ($query, Get $get) => $query
                        ->where('subject_id', $get('subject_id'))
                        ->where('visibility', 'official')
                        ->where('is_active', true)
                        ->with('subjectPart')
                        ->orderBy('subject_part_id')
                        ->orderBy('sort_order')
                )
                ->getOptionLabelFromRecordUsing(fn (Chapter $record) => collect([
                    $record->subjectPart?->name,
                    $record->name,
                ])->filter()->join(' — '))
                ->searchable()
                ->bulkToggleable()
                ->live()
                ->afterStateUpdated(function (?array $state, Get $get, Set $set) {
                    $chapterIds = array_map('intval', $state ?? []);
                    $lessonIds = Lesson::query()
                        ->whereIn('id', $get('lessons') ?? [])
                        ->whereIn('chapter_id', $chapterIds)
                        ->pluck('id')
                        ->map(fn ($id) => (string) $id)
                        ->all();

                    $set('lessons', $lessonIds);
                    $set('questions', Question::query()
                        ->whereIn('id', $get('questions') ?? [])
                        ->whereIn('lesson_id', $lessonIds)
                        ->pluck('id')
                        ->map(fn ($id) => (string) $id)
                        ->all());
                })
                ->required()
                ->minItems(1)
                ->disabled(fn (Get $get) => blank($get('subject_id')))
                ->columns(2)
                ->columnSpanFull(),
            Forms\Components\CheckboxList::make('lessons')
                ->label('الدروس داخل الحزمة')
                ->relationship(
                    'lessons',
                    'name',
                    fn ($query, Get $get) => $query
                        ->whereIn('chapter_id', $get('chapters') ?? [])
                        ->where('visibility', 'official')
                        ->where('is_active', true)
                        ->with('chapter')
                        ->orderBy('chapter_id')
                        ->orderBy('sort_order')
                )
                ->getOptionLabelFromRecordUsing(fn (Lesson $record) => "{$record->chapter->name} — {$record->name}")
                ->searchable()
                ->bulkToggleable()
                ->live()
                ->afterStateUpdated(function (?array $state, Get $get, Set $set) {
                    $lessonIds = array_map('intval', $state ?? []);

                    $set('questions', Question::query()
                        ->whereIn('id', $get('questions') ?? [])
                        ->whereIn('lesson_id', $lessonIds)
                        ->pluck('id')
                        ->map(fn ($id) => (string) $id)
                        ->all());
                })
                ->required()
                ->minItems(1)
                ->disabled(fn (Get $get) => empty($get('chapters')))
                ->columns(2)
                ->columnSpanFull(),
            Forms\Components\Toggle::make('is_free')
                ->label('مجانية؟')
                ->default(true),
            Forms\Components\TextInput::make('price')
                ->label('السعر')
                ->numeric()
                ->prefix('ر.س')
                ->visible(fn ($get) => ! $get('is_free')),
            Forms\Components\TextInput::make('platform_product_id')
                ->label('معرّف المنتج العام')
                ->maxLength(255),
            Forms\Components\TextInput::make('android_product_id')
                ->label('Google Play Product ID')
                ->maxLength(255),
            Forms\Components\TextInput::make('ios_product_id')
                ->label('App Store Product ID')
                ->maxLength(255),
            Forms\Components\Select::make('purchase_type')
                ->label('نوع الشراء')
                ->options(['non_consumable' => 'شراء دائم'])
                ->default('non_consumable')
                ->required(),
            Forms\Components\CheckboxList::make('questions')
                ->label('الأسئلة داخل الحزمة')
                ->relationship(
                    'questions',
                    'question_text',
                    fn ($query, Get $get) => $query
                        ->whereIn('lesson_id', $get('lessons') ?? [])
                        ->where('visibility', 'official')
                        ->where('is_active', true)
                        ->with('lesson.chapter')
                        ->orderBy('lesson_id')
                        ->orderBy('sort_order')
                )
                ->getOptionLabelFromRecordUsing(fn (Question $record) => "{$record->lesson->chapter->name} — {$record->lesson->name} — {$record->question_text}")
                ->searchable()
                ->bulkToggleable()
                ->required()
                ->minItems(1)
                ->disabled(fn (Get $get) => empty($get('lessons')))
                ->columnSpanFull(),
            Forms\Components\Toggle::make('is_active')
                ->label('مفعلة؟')
                ->default(true),
        ])->columns(2);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('grade.name')
                    ->label('الصف الدراسي')
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_free')
                    ->label('مجانية')
                    ->boolean(),
                Tables\Columns\TextColumn::make('price')
                    ->label('السعر')
                    ->money('SAR'),
                Tables\Columns\TextColumn::make('questions_count')
                    ->counts('questions')
                    ->label('عدد الأسئلة'),
                Tables\Columns\TextColumn::make('android_product_id')
                    ->label('Android ID')
                    ->limit(24),
                Tables\Columns\TextColumn::make('ios_product_id')
                    ->label('iOS ID')
                    ->limit(24),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('مفعلة')
                    ->boolean(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('تاريخ الإنشاء')
                    ->dateTime('Y-m-d')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('الحالة'),
                Tables\Filters\TernaryFilter::make('is_free')
                    ->label('مجانية'),
            ])
            ->actions([
                Tables\Actions\EditAction::make()->label('تعديل'),
                Tables\Actions\DeleteAction::make()->label('حذف'),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make()->label('حذف المحدد'),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListQuestionPackages::route('/'),
            'create' => CreateQuestionPackage::route('/create'),
            'edit' => EditQuestionPackage::route('/{record}/edit'),
        ];
    }

    public static function validateContentSelection(array $state): void
    {
        $gradeId = (int) ($state['grade_id'] ?? 0);
        $subjectId = (int) ($state['subject_id'] ?? 0);
        $chapterIds = collect($state['chapters'] ?? [])->map(fn ($id) => (int) $id)->unique()->values();
        $lessonIds = collect($state['lessons'] ?? [])->map(fn ($id) => (int) $id)->unique()->values();
        $questionIds = collect($state['questions'] ?? [])->map(fn ($id) => (int) $id)->unique()->values();
        $errors = [];

        $subjectIsValid = Subject::query()
            ->whereKey($subjectId)
            ->where('grade_id', $gradeId)
            ->exists();

        if (! $subjectIsValid) {
            $errors['subject_id'] = 'يجب أن تتبع المادة الصف الدراسي المحدد.';
        }

        if ($chapterIds->isEmpty()) {
            $errors['chapters'] = 'يجب اختيار فصل واحد على الأقل.';
        } elseif (Chapter::query()
            ->whereIn('id', $chapterIds)
            ->where('subject_id', $subjectId)
            ->where('visibility', 'official')
            ->where('is_active', true)
            ->count() !== $chapterIds->count()) {
            $errors['chapters'] = 'كل الفصول المختارة يجب أن تكون فصولًا رسمية مفعلة تابعة للمادة المحددة.';
        }

        if ($lessonIds->isEmpty()) {
            $errors['lessons'] = 'يجب اختيار درس واحد على الأقل.';
        } elseif (Lesson::query()
            ->whereIn('id', $lessonIds)
            ->whereIn('chapter_id', $chapterIds)
            ->where('visibility', 'official')
            ->where('is_active', true)
            ->count() !== $lessonIds->count()) {
            $errors['lessons'] = 'كل الدروس المختارة يجب أن تكون دروسًا رسمية مفعلة تابعة للفصول المحددة.';
        }

        if ($questionIds->isEmpty()) {
            $errors['questions'] = 'يجب اختيار سؤال واحد على الأقل.';
        } elseif (Question::query()
            ->whereIn('id', $questionIds)
            ->whereIn('lesson_id', $lessonIds)
            ->where('visibility', 'official')
            ->where('is_active', true)
            ->count() !== $questionIds->count()) {
            $errors['questions'] = 'كل الأسئلة المختارة يجب أن تكون أسئلة رسمية مفعلة تابعة للدروس المحددة.';
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }
    }

    public static function syncLegacyContent(QuestionPackage $package, array $state): void
    {
        $package->forceFill([
            'chapter_id' => collect($state['chapters'] ?? [])->map(fn ($id) => (int) $id)->first(),
            'lesson_id' => collect($state['lessons'] ?? [])->map(fn ($id) => (int) $id)->first(),
        ])->saveQuietly();
    }
}
