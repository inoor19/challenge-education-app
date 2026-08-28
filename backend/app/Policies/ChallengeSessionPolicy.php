<?php

namespace App\Policies;

use App\Models\ChallengeSession;
use App\Models\User;

class ChallengeSessionPolicy
{
    public function view(User $user, ChallengeSession $session): bool
    {
        return $user->isAdmin() || $session->teacher_id === $user->id;
    }

    public function update(User $user, ChallengeSession $session): bool
    {
        return $session->teacher_id === $user->id && $session->status !== 'cancelled';
    }

    public function delete(User $user, ChallengeSession $session): bool
    {
        return $user->isAdmin() || $session->teacher_id === $user->id;
    }
}
