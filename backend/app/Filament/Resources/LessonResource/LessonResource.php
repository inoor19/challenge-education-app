<?php

namespace App\Filament\Resources\LessonResource;

use App\Models\Chapter;
use App\Models\Lesson;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class LessonResource extends Resource
{
    protected static ?string $model = Lesson::class;
    protected static ?string $navigationIcon = 'heroicon-o-document-text';
    protected static ?string $navigationLabel = 'الدروس';
    protected static ?string $modelLabel = 'درس';
    protected static ?string $pluralModelLabel = 'الدروس';
    protected static ?int $navigationSort = 4;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Select::make('chapter_id')
                ->label('الفصل')
                ->options(
                    Chapter::with(['subject.grade', 'subjectPart'])->get()
                        ->mapWithKeys(fn ($c) => [$c->id => "{$c->subject->grade->name} — {$c->subject->name} — {$c->subjectPart?->name} — {$c->name}"])
                )
                ->required()
                ->searchable(),
            Forms\Components\TextInput::make('name')
                ->label('اسم الدرس')
                ->required()
                ->maxLength(150),
            Forms\Components\TextInput::make('sort_order')
                ->label('الترتيب')
                ->numeric()
                ->default(0),
            Forms\Components\Toggle::make('is_active')
                ->label('مفعل')
                ->default(true),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('chapter.subject.grade.name')->label('الصف')->sortable(),
                Tables\Columns\TextColumn::make('chapter.subject.name')->label('المادة')->sortable(),
                Tables\Columns\TextColumn::make('chapter.subjectPart.name')->label('الجزء')->sortable(),
                Tables\Columns\TextColumn::make('chapter.name')->label('الفصل')->sortable(),
                Tables\Columns\TextColumn::make('name')->label('الدرس')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('questions_count')->label('الأسئلة')->counts('questions'),
                Tables\Columns\IconColumn::make('is_active')->label('مفعل')->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('chapter_id')
                    ->label('الفصل')
                    ->options(Chapter::pluck('name', 'id')),
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
            'index' => \App\Filament\Resources\LessonResource\Pages\ListLessons::route('/'),
            'create' => \App\Filament\Resources\LessonResource\Pages\CreateLesson::route('/create'),
            'edit' => \App\Filament\Resources\LessonResource\Pages\EditLesson::route('/{record}/edit'),
        ];
    }
}
