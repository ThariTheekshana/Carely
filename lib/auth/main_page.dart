import 'package:carely_v2/auth/auth_page.dart';
import 'package:carely_v2/components/getCaregivers.dart';
import 'package:carely_v2/pages/login_page.dart';
import 'package:carely_v2/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pages/home_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ProfilePage();
            //return HomePage();
          } else {
            return AuthPage();
          }
        },
      ),
    );
  }
}
