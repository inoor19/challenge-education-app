<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Str;

class SubjectResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'grade_id' => $this->grade_id,
            'name' => $this->name,
            'background_theme' => $this->background_theme,
            'background_image_url' => $this->backgroundImageUrl($request),
            'sort_order' => $this->sort_order,
            'is_active' => $this->is_active,
            'visibility' => $this->visibility,
        ];
    }

    private function backgroundImageUrl(Request $request): ?string
    {
        $theme = $this->background_theme;

        if (! is_string($theme) || trim($theme) === '') {
            return null;
        }

        if (Str::startsWith($theme, ['http://', 'https://'])) {
            return $theme;
        }

        if (! Str::contains($theme, ['/', '.'])) {
            return null;
        }

        return rtrim($request->getSchemeAndHttpHost(), '/').'/storage/'.ltrim($theme, '/');
    }
}
