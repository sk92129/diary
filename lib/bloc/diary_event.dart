import 'package:diary/diary_entry.dart';

abstract class DiaryEvent {}

class AddDiaryEvent extends DiaryEvent {
  final DiaryEntry diaryEntry;
  AddDiaryEvent(this.diaryEntry);
}

class GetDiaryEvent extends DiaryEvent {
  GetDiaryEvent();
}

class UpdateDiaryEvent extends DiaryEvent {
  final DiaryEntry diaryEntry;
  UpdateDiaryEvent(this.diaryEntry);
}
