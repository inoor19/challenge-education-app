<x-filament-panels::page>
    <div class="space-y-6">
        <div class="bg-white rounded-xl shadow p-6">
            <h2 class="text-lg font-bold text-gray-800 mb-4">استيراد الأسئلة من ملف Excel</h2>
            <p class="text-sm text-gray-600 mb-4">
                قم بتحميل ملف Excel يحتوي على الأسئلة وفق النموذج المطلوب. سيتم إنشاء الصفوف والمواد والفصول والدروس تلقائياً إذا لم تكن موجودة.
            </p>

            <div class="bg-blue-50 rounded-lg p-4 mb-6 text-sm text-blue-800">
                <strong>الأعمدة المطلوبة:</strong>
                الصف الدراسي · المادة · الجزء · الفصل · الدرس · رقم السؤال · نص السؤال · نوع السؤال · الاختيار الأول-الرابع · الإجابة الصحيحة · مستوى السؤال · الشرح أو الملاحظة · مفعل؟
                <div class="mt-2">
                    <strong>قيم الجزء المقبولة:</strong>
                    الجزء الأول · الجزء الثاني · الأول · الثاني · 1 · 2
                </div>
            </div>

            {{ $this->form }}

            <div class="mt-4">
                <x-filament::button wire:click="downloadTemplate" color="gray" size="lg">
                    تحميل قالب Excel
                </x-filament::button>
                <x-filament::button wire:click="import" color="primary" size="lg">
                    استيراد الملف
                </x-filament::button>
            </div>
        </div>

        @if($importResult)
        <div class="bg-white rounded-xl shadow p-6">
            <h3 class="text-md font-bold text-gray-800 mb-4">نتيجة الاستيراد</h3>
            <div class="grid grid-cols-3 gap-4 mb-4">
                <div class="bg-green-50 rounded-lg p-4 text-center">
                    <div class="text-3xl font-bold text-green-700">{{ $importResult['created'] }}</div>
                    <div class="text-sm text-green-600 mt-1">سجل تم إنشاؤه</div>
                </div>
                <div class="bg-yellow-50 rounded-lg p-4 text-center">
                    <div class="text-3xl font-bold text-yellow-700">{{ $importResult['skipped'] }}</div>
                    <div class="text-sm text-yellow-600 mt-1">سجل تم تخطيه</div>
                </div>
                <div class="bg-red-50 rounded-lg p-4 text-center">
                    <div class="text-3xl font-bold text-red-700">{{ count($importResult['errors']) }}</div>
                    <div class="text-sm text-red-600 mt-1">خطأ</div>
                </div>
            </div>

            @if(count($importResult['errors']) > 0)
            <div class="border border-red-200 rounded-lg overflow-hidden">
                <table class="w-full text-sm">
                    <thead class="bg-red-50">
                        <tr>
                            <th class="text-right px-4 py-2 text-red-700">الصف</th>
                            <th class="text-right px-4 py-2 text-red-700">الخطأ</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($importResult['errors'] as $error)
                        <tr class="border-t border-red-100">
                            <td class="px-4 py-2">{{ $error['row'] }}</td>
                            <td class="px-4 py-2 text-red-600">{{ $error['error'] }}</td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            @endif
        </div>
        @endif
    </div>
</x-filament-panels::page>
