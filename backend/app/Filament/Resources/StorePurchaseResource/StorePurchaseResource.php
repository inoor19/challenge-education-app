<?php

namespace App\Filament\Resources\StorePurchaseResource;

use App\Filament\Resources\StorePurchaseResource\Pages\ListStorePurchases;
use App\Models\StorePurchase;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class StorePurchaseResource extends Resource
{
    protected static ?string $model = StorePurchase::class;
    protected static ?string $navigationIcon = 'heroicon-o-shopping-bag';
    protected static ?string $navigationLabel = 'مشتريات المتاجر';
    protected static ?string $modelLabel = 'عملية شراء';
    protected static ?string $pluralModelLabel = 'مشتريات المتاجر';
    protected static ?string $navigationGroup = 'الإدارة';
    protected static ?int $navigationSort = 12;

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')->label('المعلم')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('questionPackage.title')->label('الحزمة')->searchable(),
                Tables\Columns\BadgeColumn::make('store')->label('المتجر'),
                Tables\Columns\TextColumn::make('product_id')->label('Product ID')->searchable()->limit(40),
                Tables\Columns\TextColumn::make('transaction_id')->label('Transaction')->searchable()->limit(32),
                Tables\Columns\BadgeColumn::make('status')
                    ->label('الحالة')
                    ->colors(['success' => 'verified', 'danger' => 'rejected', 'warning' => 'pending']),
                Tables\Columns\TextColumn::make('verified_at')->label('التحقق')->dateTime('Y-m-d H:i')->sortable(),
                Tables\Columns\TextColumn::make('created_at')->label('الإنشاء')->dateTime('Y-m-d H:i')->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('store')->label('المتجر')->options(['android' => 'Android', 'ios' => 'iOS']),
                Tables\Filters\SelectFilter::make('status')->label('الحالة')->options(['pending' => 'Pending', 'verified' => 'Verified', 'rejected' => 'Rejected']),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListStorePurchases::route('/'),
        ];
    }
}
