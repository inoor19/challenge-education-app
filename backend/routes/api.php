<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChallengeController;
use App\Http\Controllers\Api\ChapterController;
use App\Http\Controllers\Api\GradeController;
use App\Http\Controllers\Api\LessonController;
use App\Http\Controllers\Api\PackageController;
use App\Http\Controllers\Api\PurchaseController;
use App\Http\Controllers\Api\QuestionController;
use App\Http\Controllers\Api\SubjectController;
use App\Http\Controllers\Api\TeacherContentController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — ساحة التنافس
|--------------------------------------------------------------------------
*/

// Public auth routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes (Sanctum token required)
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Educational hierarchy
    Route::get('/grades', [GradeController::class, 'index']);
    Route::get('/grades/{grade}/subjects', [GradeController::class, 'subjects']);
    Route::get('/subjects/{subject}/parts', [SubjectController::class, 'parts']);
    Route::get('/subjects/{subject}/chapters', [SubjectController::class, 'chapters']);
    Route::get('/chapters', [ChapterController::class, 'index']);
    Route::get('/lessons', [LessonController::class, 'index']);
    Route::get('/questions', [QuestionController::class, 'index']);

    // Teacher-owned content management
    Route::get('/teacher/grades', [TeacherContentController::class, 'grades']);
    Route::post('/teacher/grades', [TeacherContentController::class, 'storeGrade']);
    Route::patch('/teacher/grades/{grade}', [TeacherContentController::class, 'updateGrade']);
    Route::put('/teacher/grades/{grade}', [TeacherContentController::class, 'updateGrade']);
    Route::delete('/teacher/grades/{grade}', [TeacherContentController::class, 'destroyGrade']);

    Route::get('/teacher/subjects', [TeacherContentController::class, 'subjects']);
    Route::post('/teacher/subjects', [TeacherContentController::class, 'storeSubject']);
    Route::patch('/teacher/subjects/{subject}', [TeacherContentController::class, 'updateSubject']);
    Route::put('/teacher/subjects/{subject}', [TeacherContentController::class, 'updateSubject']);
    Route::delete('/teacher/subjects/{subject}', [TeacherContentController::class, 'destroySubject']);

    Route::post('/teacher/subject-parts', [TeacherContentController::class, 'storeSubjectPart']);

    Route::get('/teacher/chapters', [TeacherContentController::class, 'chapters']);
    Route::post('/teacher/chapters', [TeacherContentController::class, 'storeChapter']);
    Route::patch('/teacher/chapters/{chapter}', [TeacherContentController::class, 'updateChapter']);
    Route::put('/teacher/chapters/{chapter}', [TeacherContentController::class, 'updateChapter']);
    Route::delete('/teacher/chapters/{chapter}', [TeacherContentController::class, 'destroyChapter']);

    Route::get('/teacher/lessons', [TeacherContentController::class, 'lessons']);
    Route::post('/teacher/lessons', [TeacherContentController::class, 'storeLesson']);
    Route::patch('/teacher/lessons/{lesson}', [TeacherContentController::class, 'updateLesson']);
    Route::put('/teacher/lessons/{lesson}', [TeacherContentController::class, 'updateLesson']);
    Route::delete('/teacher/lessons/{lesson}', [TeacherContentController::class, 'destroyLesson']);

    Route::get('/teacher/questions', [TeacherContentController::class, 'questions']);
    Route::post('/teacher/questions', [TeacherContentController::class, 'storeQuestion']);
    Route::patch('/teacher/questions/{question}', [TeacherContentController::class, 'updateQuestion']);
    Route::put('/teacher/questions/{question}', [TeacherContentController::class, 'updateQuestion']);
    Route::delete('/teacher/questions/{question}', [TeacherContentController::class, 'destroyQuestion']);

    // Commercial packages and store purchases
    Route::get('/packages', [PackageController::class, 'index']);
    Route::get('/packages/owned', [PackageController::class, 'owned']);
    Route::get('/packages/suggestions', [PackageController::class, 'suggestions']);
    Route::post('/purchases/verify', [PurchaseController::class, 'verify']);
    Route::post('/purchases/restore', [PurchaseController::class, 'restore']);

    // Challenge sessions
    Route::get('/challenges', [ChallengeController::class, 'index']);
    Route::post('/challenges', [ChallengeController::class, 'store']);
    Route::get('/challenges/{challenge}', [ChallengeController::class, 'show']);
    Route::patch('/challenges/{challenge}', [ChallengeController::class, 'update']);
    Route::delete('/challenges/{challenge}', [ChallengeController::class, 'destroy']);
    Route::post('/challenges/{challenge}/restart', [ChallengeController::class, 'restart']);
    Route::post('/challenges/{challenge}/groups', [ChallengeController::class, 'addGroup']);
    Route::post('/challenges/{challenge}/roll-dice', [ChallengeController::class, 'rollDice']);
    Route::post('/challenges/{challenge}/questions/{question}/mark-correct', [ChallengeController::class, 'markCorrect']);
    Route::post('/challenges/{challenge}/questions/{question}/mark-wrong', [ChallengeController::class, 'markWrong']);
    Route::post('/challenges/{challenge}/groups/{group}/manual-score', [ChallengeController::class, 'manualScore']);
    Route::post('/challenges/{challenge}/complete', [ChallengeController::class, 'complete']);
});
