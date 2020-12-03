import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

abstract class BaseBloc extends Bloc<BaseEvent, BaseState> {
  final bool needLog;

  BaseBloc({this.needLog = false}) : super(BaseInitState());

  @override
  void onTransition(Transition<BaseEvent, BaseState> transition) {
    if (needLog == true) {
      super.onTransition(transition);
      print('$transition');
    }
  }
}

// region Base EVENT classes
abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object> get props => [];
}

abstract class BaseEventHasTag extends BaseEvent {
  final String tag;

  const BaseEventHasTag(this.tag);

  @override
  List<Object> get props => [tag];

  @override
  String toString() => '$runtimeType: $tag';
}
// endregion

// region Base STATE classes
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object> get props => [];
}

class BaseInitState extends BaseState {}

class BaseInProgressState extends BaseState {}
// endregion
