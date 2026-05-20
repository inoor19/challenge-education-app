<?php

namespace App\Support;

class ContentTextSanitizer
{
    public static function clean(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $text = (string) $value;

        if (! mb_check_encoding($text, 'UTF-8')) {
            $converted = @iconv('UTF-8', 'UTF-8//IGNORE', $text);

            if ($converted === false) {
                $converted = mb_convert_encoding($text, 'UTF-8', 'UTF-8');
            }

            $text = $converted;
        }

        $text = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $text) ?? $text;
        $text = trim($text);

        return $text === '' ? null : $text;
    }
}
