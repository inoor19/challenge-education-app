<?php

namespace App\Filament\Resources\AppSettingResource;

use App\Filament\Resources\AppSettingResource\Pages\CreateAppSetting;
use App\Filament\Resources\AppSettingResource\Pages\EditAppSetting;
use App\Filament\Resources\AppSettingResource\Pages\ListAppSettings;
use App\Models\AppSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class AppSettingResource extends Resource
{
    protected static ?string $model = AppSetting::class;
    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';
    protected static ?string $navigationLabel = 'إعدادات التطبيق';
    protected static ?string $modelLabel = 'إعداد';
    protected static ?string $pluralModelLabel = 'إعدادات التطبيق';
    protected static ?string $navigationGroup = 'الإعدادات';
    protected static ?int $navigationSort = 20;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('key')->label('المفتاح')->required()->unique(ignoreRecord: true),
            Forms\Components\TextInput::make('label')->label('العنوان')->maxLength(255),
            Forms\Components\Select::make('type')
                ->label('النوع')
                ->options([
                    'string' => 'نص',
                    'integer' => 'رقم صحيح',
                    'boolean' => 'منطقي',
                    'json' => 'JSON',
                ])
                ->required()
                ->default('string'),
            Forms\Components\Textarea::make('value')->label('القيمة')->required()->rows(3),
            Forms\Components\Textarea::make('description')->label('الوصف')->rows(2)->columnSpanFull(),
        ])->columns(2);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('key')->label('المفتاح')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('label')->label('العنوان')->searchable(),
                Tables\Columns\BadgeColumn::make('type')->label('النوع'),
                Tables\Columns\TextColumn::make('value')->label('القيمة')->limit(60),
                Tables\Columns\TextColumn::make('updated_at')->label('آخر تحديث')->dateTime('Y-m-d H:i')->sortable(),
            ])
            ->actions([
                Tables\Actions\EditAction::make()->label('تعديل'),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAppSettings::route('/'),
            'create' => CreateAppSetting::route('/create'),
            'edit' => EditAppSetting::route('/{record}/edit'),
        ];
    }
}
