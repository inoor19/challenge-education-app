<?php

namespace App\Filament\Resources\TeacherPackageResource;

use App\Filament\Resources\TeacherPackageResource\Pages\CreateTeacherPackage;
use App\Filament\Resources\TeacherPackageResource\Pages\EditTeacherPackage;
use App\Filament\Resources\TeacherPackageResource\Pages\ListTeacherPackages;
use App\Models\QuestionPackage;
use App\Models\TeacherPackage;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class TeacherPackageResource extends Resource
{
    protected static ?string $model = TeacherPackage::class;
    protected static ?string $navigationIcon = 'heroicon-o-key';
    protected static ?string $navigationLabel = 'تفعيل حزم المعلمين';
    protected static ?string $modelLabel = 'تفعيل حزمة';
    protected static ?string $pluralModelLabel = 'تفعيل حزم المعلمين';
    protected static ?string $navigationGroup = 'الإدارة';
    protected static ?int $navigationSort = 9;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Select::make('user_id')
                ->label('المعلم')
                ->options(User::where('role', 'teacher')->pluck('name', 'id'))
                ->searchable()
                ->required(),
            Forms\Components\Select::make('question_package_id')
                ->label('الحزمة')
                ->options(QuestionPackage::where('is_active', true)->pluck('title', 'id'))
                ->searchable()
                ->required(),
            Forms\Components\DateTimePicker::make('purchased_at')
                ->label('وقت التفعيل')
                ->default(now())
                ->required(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')->label('المعلم')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('questionPackage.title')->label('الحزمة')->searchable(),
                Tables\Columns\TextColumn::make('purchased_at')->label('وقت التفعيل')->dateTime('Y-m-d H:i')->sortable(),
            ])
            ->actions([
                Tables\Actions\EditAction::make()->label('تعديل'),
                Tables\Actions\DeleteAction::make()->label('إلغاء التفعيل'),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListTeacherPackages::route('/'),
            'create' => CreateTeacherPackage::route('/create'),
            'edit' => EditTeacherPackage::route('/{record}/edit'),
        ];
    }
}
