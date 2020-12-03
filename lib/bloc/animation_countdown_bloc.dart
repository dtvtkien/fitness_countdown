import 'base_bloc.dart';

class AnimationCountdownBloc extends BaseBloc {
  bool _isTriggered = false;

  AnimationCountdownBloc() : super(needLog: false);

  @override
  Stream<BaseState> mapEventToState(BaseEvent event) async* {
    if (event is StartCountdownAnimation) {
      _isTriggered = !_isTriggered;
      yield StartedCountdownAnimationState(_isTriggered);
    } else if (event is PauseAnimation) {
      yield PausedAnimationState();
    } else if (event is ContinueAnimation) {
      yield ContinuedAnimationState();
    }
  }
}

// region EVENT
class StartCountdownAnimation extends BaseEvent {}

class PauseAnimation extends BaseEvent {}

class ContinueAnimation extends BaseEvent {}
// endregion

// region STATE
class PausedAnimationState extends BaseState {}

class ContinuedAnimationState extends BaseState {}

class StartedCountdownAnimationState extends BaseState {
  final bool isTriggered;

  StartedCountdownAnimationState(this.isTriggered);

  @override
  List<Object> get props => [isTriggered];

  @override
  String toString() => 'StartedCountdownAnimationState - trigger $isTriggered';
}
// endregion
