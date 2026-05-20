<?php

namespace App\Filament\Resources\ChapterResource\Pages;

use App\Filament\Resources\ChapterResource\ChapterResource;
use Filament\Resources\Pages\CreateRecord;

class CreateChapter extends CreateRecord
{
    protected static string $resource = ChapterResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
