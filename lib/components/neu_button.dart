// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class NeuButton extends StatelessWidget {
  final onTap;
  bool isButtonPressed;

  NeuButton({this.onTap, required this.isButtonPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: 25,
        width: 70,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isButtonPressed ? Colors.grey.shade300 : Colors.grey.shade400,
            ),
            boxShadow: isButtonPressed
                ? [
                    //show no shadows if the button isnt pressed
                  ]
                : [
                    //darker sahdow for bottom right side
                    BoxShadow(
                      color: Colors.grey.shade500,
                      offset: Offset(6, 6),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),

                    //lighter one for top left side
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-6, -0),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]),
        child: Center(
          child: Text(
            'hello',
            style: TextStyle(
                color: isButtonPressed
                    ? Colors.blue.shade200
                    : Colors.blue.shade800),
          ),
        ),
      ),
    );
  }
}
