# System Overview — ساحة التحدي التعليمي

## Idea

**ساحة التحدي التعليمي** is a classroom-based educational competition platform.
Teachers use a Flutter tablet/phone app to run live quiz challenges between student groups.
Questions are pre-loaded through a Laravel admin panel or imported from Excel.

---

## User Roles

| Role | Access |
|------|--------|
| **Admin** | Filament admin dashboard (full content management) |
| **Teacher** | Flutter mobile app (run challenges only) |

---

## Educational Hierarchy

```
الصف الدراسي (Grade)
  └── المادة (Subject)
        └── الفصل (Chapter)       ← always "فصل", never "وحدة"
              └── الدرس (Lesson)
                    └── السؤال (Question)
```

---

## Teacher Workflow

```
1. Login (Sanctum token)
2. Select الصف الدراسي
3. Select المادة
4. Select one or more الفصول (multi-select)
5. Select one or more الدروس (multi-select)
6. Set up groups (minimum 2)
7. Configure timer (default 60s, can disable)
8. Enter ساحة التحدي
9. Roll dice (نقاط الحظ) — returns 1, 2, or 3
10. Tap a question number from the grid
11. Read the question to students
12. Mark answer: صحيحة or خاطئة
    - Correct: points awarded automatically
    - Wrong: no points, question marked as used
13. Manually adjust points any time (add / subtract / correct)
14. End challenge → see results screen
```

---

## Scoring Logic

| Condition | Formula |
|-----------|---------|
| Question level = easy | Points = dice value |
| Question level = hard | Points = dice value × 2 |

### Example:
- Dice = 2, Question = easy → **2 points**
- Dice = 2, Question = hard → **4 points**
- Dice = 3, Question = hard → **6 points**

Manual score events (add/subtract/correction) are logged separately in `score_events`.

---

## Challenge Arena Features

- **Numbered question grid** — each cell is a question; blue = available, grayed = used, green = correct, red = wrong
- **Dice button** — rolls before opening a question; value stored for scoring
- **60-second countdown timer** — can pause, restart, or disable
- **Group scoreboard** — always visible; updates in real time
- **Manual score editing** — long-press a group to add/subtract points
- **Question dialog** — shows question text, options, level, dice points
- **Celebration effect** — plays on correct answer

---

## Admin Dashboard (Filament)

The admin manages all content through the Filament panel at `/admin`.

### Navigation
- لوحة التحكم (Dashboard)
- الصفوف الدراسية
- المواد
- الفصول
- الدروس
- الأسئلة
- حزم الأسئلة
- المعلمون
- استيراد Excel

---

## Excel Import

Teachers or admins can bulk-import questions via an Excel file.
The import creates the full hierarchy automatically (grade → subject → chapter → lesson → question).
See [excel-template-spec.md](excel-template-spec.md) for column details.

---

## API

The Flutter app communicates via a REST API secured with Laravel Sanctum bearer tokens.
See [api-spec.md](api-spec.md) for full endpoint documentation.
