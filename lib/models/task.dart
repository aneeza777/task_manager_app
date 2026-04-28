class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final int priority; // 0: Low, 1: Medium, 2: High
  final DateTime? dueDate;
  final String? category;
  final String? description;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.priority = 0,
    this.dueDate,
    this.category,
    this.description,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? priority,
    DateTime? dueDate,
    String? category,
    String? description,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'description': description,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      category: json['category'] as String?,
      description: json['description'] as String?,
    );
  }
}
