<?php

namespace App\Filament\Resources\SubjectResource;

use App\Models\Grade;
use App\Models\Subject;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SubjectResource extends Resource
{
    protected static ?string $model = Subject::class;
    protected static ?string $navigationIcon = 'heroicon-o-book-open';
    protected static ?string $navigationLabel = 'المواد';
    protected static ?string $modelLabel = 'مادة';
    protected static ?string $pluralModelLabel = 'المواد';
    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Select::make('grade_id')
                ->label('الصف الدراسي')
                ->options(Grade::orderBy('sort_order')->pluck('name', 'id'))
                ->required()
                ->searchable(),
            Forms\Components\TextInput::make('name')
                ->label('اسم المادة')
                ->required()
                ->maxLength(100),
            Forms\Components\FileUpload::make('background_theme')
                ->label('خلفية ساحة التنافس')
                ->helperText('ارفع صورة مناسبة للمادة. القيم القديمة مثل science/math ستبقى كخلفيات افتراضية.')
                ->disk('public')
                ->directory('subject-backgrounds')
                ->visibility('public')
                ->image()
                ->acceptedFileTypes(['image/jpeg', 'image/png', 'image/webp'])
                ->imagePreviewHeight('180')
                ->maxSize(4096),
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
                Tables\Columns\TextColumn::make('grade.name')->label('الصف')->sortable()->searchable(),
                Tables\Columns\TextColumn::make('name')->label('المادة')->searchable()->sortable(),
                Tables\Columns\ImageColumn::make('background_theme')
                    ->label('الخلفية')
                    ->getStateUsing(function (Subject $record): ?string {
                        $value = $record->background_theme;

                        if (! is_string($value)) {
                            return null;
                        }

                        return str_contains($value, '/') || str_contains($value, '.')
                            ? $value
                            : null;
                    })
                    ->disk('public')
                    ->height(48)
                    ->width(72),
                Tables\Columns\TextColumn::make('background_theme')
                    ->label('الثيم/المسار')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('sort_order')->label('الترتيب')->sortable(),
                Tables\Columns\IconColumn::make('is_active')->label('مفعل')->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('grade_id')
                    ->label('الصف')
                    ->options(Grade::pluck('name', 'id')),
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
            'index' => \App\Filament\Resources\SubjectResource\Pages\ListSubjects::route('/'),
            'create' => \App\Filament\Resources\SubjectResource\Pages\CreateSubject::route('/create'),
            'edit' => \App\Filament\Resources\SubjectResource\Pages\EditSubject::route('/{record}/edit'),
        ];
    }
}
