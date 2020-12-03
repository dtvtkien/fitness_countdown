import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/animation_countdown_bloc.dart';
import '../bloc/base_bloc.dart';
import '../bloc/countdown_bloc.dart';
import 'focus_detector.dart';

const _counter_text_width_ratio = 0.36;
const _total_countdown_in_milliseconds = 3600;
const _interval_in_milliseconds = 1200;

class CounterAnimationWidget extends StatefulWidget {
  final double width;
  final double height;
  final double counterTextWidthRatio;
  final int totalCountdownInMillis;
  final int intervalInMillis;
  final VoidCallback onFinishCounter;

  const CounterAnimationWidget({
    Key key,
    this.width,
    this.height,
    this.counterTextWidthRatio = _counter_text_width_ratio,
    int totalCountdownInMillis,
    int intervalInMillis,
    this.onFinishCounter,
  })  : this.totalCountdownInMillis =
            totalCountdownInMillis ?? _total_countdown_in_milliseconds,
        this.intervalInMillis = intervalInMillis ?? _interval_in_milliseconds,
        super(key: key);

  @override
  _CounterAnimationWidgetState createState() => _CounterAnimationWidgetState();
}

class _CounterAnimationWidgetState extends State<CounterAnimationWidget>
    with TickerProviderStateMixin {
  // Timer bloc
  CountdownBloc _countdownBloc;

  // Animation controller & transform animations
  AnimationController _animationController;
  Animation<double> _translateAnimation;
  Animation<double> _fadeInAnimation;
  Animation<double> _fadeOutAnimation;
  bool _forceGoneView = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: widget.intervalInMillis),
      vsync: this,
    )..addListener(() {
        setState(() {});
      });
    _translateAnimation =
        Tween(begin: -120.0, end: 120.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fadeInAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.0,
        0.5,
        curve: Curves.ease,
      ),
    ));
    _fadeOutAnimation = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.5,
        1.0,
        curve: Curves.ease,
      ),
    ));
  }

  @override
  void dispose() {
    _countdownBloc?.close();
    _animationController?.dispose();
    super.dispose();
  }

  void _onResumed(String tag) {
    _countdownBloc?.add(ContinueCountdown(tag));
  }

  void _onPaused(String tag) {
    _countdownBloc?.add(PauseCountdown(tag));
    _animationController.reset();
  }

  void _startCountdown() {
    if (!mounted) {
      return;
    }
    setState(() {
      _forceGoneView = false;
    });
    _countdownBloc?.add(StartCountdown(
      countdownTimeInMillis: widget.totalCountdownInMillis,
      intervalInMillis: widget.intervalInMillis,
    ));
    _animationController.repeat();
  }

  void _onCountingDown() {
    if (_animationController.isDismissed) {
      _animationController.repeat();
    }
  }

  void _onCountEnded() {
    setState(() {
      _forceGoneView = true;
    });
    _animationController.stop();
    widget.onFinishCounter?.call();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? MediaQuery.of(context).size.width;
    final height = widget.height ?? MediaQuery.of(context).size.height;
    return BlocProvider(
      create: (BuildContext context) {
        _countdownBloc = CountdownBloc(needTts: true);
        return _countdownBloc;
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<AnimationCountdownBloc, BaseState>(
            listener: (context, state) {
              if (state is StartedCountdownAnimationState) {
                _startCountdown();
              } else if (state is PausedAnimationState) {
                _onPaused((AnimationCountdownBloc).toString());
              } else if (state is ContinuedAnimationState) {
                _onResumed((AnimationCountdownBloc).toString());
              }
            },
          ),
          BlocListener<CountdownBloc, BaseState>(
            cubit: _countdownBloc,
            listener: (context, state) {
              if (state is EndedCountdownState) {
                _onCountEnded();
              } else if (state is FitnessCountingState) {
                _onCountingDown();
              }
            },
          ),
        ],
        child: FocusDetector(
          key: Key('key_countdown_common_widget'),
          onFocusGained: () => _onResumed((CounterAnimationWidget).toString()),
          onFocusLost: () => _onPaused((CounterAnimationWidget).toString()),
          child: Visibility(
            visible: !_forceGoneView,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
                height: height,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0.0, _translateAnimation.value),
                      child: child,
                    );
                  },
                  child: Opacity(
                    opacity: _fadeOutAnimation.value,
                    child: Opacity(
                      opacity: _fadeInAnimation.value,
                      child: BlocBuilder<CountdownBloc, BaseState>(
                        cubit: _countdownBloc,
                        builder: (context, state) {
                          int remainTime;
                          if (state is FitnessCountingState &&
                              state.remainingTime != null) {
                            remainTime = state.remainingTime;
                          }
                          return Center(
                            child: SizedBox(
                              width: width * widget.counterTextWidthRatio,
                              child: FittedBox(
                                child: Text(
                                  remainTime != null ? '$remainTime' : ' ',
                                  style: const TextStyle(
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
