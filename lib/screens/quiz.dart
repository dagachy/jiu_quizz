import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../shared/shared.dart';
import '../services/services.dart';

class QuizState with ChangeNotifier {
  double _progress = 0;
  Option _selected;

  final PageController controller = PageController();

  get progress => _progress;

  get selected => _selected;

  set progress(double newValue) {
    _progress = newValue;
    notifyListeners();
  }

  set selected(Option newValue) {
    _selected = newValue;
    notifyListeners();
  }

  void nextPage() async {
    await controller.nextPage(
      duration: Duration(microseconds: 500),
      curve: Curves.easeOut,
    );
    Global.stopLoopSound();
    Global.loopSound('sounds/ticking.mp3');
  }
}

class QuizScreen extends StatelessWidget {
  QuizScreen({this.quizId});

  final String quizId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizState(),
      child: FutureBuilder(
        future: Document<Quiz>(path: 'quizzes/$quizId').getData(),
        builder: (BuildContext context, AsyncSnapshot snap) {
          var state = Provider.of<QuizState>(context);

          if (!snap.hasData || snap.hasError) {
            return LoadingScreen();
          } else {
            Quiz quiz = snap.data;
            return Scaffold(
              appBar: AppBar(
                title: AnimatedProgressbar(value: state.progress),
                leading: IconButton(
                  icon: Icon(FontAwesomeIcons.times),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: PageView.builder(
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                controller: state.controller,
                onPageChanged: (int idx) =>
                    state.progress = (idx / (quiz.questions.length + 1)),
                itemBuilder: (BuildContext context, int idx) {
                  if (idx == 0) {
                    return StartPage(quiz: quiz);
                  } else if (idx == quiz.questions.length + 1) {
                    return CongratsPage(quiz: quiz);
                  } else {
                    return QuestionPage(question: quiz.questions[idx - 1]);
                  }
                },
              ),
            );
          }
        },
      ),
    );
  }
}

class StartPage extends StatelessWidget {
  final Quiz quiz;
  final PageController controller;

  StartPage({this.quiz, this.controller});

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<QuizState>(context);

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(quiz.title, style: Theme.of(context).textTheme.headline),
          Divider(),
          Expanded(child: Text(quiz.description)),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              FlatButton.icon(
                onPressed: state.nextPage,
                label: Text('시작하기!'),
                icon: Icon(Icons.poll),
                color: Colors.green,
              )
            ],
          )
        ],
      ),
    );
  }
}

class CongratsPage extends StatelessWidget {
  final Quiz quiz;

  CongratsPage({this.quiz});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '축하해요!\n[ ${quiz.title} ]\n를 완료했어요!\n\n',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline,
          ),
          Divider(),
          Image.asset('assets/congrats.gif'),
          Divider(),
          FlatButton.icon(
            color: Colors.green,
            icon: Icon(FontAwesomeIcons.check),
            label: Text(' 완료로 표시!'),
            onPressed: () {
              _updateUserReport(quiz);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/topics',
                (route) => false,
              );
            },
          )
        ],
      ),
    );
  }

  /// Database write to update report doc when complete
  Future<void> _updateUserReport(Quiz quiz) {
    return Global.reportRef.upsert(
      ({
        'total': FieldValue.increment(1),
        'topics': {
          '${quiz.topic}': FieldValue.arrayUnion([quiz.id])
        }
      }),
    );
  }
}

class QuestionPage extends StatelessWidget {
  final Question question;

  QuestionPage({this.question});

  @override
  Widget build(BuildContext context) {
    Widget questionWidget;
    if (question.type == 'image') {
      questionWidget = _imageQuiz(context);
    } else if (question.type == 'explanation') {
      questionWidget = _expQuiz(context);
    } else if (question.type == 'vocabulary') {
      questionWidget = _vocaQuiz(context);
    } else if (question.type == 'meaning') {
      questionWidget = _meaningQuiz(context);
    } else if (question.type == 'read') {
      questionWidget = _readQuiz(context);
    } else if (question.type == 'write') {
      questionWidget = _writeQuiz(context);
    } else {
      questionWidget = Container();
    }

    var state = Provider.of<QuizState>(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        questionWidget,
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: question.options.map((opt) {
              return Container(
                margin: EdgeInsets.only(bottom: 10),
                color: Colors.black26,
                child: InkWell(
                  onTap: () {
                    state.selected = opt;
                    _bottomSheet(context, opt);
                    opt.correct? Global.audioCache.play('sounds/correct.wav', mode: PlayerMode.LOW_LATENCY)
                        : Global.audioCache.play('sounds/notcorrect.mp3');
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                            state.selected == opt
                                ? FontAwesomeIcons.checkCircle
                                : FontAwesomeIcons.circle,
                            size: 30),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(left: 16),
                            child: Text(
                              opt.value,
                              style: Theme.of(context).textTheme.body2,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _imageQuiz(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(question.text),
            SizedBox(height: 20),
            Image.asset(
              'assets/covers/${question.typeData}',
              height: 130,
              fit: BoxFit.fitHeight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _expQuiz(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(question.text),
            SizedBox(height: 20),
            Text(question.typeData,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 90,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vocaQuiz(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(question.text),
            SizedBox(height: 20),
            Text(question.typeData,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 80,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meaningQuiz(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(question.text),
            SizedBox(height: 20),
            Text(question.typeData,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 80,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readQuiz(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(question.text),
            SizedBox(height: 20),
            Text(question.typeData,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _writeQuiz(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(question.text),
            SizedBox(height: 20),
            Text(question.typeData,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet shown when Question is answered
  _bottomSheet(BuildContext context, Option opt) {
    bool correct = opt.correct;
    var state = Provider.of<QuizState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(correct ? '맞았어요!' : '틀렸어요!'),
              Text(
                opt.detail,
                style: TextStyle(fontSize: 18, color: Colors.white54),
              ),
              FlatButton(
                color: correct ? Colors.green : Colors.red,
                child: Text(
                  correct ? '다음 문제!' : '다시 맞춰봐요',
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  if (correct) {
                    state.nextPage();
                    Global.audioCache.play('sounds/button.mp3');
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
