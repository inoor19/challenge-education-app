<?php

namespace App\Providers\Filament;

use App\Filament\Resources\AppSettingResource\AppSettingResource;
use App\Filament\Resources\ChallengeSessionResource\ChallengeSessionResource;
use App\Filament\Pages\ImportQuestionsPage;
use App\Filament\Resources\ChapterResource\ChapterResource;
use App\Filament\Resources\GradeResource\GradeResource;
use App\Filament\Resources\LessonResource\LessonResource;
use App\Filament\Resources\QuestionResource\QuestionResource;
use App\Filament\Resources\QuestionPackageResource\QuestionPackageResource;
use App\Filament\Resources\ScoreEventResource\ScoreEventResource;
use App\Filament\Resources\StorePurchaseResource\StorePurchaseResource;
use App\Filament\Resources\SubjectResource\SubjectResource;
use App\Filament\Resources\TeacherPackageResource\TeacherPackageResource;
use App\Filament\Resources\UserResource\UserResource;
use Filament\FontProviders\LocalFontProvider;
use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Pages;
use Filament\Pages\Auth\Login;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\View\PanelsRenderHook;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\AuthenticateSession;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login()
            ->colors([
                'primary' => Color::Blue,
            ])
            ->brandName('ساحة التنافس')
            ->brandLogo(asset('logo.png'))
            ->brandLogoHeight('3rem')
            ->renderHook(
                PanelsRenderHook::HEAD_END,
                fn (): string => '<style>.fi-simple-header .fi-logo{height:4.5rem!important}</style>',
                scopes: Login::class,
            )
            ->font('Tajawal', url: asset('css/fonts.css'), provider: LocalFontProvider::class)
            ->resources([
                GradeResource::class,
                SubjectResource::class,
                ChapterResource::class,
                LessonResource::class,
                QuestionResource::class,
                QuestionPackageResource::class,
                UserResource::class,
                TeacherPackageResource::class,
                ChallengeSessionResource::class,
                ScoreEventResource::class,
                StorePurchaseResource::class,
                AppSettingResource::class,
            ])
            ->pages([
                Pages\Dashboard::class,
                ImportQuestionsPage::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ])
            ->navigationGroups([
                'المحتوى التعليمي',
                'الإدارة',
                'الإعدادات',
            ]);
    }
}
