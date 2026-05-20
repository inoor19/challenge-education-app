<?php

namespace App\Filament\Resources\GradeResource;

use App\Models\Grade;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class GradeResource extends Resource
{
    protected static ?string $model = Grade::class;
    protected static ?string $navigationIcon = 'heroicon-o-academic-cap';
    protected static ?string $navigationLabel = 'الصفوف الدراسية';
    protected static ?string $modelLabel = 'صف دراسي';
    protected static ?string $pluralModelLabel = 'الصفوف الدراسية';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('name')
                ->label('اسم الصف')
                ->required()
                ->maxLength(100),
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
                Tables\Columns\TextColumn::make('name')->label('الصف')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('sort_order')->label('الترتيب')->sortable(),
                Tables\Columns\IconColumn::make('is_active')->label('مفعل')->boolean(),
                Tables\Columns\TextColumn::make('subjects_count')
                    ->label('المواد')
                    ->counts('subjects'),
                Tables\Columns\TextColumn::make('created_at')->label('تاريخ الإنشاء')->dateTime('Y-m-d')->sortable(),
            ])
            ->filters([
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

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => \App\Filament\Resources\GradeResource\Pages\ListGrades::route('/'),
            'create' => \App\Filament\Resources\GradeResource\Pages\CreateGrade::route('/create'),
            'edit' => \App\Filament\Resources\GradeResource\Pages\EditGrade::route('/{record}/edit'),
        ];
    }
}
