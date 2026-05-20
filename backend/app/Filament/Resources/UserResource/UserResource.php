<?php

namespace App\Filament\Resources\UserResource;

use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Hash;

class UserResource extends Resource
{
    protected static ?string $model = User::class;
    protected static ?string $navigationIcon = 'heroicon-o-users';
    protected static ?string $navigationLabel = 'المعلمون';
    protected static ?string $modelLabel = 'مستخدم';
    protected static ?string $pluralModelLabel = 'المستخدمون';
    protected static ?int $navigationSort = 7;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('name')
                ->label('الاسم')
                ->required()
                ->maxLength(100),
            Forms\Components\TextInput::make('email')
                ->label('البريد الإلكتروني')
                ->email()
                ->required()
                ->unique(ignoreRecord: true),
            Forms\Components\TextInput::make('password')
                ->label('كلمة المرور')
                ->password()
                ->dehydrateStateUsing(fn ($state) => Hash::make($state))
                ->dehydrated(fn ($state) => filled($state))
                ->required(fn (string $context): bool => $context === 'create'),
            Forms\Components\Select::make('role')
                ->label('الدور')
                ->options([
                    'admin' => 'مسؤول',
                    'teacher' => 'معلم',
                ])
                ->required()
                ->default('teacher'),
            Forms\Components\Toggle::make('is_active')
                ->label('مفعل')
                ->default(true),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')->label('الاسم')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('email')->label('البريد')->searchable(),
                Tables\Columns\BadgeColumn::make('role')
                    ->label('الدور')
                    ->formatStateUsing(fn ($state) => $state === 'admin' ? 'مسؤول' : 'معلم')
                    ->colors(['warning' => 'admin', 'primary' => 'teacher']),
                Tables\Columns\IconColumn::make('is_active')->label('مفعل')->boolean(),
                Tables\Columns\TextColumn::make('created_at')->label('تاريخ الإنشاء')->dateTime('Y-m-d')->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('role')
                    ->label('الدور')
                    ->options(['admin' => 'مسؤول', 'teacher' => 'معلم']),
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
            'index' => \App\Filament\Resources\UserResource\Pages\ListUsers::route('/'),
            'create' => \App\Filament\Resources\UserResource\Pages\CreateUser::route('/create'),
            'edit' => \App\Filament\Resources\UserResource\Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
