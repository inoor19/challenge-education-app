<?php

namespace App\Filament\Resources\QuestionPackageResource\Pages;

use App\Filament\Resources\QuestionPackageResource\QuestionPackageResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListQuestionPackages extends ListRecords
{
    protected static string $resource = QuestionPackageResource::class;

    protected function getHeaderActions(): array
    {
        return [Actions\CreateAction::make()->label('إضافة حزمة أسئلة')];
    }
}
