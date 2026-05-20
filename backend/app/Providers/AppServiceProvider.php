<?php

namespace App\Providers;

use App\Models\ChallengeSession;
use App\Policies\ChallengeSessionPolicy;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        JsonResource::withoutWrapping();

        Gate::policy(ChallengeSession::class, ChallengeSessionPolicy::class);
    }
}
