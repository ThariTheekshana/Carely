// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';
import 'dart:ui';
import 'package:carely_v2/components/reg_textField.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickalert/quickalert.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;

  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //bool for switch pages
  bool isCareRecScreen = true;

  //text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _occupationController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressController = TextEditingController();

  //File? _profileImage;
  File? _selectedImage;

  //disposing all controllers
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _occupationController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future signUp() async {
    //creating user
    if (passwordConfrimed() &&
        _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _mobileController.text.isNotEmpty &&
        _birthdayController.text.isNotEmpty &&
        _occupationController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _selectedImage != null) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on Exception catch (e) {
        print('error ⛔: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password should be at least 6 characters.'),
            duration: Duration(seconds: 2),
            backgroundColor: Color.fromARGB(255, 165, 59, 59),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
      //! new parameter
      String userType = isCareRecScreen ? "recipient" : "caregiver";

      //add user details, new method was called here.
      newaddUserDetails(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _emailController.text.trim(),
        _mobileController.text.trim(),
        _occupationController.text.trim(),
        _birthdayController.text.trim(),
        _addressController.text,
        //! new parameter
        userType,
      );

      //!called update profile image method here since it wont write image data to firestore automatically.
      uploadProfileImage(_emailController.text.trim());

      //adding a tips screen
      Future.delayed(Duration(microseconds: 200), () {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.info,
          title: 'Welcome ${_firstNameController.text.trim()}!',
          text:
              'Empower your journey with our comprehensive support and resources.',
        );
      });
    } else {
      //snackbar to inform the registration was failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getSnackBarText()),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

//old method is here
  Future addUserDetails(
      String firstName, String lastName, String email, int age) async {
    await FirebaseFirestore.instance.collection('usersv2').add({
      'First Name': firstName,
      'Last Name': lastName,
      'email': email,
      'age': age,
    });
  }

  //testing new method here. this method was called in the signUp method.
  Future<void> newaddUserDetails(
    String firstName,
    String lastName,
    String email,
    String mobile,
    String occuption,
    String birthday,
    String address,
    //! new parameter
    String userType,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDocumentReference = FirebaseFirestore.instance
          .collection('usersv2')
          .doc(currentUser.email);

      // Set data in Firestore using the user's email as the document ID
      await userDocumentReference.set({
        'First Name': firstName,
        'Last Name': lastName,
        'email': email,
        'Mobile Phone': mobile,
        'occupation': occuption,
        'birthday': birthday,
        'address': address,
        //new
        'userType': userType,
      });
    } else {
      //handling error
      print('No user is signed in');
    }
  }

//datepicker for birthday  method
  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      _birthdayController.text =
          "${pickedDate.toLocal()}".split(' ')[0]; // Format the selected date
    }
  }

//profile picture uploader
  Future<void> uploadProfileImage(String userEmail) async {
    if (_selectedImage != null) {
      // Generate a unique file name for profile image
      //final uniqueFileName = Uuid().v4();
      final fileName = _emailController.text.trim();

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$fileName.jpg');

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

      //final userEmail = _emailController.text.trim();

      // Call the uploadProfileImage method with the user's email
      //await uploadProfileImage(userEmail);
    } else {
      print('Error picking image');
    }
  }

//password confirmed? method
  bool passwordConfrimed() {
    if (_passwordController.text.trim() ==
        _confirmPasswordController.text.trim()) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords Does Not Match '),
          duration: Duration(seconds: 2),
          backgroundColor: Color.fromARGB(255, 165, 59, 59),
          behavior: SnackBarBehavior.floating,
        ),
      );
      print(' ⛔ Passwords does not match');
      //clear the fields
      _confirmPasswordController.clear();
      return false;
    }
  }

