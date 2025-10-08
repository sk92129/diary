import 'dart:async';

import 'package:diary/bloc/diary_event.dart';
import 'package:diary/bloc/diary_state.dart';
import 'package:diary/diary_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class DiaryBloc extends HydratedBloc<DiaryEvent, DiaryState> {
  final Map<String, DiaryEntry> _diaryCache = {};
  DateTime _lastFetchedDiary = DateTime.now();

  DiaryBloc() : super(DiaryInitial()) {
    on<AddDiaryEvent>(_addDiary);
    on<GetDiaryEvent>(_getDiary);
  }

  Future<void> _addDiary(AddDiaryEvent event, Emitter<DiaryState> emit) async {
    try {
      emit(DiaryProgressing());
      await Future.delayed(const Duration(seconds: 2));
      _diaryCache[event.diaryEntry.id] = event.diaryEntry;
      emit(DiaryLoadSuccess(_diaryCache));
    } catch (e) {
      emit(DiaryFailure("Failed to add diary: $e"));
    }
  }

  FutureOr<void> _getDiary(
    GetDiaryEvent event,
    Emitter<DiaryState> emit,
  ) async {
    try {
      emit(DiaryProgressing());
      await Future.delayed(const Duration(seconds: 2));
      emit(DiaryLoadSuccess(_diaryCache));
    } catch (e) {
      emit(DiaryFailure("Failed to get diary: $e"));
    }
  }

  // loading from storage
  @override
  DiaryState? fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('fromJson called with: $json'); // Debug print

      // Load cached weather data for multiple cities
      if (json.containsKey('cachedDiary')) {
        final cachedData = json['cachedDiary'] as Map<String, dynamic>;
        debugPrint('Loading cached data: $cachedData'); // Debug print
        _diaryCache.clear();
        _lastFetchedDiary = DateTime.now();
        cachedData.forEach((id, diaryData) {
          _diaryCache[id] = DiaryEntry.fromJson(diaryData);
        });
        debugPrint(
          'Cache loaded with ${_diaryCache.length} diary',
        ); // Debug print
      }

      // Return the last loaded product state if available
      if (json.containsKey('timeStamp')) {
        final timeStamp = json['timeStamp'] as String;
        final lastFetchedDiary = DateTime.parse(timeStamp);
        _lastFetchedDiary = lastFetchedDiary;
        debugPrint('lastFetchedDiary: $lastFetchedDiary');
        // check if the groups are older than 10 minutes
        return DiaryLoadSuccess(_diaryCache);
      }
      return null;
    } catch (e) {
      debugPrint('Error in fromJson: $e'); // Debug print
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(DiaryState state) {
    if (state is DiaryLoadSuccess) {
      //
      final cachedDiaryEntries = <String, dynamic>{};

      for (var entry in state.entries.values) {
        cachedDiaryEntries[entry.id] = entry.toJson();
      }

      final result = {
        'cachedDiary': cachedDiaryEntries,
        'timeStamp': DateTime.now().toIso8601String(),
      };

      debugPrint(
        'toJson called, saving cache with ${_diaryCache.length} diary',
      ); // Debug print
      debugPrint('Cache contents: ${_diaryCache.keys.toList()}'); // Debug print

      return result;
    } else {
      return {};
    }
  }
}
