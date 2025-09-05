
import 'dart:async';
import 'package:flutter/material.dart';
import 'main_page.dart';
import 'translated_text.dart';


class WelcomeUserPage extends StatefulWidget {
  final String uid; //only with uid

  const WelcomeUserPage({
    Key? key,
    required this.uid,
  }) : super(key: key);

  @override
  _WelcomeUserPageState createState() => _WelcomeUserPageState();
}

class _WelcomeUserPageState extends State<WelcomeUserPage> {
  @override
  void initState() {
    super.initState();

 
    Timer(const Duration(seconds: 10), _goToMainPage);
  }

  void _goToMainPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(uid: widget.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const SizedBox(height: 10),
            const TranslatedText(
              "We’re glad to have you 🎉",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _goToMainPage,
              child: const TranslatedText(
                "Go to Home",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

