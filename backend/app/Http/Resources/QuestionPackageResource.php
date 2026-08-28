<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuestionPackageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'grade' => new GradeResource($this->whenLoaded('grade')),
            'subject' => new SubjectResource($this->whenLoaded('subject')),
            'chapter' => new ChapterResource($this->whenLoaded('chapter')),
            'lesson' => new LessonResource($this->whenLoaded('lesson')),
            'chapters' => ChapterResource::collection($this->whenLoaded('chapters')),
            'lessons' => LessonResource::collection($this->whenLoaded('lessons')),
            'is_free' => $this->is_free,
            'price' => $this->price,
            'platform_product_id' => $this->platform_product_id,
            'android_product_id' => $this->android_product_id,
            'ios_product_id' => $this->ios_product_id,
            'purchase_type' => $this->purchase_type,
            'is_active' => $this->is_active,
            'questions_count' => $this->whenCounted('questions'),
            'is_owned' => (bool) ($this->is_owned ?? $this->is_free),
        ];
    }
}
