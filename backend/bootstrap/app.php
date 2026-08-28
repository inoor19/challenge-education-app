<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->api(prepend: [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        ]);

        $middleware->alias([
            'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $safeArabicMessage = static function (?string $message): ?string {
            $message = trim((string) $message);

            if ($message === '' || ! preg_match('/[\x{0600}-\x{06FF}]/u', $message)) {
                return null;
            }

            foreach (['Exception', 'SQLSTATE', 'Stack trace', 'vendor/', 'vendor\\', '.php'] as $technicalTerm) {
                if (str_contains($message, $technicalTerm)) {
                    return null;
                }
            }

            if (preg_match('/\b[a-z][a-z0-9]*(?:_[a-z0-9]+)+\b/i', $message)) {
                return null;
            }

            return $message;
        };

        $exceptions->renderable(function (\Illuminate\Auth\AuthenticationException $e, $request) {
            if ($request->is('api/*')) {
                return response()->json(['message' => 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.'], 401);
            }
        });

        $exceptions->renderable(function (\Illuminate\Validation\ValidationException $e, $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => 'بيانات غير صحيحة.',
                    'errors' => $e->errors(),
                ], 422);
            }
        });

        $exceptions->renderable(function (\Illuminate\Database\Eloquent\ModelNotFoundException $e, $request) {
            if ($request->is('api/*')) {
                return response()->json(['message' => 'لم نتمكن من العثور على البيانات المطلوبة.'], 404);
            }
        });

        $exceptions->renderable(function (\Illuminate\Auth\Access\AuthorizationException $e, $request) {
            if ($request->is('api/*')) {
                return response()->json(['message' => 'لا تملك صلاحية لإتمام هذه العملية.'], 403);
            }
        });

        $exceptions->renderable(function (\Symfony\Component\HttpKernel\Exception\HttpExceptionInterface $e, $request) use ($safeArabicMessage) {
            if (! $request->is('api/*')) {
                return null;
            }

            $status = $e->getStatusCode();
            $defaultMessage = match ($status) {
                401, 419 => 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.',
                403 => 'لا تملك صلاحية لإتمام هذه العملية.',
                404 => 'لم نتمكن من العثور على البيانات المطلوبة.',
                422 => 'تعذر إتمام العملية بسبب بيانات غير صحيحة.',
                429 => 'تم إرسال طلبات كثيرة. انتظر قليلاً ثم حاول مجدداً.',
                default => $status >= 500
                    ? 'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.'
                    : 'تعذر إتمام الطلب. يرجى المحاولة مجدداً.',
            };

            $message = $status >= 500
                ? null
                : $safeArabicMessage($e->getMessage());

            return response()->json(['message' => $message ?? $defaultMessage], $status);
        });

        $exceptions->renderable(function (\Throwable $e, $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => 'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
                ], 500);
            }
        });
    })->create();
