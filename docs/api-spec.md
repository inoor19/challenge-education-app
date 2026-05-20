# API Specification — ساحة التحدي التعليمي

## Base URL
```
http://localhost:8000/api
```

## Authentication
All endpoints (except `/login`) require:
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

---

## Auth Endpoints

### POST `/login`
Login and obtain a Sanctum token.

**Request:**
```json
{
  "email": "teacher@example.com",
  "password": "password",
  "device_name": "flutter-app"
}
```

**Response 200:**
```json
{
  "token": "1|abc123...",
  "user": {
    "id": 2,
    "name": "معلم تجريبي",
    "email": "teacher@example.com",
    "role": "teacher"
  }
}
```

---

### POST `/logout`
Revoke the current token.

**Response 200:**
```json
{ "message": "تم تسجيل الخروج بنجاح." }
```

---

### GET `/me`
Get the authenticated user.

**Response 200:**
```json
{
  "id": 2,
  "name": "معلم تجريبي",
  "email": "teacher@example.com",
  "role": "teacher"
}
```

---

## Educational Data Endpoints

### GET `/grades`
**Response 200:**
```json
[
  { "id": 1, "name": "الصف الثاني", "sort_order": 2, "is_active": true }
]
```

---

### GET `/grades/{id}/subjects`
**Response 200:**
```json
[
  { "id": 1, "grade_id": 1, "name": "علوم", "background_theme": null, "sort_order": 1, "is_active": true }
]
```

---

### GET `/subjects/{id}/chapters`
**Response 200:**
```json
[
  { "id": 1, "subject_id": 1, "name": "الفصل الأول", "sort_order": 1, "is_active": true }
]
```

---

### GET `/chapters?subject_id=1`
Same as above but via query param.

---

### GET `/lessons?chapter_ids[]=1&chapter_ids[]=2`
**Response 200:**
```json
[
  { "id": 1, "chapter_id": 1, "name": "الدرس الأول: المادة وخصائصها", "sort_order": 1, "is_active": true },
  { "id": 2, "chapter_id": 1, "name": "الدرس الثاني: حالات المادة", "sort_order": 2, "is_active": true }
]
```

---

### GET `/questions?lesson_ids[]=1&lesson_ids[]=2`
**Response 200:**
```json
[
  {
    "id": 1,
    "lesson_id": 1,
    "question_text": "ما هي وحدة قياس الكتلة في النظام الدولي؟",
    "question_type": "multiple_choice",
    "option_a": "كيلوغرام",
    "option_b": "غرام",
    "option_c": "طن",
    "option_d": "ميلليغرام",
    "correct_answer": "كيلوغرام",
    "level": "easy",
    "explanation": null,
    "sort_order": 1
  }
]
```

---

## Challenge Endpoints

### POST `/challenges`
Create a new challenge session.

**Request:**
```json
{
  "grade_id": 1,
  "subject_id": 1,
  "chapter_ids": [1],
  "lesson_ids": [1, 2],
  "question_ids": [1, 3],
  "timer_seconds": 60,
  "timer_enabled": true
}
```

`question_ids` is optional. When omitted, the session includes all accessible active questions from the selected lessons.

**Response 201:**
```json
{
  "id": 1,
  "grade": { "id": 1, "name": "الصف الثاني" },
  "subject": { "id": 1, "name": "علوم" },
  "chapters": [...],
  "lessons": [...],
  "timer_seconds": 60,
  "timer_enabled": true,
  "status": "active",
  "started_at": "2024-01-01T10:00:00.000Z",
  "groups": [],
  "questions": [
    { "id": 1, "sequence_number": 1, "is_used": false, "question": {...} }
  ]
}
```

---

### GET `/challenges/{id}`
Get full challenge session with groups and questions.

---

### POST `/challenges/{id}/groups`
Add a group to the challenge.

**Request:**
```json
{ "name": "المجموعة الأولى", "sort_order": 0 }
```

**Response 201:**
```json
{ "id": 1, "challenge_session_id": 1, "name": "المجموعة الأولى", "score": 0, "sort_order": 0 }
```

---

### POST `/challenges/{id}/roll-dice`
Roll the luck dice.

**Response 200:**
```json
{ "dice_value": 2 }
```

---

### POST `/challenges/{id}/questions/{challengeQuestionId}/mark-correct`
Mark question as correctly answered and award points.

**Request:**
```json
{ "group_id": 1, "dice_value": 2 }
```

**Response 200:**
```json
{
  "points_awarded": 4,
  "group": { "id": 1, "name": "المجموعة الأولى", "score": 4 },
  "groups": [
    { "id": 1, "name": "المجموعة الأولى", "score": 4 },
    { "id": 2, "name": "المجموعة الثانية", "score": 0 }
  ]
}
```

> **Scoring rule:** if question level is `hard`, points = dice × 2. If `easy`, points = dice.

---

### POST `/challenges/{id}/questions/{challengeQuestionId}/mark-wrong`
Mark question as wrong. No points awarded.

**Request:**
```json
{ "group_id": 1, "dice_value": 2 }
```

**Response 200:**
```json
{ "message": "تم تسجيل إجابة خاطئة." }
```

---

### POST `/challenges/{id}/groups/{groupId}/manual-score`
Manually adjust a group's score.

**Request (add points):**
```json
{ "type": "add", "points": 3, "note": "مكافأة" }
```

**Request (subtract points):**
```json
{ "type": "subtract", "points": 2, "note": "خصم" }
```

**Request (set exact score):**
```json
{ "type": "correction", "score": 10, "note": "تصحيح" }
```

**Response 200:**
```json
{
  "group": { "id": 1, "name": "المجموعة الأولى", "score": 7 },
  "groups": [...]
}
```

---

### POST `/challenges/{id}/complete`
Mark the challenge as completed.

**Response 200:**
```json
{
  "id": 1,
  "status": "completed",
  "ended_at": "2024-01-01T10:35:00.000Z"
}
```

---

## Error Responses

### 401 Unauthorized
```json
{ "message": "غير مصرح. يرجى تسجيل الدخول." }
```

### 422 Validation Error
```json
{
  "message": "بيانات غير صحيحة.",
  "errors": {
    "email": ["البريد الإلكتروني مطلوب."]
  }
}
```

### 404 Not Found
```json
{ "message": "السجل غير موجود." }
```

### 403 Forbidden
```json
{ "message": "This action is unauthorized." }
```
