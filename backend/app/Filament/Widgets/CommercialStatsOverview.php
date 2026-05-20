<?php

namespace App\Filament\Widgets;

use App\Models\ChallengeSession;
use App\Models\Question;
use App\Models\QuestionPackage;
use App\Models\StorePurchase;
use App\Models\TeacherPackage;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class CommercialStatsOverview extends StatsOverviewWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make('المعلمون', User::where('role', 'teacher')->count())
                ->description('حسابات المعلمين النشطة وغير النشطة'),
            Stat::make('الحزم المفعلة', QuestionPackage::where('is_active', true)->count())
                ->description(TeacherPackage::count() . ' تفعيل للمعلمين'),
            Stat::make('جلسات التحدي', ChallengeSession::count())
                ->description(ChallengeSession::where('status', 'completed')->count() . ' مكتملة'),
            Stat::make('مشتريات موثقة', StorePurchase::where('status', 'verified')->count())
                ->description('من App Store و Google Play'),
            Stat::make('الأسئلة', Question::where('is_active', true)->count())
                ->description('أسئلة متاحة داخل الحزم'),
        ];
    }
}
