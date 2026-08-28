<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChallengeSessionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'grade' => new GradeResource($this->whenLoaded('grade')),
            'grade_section' => $this->grade_section,
            'subject' => new SubjectResource($this->whenLoaded('subject')),
            'subject_part' => new SubjectPartResource($this->whenLoaded('subjectPart')),
            'subject_part_id' => $this->subject_part_id,
            'chapters' => ChapterResource::collection($this->whenLoaded('chapters')),
            'lessons' => LessonResource::collection($this->whenLoaded('lessons')),
            'timer_seconds' => $this->timer_seconds,
            'timer_enabled' => $this->timer_enabled,
            'status' => $this->status,
            'current_turn_group_id' => $this->current_turn_group_id,
            'started_at' => $this->started_at?->toISOString(),
            'ended_at' => $this->ended_at?->toISOString(),
            'groups' => ChallengeGroupResource::collection($this->whenLoaded('groups')),
            'questions' => ChallengeQuestionResource::collection($this->whenLoaded('challengeQuestions')),
        ];
    }
}
