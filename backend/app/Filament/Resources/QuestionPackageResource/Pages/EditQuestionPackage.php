<?php

namespace App\Filament\Resources\QuestionPackageResource\Pages;

use App\Filament\Resources\QuestionPackageResource\QuestionPackageResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditQuestionPackage extends EditRecord
{
    protected static string $resource = QuestionPackageResource::class;

    protected function getHeaderActions(): array
    {
        return [Actions\DeleteAction::make()->label('حذف')];
    }

    protected function beforeSave(): void
    {
        QuestionPackageResource::validateContentSelection($this->data);
    }

    protected function afterSave(): void
    {
        QuestionPackageResource::syncLegacyContent($this->record, $this->data);
    }
}
