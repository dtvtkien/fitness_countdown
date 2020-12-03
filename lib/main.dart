import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/animation_countdown_bloc.dart';
import 'widget/counter_animation_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnimationCountdownBloc(),
      child: MaterialApp(
        title: 'Fitness Countdown',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: CountdownPage(title: 'Fitness Countdown'),
      ),
    );
  }
}

class CountdownPage extends StatefulWidget {
  CountdownPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _CountdownPageState createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  bool _finished = true;

  void _onStartAnimation() {
    setState(() {
      _finished = false;
    });
    context.read<AnimationCountdownBloc>()?.add(StartCountdownAnimation());
  }

  void _onFinishedCounter() {
    setState(() {
      _finished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CounterAnimationWidget(
              width: 400.0,
              height: 400.0,
              onFinishCounter: _onFinishedCounter,
            ),
            if (_finished)
              Text(
                'Animation finished',
                style: TextStyle(
                  color: Colors.brown,
                  fontSize: 18.0,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _finished
          ? FloatingActionButton(
              onPressed: _onStartAnimation,
              tooltip: 'Start',
              child: Icon(Icons.play_arrow),
            )
          : const SizedBox(),
    );
  }
}
