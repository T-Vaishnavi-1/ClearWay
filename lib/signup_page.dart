
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'login_page.dart';
import 'package:clearway/main_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
 
  final _formKey = GlobalKey<FormState>();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastStatus = '';
  String _lastError = '';

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _languageController = TextEditingController();

 
  String? selectedLanguage;
  String? _languageError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;


  final Map<String, String> _langCode = {
    "English": "en",
    "Spanish": "es",
    "French": "fr",
    "German": "de",
    "Hindi": "hi",
    "Tamil": "ta",
    "Telugu": "te",
    "Chinese": "zh",
    "Japanese": "ja",
    "Arabic": "ar",
  };

  final List<String> _allLanguages = [
    "English",
    "Spanish",
    "French",
    "German",
    "Hindi",
    "Tamil",
    "Telugu",
    "Chinese",
    "Japanese",
    "Arabic"
  ];

 
  final List<String> _stateSuggestions = [
    "Alabama",
    "Alaska",
    "Arizona",
    "Arkansas",
    "California",
    "Colorado",
    "Connecticut",
    "Delaware",
    "Florida",
    "Georgia",
    "Hawaii",
    "Idaho",
    "Illinois",
    "Indiana",
    "Iowa",
    "Kansas",
    "Kentucky",
    "Louisiana",
    "Maine",
    "Maryland",
    "Massachusetts",
    "Michigan",
    "Minnesota",
    "Mississippi",
    "Missouri",
    "Montana",
    "Nebraska",
    "Nevada",
    "New Hampshire",
    "New Jersey",
    "New Mexico",
    "New York",
    "North Carolina",
    "North Dakota",
    "Ohio",
    "Oklahoma",
    "Oregon",
    "Pennsylvania",
    "Rhode Island",
    "South Carolina",
    "South Dakota",
    "Tennessee",
    "Texas",
    "Utah",
    "Vermont",
    "Virginia",
    "Washington",
    "West Virginia",
    "Wisconsin",
    "Wyoming",
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
  ];

 
  final List<String> _existingUsernames = [ "user123"];

  String generatePassword(int length) {
    const chars =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$%^&*";
    Random rnd = Random();
    return String.fromCharCodes(
        Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<bool> _ensureMicPermission() async {
    final PermissionStatus status = await Permission.microphone.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      final PermissionStatus result = await Permission.microphone.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Microphone permission permanently denied. Please enable it in settings."),
      ));
      await openAppSettings();
      return false;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _usernameController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _listen(TextEditingController controller) async {
    final ok = await _ensureMicPermission();
    if (!ok) return;

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          setState(() => _lastStatus = val);
          if (val == "notListening" || val == "done") {
            setState(() => _isListening = false);
          }
        },
        onError: (err) {
          setState(() {
            _lastError = err.toString();
            _isListening = false;
          });
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            controller.text = val.recognizedWords;
            controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length));
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Speech recognition unavailable")));
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }


  void _onSignUp() async {
  setState(() {
    _languageError = null;
    _autoValidate = AutovalidateMode.onUserInteraction;
  });

  if (_formKey.currentState == null) return;
  if (!_formKey.currentState!.validate()) return;

  if (_existingUsernames
      .map((u) => u.toLowerCase())
      .contains(_usernameController.text.trim().toLowerCase())) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Username already exists. Please choose another.")));
    return;
  }

  // Language check
  String inputLang = _languageController.text.trim();
  if (selectedLanguage == null && inputLang.isEmpty) {
    setState(() => _languageError = "Please select a preferred language");
    return;
  }

  if (inputLang.contains(" ") || inputLang.contains(",")) {
    setState(() => _languageError = "Only one language allowed");
    return;
  }

  if (_passwordController.text != _confirmPasswordController.text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Passwords do not match")));
    return;
  }

  try {
    UserCredential result =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    User? user = result.user;
 
if (user != null && !user.emailVerified) {
  await user.sendEmailVerification();
}

    String langName = selectedLanguage ?? _languageController.text.trim();
    String langCode = _langCode[langName] ?? "en";

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("preferredLanguage", langCode);

    if (user != null) {
      
      await user.sendEmailVerification();

     
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "username": _usernameController.text.trim(),
        "from": _fromController.text.trim(),
        "to": _toController.text.trim(),
        "email": _emailController.text.trim(),
        "preferredLanguage": langCode,
        "createdAt": FieldValue.serverTimestamp(),
      });

      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CheckEmailPage(email: _emailController.text.trim()),
        ),
      );
    }
  } on FirebaseAuthException catch (e) {
    String message = "An error occurred";
    if (e.code == "email-already-in-use") {
      message = "This email is already registered.";
    } else if (e.code == "invalid-email") {
      message = "Invalid email address.";
    } else if (e.code == "weak-password") {
      message = "Password is too weak.";
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
  }
}


  Widget _vSpace(double h) => SizedBox(height: h);

  Widget _sectionTitle(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          t,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
        ),
      );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
        backgroundColor: Colors.blue.shade700,
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
            heightFactor: 0.9,
            child: SingleChildScrollView(
              child: Card(
                elevation: 15,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _vSpace(10),
                        Icon(Icons.person_add_alt_1,
                            size: 90, color: Colors.blue.shade700),
                        _vSpace(12),
                        Text(
                          "Create Account",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade900),
                        ),
                        _vSpace(18),

                     
                        // Username
                   
                        _sectionTitle("Username"),
                        _vSpace(8),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color:
                                    _isListening ? Colors.red : Colors.blue,
                              ),
                              onPressed: () => _listen(_usernameController),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Enter a username";
                            }
                            return null;
                          },
                        ),
                        _vSpace(15),

                      
                        // Coming From
                    
                        _sectionTitle("Coming From"),
                        _vSpace(8),
                        Autocomplete<String>(
                          optionsBuilder: (text) {
                            if (text.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return _stateSuggestions.where((opt) => opt
                                .toLowerCase()
                                .startsWith(text.text.toLowerCase()));
                          },
                          fieldViewBuilder: (context, fieldController,
                              focusNode, onFieldSubmitted) {
                            fieldController.text = _fromController.text;
                            return TextFormField(
                              controller: fieldController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: "Coming From",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_city),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _isListening
                                          ? Icons.mic
                                          : Icons.mic_none,
                                      color: _isListening
                                          ? Colors.red
                                          : Colors.blue),
                                  onPressed: () => _listen(_fromController),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty)
                                  return "Enter your origin state";
                                if (!_stateSuggestions
                                    .map((s) => s.toLowerCase())
                                    .contains(val.toLowerCase())) {
                                  return "Select a valid state from list";
                                }
                                return null;
                              },
                              onChanged: (v) => _fromController.text = v,
                              onEditingComplete: onFieldSubmitted,
                            );
                          },
                          onSelected: (sel) => _fromController.text = sel,
                        ),
                        _vSpace(15),

                       
                        // Going To
                    
                        _sectionTitle("Going To"),
                        _vSpace(8),
                        Autocomplete<String>(
                          optionsBuilder: (text) {
                            if (text.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return _stateSuggestions.where((s) => s
                                .toLowerCase()
                                .startsWith(text.text.toLowerCase()));
                          },
                          fieldViewBuilder: (context, fieldController,
                              focusNode, onFieldSubmitted) {
                            fieldController.text = _toController.text;
                            return TextFormField(
                              controller: fieldController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: "Going To",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.flight_takeoff),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _isListening
                                          ? Icons.mic
                                          : Icons.mic_none,
                                      color: _isListening
                                          ? Colors.red
                                          : Colors.blue),
                                  onPressed: () => _listen(_toController),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty)
                                  return "Enter your destination state";
                                if (!_stateSuggestions
                                    .map((s) => s.toLowerCase())
                                    .contains(val.toLowerCase())) {
                                  return "Select a valid state from list";
                                }
                                return null;
                              },
                              onChanged: (v) => _toController.text = v,
                              onEditingComplete: onFieldSubmitted,
                            );
                          },
                          onSelected: (sel) => _toController.text = sel,
                        ),
                        _vSpace(15),

                       
                        // Email
                    
                        _sectionTitle("Email"),
                        _vSpace(8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return "Enter email";
                            final pattern =
                                r'^[\w\.-]+@([\w-]+\.)+[a-zA-Z]{2,4}$';
                            if (!RegExp(pattern).hasMatch(val.trim()))
                              return "Enter valid email";
                            return null;
                          },
                        ),
                        _vSpace(15),

                    
                        // Password and Confirm
                   
                        _sectionTitle("Password"),
                        _vSpace(8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                                IconButton(
                                  icon: Icon(Icons.refresh),
                                  tooltip: "Generate Password",
                                  onPressed: () {
                                    final pwd = generatePassword(10);
                                    setState(() {
                                    _passwordController.text = pwd;
                                      _confirmPasswordController.text = pwd;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Enter a password";
                            }
                            if (val.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        _vSpace(15),

                        _sectionTitle("Confirm Password"),
                        _vSpace(8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Re-enter your password";
                            }
                            if (val != _passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        _vSpace(15),

                
                        // Preferred Language
                  
                        _sectionTitle("Preferred Language"),
                        _vSpace(8),
                        DropdownButtonFormField<String>(
                          value: selectedLanguage,
                          items: _allLanguages
                              .map((lang) => DropdownMenuItem(
                                    value: lang,
                                    child: Text(lang),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedLanguage = val;
                              _languageController.clear();
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.language),
                          ),
                        ),
                        _vSpace(8),
                        Text(
                          "Or type a language:",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        _vSpace(8),
                        TextFormField(
                          controller: _languageController,
                          decoration: InputDecoration(
                            labelText: "Custom Language",
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? Colors.red : Colors.blue,
                              ),
                              onPressed: () => _listen(_languageController),
                            ),
                          ),
                        ),
                        if (_languageError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              _languageError!,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        _vSpace(25),

                   
                        // Sign Up Button
                  
                        ElevatedButton(
                          onPressed: _onSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        _vSpace(20),

                    
                        // Already account?
                  
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account? "),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginPage()),
                                );
                              },
                              child: Text("Login"),
                            ),
                          ],
                        ),
                        _vSpace(10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class CheckEmailPage extends StatelessWidget {
  final String email;
  CheckEmailPage({required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verify Email"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email, size: 100, color: Colors.blue.shade700),
              SizedBox(height: 20),
              Text(
                "A verification link has been sent to $email.\nPlease check your inbox and verify your email before logging in.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => LoginPage())),
                child: Text("Back to Login"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





