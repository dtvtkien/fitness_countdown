import 'dart:async';

const _time_to_start_in_millis = 1000;
const _interval_callback_timer_in_millis = 200;
const _delay_time_for_last_data_in_millis = 600;

class FitnessCountdownTimer {
  /// Interval time is set for callback data
  final int intervalTimeInMillis;

  /// Subscribe [CountdownTimer] onData callback
  final Function(int remainingTime, int totalTime) onData;

  /// Subscribe [CountdownTimer] onDone callback
  final Function onDone;

  /// Subscribe [CountdownTimer] onError callback
  final Function onError;

  /// Need delay `intervalTimeInMillis` for preparing enough time showing that last data
  final bool needTimeShowingTheLastData;

  /// Countdown timer utility
  Ticker _ticker;

  /// Countdown timer subscription
  StreamSubscription<int> _timerSubscription;

  /// Total time to countdown in milliseconds
  int _totalTimeInMillis;

  /// Remaining timer after each tick
  int _remainingTimeInMillis;

  FitnessCountdownTimer({
    int totalTimeInMillis = _time_to_start_in_millis,
    this.intervalTimeInMillis = _interval_callback_timer_in_millis,
    this.onData,
    this.onDone,
    this.onError,
    this.needTimeShowingTheLastData = true,
  }) {
    _totalTimeInMillis = totalTimeInMillis;
    _remainingTimeInMillis = _totalTimeInMillis;
  }

  /// Create a countdown timer instance and start it
  void trigger() {
    _ticker = Ticker();
    _setupSubscription();
  }

  void pause() {
    if (!(_timerSubscription?.isPaused ?? false)) {
      _timerSubscription?.pause();
    }
  }

  void resume() {
    if (_timerSubscription?.isPaused ?? false) {
      _timerSubscription?.resume();
    }
  }

  void cancel() {
    _timerSubscription?.cancel();
  }

  void extraTime({int milliseconds = 0}) {
    assert(_ticker != null, 'Need to call [trigger()] first!');
    _remainingTimeInMillis += milliseconds;
    _totalTimeInMillis += milliseconds;
    _setupSubscription();
  }

  void _setupSubscription() {
    // Create a sub to handle countdown event
    _timerSubscription?.cancel();
    _timerSubscription = _ticker
        .tick(
          totalInMillis: _remainingTimeInMillis,
          periodInMillis: intervalTimeInMillis,
        )
        .listen(null);
    _timerSubscription.onData((elapsed) {
      // Callback in each [intervalTimeInMillis]
      _remainingTimeInMillis -= intervalTimeInMillis;
      onData?.call(_remainingTimeInMillis, _totalTimeInMillis);
    });
    _timerSubscription.onDone(() async {
      // If need time to show the last data, we will delay one more `intervalTimeInMillis`
      if (needTimeShowingTheLastData) {
        await Future.delayed(
            Duration(milliseconds: _delay_time_for_last_data_in_millis));
      }
      // Stop this countdown timer
      await _timerSubscription.cancel();
      onDone?.call();
    });
    _timerSubscription.onError(onError);
  }
}

class Ticker {
  Stream<int> tick({int totalInMillis, int periodInMillis}) {
    return Stream.periodic(
      Duration(milliseconds: periodInMillis),
      (x) => totalInMillis - x - periodInMillis,
    ).take((totalInMillis / periodInMillis).floor());
  }
}
