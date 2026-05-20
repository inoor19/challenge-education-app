<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Grade extends Model
{
    use HasFactory;

    protected $fillable = ['created_by_user_id', 'visibility', 'name', 'sort_order', 'is_active'];

    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    public function subjects(): HasMany
    {
        return $this->hasMany(Subject::class)->orderBy('sort_order');
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
}
