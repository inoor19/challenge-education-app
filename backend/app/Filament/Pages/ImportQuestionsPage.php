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

        $path = storage_path('app/public/' . $this->data['excel_file']);

        $import = new QuestionsImport(app(ExcelImportService::class));

        try {
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
}
