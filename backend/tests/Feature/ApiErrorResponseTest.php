<?php

namespace Tests\Feature;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class ApiErrorResponseTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Route::get('/api/test-forbidden', fn () => abort(403));
        Route::get('/api/test-specific-forbidden', fn () => abort(403, 'يمكنك تعديل المحتوى الذي أنشأته فقط.'));
        Route::get('/api/test-specific-unprocessable', fn () => abort(422, 'هذا السؤال تم استخدامه بالفعل.'));
        Route::get('/api/test-technical-unprocessable', fn () => abort(422, 'حقل subject_part_id غير صحيح.'));
        Route::get('/api/test-session-expired', fn () => abort(419));
        Route::get('/api/test-too-many-requests', fn () => abort(429));
        Route::get('/api/test-server-error', fn () => throw new \RuntimeException('SQLSTATE developer details'));
        Route::post('/api/test-validation', function (Request $request) {
            $request->validate([
                'groups' => ['required', 'array', 'min:1'],
                'groups.*.name' => ['required', 'string'],
            ]);

            return response()->json([]);
        });
    }

    public function test_api_general_errors_are_arabic_and_safe(): void
    {
        $this->getJson('/api/me')
            ->assertUnauthorized()
            ->assertExactJson(['message' => 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.']);

        $this->getJson('/api/test-forbidden')
            ->assertForbidden()
            ->assertExactJson(['message' => 'لا تملك صلاحية لإتمام هذه العملية.']);

        $this->getJson('/api/missing-route')
            ->assertNotFound()
            ->assertExactJson(['message' => 'لم نتمكن من العثور على البيانات المطلوبة.']);

        $this->getJson('/api/test-session-expired')
            ->assertStatus(419)
            ->assertExactJson(['message' => 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.']);

        $this->getJson('/api/test-too-many-requests')
            ->assertTooManyRequests()
            ->assertExactJson(['message' => 'تم إرسال طلبات كثيرة. انتظر قليلاً ثم حاول مجدداً.']);

        $this->getJson('/api/test-server-error')
            ->assertInternalServerError()
            ->assertExactJson(['message' => 'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.'])
            ->assertJsonMissing(['message' => 'SQLSTATE developer details']);
    }

    public function test_api_keeps_safe_specific_arabic_reasons(): void
    {
        $this->getJson('/api/test-specific-forbidden')
            ->assertForbidden()
            ->assertExactJson(['message' => 'يمكنك تعديل المحتوى الذي أنشأته فقط.']);

        $this->getJson('/api/test-specific-unprocessable')
            ->assertUnprocessable()
            ->assertExactJson(['message' => 'هذا السؤال تم استخدامه بالفعل.']);

        $this->getJson('/api/test-technical-unprocessable')
            ->assertUnprocessable()
            ->assertExactJson(['message' => 'تعذر إتمام العملية بسبب بيانات غير صحيحة.']);
    }

    public function test_validation_errors_use_user_facing_attribute_names(): void
    {
        $response = $this->postJson('/api/test-validation', [
            'groups' => [[]],
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'بيانات غير صحيحة.');

        $this->assertSame(
            'حقل اسم المجموعة مطلوب.',
            $response->json('errors')['groups.0.name'][0],
        );
    }
}
