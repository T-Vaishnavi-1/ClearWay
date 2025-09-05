import 'package:clearway/signup_page.dart';
import 'package:clearway/translated_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'legal_page.dart';
import 'practical_page.dart';
import 'financial_page.dart';
import 'cultural_page.dart';
import 'communication_page.dart';
import 'emotional_page.dart';
import 'settling_page.dart';

void main() {
  runApp(MyApp());
}

// Root widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearWay',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Main Page
class MainPage extends StatefulWidget {
  final String? uid;
  MainPage({this.uid});
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String currentUsername = "";
  String currentEmail = "";
  String currentPassword = "";
  String currentLanguage = "";
  String currentUserFrom = "";
  String currentUserTo = "";

  final List<Map<String, dynamic>> storedItems = [
    {"title": "Legal", "icon": Icons.document_scanner},
    {"title": "Practical", "icon": Icons.build},
    {"title": "Finance", "icon": Icons.account_balance_wallet},
    {"title": "Communication", "icon": Icons.wifi},
    {"title": "Cultural", "icon": Icons.people},
    {"title": "Settling", "icon": Icons.home},
    {"title": "Emotional", "icon": Icons.psychology},
  ];

  final TextEditingController searchController = TextEditingController();
  String? notFoundMessage;
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.uid != null) {
      _fetchUserData(widget.uid!);
    }
    _startAutoScroll();
  }

  void _fetchUserData(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (doc.exists) {
        setState(() {
          currentUsername = doc['username'] ?? "";
          currentEmail = doc['email'] ?? "";
          currentUserFrom = doc['from'] ?? "";
          currentUserTo = doc['to'] ?? "";
          currentLanguage = doc['preferredLanguage'] ?? "";
        });
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

void _startAutoScroll() {

  _timer?.cancel();

  _timer = Timer.periodic(const Duration(seconds: 2), (_) {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      double nextScroll = currentScroll + 160;

      if (nextScroll >= maxScroll) {
        nextScroll = 0; 
      }

      _scrollController.animateTo(
        nextScroll,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });
}

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _showNotFound() {
    setState(() {
      notFoundMessage = "Item not found!";
    });
    Timer(Duration(seconds: 5), () {
      setState(() {
        notFoundMessage = null;
      });
    });
  }

  void _onCardClicked(String name) {
    if (name == "Legal") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LegalPage(userFrom: currentUserFrom, userTo: currentUserTo),
        ),
      );
    } else if (name == "Practical") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PracticalPage(userFrom: currentUserFrom, userTo: currentUserTo),
        ),
      );
    } else if (name == "Finance") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FinancialPage(userFrom: currentUserFrom, userTo: currentUserTo),
        ),
      );
    } else if (name == "Cultural") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CulturalPage(
              userFrom: currentUserFrom,
              userTo: currentUserTo,
              currentLanguage: currentLanguage),
        ),
      );
    } else if (name == "Communication") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CommunicationPage(userFrom: currentUserFrom, userTo: currentUserTo),
        ),
      );
    } else if (name == "Emotional") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EmotionalPage(userFrom: currentUserFrom, userTo: currentUserTo),
        ),
      );
    } else if (name == "Settling") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SettlingPage(userFrom: currentUserFrom, userTo: currentUserTo),
        ),
      );
    } else {
      _showNotFound();
    }
  }

  void _onSearch(String value) {
    final found = storedItems.firstWhere(
      (item) => (item['title'] as String).toLowerCase() == value.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );
    if (found.isNotEmpty) {
      _onCardClicked(found['title']);
    } else {
      _showNotFound();
    }
  }

  void _openEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserPage(
          username: currentUsername,
          email: currentEmail,
          password: currentPassword,
          preferredLanguage: currentLanguage,
        ),
      ),
    );
    if (result != null && result is Map<String, String>) {
      currentUsername = result['username']!;
      currentEmail = result['email']!;
      currentPassword = result['password']!;
      currentLanguage = result['preferredLanguage']!;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MainPage(uid: FirebaseAuth.instance.currentUser?.uid),
        ),
      );
    }
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _onCardClicked(item['title'] as String),
      child: Container(
        margin: EdgeInsets.all(8),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item['icon'], size: 60, color: Colors.blueAccent),
            SizedBox(height: 12),
            TranslatedText(
              item['title'] as String,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'RobotoMono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(currentUsername),
              accountEmail: Text(currentEmail),
              currentAccountPicture: CircleAvatar(
                child: TranslatedText(currentUsername.isNotEmpty
                    ? currentUsername[0].toUpperCase()
                    : '?'),
              ),
              otherAccountsPictures: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: _openEditPage,
                ),
              ],
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: TranslatedText("Change Password"),
              subtitle: TranslatedText('*' * currentPassword.length),
              onTap: _openEditPage,
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: TranslatedText("Preferred Language"),
              subtitle: TranslatedText(currentLanguage),
              onTap: _openEditPage,
            ),
            ListTile(
              leading: Icon(Icons.close),
              title: TranslatedText("Close"),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Icon(Icons.flutter_dash, size: 35),
            SizedBox(width: 10),
            TranslatedText(
              'ClearWay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return storedItems
                          .map((e) => e['title'] as String)
                          .where((option) => option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: _onCardClicked,
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                      searchController.text = controller.text;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: _onSearch,
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: TranslatedText(
                      "🌍 Check rules before crossing borders",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'RobotoMono',
                        color: Colors.indigo[900],
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            if (notFoundMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red),
                      SizedBox(height: 10),
                      TranslatedText(
                        notFoundMessage!,
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ),
            if (notFoundMessage == null)
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: storedItems
                                .asMap()
                                .entries
                                .where((e) => e.key % 2 == 0)
                                .map((e) => _buildCard(e.value))
                                .toList(),
                          ),
                          Row(
                            children: storedItems
                                .asMap()
                                .entries
                                .where((e) => e.key % 2 != 0)
                                .map((e) => _buildCard(e.value))
                                .toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Edit User Page
class EditUserPage extends StatefulWidget {
  final String username;
  final String email;
  final String password;
  final String preferredLanguage;

  EditUserPage({
    required this.username,
    required this.email,
    required this.password,
    required this.preferredLanguage,
  });

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool obscurePassword = true;

  final Map<String, String> _languageMap = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'hi': 'Hindi',
    'ta': 'Tamil',
    'te': 'Telugu',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ar': 'Arabic',
  };

  String? _selectedLanguageName;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.username);
    emailController = TextEditingController(text: widget.email);
    passwordController = TextEditingController(text: widget.password);

    if (widget.preferredLanguage.isNotEmpty &&
        _languageMap.containsKey(widget.preferredLanguage)) {
      _selectedLanguageName = _languageMap[widget.preferredLanguage];
    } else if (widget.preferredLanguage.isNotEmpty) {
      _selectedLanguageName = widget.preferredLanguage;
    } else {
      _selectedLanguageName = null;
    }
  }

  void _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    String selectedCode = widget.preferredLanguage;
    if (_selectedLanguageName != null) {
      bool found = false;
      for (var entry in _languageMap.entries) {
        if (entry.value == _selectedLanguageName) {
          selectedCode = entry.key;
          found = true;
          break;
        }
      }
      if (!found) {
        if (_languageMap.containsKey(_selectedLanguageName)) {
          selectedCode = _selectedLanguageName!;
        }
      }
    } else {
      selectedCode = '';
    }

    final updatedData = {
      'username': usernameController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text,
      'preferredLanguage': selectedCode,
    };

    await prefs.setString("preferredLanguage", updatedData['preferredLanguage']!);

    if (uid != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update(updatedData);
    }

    Navigator.pop(context, updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TranslatedText("Edit User Info")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: usernameController,
              decoration:
                  InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person)),
            ),
            SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration:
                  InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
            ),
            SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _languageMap.values.contains(_selectedLanguageName)
                  ? _selectedLanguageName
                  : null,
              decoration: InputDecoration(
                labelText: "Preferred Language",
                prefixIcon: Icon(Icons.language),
              ),
              items: _languageMap.values.map((String name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguageName = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _saveChanges, child: Text("Save Changes")),
          ],
        ),
      ),
    );
  }
}


class DetailPage extends StatelessWidget {
  final String title;
  DetailPage({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text("Content for $title", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}