<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'مسؤول النظام',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );

        User::updateOrCreate(
            ['email' => 'teacher@example.com'],
            [
                'name' => 'معلم تجريبي',
                'password' => Hash::make('password'),
                'role' => 'teacher',
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );
    }
}
