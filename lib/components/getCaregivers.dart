import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GetCareGivers extends StatelessWidget {
  final String documentId;

  GetCareGivers({required this.documentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usersv2')
          .doc(documentId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.hasData) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            return Text(
              '${data['First Name']}' + '  ' + '${data['Last Name']}',
              style: GoogleFonts.ubuntu(
                color: Colors.black,
                fontSize: 16,
              ),
            );
          } else {
            return Text('No data available.');
          }
        }

        return Text('Loading data...');
      },
    );
  }
}
