<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="rtl">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>{{ config('app.name', 'ساحة التنافس') }}</title>
        <link rel="icon" href="{{ asset('favicon.ico') }}">
        <style>
            body {
                margin: 0;
                min-height: 100vh;
                display: grid;
                place-items: center;
                font-family: Tahoma, Arial, sans-serif;
                background: #f8fafc;
                color: #111827;
            }

            main {
                width: min(92vw, 720px);
                padding: 40px 24px;
                text-align: center;
            }

            h1 {
                margin: 0 0 12px;
                font-size: clamp(2rem, 6vw, 4rem);
                line-height: 1.15;
            }

            .logo {
                width: 132px;
                height: 132px;
                object-fit: contain;
                margin: 0 auto 20px;
            }

            p {
                margin: 0 auto 28px;
                max-width: 560px;
                color: #4b5563;
                font-size: 1.1rem;
                line-height: 1.8;
            }

            a {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                min-height: 44px;
                padding: 0 18px;
                border-radius: 8px;
                background: #1d4ed8;
                color: white;
                font-weight: 700;
                text-decoration: none;
            }
        </style>
    </head>
    <body>
        <main>
            <img class="logo" src="{{ asset('logo.png') }}" alt="{{ config('app.name', 'ساحة التنافس') }}">
            <h1>{{ config('app.name', 'ساحة التنافس') }}</h1>
            <p>منصة عربية لإدارة المحتوى التعليمي وتشغيل منافسات تفاعلية داخل الصف.</p>
            @if (Route::has('filament.admin.pages.dashboard'))
                <a href="{{ route('filament.admin.pages.dashboard') }}">الدخول إلى لوحة الإدارة</a>
            @else
                <a href="/admin">الدخول إلى لوحة الإدارة</a>
            @endif
        </main>
    </body>
</html>
