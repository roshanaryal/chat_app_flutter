import 'dart:io';

import 'package:chatapp/widget/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  var _enteredEmail = "";
  var _enteredPassword = "";
  var _enteredUsername = "";
  File? _selectedImage;
  var _isLogin = true;
  var _isAuthentacating = false;

  void _sumit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    if (!_isLogin) {
      if (_selectedImage == null) {
        return;
      }
    }

    if (isValid) {
      setState(() {
        _isAuthentacating = true;
      });

      _formKey.currentState!.save();
      try {
        if (_isLogin) {
          final userCredintial = await _firebase.signInWithEmailAndPassword(
              email: _enteredEmail, password: _enteredPassword);
          print(userCredintial);

          setState(() {
            _isAuthentacating = false;
          });
        } else {
          final userCrediential =
              await _firebase.createUserWithEmailAndPassword(
                  email: _enteredEmail, password: _enteredPassword);

          final storageRef = FirebaseStorage.instance
              .ref('user-images')
              .child('${userCrediential.user!.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          final uploadedImage = await storageRef.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('users')
              .doc('${userCrediential.user!.uid}')
              .set({
            'username': _enteredUsername,
            'email': _enteredEmail,
            'image_url': uploadedImage,
          });

          setState(() {
            _isAuthentacating = false;
          });

          print(userCrediential);
        }
      } on FirebaseAuthException catch (error) {
        setState(() {
          _isAuthentacating = false;
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error : ${error.message}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin:
                    EdgeInsets.only(top: 30, bottom: 20, left: 20, right: 20),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(
                              onPickedImage: (pickedimg) {
                                _selectedImage = pickedimg;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'Email adress'),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@') ||
                                  !value.contains('.')) {
                                return "Please enter valid email adress";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          if (!_isLogin)
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Username'),
                              enableSuggestions: false,
                              onSaved: (value) {
                                _enteredUsername = value!;
                              },
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.trim().length < 4) {
                                  return "Please enter correct username, atleast 4 chracter";
                                }
                                return null;
                              },
                            ),
                          const SizedBox(
                            height: 16,
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Passord'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  value.length < 8) {
                                return "Password must be atleast 8 character long";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          if (_isAuthentacating)
                            const CircularProgressIndicator(),
                          if (!_isAuthentacating)
                            ElevatedButton(
                              onPressed: _sumit,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                              child: Text(
                                _isLogin ? "Log in" : "Sign Up",
                              ),
                            ),
                          const SizedBox(
                            height: 16,
                          ),
                          if (!_isAuthentacating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(
                                _isLogin
                                    ? "Create an account"
                                    : "I already have an account",
                              ),
                            )
                        ],
                      )),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
