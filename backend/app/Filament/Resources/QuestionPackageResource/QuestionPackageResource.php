<?php

namespace App\Filament\Resources\QuestionPackageResource;

use App\Filament\Resources\QuestionPackageResource\Pages\ListQuestionPackages;
use App\Filament\Resources\QuestionPackageResource\Pages\CreateQuestionPackage;
use App\Filament\Resources\QuestionPackageResource\Pages\EditQuestionPackage;
use App\Models\Grade;
use App\Models\Chapter;
use App\Models\Lesson;
use App\Models\Question;
use App\Models\QuestionPackage;
use App\Models\Subject;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

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
                ->options(Grade::all()->pluck('name', 'id'))
                ->searchable()
                ->required(),
            Forms\Components\Select::make('subject_id')
                ->label('المادة')
                ->options(Subject::with('grade')->get()->mapWithKeys(fn ($subject) => [
                    $subject->id => "{$subject->grade->name} — {$subject->name}",
                ]))
                ->searchable(),
            Forms\Components\Select::make('chapter_id')
                ->label('الفصل')
                ->options(Chapter::with(['subject.grade', 'subjectPart'])->get()->mapWithKeys(fn ($chapter) => [
                    $chapter->id => "{$chapter->subject->grade->name} — {$chapter->subject->name} — {$chapter->subjectPart?->name} — {$chapter->name}",
                ]))
                ->searchable(),
            Forms\Components\Select::make('lesson_id')
                ->label('الدرس')
                ->options(Lesson::with(['chapter.subject.grade', 'chapter.subjectPart'])->get()->mapWithKeys(fn ($lesson) => [
                    $lesson->id => "{$lesson->chapter->subject->grade->name} — {$lesson->chapter->subject->name} — {$lesson->chapter->subjectPart?->name} — {$lesson->chapter->name} — {$lesson->name}",
                ]))
                ->searchable(),
            Forms\Components\Toggle::make('is_free')
                ->label('مجانية؟')
                ->default(true),
            Forms\Components\TextInput::make('price')
                ->label('السعر')
                ->numeric()
                ->prefix('ر.س')
                ->visible(fn ($get) => !$get('is_free')),
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
            Forms\Components\Select::make('questions')
                ->label('الأسئلة داخل الحزمة')
                ->relationship('questions', 'question_text')
                ->options(Question::where('visibility', 'official')->with(['lesson.chapter.subject.grade', 'lesson.chapter.subjectPart'])->get()->mapWithKeys(fn ($question) => [
                    $question->id => "{$question->lesson->chapter->subject->grade->name} — {$question->lesson->chapter->subject->name} — {$question->lesson->chapter->subjectPart?->name} — {$question->lesson->name} — {$question->question_text}",
                ]))
                ->multiple()
                ->preload()
                ->searchable()
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
}
