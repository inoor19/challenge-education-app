<?php

namespace App\Filament\Resources\ChallengeSessionResource;

use App\Filament\Resources\ChallengeSessionResource\Pages\EditChallengeSession;
use App\Filament\Resources\ChallengeSessionResource\Pages\ListChallengeSessions;
use App\Models\ChallengeSession;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ChallengeSessionResource extends Resource
{
    protected static ?string $model = ChallengeSession::class;
    protected static ?string $navigationIcon = 'heroicon-o-presentation-chart-bar';
    protected static ?string $navigationLabel = 'جلسات التحدي';
    protected static ?string $modelLabel = 'جلسة تحدي';
    protected static ?string $pluralModelLabel = 'جلسات التحدي';
    protected static ?string $navigationGroup = 'الإدارة';
    protected static ?int $navigationSort = 10;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('teacher.name')->label('المعلم')->disabled(),
            Forms\Components\TextInput::make('grade.name')->label('الصف')->disabled(),
            Forms\Components\TextInput::make('subject.name')->label('المادة')->disabled(),
            Forms\Components\Select::make('status')
                ->label('الحالة')
                ->options([
                    'active' => 'نشطة',
                    'completed' => 'مكتملة',
                    'cancelled' => 'ملغاة',
                ])
                ->required(),
            Forms\Components\TextInput::make('timer_seconds')->label('المؤقت بالثواني')->numeric()->required(),
            Forms\Components\Toggle::make('timer_enabled')->label('المؤقت مفعل'),
            Forms\Components\DateTimePicker::make('started_at')->label('بدأت في'),
            Forms\Components\DateTimePicker::make('ended_at')->label('انتهت في'),
        ])->columns(2);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')->label('#')->sortable(),
                Tables\Columns\TextColumn::make('teacher.name')->label('المعلم')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('grade.name')->label('الصف')->sortable(),
                Tables\Columns\TextColumn::make('subject.name')->label('المادة')->sortable(),
                Tables\Columns\BadgeColumn::make('status')
                    ->label('الحالة')
                    ->formatStateUsing(fn ($state) => match ($state) {
                        'active' => 'نشطة',
                        'completed' => 'مكتملة',
                        'cancelled' => 'ملغاة',
                        default => $state,
                    })
                    ->colors(['success' => 'completed', 'warning' => 'active', 'danger' => 'cancelled']),
                Tables\Columns\TextColumn::make('groups_count')->counts('groups')->label('المجموعات'),
                Tables\Columns\TextColumn::make('challenge_questions_count')->counts('challengeQuestions')->label('الأسئلة'),
                Tables\Columns\TextColumn::make('started_at')->label('البداية')->dateTime('Y-m-d H:i')->sortable(),
            ])
            ->defaultSort('started_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('الحالة')
                    ->options(['active' => 'نشطة', 'completed' => 'مكتملة', 'cancelled' => 'ملغاة']),
            ])
            ->actions([
                Tables\Actions\EditAction::make()->label('إدارة'),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListChallengeSessions::route('/'),
            'edit' => EditChallengeSession::route('/{record}/edit'),
        ];
    }
}
