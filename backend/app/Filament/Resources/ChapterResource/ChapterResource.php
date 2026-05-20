<?php

namespace App\Filament\Resources\ChapterResource;

use App\Models\Chapter;
use App\Models\Subject;
use App\Models\SubjectPart;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ChapterResource extends Resource
{
    protected static ?string $model = Chapter::class;
    protected static ?string $navigationIcon = 'heroicon-o-folder';
    protected static ?string $navigationLabel = 'الفصول';
    protected static ?string $modelLabel = 'فصل';
    protected static ?string $pluralModelLabel = 'الفصول';
    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Select::make('subject_part_id')
                ->label('جزء المادة')
                ->options(SubjectPart::with('subject.grade')->get()->mapWithKeys(fn ($part) => [
                    $part->id => "{$part->subject->grade->name} — {$part->subject->name} — {$part->name}",
                ]))
                ->required()
                ->searchable(),
            Forms\Components\TextInput::make('name')
                ->label('اسم الفصل')
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
                Tables\Columns\TextColumn::make('subject.grade.name')->label('الصف')->sortable(),
                Tables\Columns\TextColumn::make('subject.name')->label('المادة')->sortable()->searchable(),
                Tables\Columns\TextColumn::make('subjectPart.name')->label('الجزء')->sortable(),
                Tables\Columns\TextColumn::make('name')->label('الفصل')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('lessons_count')->label('الدروس')->counts('lessons'),
                Tables\Columns\TextColumn::make('sort_order')->label('الترتيب')->sortable(),
                Tables\Columns\IconColumn::make('is_active')->label('مفعل')->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('subject_id')
                    ->label('المادة')
                    ->options(Subject::pluck('name', 'id')),
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
            ])
            ->defaultSort('sort_order');
    }

    public static function getPages(): array
    {
        return [
            'index' => \App\Filament\Resources\ChapterResource\Pages\ListChapters::route('/'),
            'create' => \App\Filament\Resources\ChapterResource\Pages\CreateChapter::route('/create'),
            'edit' => \App\Filament\Resources\ChapterResource\Pages\EditChapter::route('/{record}/edit'),
        ];
    }
}