//snack bar text customizer
  String getSnackBarText() {
    if (_emailController.text.isEmpty) {
      return 'Email is Required.';
    } else if (_passwordController.text.isEmpty) {
      return 'Password is Required.';
    } else if (_firstNameController.text.isEmpty) {
      return 'First Name is Required.';
    } else if (_lastNameController.text.isEmpty) {
      return 'Last Name is Required.';
    } else if (_addressController.text.isEmpty) {
      return 'Address is Required.';
    } else if (_mobileController.text.isEmpty) {
      return 'Mobile Phone Number is Required.';
    } else if (_birthdayController.text.isEmpty) {
      return 'Birthday is Required.';
    } else if (_occupationController.text.isEmpty) {
      return 'Occupation is Required.';
    } else if (_selectedImage == null) {
      return 'Profile Photo Is Required.';
    } else {
      return 'Some Error Has Occured. Try Again In a While';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isCareRecScreen
          ? Color.fromARGB(255, 0, 83, 161).withOpacity(0.3)
          : Color.fromARGB(255, 52, 182, 1).withOpacity(0.3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCareRecScreen)
                  //if care recipient text
                  Text(
                    "Greetings !",
                    style: GoogleFonts.lobster(
                      fontSize: 40,
                    ),
                  ),
                if (!isCareRecScreen)
                  //if care giver  text
                  Text(
                    "Greetings !",
                    style: GoogleFonts.lobster(
                      fontSize: 40,
                    ),
                  ),
                SizedBox(height: 5),
                if (isCareRecScreen)
                  //register below text for care recipient
                  Text(
                    "Discover The Care You Deserve.",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                    ),
                  ),
                if (!isCareRecScreen)
                  //register below text for care giver
                  Text(
                    "Join Our Caregiving Community.",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                    ),
                  ),

                SizedBox(height: 5),

                Container(
                  width: MediaQuery.of(context).size.width - 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white.withOpacity(0.6),
                    border: Border.all(
                      width: 1.7,
                      color:
                          isCareRecScreen ? Colors.blue.shade600 : Colors.green,
                    ),
                  ),
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      //!adding from row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isCareRecScreen = true;
                              });
                            },
                            child: Column(
                              children: [
                                Text(
                                  "CARE - RECIPIENT",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCareRecScreen
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                                if (isCareRecScreen)
                                  Container(
                                    height: 2,
                                    width: 130,
                                    color: Colors.blue,
                                  ),
                              ],
                            ),
                          ),

                          //caregiver
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isCareRecScreen = false;
                              });
                            },
                            child: Column(
                              children: [
                                Text(
                                  "CARE - GIVER",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: !isCareRecScreen
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                                if (!isCareRecScreen)
                                  Container(
                                    height: 2,
                                    width: 99,
                                    color: Colors.green,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ), //!new changes ends here

                      //profile pic
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.black.withOpacity(0.1),
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : null,
                          child: _selectedImage == null
                              ? IconButton(
                                  icon: Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                  ),
                                  onPressed: _pickImage,
                                  iconSize: 20,
                                )
                              : null,
                        ),
                      ),

                      //first name field
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 25.0),
                              child: TextField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  suffixIcon: Icon(Icons.person_rounded),
                                  suffixIconColor: Colors.black,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isCareRecScreen
                                          ? Colors.blue
                                          : Colors.green,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  hintText: 'First Name',
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 8.0),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 10),

                          //last name field
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 25.0),
                              child: TextField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  suffixIcon: Icon(Icons.person_rounded),
                                  suffixIconColor: Colors.black,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isCareRecScreen
                                          ? Colors.blue
                                          : Colors.green,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  hintText: 'Last Name',
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 8.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),

                      //!address new text box
                      CustomTextField(
                        controller: _addressController,
                        hintText: 'Address',
                        focusedBorderColor:
                            isCareRecScreen ? Colors.blue : Colors.green,
                        suffixIcon: Icon(Icons.location_on_outlined),
                      ),
                      SizedBox(height: 10),

                      //address field
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      //   child: TextField(
                      //     controller: _addressController,
                      //     decoration: InputDecoration(
                      //       suffixIcon: Icon(Icons.person_outline),
                      //       enabledBorder: OutlineInputBorder(
                      //         borderSide: BorderSide(color: Colors.white),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       focusedBorder: OutlineInputBorder(
                      //         borderSide: BorderSide(color: Colors.deepPurple),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       fillColor: Colors.white,
                      //       filled: true,
                      //       hintText: 'Address',
                      //       contentPadding: EdgeInsets.symmetric(
                      //           vertical: 12.0, horizontal: 8.0),
                      //     ),
                      //   ),
                      // ),

                      // SizedBox(height: 10),

                      //!mobile new text box
                      CustomTextField(
                        controller: _mobileController,
                        hintText: 'Mobile Phone',
                        focusedBorderColor:
                            isCareRecScreen ? Colors.blue : Colors.green,
                        suffixIcon: Icon(Icons.phone_android_rounded),
                      ),
                      SizedBox(height: 10),

                      //mobile phone field
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      //   child: TextField(
                      //     controller: _mobileController,
                      //     keyboardType: TextInputType.number,
                      //     decoration: InputDecoration(
                      //       suffixIcon: Icon(Icons.call_outlined),
                      //       enabledBorder: OutlineInputBorder(
                      //         borderSide: BorderSide(color: Colors.white),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       focusedBorder: OutlineInputBorder(
                      //         borderSide: BorderSide(color: Colors.deepPurple),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       fillColor: Colors.white,
                      //       filled: true,
                      //       hintText: 'Mobile Phone',
                      //       contentPadding: EdgeInsets.symmetric(
                      //           vertical: 12.0, horizontal: 8.0),
                      //     ),
                      //   ),
                      // ),

                      // SizedBox(height: 10),

                      //birthday
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GestureDetector(
                          onTap: () => _selectBirthday(context),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _birthdayController,
                              decoration: InputDecoration(
                                suffixIcon: Icon(Icons.cake_outlined),
                                suffixIconColor: Colors.black,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: isCareRecScreen
                                          ? Colors.blue
                                          : Colors.green),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                hintText: 'Birthday',
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 8.0),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10),

                      //!occupation new text box
                      CustomTextField(
                        controller: _occupationController,
                        hintText: 'Occupation',
                        focusedBorderColor:
                            isCareRecScreen ? Colors.blue : Colors.green,
                        suffixIcon: Icon(Icons.work_outline_rounded),
                      ),
                      SizedBox(height: 10),

                      //occupation field
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      //   child: TextField(
                      //     controller: _occupationController,
                      //     decoration: InputDecoration(
                      //       suffixIcon: Icon(Icons.work_outline_outlined),
                      //       enabledBorder: OutlineInputBorder(
                      //         borderSide: BorderSide(color: Colors.white),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       focusedBorder: OutlineInputBorder(
                      //         borderSide: BorderSide(color: Colors.deepPurple),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       fillColor: Colors.white,
                      //       filled: true,
                      //       hintText: 'Occupation',
                      //       contentPadding: EdgeInsets.symmetric(
                      //           vertical: 12.0, horizontal: 8.0),
                      //     ),
                      //   ),
                      // ),

                      // SizedBox(height: 10),

                      //!email new text box
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'E - Mail',
                        focusedBorderColor:
                            isCareRecScreen ? Colors.blue : Colors.green,
                        suffixIcon: Icon(Icons.email_outlined),
                      ),
                      SizedBox(height: 10),

                      //email field
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      //   child: TextField(
                      //     controller: _emailController,
                      //     keyboardType: TextInputType.emailAddress,
                      //     decoration: InputDecoration(
                      //       suffixIcon: Icon(Icons.email_outlined),
                      //       enabledBorder: OutlineInputBorder(
                      //         borderSide: BorderSide(color: Colors.white),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       focusedBorder: OutlineInputBorder(
                      //         borderSide: BorderSide(color: Colors.deepPurple),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       fillColor: Colors.white,
                      //       filled: true,
                      //       hintText: 'E-mail',
                      //       contentPadding: EdgeInsets.symmetric(
                      //           vertical: 12.0, horizontal: 8.0),
                      //     ),
                      //   ),
                      // ),

                      // SizedBox(height: 10),

                      //password field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            suffixIcon: Icon(Icons.lock_outline_rounded),
                            suffixIconColor: Colors.black,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isCareRecScreen
                                    ? Colors.blue
                                    : Colors.green,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            hintText: 'Password',
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 8.0),
                          ),
                        ),
                      ),

                      SizedBox(height: 10),
                      //confirm-password field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            suffixIcon: Icon(Icons.done_all_rounded),
                            suffixIconColor: Colors.black,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isCareRecScreen
                                    ? Colors.blue
                                    : Colors.green,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            hintText: 'Confrim Password',
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 8.0),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      //register now button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GestureDetector(
                          onTap: signUp,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isCareRecScreen
                                  ? Colors.blue.shade800.withOpacity(0.8)
                                  : Colors.green.shade700.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Register Now',
                                style: GoogleFonts.libreFranklin(
                                  color: Colors.white,
                                  //fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 5),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                //sign in now text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already Registered?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.showLoginPage,
                      child: Text(
                        ' Sign In Now.',
                        style: TextStyle(
                          color: isCareRecScreen
                              ? Colors.blue.shade800
                              : Color.fromARGB(255, 3, 75, 7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
