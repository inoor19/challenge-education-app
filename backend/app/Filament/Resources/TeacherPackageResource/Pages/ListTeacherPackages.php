<?php

namespace App\Filament\Resources\TeacherPackageResource\Pages;

use App\Filament\Resources\TeacherPackageResource\TeacherPackageResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListTeacherPackages extends ListRecords
{
    protected static string $resource = TeacherPackageResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()->label('تفعيل حزمة'),
        ];
    }
}
