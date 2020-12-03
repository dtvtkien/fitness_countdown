import '../utils/fitness_countdown_timer.dart';
import 'base_bloc.dart';

const _default_sample_countdown_duration_in_millis = 3600;
const _default_interval_callback_timer_in_millis = 200;

class CountdownBloc extends BaseBloc {
  /// Remaining counting down time in milliseconds
  int _remainingTimeInMillis;

  /// Total counting time
  int _totalTimeInMillis;

  /// Countdown timer
  FitnessCountdownTimer _countdownTimer;

  /// Flag check if extra time is added or not yet
  bool _addedExtraTime;

  /// Need tts guide
  bool _needTts;

  /// Check abused force pause/play
  String _firstPausedTag;

  CountdownBloc({bool needTts}) : super(needLog: true) {
    _remainingTimeInMillis = _default_sample_countdown_duration_in_millis;
    _totalTimeInMillis = _default_sample_countdown_duration_in_millis;
    _addedExtraTime = false;
    _needTts = needTts ?? false;
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }

  @override
  Stream<BaseState> mapEventToState(BaseEvent event) async* {
    switch (event.runtimeType) {
      case StartCountdown:
        yield* _handleStartCountdown(event);
        break;

      case PauseCountdown:
        yield* _handlePauseCountdown(event);
        break;

      case ContinueCountdown:
        yield* _handleContinueCountdown(event);
        break;

      case AddExtraTime:
        yield* _handleAddExtraTime(event);
        break;

      case FitnessCountingDown:
        yield* _handleFitnessCountingDown(event);
        break;

      case EndCountdown:
        yield* _handleEndCountdown(event);
        break;
    }
  }

  Stream<BaseState> _handleStartCountdown(StartCountdown event) async* {
    // Reset counting
    _totalTimeInMillis = event.countdownTimeInMillis ??
        _default_sample_countdown_duration_in_millis;
    _remainingTimeInMillis = _totalTimeInMillis;
    int intervalInMillis =
        event.intervalInMillis ?? _default_interval_callback_timer_in_millis;
    // Create a countdown for starting this group workout
    _countdownTimer = FitnessCountdownTimer(
      needTimeShowingTheLastData: false,
      totalTimeInMillis: _totalTimeInMillis,
      intervalTimeInMillis: intervalInMillis,
      onData: (remainingTime, totalTime) {
        _remainingTimeInMillis = remainingTime;
        _totalTimeInMillis = totalTime;
        add(FitnessCountingDown(remainingTime));
      },
      onDone: () {
        // After counting, start this group workout
        add(EndCountdown());
      },
    );
    // Start to countdown
    add(FitnessCountingDown(_remainingTimeInMillis));
    _countdownTimer?.trigger();
  }

  Stream<BaseState> _handlePauseCountdown(PauseCountdown event) async* {
    if (_firstPausedTag == null || _firstPausedTag.isEmpty) {
      _firstPausedTag = event.tag;
    }
    _countdownTimer?.pause();
  }

  Stream<BaseState> _handleContinueCountdown(ContinueCountdown event) async* {
    if (_firstPausedTag == event.tag) {
      _countdownTimer?.resume();
    }
  }

  Stream<BaseState> _handleAddExtraTime(AddExtraTime event) async* {
    _countdownTimer?.extraTime(milliseconds: event.extraTimeInMillis ?? 0);
    _addedExtraTime = true;
  }

  Stream<BaseState> _handleFitnessCountingDown(
      FitnessCountingDown event) async* {
    _firstPausedTag = null; // Reset
    int remainingTimeInSeconds = _remainingTimeInMillis ~/ 1000;
    int totalTimeInSeconds = _totalTimeInMillis ~/ 1000;
    yield FitnessCountingState(
        remainingTimeInSeconds, totalTimeInSeconds, _addedExtraTime);
    // Check for using Text to speech
    if (!_needTts || remainingTimeInSeconds <= 0) {
      return;
    }
    // Do Text To Speech speak here
  }

  Stream<BaseState> _handleEndCountdown(EndCountdown event) async* {
    yield EndedCountdownState();
  }
}

// region EVENT
class StartCountdown extends BaseEvent {
  final int countdownTimeInMillis;
  final int intervalInMillis;

  StartCountdown({
    this.countdownTimeInMillis,
    this.intervalInMillis,
  });

  @override
  List<Object> get props => [countdownTimeInMillis, intervalInMillis];

  @override
  String toString() =>
      'StartCountdown: { $countdownTimeInMillis with interval $intervalInMillis }';
}

class PauseCountdown extends BaseEventHasTag {
  const PauseCountdown(String tag) : super(tag);
}

class ContinueCountdown extends BaseEventHasTag {
  const ContinueCountdown(String tag) : super(tag);
}

class AddExtraTime extends BaseEvent {
  final int extraTimeInMillis;

  AddExtraTime(this.extraTimeInMillis);

  @override
  List<Object> get props => [extraTimeInMillis];

  @override
  String toString() => 'AddExtraTime: { $extraTimeInMillis }';
}

class FitnessCountingDown extends BaseEvent {
  final int remainTimeInMillis;

  const FitnessCountingDown(this.remainTimeInMillis);

  @override
  List<Object> get props => [remainTimeInMillis];

  @override
  String toString() => 'FitnessCountingDown: at $remainTimeInMillis';
}

class EndCountdown extends BaseEvent {}
// endregion

// region STATE
class FitnessCountingState extends BaseState {
  final int remainingTime;
  final int totalTime;
  final bool addedExtraTime;

  const FitnessCountingState(
      this.remainingTime, this.totalTime, this.addedExtraTime);

  @override
  List<Object> get props => [remainingTime, totalTime, addedExtraTime];

  @override
  String toString() =>
      'FitnessCountingState: { remainingTime: $remainingTime / totalTime: $totalTime, addedExtraTime: $addedExtraTime }';
}

class EndedCountdownState extends BaseState {}
// endregion
