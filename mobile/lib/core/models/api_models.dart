// =============================
// Core domain models
// =============================

class Grade {
  final int id;
  final String name;
  final int sortOrder;
  final bool isActive;

  const Grade({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        id: json['id'],
        name: json['name'],
        sortOrder: json['sort_order'] ?? 0,
        isActive: json['is_active'] ?? true,
      );
}

class Subject {
  final int id;
  final int gradeId;
  final String name;
  final String? backgroundTheme;
  final String? backgroundImageUrl;

  const Subject({
    required this.id,
    required this.gradeId,
    required this.name,
    this.backgroundTheme,
    this.backgroundImageUrl,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'],
        gradeId: json['grade_id'],
        name: json['name'],
        backgroundTheme: json['background_theme'],
        backgroundImageUrl: json['background_image_url'],
      );
}

class SubjectPart {
  final int id;
  final int subjectId;
  final String name;
  final int partNumber;
  final int sortOrder;

  const SubjectPart({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.partNumber,
    required this.sortOrder,
  });

  factory SubjectPart.fromJson(Map<String, dynamic> json) => SubjectPart(
        id: json['id'],
        subjectId: json['subject_id'],
        name: json['name'],
        partNumber: json['part_number'] ?? 1,
        sortOrder: json['sort_order'] ?? 0,
      );
}

class Chapter {
  final int id;
  final int subjectId;
  final int? subjectPartId;
  final String name;
  final int sortOrder;

  const Chapter({
    required this.id,
    required this.subjectId,
    this.subjectPartId,
    required this.name,
    required this.sortOrder,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'],
        subjectId: json['subject_id'],
        subjectPartId: json['subject_part_id'],
        name: json['name'],
        sortOrder: json['sort_order'] ?? 0,
      );
}

class Lesson {
  final int id;
  final int chapterId;
  final String name;
  final int sortOrder;

  const Lesson({
    required this.id,
    required this.chapterId,
    required this.name,
    required this.sortOrder,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'],
        chapterId: json['chapter_id'],
        name: json['name'],
        sortOrder: json['sort_order'] ?? 0,
      );
}

class Question {
  final int id;
  final int lessonId;
  final int? subjectPartId;
  final String questionText;
  final String questionType;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String correctAnswer;
  final String level; // 'easy' | 'hard'
  final String? explanation;
  final int? sortOrder;

  const Question({
    required this.id,
    required this.lessonId,
    this.subjectPartId,
    required this.questionText,
    required this.questionType,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    required this.correctAnswer,
    required this.level,
    this.explanation,
    this.sortOrder,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'],
        lessonId: json['lesson_id'],
        subjectPartId: json['subject_part_id'],
        questionText: json['question_text'],
        questionType: json['question_type'],
        optionA: json['option_a'],
        optionB: json['option_b'],
        optionC: json['option_c'],
        optionD: json['option_d'],
        correctAnswer: json['correct_answer'],
        level: json['level'],
        explanation: json['explanation'],
        sortOrder: json['sort_order'],
      );

  bool get isHard => level == 'hard';

  String get levelLabel => level == 'easy' ? 'سهل' : 'صعب';
}

class ChallengeGroup {
  final int id;
  final int challengeSessionId;
  final String name;
  final int score;
  final int sortOrder;

  const ChallengeGroup({
    required this.id,
    required this.challengeSessionId,
    required this.name,
    required this.score,
    required this.sortOrder,
  });

  factory ChallengeGroup.fromJson(Map<String, dynamic> json) => ChallengeGroup(
        id: json['id'],
        challengeSessionId: json['challenge_session_id'],
        name: json['name'],
        score: json['score'] ?? 0,
        sortOrder: json['sort_order'] ?? 0,
      );

  ChallengeGroup copyWith({int? score}) => ChallengeGroup(
        id: id,
        challengeSessionId: challengeSessionId,
        name: name,
        score: score ?? this.score,
        sortOrder: sortOrder,
      );
}

class ChallengeQuestionItem {
  final int id;
  final int sequenceNumber;
  final bool isUsed;
  final String? answerStatus; // 'correct' | 'wrong'
  final int? awardedPoints;
  final int? lastDiceValue;
  final int? selectedGroupId;
  final Question? question;

  const ChallengeQuestionItem({
    required this.id,
    required this.sequenceNumber,
    required this.isUsed,
    this.answerStatus,
    this.awardedPoints,
    this.lastDiceValue,
    this.selectedGroupId,
    this.question,
  });

  factory ChallengeQuestionItem.fromJson(Map<String, dynamic> json) =>
      ChallengeQuestionItem(
        id: json['id'],
        sequenceNumber: json['sequence_number'],
        isUsed: json['is_used'] ?? false,
        answerStatus: json['answer_status'],
        awardedPoints: json['awarded_points'],
        lastDiceValue: json['last_dice_value'],
        selectedGroupId: json['selected_group_id'],
        question: json['question'] != null
            ? Question.fromJson(json['question'])
            : null,
      );

