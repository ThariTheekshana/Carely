// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:carely_v2/components/getCaregivers.dart';
import 'package:carely_v2/components/get_username.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

//sign user out method
void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class _HomePageState extends State<HomePage> {
//get current user
  final user = FirebaseAuth.instance.currentUser!;

//store doc ids
  List<String> doccids = [];

//get doc id
  Future<void> getDocId() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('usersv2')
        .where('userType', isEqualTo: 'caregiver')
        .get();

    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      doccids.add(document.reference.id);
    }
  }

//get care giver details
  Future<Map<String, dynamic>?> getCaregiverDetails(String documentId) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('usersv2')
          .doc(documentId)
          .get();

      if (documentSnapshot.exists) {
        return documentSnapshot.data() as Map<String, dynamic>;
      } else {
        // Caregiver not found
        return null;
      }
    } catch (e) {
      print('Error fetching caregiver details: $e');
      return null;
    }
  }

  void showCaregiverDetails(BuildContext context, String caregiverId) async {
    final caregiverDetails = await getCaregiverDetails(caregiverId);

    if (caregiverDetails != null) {
      showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        )),
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 600,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('Caregiver Details'),
                Text('First Name : ${caregiverDetails['First Name']}'),
                Text('Last Name : ${caregiverDetails['Last Name']}'),
                Text('E - mail : ${caregiverDetails['email']}'),
                Text('Address : ${caregiverDetails['address']}'),
              ],
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 200,
            child: Center(
              child: Text('Caregiver details not found'),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: signUserOut,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Text(
              'signed in as ' + user.email!,
            ),
            SizedBox(height: 40),
            Expanded(
              child: FutureBuilder(
                future: getDocId(),
                builder: ((context, snapshot) {
                  return ListView.builder(
                    itemCount: doccids.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 40.0, right: 40, top: 5, bottom: 5),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1.5,
                              color: Colors.grey,
                            ),
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              //name
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 16.0, top: 5),
                                child:
                                    GetCareGivers(documentId: doccids[index]),
                              ),

                              //view profile icon
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 15.0, top: 5),
                                    child: GestureDetector(
                                        onTap: () {
                                          showCaregiverDetails(
                                              context, doccids[index]);
                                        },
                                        child: Icon(
                                            Icons.account_circle_outlined)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
