<?php

namespace App\Imports;

use App\Services\ExcelImportService;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Imports\HeadingRowFormatter;

class QuestionsImport implements ToCollection, WithHeadingRow
{
    private ExcelImportService $service;

    public array $result = [];

    public function __construct(ExcelImportService $service)
    {
        $this->service = $service;
        HeadingRowFormatter::default('none');
    }

    public function collection(Collection $rows): void
    {
        // Convert Collection of arrays/objects to plain arrays keyed by Arabic headers
        $plainRows = $rows->map(fn ($row) => $row instanceof Collection ? $row->toArray() : (array) $row);

        $this->result = $this->service->import($plainRows);
    }

    public function headingRow(): int
    {
        return 1;
    }
}
