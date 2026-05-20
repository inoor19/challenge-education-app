<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthRegistrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_teacher_can_register_and_use_token_for_me_endpoint(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'أحمد المعلم',
            'email' => 'teacher@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'device_name' => 'feature-test',
        ]);

        $response->assertCreated()
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'email', 'role']])
            ->assertJsonPath('user.email', 'teacher@example.com')
            ->assertJsonPath('user.role', 'teacher');

        $this->assertDatabaseHas('users', [
            'email' => 'teacher@example.com',
            'role' => 'teacher',
            'is_active' => true,
        ]);

        $this->withToken($response->json('token'))
            ->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('email', 'teacher@example.com');
    }

    public function test_register_rejects_duplicate_email(): void
    {
        User::factory()->create(['email' => 'teacher@example.com']);

        $this->postJson('/api/register', [
            'name' => 'معلم جديد',
            'email' => 'teacher@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['email']);
    }

    public function test_register_requires_matching_password_confirmation(): void
    {
        $this->postJson('/api/register', [
            'name' => 'معلم جديد',
            'email' => 'teacher@example.com',
            'password' => 'password123',
            'password_confirmation' => 'different123',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['password']);
    }
}
