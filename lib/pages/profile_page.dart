// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'dart:ui';

import 'package:carely_v2/components/text_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:quickalert/quickalert.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

//sign user out method
void signUserOut(BuildContext context) async {
  await FirebaseAuth.instance.signOut();

  //showing snack bar
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('You have been signed out successfully.'),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _ProfilePageState extends State<ProfilePage> {
  //getting the current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  //getting all users
  final userCollection = FirebaseFirestore.instance.collection('usersv2');

  //to select a profile picture
  File? _selectedImage;

  //edit field method
  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (BuildContext context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AlertDialog(
            backgroundColor: Colors.blue.withOpacity(0.2),
            title: Text(
              'Editing  ' + field,
              style: TextStyle(color: Colors.black54),
            ),
            icon: LottieBuilder.network(
              'https://lottie.host/8cdaf92e-2175-4fa9-8331-e835415efb58/750w19oY5k.json',
              height: 50,
              width: 100,
            ),
            content: TextField(
              autofocus: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter a New $field',
                hintStyle: TextStyle(color: Colors.white),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                newValue = value;
              },
            ),
            actions: [
              //cancel button
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),

              //accept button
              TextButton(
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.black54),
                ),
                onPressed: () {
                  if (newValue.trim().length > 0) {
                    userCollection
                        .doc(currentUser.email)
                        .update({field: newValue});
                  }

                  Navigator.of(context).pop();

                  if (newValue != '')
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.success,
                      title: 'Success !',
                      text: 'Successfully Saved New $field ',
                    );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //fetching profile picture method
  Future<String?> getProfilePictureURL() async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser.email}.jpg');

      final downloadURL = await storageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error retrieving profile picture: $e');
      return null;
    }
  }

  //editing existing photo
  Future<void> uploadProfileImage(String userEmail) async {
    if (_selectedImage != null) {
      final fileName = currentUser.email;

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$fileName.jpg');

        // Delete the existing image file, if it exists
        try {
          await storageRef.delete();
        } catch (e) {
          print('Error deleting existing image: $e');
        }

        //uploading the new image
        final uploadTask = storageRef.putFile(_selectedImage!);

        // Wait for the upload to complete
        await uploadTask.whenComplete(() async {
          // Get the download URL of the uploaded image
          final downloadURL = await storageRef.getDownloadURL();

          // Store the mapping of user email to the unique file name in Firestore
          await FirebaseFirestore.instance
              .collection('usersv2')
              .doc(userEmail)
              .update({
            'imageFileName': fileName,
            'imageUrl': downloadURL,
          });
        });

        //!quickalert was added to inform the changes to the user.
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Success !',
          text: 'Successfully Updated Your Profile Picture',
        );
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });

      final userEmail = currentUser.email;

      //Call the uploadProfileImage method with the user's email
      await uploadProfileImage(userEmail!);
    } else {
      print('Error picking image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Your Profile'),
          backgroundColor: Colors.black,
          //leading: Icon(Icons.abc_outlined),
          actions: [
            IconButton(
              onPressed: () => signUserOut(context),
              icon: Icon(Icons.logout),
            ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usersv2')
              .doc(currentUser.email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>;

                return ListView(
                  children: [
                    SizedBox(height: 10),

                    //profile picture
                    FutureBuilder<String?>(
                      future: getProfilePictureURL(),
                      builder: (context, profilePictureSnapshot) {
                        if (profilePictureSnapshot.connectionState ==
                                ConnectionState.done &&
                            profilePictureSnapshot.data != null) {
                          // Display the profile picture using CircleAvatar
                          return CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                NetworkImage(profilePictureSnapshot.data!),
                            backgroundColor: Colors.transparent,
                            child: IconButton(
                              onPressed: _pickImage,
                              icon: Icon(Icons.edit),
                            ),
                          );
                        } else {
                          // Display a placeholder or loading indicator while fetching the picture
                          return LottieBuilder.network(
                            'https://lottie.host/8cdaf92e-2175-4fa9-8331-e835415efb58/750w19oY5k.json',
                            width: 100,
                            height: 100,
                          );
                        }
                      },
                    ),

                    SizedBox(height: 10),
                    Text(
                      userData['First Name'] +
                          ' ' +
                          userData['Last Name'] +
                          '.',
                      style: GoogleFonts.cabin(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    //user email
                    Text(
                      currentUser.email!,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        //fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      userData['userType'] + '.',
                      textAlign: TextAlign.center,
                    ),

                    //first name
                    MyTextBox(
                      text: userData['First Name'],
                      sectionName: 'First Name',
                      onPressed: () => editField('First Name'),
                    ),

                    //second name
                    MyTextBox(
                      text: userData['Last Name'],
                      sectionName: 'Last Name',
                      onPressed: () => editField('Last Name'),
                    ),

                    //occupation
                    MyTextBox(
                      text: userData['occupation'],
                      sectionName: 'Occupation',
                      onPressed: () => editField('occupation'),
                    ),

                    //mobile number
                    MyTextBox(
                      text: userData['Mobile Phone'],
                      sectionName: 'Mobile Phone',
                      onPressed: () => editField('Mobile Phone'),
                    ),

                    //address
                    MyTextBox(
                      text: userData['address'],
                      sectionName: 'Address',
                      onPressed: () => editField('address'),
                    ),
                  ],
                );
              } else {
                // Document doesn't exist
                return Center(
                  child: Text('Document does not exist'),
                );
              }
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error.toString()}'),
              );
            }

            return Center(
              child: Text('Loading....'),
            );
          },
        ));
  }
}
