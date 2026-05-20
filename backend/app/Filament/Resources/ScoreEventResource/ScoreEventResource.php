<?php

namespace App\Filament\Resources\ScoreEventResource;

use App\Filament\Resources\ScoreEventResource\Pages\ListScoreEvents;
use App\Models\ScoreEvent;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ScoreEventResource extends Resource
{
    protected static ?string $model = ScoreEvent::class;
    protected static ?string $navigationIcon = 'heroicon-o-numbered-list';
    protected static ?string $navigationLabel = 'سجل النقاط';
    protected static ?string $modelLabel = 'حدث نقاط';
    protected static ?string $pluralModelLabel = 'سجل النقاط';
    protected static ?string $navigationGroup = 'الإدارة';
    protected static ?int $navigationSort = 11;

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('challenge_session_id')->label('الجلسة')->sortable(),
                Tables\Columns\TextColumn::make('group.name')->label('المجموعة')->searchable(),
                Tables\Columns\BadgeColumn::make('type')
                    ->label('النوع')
                    ->formatStateUsing(fn ($state) => match ($state) {
                        'auto_correct_answer' => 'إجابة صحيحة',
                        'manual_add' => 'إضافة يدوية',
                        'manual_subtract' => 'خصم يدوي',
                        'correction' => 'تصحيح',
                        default => $state,
                    }),
                Tables\Columns\TextColumn::make('points')->label('النقاط')->sortable(),
                Tables\Columns\TextColumn::make('dice_value')->label('النرد'),
                Tables\Columns\TextColumn::make('createdBy.name')->label('بواسطة'),
                Tables\Columns\TextColumn::make('created_at')->label('الوقت')->dateTime('Y-m-d H:i')->sortable(),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => ListScoreEvents::route('/'),
        ];
    }
}
