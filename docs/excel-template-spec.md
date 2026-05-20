# Excel Import Template Specification

## Overview

The admin can import questions in bulk from an Excel (.xlsx) file.
The system automatically creates the full hierarchy (grade → subject → subject part → chapter → lesson) if it doesn't exist.

---

## File Format

- Format: `.xlsx` (Excel 2007+)
- Encoding: UTF-8 (Arabic content supported)
- Row 1: **Headers** (must match exactly)
- Row 2+: Data rows

---

## Required Columns (Row 1 Headers)

| Column Header | Required | Description |
|---------------|----------|-------------|
| `الصف الدراسي` | ✅ | Grade name — created if not exists |
| `المادة` | ✅ | Subject name under the grade — created if not exists |
| `الجزء` | ✅ | Subject part. Accepted values: `الجزء الأول`, `الجزء الثاني`, `الأول`, `الثاني`, `1`, `2` |
| `الفصل` | ✅ | Chapter name under the subject — created if not exists |
| `الدرس` | ✅ | Lesson name under the chapter — created if not exists |
| `رقم السؤال` | ⬜ | Optional sort order for the question |
| `نص السؤال` | ✅ | The question text |
| `نوع السؤال` | ✅ | See valid values below |
| `الاختيار الأول` | ⬜ | Option A (for multiple choice) |
| `الاختيار الثاني` | ⬜ | Option B (for multiple choice) |
| `الاختيار الثالث` | ⬜ | Option C (for multiple choice) |
| `الاختيار الرابع` | ⬜ | Option D (for multiple choice) |
| `الإجابة الصحيحة` | ✅ | The correct answer text |
| `مستوى السؤال` | ✅ | See valid values below |
| `الشرح أو الملاحظة` | ⬜ | Optional explanation shown after answering |
| `مفعل؟` | ⬜ | 1/نعم/yes = active, 0/لا/no = inactive (default: active) |

---

## Valid Values

### `نوع السؤال` (Question Type)
| Value | Stored As |
|-------|-----------|
| `اختيار من متعدد` | `multiple_choice` |
| `صح أو خطأ` | `true_false` |
| `نصي` | `text` |
| `multiple_choice` | `multiple_choice` (English accepted) |
| `true_false` | `true_false` |
| `text` | `text` |

### `مستوى السؤال` (Question Level)
| Value | Stored As |
|-------|-----------|
| `سهل` | `easy` |
| `صعب` | `hard` |
| `easy` | `easy` |
| `hard` | `hard` |

### `الجزء` (Subject Part)
| Value | Stored As |
|-------|-----------|
| `الجزء الأول`, `الأول`, `الاول`, `1` | Part 1 |
| `الجزء الثاني`, `الثاني`, `2` | Part 2 |

### `مفعل؟` (Active)
| Value | Meaning |
|-------|---------|
| `1`, `نعم`, `yes`, `true`, `✓` | Active |
| `0`, `لا`, `no`, `false` | Inactive |
| *(empty)* | Active (default) |

---

## Example Data Row

| الصف الدراسي | المادة | الجزء | الفصل | الدرس | رقم السؤال | نص السؤال | نوع السؤال | الاختيار الأول | الاختيار الثاني | الاختيار الثالث | الاختيار الرابع | الإجابة الصحيحة | مستوى السؤال | الشرح أو الملاحظة | مفعل؟ |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| الصف الثاني | علوم | الجزء الأول | الفصل الأول | الدرس الأول | 1 | ما وحدة الكتلة في النظام الدولي؟ | اختيار من متعدد | كيلوغرام | غرام | طن | ميلليغرام | كيلوغرام | سهل | الكيلوغرام هو وحدة الكتلة الأساسية | نعم |
| الصف الثاني | علوم | الجزء الأول | الفصل الأول | الدرس الأول | 2 | المادة لها كتلة وحجم | صح أو خطأ | صح | خطأ | | | صح | سهل | | نعم |
| الصف الثاني | علوم | الجزء الثاني | الفصل الثالث | الدرس الثاني | 1 | ما الفرق بين الكتلة والوزن؟ | نصي | | | | | الكتلة ثابتة أما الوزن يتغير بتغير الجاذبية | صعب | مثال على سؤال نصي للجزء الثاني | نعم |

---

## Import Behavior

1. For each row, the system checks if the grade, subject, subject part, chapter, and lesson exist.
2. If any level doesn't exist under its parent, it is **created** with `is_active = true`.
3. A new question is always created (no duplicate detection by question text).
4. If validation fails for a row (missing required field, invalid level/type), that row is **skipped** and logged as an error.
5. All other valid rows are still imported.

---

## Import Result

After import, the admin sees:
- ✅ **سجل تم إنشاؤه** — number of successfully created questions
- ⚠️ **سجل تم تخطيه** — number of skipped rows (including error rows)
- ❌ **أخطاء** — table of row numbers and error messages

---

## Download Sample Template

The admin import page downloads a ready-made `.xlsx` template with the correct headers and three sample rows.

---

## Tips

- Keep grade names consistent across rows (exact match, case-sensitive for Arabic)
- Fill `الجزء` explicitly to avoid placing chapters in the wrong part
- For true/false questions, set option_a = "صح" and option_b = "خطأ"
- Leave option_c and option_d empty for true/false
- For text questions, leave all options empty
- The correct_answer should match one of the options exactly for multiple_choice
