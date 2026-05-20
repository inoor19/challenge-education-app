<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SubjectPartResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'subject_id' => $this->subject_id,
            'name' => $this->name,
            'part_number' => $this->part_number,
            'sort_order' => $this->sort_order,
            'is_active' => $this->is_active,
        ];
    }
}
