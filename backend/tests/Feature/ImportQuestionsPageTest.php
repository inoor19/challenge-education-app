<?php

namespace Tests\Feature;

use App\Filament\Pages\ImportQuestionsPage;
use Illuminate\Support\Facades\Storage;
use ReflectionClass;
use Tests\TestCase;

class ImportQuestionsPageTest extends TestCase
{
    public function test_uploaded_excel_path_can_be_resolved_from_file_upload_array_state(): void
    {
        Storage::fake('public');

        $page = (new ReflectionClass(ImportQuestionsPage::class))->newInstanceWithoutConstructor();
        $method = new \ReflectionMethod(ImportQuestionsPage::class, 'resolveUploadedExcelPath');
        $method->setAccessible(true);

        $path = $method->invoke($page, ['uploads/example.xlsx']);

        $this->assertSame(
            Storage::disk('public')->path('uploads/example.xlsx'),
            $path
        );
    }
}
