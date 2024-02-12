// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:carely_v2/auth/main_page.dart';
import 'package:carely_v2/components/neu_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  //text controllers
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  //password reset method
  Future passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            //title: Text('Hello There'),
            content: Text(
                'password reset link was sent! Please check your mail box'),
          );
        },
      );
      //clear email field
      _emailController.clear();
    } on FirebaseAuthException catch (e) {
      //print(e);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('E-mail is not verified with our system.'),
            content: Text(e.message.toString()),
          );
        },
      );
    }
  }

  bool isButtonPressed = false;

  void neuButtonPresed() {
    setState(() {
      if (isButtonPressed == false) {
        isButtonPressed = true;
      } else if (isButtonPressed == true) {
        isButtonPressed = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              width: 200,
              height: 200,
              child: LottieBuilder.network(
                'https://lottie.host/73f08757-c273-43b5-8311-ca3d2ee2f78c/lr8rYTIHDv.json',
                fit: BoxFit.fill,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              'Please enter your email. we will send you a password reset link shortly',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),

          SizedBox(height: 30),

          //email textfield
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
                hintText: 'E-mail',
              ),
            ),
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: MaterialButton(
              onPressed: passwordReset,
              color: Color.fromARGB(166, 45, 167, 47),
              child: Text('Send Link'),
            ),
          ),
          SizedBox(height: 10),
          NeuButton(
            onTap: neuButtonPresed,
            isButtonPressed: isButtonPressed,
          ),
        ],
      ),
    );
  }
}
