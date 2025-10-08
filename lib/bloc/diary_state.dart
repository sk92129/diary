import 'package:diary/diary_entry.dart';

abstract class DiaryState {}

class DiaryInitial extends DiaryState {}

class DiaryProgressing extends DiaryState {}

class DiaryLoadSuccess extends DiaryState {
  final Map<String, DiaryEntry> entries;
  DiaryLoadSuccess(this.entries);
}

class DiaryFailure extends DiaryState {
  final String message;
  DiaryFailure(this.message);
}
