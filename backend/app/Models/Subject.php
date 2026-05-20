<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Subject extends Model
{
    use HasFactory;

    protected $fillable = ['grade_id', 'created_by_user_id', 'visibility', 'name', 'background_theme', 'sort_order', 'is_active'];

    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    protected static function booted(): void
    {
        static::created(function (Subject $subject) {
            $subject->ensureDefaultParts();
        });
    }

    public function grade(): BelongsTo
    {
        return $this->belongsTo(Grade::class);
    }

    public function chapters(): HasMany
    {
        return $this->hasMany(Chapter::class)->orderBy('sort_order');
    }

    public function parts(): HasMany
    {
        return $this->hasMany(SubjectPart::class)->orderBy('sort_order');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function challengeSessions(): HasMany
    {
        return $this->hasMany(ChallengeSession::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true)->orderBy('sort_order');
    }

    public function scopeVisibleTo($query, User $user)
    {
        return $query->where(function ($query) use ($user) {
            $query->where('visibility', 'official')
                ->orWhere('created_by_user_id', $user->id);
        });
    }

    public function ensureDefaultParts(): void
    {
        foreach ([1 => 'الجزء الأول', 2 => 'الجزء الثاني'] as $number => $name) {
            $this->parts()->firstOrCreate(
                ['part_number' => $number],
                [
                    'name' => $name,
                    'sort_order' => $number,
                    'is_active' => true,
                ]
            );
        }
    }
}
