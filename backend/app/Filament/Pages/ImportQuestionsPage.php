<?php

namespace App\Filament\Pages;

use App\Exports\QuestionsTemplateExport;
use App\Imports\QuestionsImport;
use App\Services\ExcelImportService;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Storage;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class ImportQuestionsPage extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-arrow-up-tray';
    protected static ?string $navigationLabel = 'استيراد Excel';
    protected static ?string $title = 'استيراد الأسئلة من Excel';
    protected static ?int $navigationSort = 8;
    protected static string $view = 'filament.pages.import-questions';

    public ?array $data = [];
    public ?array $importResult = null;

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                FileUpload::make('excel_file')
                    ->label('ملف Excel')
                    ->acceptedFileTypes(['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel'])
                    ->required()
                    ->maxSize(5120),
            ])
            ->statePath('data');
    }

    public function import(): void
    {
        $this->form->validate();

        $import = new QuestionsImport(app(ExcelImportService::class));

        try {
            $path = $this->resolveUploadedExcelPath($this->data['excel_file'] ?? null);

            Excel::import($import, $path);
        } catch (\Throwable $e) {
            $this->importResult = [
                'created' => 0,
                'skipped' => 0,
                'errors' => [['row' => '-', 'error' => $e->getMessage()]],
            ];

            Notification::make()
                ->title('تعذر الاستيراد')
                ->body($e->getMessage())
                ->danger()
                ->send();

            return;
        }

        $this->importResult = $import->result;

        Notification::make()
            ->title('تم الاستيراد')
            ->body("تم إنشاء {$this->importResult['created']} سجل. تم تخطي {$this->importResult['skipped']} سجل.")
            ->success()
            ->send();
    }

    public function downloadTemplate(): BinaryFileResponse
    {
        return Excel::download(new QuestionsTemplateExport(), 'challenge-questions-template.xlsx');
    }

    protected function getFormActions(): array
    {
        return [];
    }

    private function resolveUploadedExcelPath(mixed $fileState): string
    {
        if (is_object($fileState) && method_exists($fileState, 'getRealPath')) {
            $realPath = $fileState->getRealPath();

            if (is_string($realPath) && $realPath !== '') {
                return $realPath;
            }
        }

        $relativePath = $this->firstUploadedPath($fileState);

        if ($relativePath === null) {
            throw new \InvalidArgumentException('لم يتم العثور على ملف Excel المرفوع.');
        }

        if (file_exists($relativePath)) {
            return $relativePath;
        }

        $relativePath = ltrim(str_replace('\\', '/', $relativePath), '/');

        return Storage::disk('public')->path($relativePath);
    }

    private function firstUploadedPath(mixed $fileState): ?string
    {
        if (is_string($fileState) && trim($fileState) !== '') {
            return $fileState;
        }

        if (is_object($fileState) && method_exists($fileState, 'getRealPath')) {
            $realPath = $fileState->getRealPath();

            return is_string($realPath) && $realPath !== '' ? $realPath : null;
        }

        if (! is_array($fileState)) {
            return null;
        }

        foreach ($fileState as $value) {
            $path = $this->firstUploadedPath($value);

            if ($path !== null) {
                return $path;
            }
        }

        return null;
    }
}
