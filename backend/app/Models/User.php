<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;

class User extends Authenticatable implements FilamentUser
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'is_active' => 'boolean',
    ];

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isTeacher(): bool
    {
        return $this->role === 'teacher';
    }

    public function challengeSessions(): HasMany
    {
        return $this->hasMany(ChallengeSession::class, 'teacher_id');
    }

    public function teacherPackages(): HasMany
    {
        return $this->hasMany(TeacherPackage::class);
    }

    public function storePurchases(): HasMany
    {
        return $this->hasMany(StorePurchase::class);
    }

    public function createdGrades(): HasMany
    {
        return $this->hasMany(Grade::class, 'created_by_user_id');
    }

    public function createdSubjects(): HasMany
    {
        return $this->hasMany(Subject::class, 'created_by_user_id');
    }

    public function createdQuestions(): HasMany
    {
        return $this->hasMany(Question::class, 'created_by_user_id');
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return $this->isAdmin() && $this->is_active;
    }
}
