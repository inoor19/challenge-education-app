<?php

namespace App\Filament\Resources\QuestionPackageResource\Pages;

use App\Filament\Resources\QuestionPackageResource\QuestionPackageResource;
use Filament\Resources\Pages\CreateRecord;

class CreateQuestionPackage extends CreateRecord
{
    protected static string $resource = QuestionPackageResource::class;

    protected function beforeCreate(): void
    {
        QuestionPackageResource::validateContentSelection($this->data);
    }

    protected function afterCreate(): void
    {
        QuestionPackageResource::syncLegacyContent($this->record, $this->data);
    }
}
