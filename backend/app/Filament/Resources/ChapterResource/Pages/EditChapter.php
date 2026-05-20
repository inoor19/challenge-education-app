<?php

namespace App\Filament\Resources\ChapterResource\Pages;

use App\Filament\Resources\ChapterResource\ChapterResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditChapter extends EditRecord
{
    protected static string $resource = ChapterResource::class;

    protected function getHeaderActions(): array
    {
        return [Actions\DeleteAction::make()->label('حذف')];
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
