# Google Form Setup for Account Deletion Requests

This guide shows how to create a Google Form for users to request account deletion.

## Step 1: Create Google Form

1. Go to: https://forms.google.com/
2. Click: **+ Create** (new form)
3. Name it: "حذف الحساب" (Delete Account) or "Account Deletion Request"

## Step 2: Add Form Fields

Add these fields to your form:

### Field 1: Email Address (Required)
- Question: "البريد الإلكتروني للحساب" (Account Email)
- Type: Short answer
- Required: Yes

### Field 2: Reason for Deletion (Optional)
- Question: "السبب وراء طلب حذف الحساب" (Reason for deletion request)
- Type: Paragraph
- Required: No
- Options:
  - لا أستخدم التطبيق أكثر (Don't use app anymore)
  - مشاكل في الخصوصية (Privacy concerns)
  - أسباب أخرى (Other reasons)

### Field 3: Confirmation (Required)
- Question: "أؤكد أنني أفهم أنه سيتم حذف جميع بيانات حسابي بشكل دائم" (I confirm deletion of all data)
- Type: Checkboxes
- Options: ✓ أوافق (I agree)
- Required: Yes

## Step 3: Get Form URL

1. After creating the form, click: **Send** button (top right)
2. Copy the **Link** tab
3. The URL should look like: `https://forms.gle/XXXXXXXXXX`

## Step 4: Configure in Flutter App

Replace the form URL in `settings_screen.dart`:

```dart
static const String deleteAccountFormUrl =
    'https://forms.gle/YOUR_FORM_ID';  // ← Replace with your actual URL
```

## Step 5: Add Responses Destination

1. In Google Forms, go to **Responses** tab
2. Click: **Create spreadsheet** icon
3. Create new Google Sheet to receive responses
4. All deletion requests will be logged here

## Step 6: Set Up Form Notifications (Optional)

1. Click: **Settings** (gear icon)
2. Check: "Collect email addresses"
3. Go to: **Responses** tab
4. Click: **Get email notifications for new responses**

## Step 7: Process Deletion Requests

When you receive a deletion request:

1. Verify the email address matches an account
2. Delete user data from your database:
   ```sql
   DELETE FROM users WHERE email = 'user@example.com';
   DELETE FROM user_scores WHERE user_id = 'user_id';
   DELETE FROM user_challenges WHERE user_id = 'user_id';
   ```
3. Send confirmation email to user
4. Mark in Google Sheet as processed

---

## Form Response Handling

Your Google Sheet will contain:

| Timestamp | Email | Reason | Confirmed | Status |
|-----------|-------|--------|-----------|--------|
| 2026-08-29 10:30 | user@example.com | Don't use app | Yes | Processed |

Add a "Status" column manually to track:
- Received
- In Progress  
- Deleted
- Confirmed

---

## Notification Email Template

Send this to users after deletion:

```
Subject: تأكيد حذف الحساب (Account Deletion Confirmed)

مرحبا [User Name],

تم حذف حسابك وجميع البيانات المرتبطة به بنجاح.

Hello [User Name],

Your account and all associated data have been successfully deleted.

كل البيانات التالية تم حذفها:
All the following data has been deleted:
- معلومات الحساب (Account information)
- السجلات والدرجات (Scores and records)
- التحديات المحفوظة (Saved challenges)

إذا كان لديك أي أسئلة، يرجى التواصل معنا.
If you have any questions, please contact us.

مع أطيب التحيات,
Best regards,

Challenge Education Team
```

---

## Data Privacy Compliance

This implementation ensures GDPR/privacy compliance:

✓ Users can request account deletion
✓ Deletion confirmed via email
✓ Data retention policy (30 days to process)
✓ Audit trail (Google Sheet logs all requests)
✓ Easy account removal from database

---

## Example Google Form URL

After setting up, your form URL will look like:
```
https://forms.gle/8K3xM2pQfL9wNjVa4
```

Replace in `settings_screen.dart` line 16:
```dart
static const String deleteAccountFormUrl =
    'https://forms.gle/8K3xM2pQfL9wNjVa4';  // ← Your actual form
```

---

## Testing the Feature

1. Open app
2. Go to Settings (add button first)
3. Tap "طلب حذف الحساب" (Request Account Deletion)
4. Fill Google Form
5. Check Google Sheet for response

Done! ✅
