# Database Schema — ساحة التنافس

## Tables

### `grades`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| name | varchar | e.g. "الصف الثاني" |
| sort_order | smallint | display order |
| is_active | boolean | |
| created_at, updated_at | timestamp | |

---

### `subjects`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| grade_id | FK → grades | |
| name | varchar | |
| background_theme | varchar nullable | color/theme string |
| sort_order | smallint | |
| is_active | boolean | |

---

### `chapters`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| subject_id | FK → subjects | |
| name | varchar | always called "الفصل" |
| sort_order | smallint | |
| is_active | boolean | |

---

### `lessons`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| chapter_id | FK → chapters | |
| name | varchar | |
| sort_order | smallint | |
| is_active | boolean | |

---

### `questions`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| lesson_id | FK → lessons | |
| question_text | text | |
| question_type | enum | multiple_choice, true_false, text |
| option_a–d | varchar nullable | for multiple_choice |
| correct_answer | varchar | |
| level | enum | easy, hard |
| explanation | text nullable | |
| sort_order | smallint nullable | |
| is_active | boolean | |

---

### `users`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| name | varchar | |
| email | varchar unique | |
| password | varchar | hashed |
| role | enum | admin, teacher |
| is_active | boolean | |
| remember_token | varchar | |

---

### `question_packages`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| title | varchar | |
| description | text nullable | |
| grade_id | FK nullable | |
| subject_id | FK nullable | |
| chapter_id | FK nullable | |
| lesson_id | FK nullable | |
| is_free | boolean | |
| price | decimal(8,2) nullable | |
| platform_product_id | varchar nullable | |
| is_active | boolean | |

### `question_package_items`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| question_package_id | FK | |
| question_id | FK | unique per package |

### `teacher_packages`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| user_id | FK → users | |
| question_package_id | FK | unique per teacher |
| purchased_at | timestamp nullable | |

---

### `challenge_sessions`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| teacher_id | FK → users | |
| grade_id | FK | |
| subject_id | FK | |
| timer_seconds | smallint | default 60 |
| timer_enabled | boolean | default true |
| status | enum | active, completed, cancelled |
| started_at | timestamp nullable | |
| ended_at | timestamp nullable | |

### `challenge_session_chapters`
| Column | Type |
|--------|------|
| id | bigint PK |
| challenge_session_id | FK |
| chapter_id | FK |

### `challenge_session_lessons`
| Column | Type |
|--------|------|
| id | bigint PK |
| challenge_session_id | FK |
| lesson_id | FK |

### `challenge_groups`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| challenge_session_id | FK | |
| name | varchar | |
| score | integer | default 0 |
| sort_order | smallint | |

### `challenge_questions`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| challenge_session_id | FK | |
| question_id | FK | |
| sequence_number | smallint | grid position |
| is_used | boolean | |
| used_at | timestamp nullable | |
| selected_group_id | FK nullable | group that answered |
| last_dice_value | tinyint nullable | dice rolled |
| awarded_points | integer nullable | final points |
| answer_status | enum nullable | correct, wrong |

### `score_events`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| challenge_session_id | FK | |
| group_id | FK → challenge_groups | |
| question_id | FK nullable | |
| type | enum | auto_correct_answer, manual_add, manual_subtract, correction |
| points | integer | negative for subtraction |
| dice_value | tinyint nullable | |
| question_level | enum nullable | easy, hard |
| note | text nullable | |
| created_by | FK → users | |

### `app_settings`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| key | varchar unique | e.g. "default_timer_seconds" |
| value | text nullable | |
| type | varchar | string, boolean, integer, json |
| label | varchar nullable | human-readable label |
| description | text nullable | |

---

## Entity Relationships

```
grades ──< subjects ──< chapters ──< lessons ──< questions
                                              └──< question_package_items >── question_packages

users (teachers) ──< challenge_sessions
challenge_sessions >──< chapters (via challenge_session_chapters)
challenge_sessions >──< lessons  (via challenge_session_lessons)
challenge_sessions ──< challenge_groups
challenge_sessions ──< challenge_questions >── questions
challenge_sessions ──< score_events ──> challenge_groups
```
