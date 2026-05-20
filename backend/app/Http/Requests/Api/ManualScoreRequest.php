<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class ManualScoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'type' => ['required', 'in:add,subtract,correction'],
            'points' => ['required_if:type,add,subtract', 'nullable', 'integer', 'min:1'],
            'score' => ['required_if:type,correction', 'nullable', 'integer', 'min:0'],
            'note' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'type.required' => 'نوع العملية مطلوب.',
            'type.in' => 'نوع العملية يجب أن يكون: add أو subtract أو correction.',
            'points.required_if' => 'عدد النقاط مطلوب.',
            'score.required_if' => 'النقاط الجديدة مطلوبة لعملية التصحيح.',
        ];
    }
}
