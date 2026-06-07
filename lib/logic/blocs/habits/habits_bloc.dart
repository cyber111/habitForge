import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/habit.dart';
import '../../../data/models/habit_completion.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../helpers/streak_calculator.dart';

part 'habits_event.dart';
part 'habits_state.dart';

class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  HabitsBloc({required HabitRepository repository})
      : _repository = repository,
        super(const HabitsState()) {
    on<HabitsLoaded>(_onLoaded);
    on<HabitAdded>(_onAdded);
    on<HabitUpdated>(_onUpdated);
    on<HabitArchiveToggled>(_onArchiveToggled);
    on<HabitDeleted>(_onDeleted);
    on<HabitCompletionToggled>(_onCompletionToggled);
    on<SelectedDateChanged>(_onSelectedDateChanged);
  }

  final HabitRepository _repository;

  Future<void> _onLoaded(HabitsLoaded event, Emitter<HabitsState> emit) async {
    emit(state.copyWith(status: HabitsStatus.loading));
    _emitFromRepository(emit);
  }

  Future<void> _onAdded(HabitAdded event, Emitter<HabitsState> emit) async {
    await _repository.addHabit(
      name: event.name,
      emoji: event.emoji,
      colorIndex: event.colorIndex,
      activeDays: event.activeDays,
      reminderHour: event.reminderHour,
      reminderMinute: event.reminderMinute,
    );
    _emitFromRepository(emit);
  }

  Future<void> _onUpdated(HabitUpdated event, Emitter<HabitsState> emit) async {
    await _repository.updateHabit(
      event.habit,
      name: event.name,
      emoji: event.emoji,
      colorIndex: event.colorIndex,
      activeDays: event.activeDays,
      reminderHour: event.reminderHour,
      reminderMinute: event.reminderMinute,
      clearReminder: event.clearReminder,
    );
    _emitFromRepository(emit);
  }

  Future<void> _onArchiveToggled(
    HabitArchiveToggled event,
    Emitter<HabitsState> emit,
  ) async {
    if (event.habit.isArchived) {
      await _repository.unarchiveHabit(event.habit);
    } else {
      await _repository.archiveHabit(event.habit);
    }
    _emitFromRepository(emit);
  }

  Future<void> _onDeleted(HabitDeleted event, Emitter<HabitsState> emit) async {
    await _repository.deleteHabit(event.habit);
    _emitFromRepository(emit);
  }

  Future<void> _onCompletionToggled(
    HabitCompletionToggled event,
    Emitter<HabitsState> emit,
  ) async {
    await _repository.toggleCompletion(event.habit.id, event.date);
    _emitFromRepository(emit);
  }

  void _onSelectedDateChanged(
    SelectedDateChanged event,
    Emitter<HabitsState> emit,
  ) {
    emit(state.copyWith(selectedDate: event.date));
  }

  void _emitFromRepository(Emitter<HabitsState> emit) {
    emit(state.copyWith(
      status: HabitsStatus.loaded,
      habits: _repository.getActiveHabits(),
      archivedHabits: _repository.getArchivedHabits(),
      completions: _repository.getAllCompletions(),
    ));
  }
}
