<?php

namespace App\Services;

use App\Models\Question;
use App\Models\QuestionPackage;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

class EntitlementService
{
    public function availablePackages(User $user): Collection
    {
        return QuestionPackage::query()
            ->active()
            ->with(['grade', 'subject', 'chapter', 'lesson', 'chapters.subjectPart', 'lessons.chapter'])
            ->withCount('questions')
            ->get()
            ->map(function (QuestionPackage $package) use ($user) {
                $package->setAttribute('is_owned', $this->ownsPackage($user, $package));

                return $package;
            });
    }

    public function ownedPackages(User $user): Collection
    {
        return QuestionPackage::query()
            ->active()
            ->where(function (Builder $query) use ($user) {
                $query->where('is_free', true)
                    ->orWhereHas('teacherPackages', fn (Builder $teacherPackageQuery) => $teacherPackageQuery->where('user_id', $user->id));
            })
            ->with(['grade', 'subject', 'chapter', 'lesson', 'chapters.subjectPart', 'lessons.chapter'])
            ->withCount('questions')
            ->get();
    }

    public function suggestedPackages(User $user, ?int $gradeId = null, ?int $subjectId = null): Collection
    {
        return QuestionPackage::query()
            ->active()
            ->where('is_free', false)
            ->when($gradeId !== null, fn (Builder $query) => $query->where('grade_id', $gradeId))
            ->when($subjectId !== null, fn (Builder $query) => $query->where('subject_id', $subjectId))
            ->whereDoesntHave('teacherPackages', fn (Builder $query) => $query->where('user_id', $user->id))
            ->with(['grade', 'subject', 'chapter', 'lesson', 'chapters.subjectPart', 'lessons.chapter'])
            ->withCount('questions')
            ->get()
            ->map(function (QuestionPackage $package) {
                $package->setAttribute('is_owned', false);

                return $package;
            });
    }

    public function ownsPackage(User $user, QuestionPackage $package): bool
    {
        if ($package->is_free) {
            return true;
        }

        return $package->teacherPackages()
            ->where('user_id', $user->id)
            ->exists();
    }

    public function accessibleQuestionIds(User $user): Collection
    {
        return Question::query()
            ->active()
            ->where(function (Builder $query) use ($user) {
                $query->where(function (Builder $officialQuery) use ($user) {
                    $officialQuery->where('visibility', 'official')
                        ->whereHas('packages', function (Builder $packageQuery) use ($user) {
                            $packageQuery->where('question_packages.is_active', true)
                                ->where(function (Builder $ownedPackageQuery) use ($user) {
                                    $ownedPackageQuery->where('question_packages.is_free', true)
                                        ->orWhereHas('teacherPackages', fn (Builder $teacherPackageQuery) => $teacherPackageQuery->where('user_id', $user->id));
                                });
                        });
                })->orWhere(function (Builder $privateQuery) use ($user) {
                    $privateQuery->where('visibility', 'private')
                        ->where('created_by_user_id', $user->id);
                });
            })
            ->pluck('questions.id');
    }

    public function restrictQuestions(Builder $query, User $user): Builder
    {
        return $query->whereIn('questions.id', $this->accessibleQuestionIds($user));
    }
}
