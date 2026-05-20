<?php

namespace App\Filament\Resources\QuestionResource;

use App\Models\Lesson;
use App\Models\Question;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class QuestionResource extends Resource
{
    protected static ?string $model = Question::class;
    protected static ?string $navigationIcon = 'heroicon-o-question-mark-circle';
    protected static ?string $navigationLabel = 'الأسئلة';
    protected static ?string $modelLabel = 'سؤال';
    protected static ?string $pluralModelLabel = 'الأسئلة';
    protected static ?int $navigationSort = 5;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Select::make('lesson_id')
                ->label('الدرس')
                ->options(
                    Lesson::with(['chapter.subject.grade', 'chapter.subjectPart'])->get()
                        ->mapWithKeys(fn ($l) => [
                            $l->id => "{$l->chapter->subject->grade->name} — {$l->chapter->subject->name} — {$l->chapter->subjectPart?->name} — {$l->chapter->name} — {$l->name}"
                        ])
                )
                ->required()
                ->searchable()
                ->columnSpanFull(),
            Forms\Components\Textarea::make('question_text')
                ->label('نص السؤال')
                ->required()
                ->rows(3)
                ->columnSpanFull(),
            Forms\Components\Select::make('question_type')
                ->label('نوع السؤال')
                ->options([
                    'multiple_choice' => 'اختيار من متعدد',
                    'true_false' => 'صح أو خطأ',
                    'text' => 'نصي',
                ])
                ->required()
                ->reactive(),
            Forms\Components\Select::make('level')
                ->label('مستوى السؤال')
                ->options([
                    'easy' => 'سهل',
                    'hard' => 'صعب',
                ])
                ->required(),
            Forms\Components\TextInput::make('option_a')
                ->label('الاختيار الأول (أ)')
                ->visible(fn ($get) => $get('question_type') === 'multiple_choice'),
            Forms\Components\TextInput::make('option_b')
                ->label('الاختيار الثاني (ب)')
                ->visible(fn ($get) => $get('question_type') === 'multiple_choice'),
            Forms\Components\TextInput::make('option_c')
                ->label('الاختيار الثالث (ج)')
                ->visible(fn ($get) => $get('question_type') === 'multiple_choice'),
            Forms\Components\TextInput::make('option_d')
                ->label('الاختيار الرابع (د)')
                ->visible(fn ($get) => $get('question_type') === 'multiple_choice'),
            Forms\Components\TextInput::make('correct_answer')
                ->label('الإجابة الصحيحة')
                ->required(),
            Forms\Components\Textarea::make('explanation')
                ->label('الشرح أو الملاحظة')
                ->rows(2)
                ->columnSpanFull(),
            Forms\Components\TextInput::make('sort_order')
                ->label('رقم السؤال / الترتيب')
                ->numeric(),
            Forms\Components\Toggle::make('is_active')
                ->label('مفعل')
                ->default(true),
        ])->columns(2);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('lesson.chapter.subject.grade.name')->label('الصف')->sortable(),
                Tables\Columns\TextColumn::make('lesson.chapter.subject.name')->label('المادة')->sortable(),
                Tables\Columns\TextColumn::make('lesson.chapter.subjectPart.name')->label('الجزء')->sortable(),
                Tables\Columns\TextColumn::make('lesson.chapter.name')->label('الفصل')->sortable(),
                Tables\Columns\TextColumn::make('lesson.name')->label('الدرس')->sortable(),
                Tables\Columns\TextColumn::make('question_text')->label('السؤال')->limit(60)->searchable(),
                Tables\Columns\BadgeColumn::make('level')
                    ->label('المستوى')
                    ->formatStateUsing(fn ($state) => $state === 'easy' ? 'سهل' : 'صعب')
                    ->colors(['success' => 'easy', 'danger' => 'hard']),
                Tables\Columns\BadgeColumn::make('question_type')
                    ->label('النوع')
                    ->formatStateUsing(fn ($state) => match($state) {
                        'multiple_choice' => 'متعدد',
                        'true_false' => 'صح/خطأ',
                        'text' => 'نصي',
                    }),
                Tables\Columns\IconColumn::make('is_active')->label('مفعل')->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('level')
                    ->label('المستوى')
                    ->options(['easy' => 'سهل', 'hard' => 'صعب']),
                Tables\Filters\SelectFilter::make('question_type')
                    ->label('النوع')
                    ->options([
                        'multiple_choice' => 'اختيار من متعدد',
                        'true_false' => 'صح أو خطأ',
                        'text' => 'نصي',
                    ]),
                Tables\Filters\TernaryFilter::make('is_active')->label('الحالة'),
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
            'index' => \App\Filament\Resources\QuestionResource\Pages\ListQuestions::route('/'),
            'create' => \App\Filament\Resources\QuestionResource\Pages\CreateQuestion::route('/create'),
            'edit' => \App\Filament\Resources\QuestionResource\Pages\EditQuestion::route('/{record}/edit'),
        ];
    }
}