  ChallengeQuestionItem copyWith({
    bool? isUsed,
    String? answerStatus,
    int? awardedPoints,
    int? lastDiceValue,
    int? selectedGroupId,
  }) =>
      ChallengeQuestionItem(
        id: id,
        sequenceNumber: sequenceNumber,
        isUsed: isUsed ?? this.isUsed,
        answerStatus: answerStatus ?? this.answerStatus,
        awardedPoints: awardedPoints ?? this.awardedPoints,
        lastDiceValue: lastDiceValue ?? this.lastDiceValue,
        selectedGroupId: selectedGroupId ?? this.selectedGroupId,
        question: question,
      );
}

class ChallengeSession {
  final int id;
  final Grade? grade;
  final Subject? subject;
  final SubjectPart? subjectPart;
  final List<Chapter> chapters;
  final List<Lesson> lessons;
  final int timerSeconds;
  final bool timerEnabled;
  final String status;
  final List<ChallengeGroup> groups;
  final List<ChallengeQuestionItem> questions;

  const ChallengeSession({
    required this.id,
    this.grade,
    this.subject,
    this.subjectPart,
    required this.chapters,
    required this.lessons,
    required this.timerSeconds,
    required this.timerEnabled,
    required this.status,
    required this.groups,
    required this.questions,
  });

  factory ChallengeSession.fromJson(Map<String, dynamic> json) =>
      ChallengeSession(
        id: json['id'],
        grade: json['grade'] != null ? Grade.fromJson(json['grade']) : null,
        subject:
            json['subject'] != null ? Subject.fromJson(json['subject']) : null,
        subjectPart: json['subject_part'] != null
            ? SubjectPart.fromJson(json['subject_part'])
            : null,
        chapters: (json['chapters'] as List? ?? [])
            .map((c) => Chapter.fromJson(c))
            .toList(),
        lessons: (json['lessons'] as List? ?? [])
            .map((l) => Lesson.fromJson(l))
            .toList(),
        timerSeconds: json['timer_seconds'] ?? 60,
        timerEnabled: json['timer_enabled'] ?? true,
        status: json['status'] ?? 'active',
        groups: (json['groups'] as List? ?? [])
            .map((g) => ChallengeGroup.fromJson(g))
            .toList(),
        questions: (json['questions'] as List? ?? [])
            .map((q) => ChallengeQuestionItem.fromJson(q))
            .toList(),
      );

  ChallengeSession copyWith({
    String? status,
    List<ChallengeGroup>? groups,
    List<ChallengeQuestionItem>? questions,
  }) =>
      ChallengeSession(
        id: id,
        grade: grade,
        subject: subject,
        subjectPart: subjectPart,
        chapters: chapters,
        lessons: lessons,
        timerSeconds: timerSeconds,
        timerEnabled: timerEnabled,
        status: status ?? this.status,
        groups: groups ?? this.groups,
        questions: questions ?? this.questions,
      );
}

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        role: json['role'],
      );
}

class QuestionPackage {
  final int id;
  final String title;
  final String? description;
  final Grade? grade;
  final Subject? subject;
  final Chapter? chapter;
  final Lesson? lesson;
  final bool isFree;
  final String? price;
  final String? platformProductId;
  final String? androidProductId;
  final String? iosProductId;
  final String purchaseType;
  final bool isActive;
  final int questionsCount;
  final bool isOwned;

  const QuestionPackage({
    required this.id,
    required this.title,
    this.description,
    this.grade,
    this.subject,
    this.chapter,
    this.lesson,
    required this.isFree,
    this.price,
    this.platformProductId,
    this.androidProductId,
    this.iosProductId,
    required this.purchaseType,
    required this.isActive,
    required this.questionsCount,
    required this.isOwned,
  });

  factory QuestionPackage.fromJson(Map<String, dynamic> json) =>
      QuestionPackage(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        grade: json['grade'] != null ? Grade.fromJson(json['grade']) : null,
        subject:
            json['subject'] != null ? Subject.fromJson(json['subject']) : null,
        chapter:
            json['chapter'] != null ? Chapter.fromJson(json['chapter']) : null,
        lesson: json['lesson'] != null ? Lesson.fromJson(json['lesson']) : null,
        isFree: json['is_free'] ?? false,
        price: json['price']?.toString(),
        platformProductId: json['platform_product_id'],
        androidProductId: json['android_product_id'],
        iosProductId: json['ios_product_id'],
        purchaseType: json['purchase_type'] ?? 'non_consumable',
        isActive: json['is_active'] ?? true,
        questionsCount: json['questions_count'] ?? 0,
        isOwned: json['is_owned'] ?? json['is_free'] ?? false,
      );

  String? productIdForStore(String store) {
    if (store == 'ios') return iosProductId ?? platformProductId;
    if (store == 'android') return androidProductId ?? platformProductId;
    return platformProductId;
  }
}
