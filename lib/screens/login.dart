import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/services.dart';

class LoginScreen extends StatefulWidget {
  createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  AuthService auth = AuthService();

  @override
  void initState() {
    super.initState();
    // if (auth.getUser != null) {
    //   _delay();
    //   Navigator.pushReplacementNamed(context, '/topics');
    // }
    Global.loopSound('sounds/opening.mp3');
  }

  Future<void> _delay() async {
    await Future.delayed(Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              'assets/covers/logo.png',
              height: 280,
              width: 280,
              fit: BoxFit.contain,
            ),
            // FlutterLogo(
            //   size: 150,
            // ),
            Text(
              '퀴즈풀고 만화보자!',
              style: Theme.of(context).textTheme.headline,
              textAlign: TextAlign.center,
            ),
            Text('선물도 있어요~!'),
            LoginButton(
              text: '구글 계정으로 로그인',
              icon: FontAwesomeIcons.google,
              color: Colors.black45,
              loginMethod: auth.googleSignIn,
            ),
            LoginButton(text: '손님으로 퀴즈 맞추기', loginMethod: auth.anonLogin)
          ],
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final Function loginMethod;

  const LoginButton(
      {Key key, this.text, this.icon, this.color, this.loginMethod})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: FlatButton.icon(
        padding: EdgeInsets.all(30),
        icon: Icon(icon, color: Colors.white),
        color: color,
        onPressed: () async {
          var user = await loginMethod();
          if (user != null) {
            Navigator.pushReplacementNamed(context, '/topics');
            Global.stopLoopSound();
            Global.loopSound('sounds/lobby.mp3');
          }
        },
        label: Expanded(
          child: Text('$text', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
