
import 'package:clearway/translated_text.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:convert';

class LegalPage extends StatefulWidget {
  final String userFrom;
  final String userTo;

  const LegalPage({Key? key, required this.userFrom, required this.userTo})
      : super(key: key);

  @override
  _LegalPageState createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  final List<Map<String, dynamic>> legalItems = [
    {
      "title": "Visa & Immigration",
      "key": "visaAndImmigration",
      "icon": Icons.airplane_ticket
    },
    {
      "title": "Important Documents", 
      "key": "importantDocuments", 
      "icon": Icons.insert_drive_file
    },
    {
      "title": "Banking", 
      "key": "banking", 
      "icon": Icons.account_balance
    },
    {
      "title": "Taxes", 
      "key": "taxes", 
      "icon": Icons.request_page
    },
  ];

  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_scrollController.hasClients) return;

      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double currentScroll = _scrollController.offset;

      double availableWidth = MediaQuery.of(context).size.width - 32;
      double tileHeight = availableWidth;
      if (tileHeight <= 0) tileHeight = 200;

      final double scrollStep = tileHeight + 16;

      double nextScroll = currentScroll + scrollStep;
      if (nextScroll > maxScroll) {
        nextScroll = 0;
      }

      _scrollController.animateTo(
        nextScroll,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _findStateObject(String stateName) async {
    final candidatePaths = [
      'assets/india_rules.json',
      'assets/us_rules.json'
    ];

    for (final path in candidatePaths) {
      try {
        final raw = await rootBundle.loadString(path);
        final parsed = json.decode(raw);

        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('india')) {
            final india = parsed['india'];
            if (india is Map<String, dynamic> && india.containsKey(stateName)) {
              return Map<String, dynamic>.from(india[stateName]);
            }
            if (india is List) {
              final found = india.firstWhere(
                (it) => it is Map && (it['name'] == stateName || it['name']?.toString().toLowerCase() == stateName.toLowerCase()),
                orElse: () => null,
              );
              if (found != null) return Map<String, dynamic>.from(found);
            }
          }

          if (parsed.containsKey('us')) {
            final us = parsed['us'];
            if (us is Map<String, dynamic> && us.containsKey(stateName)) {
              return Map<String, dynamic>.from(us[stateName]);
            }
            if (us is List) {
              final found = us.firstWhere(
                (it) => it is Map && (it['name'] == stateName || it['name']?.toString().toLowerCase() == stateName.toLowerCase()),
                orElse: () => null,
              );
              if (found != null) return Map<String, dynamic>.from(found);
            }
          }

          if (parsed.containsKey('states') && parsed['states'] is List) {
            final found = (parsed['states'] as List).firstWhere(
              (it) => it is Map && (it['name'] == stateName),
              orElse: () => null,
            );
            if (found != null) return Map<String, dynamic>.from(found);
          }

          if (parsed.containsKey(stateName) && parsed[stateName] is Map) {
            return Map<String, dynamic>.from(parsed[stateName]);
          }
        }

        if (parsed is List) {
          final found = parsed.firstWhere(
            (it) => it is Map && (it['name'] == stateName || it['name']?.toString().toLowerCase() == stateName.toLowerCase()),
            orElse: () => null,
          );
          if (found != null) return Map<String, dynamic>.from(found);
        }
      } catch (e) {
         debugPrint("Error loading state data: $e");
      }
    }

    return null;
  }
  void _onCardClicked(Map<String, dynamic> item) async {
  final String? key = item['key'] as String?;
  if (key == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: TranslatedText('Invalid item configuration.')),
    );
    return;
  }

  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
   
    final stateFromObj = await _findStateObject(widget.userFrom);
    final stateToObj = await _findStateObject(widget.userTo);

    Navigator.pop(context);

    if (stateFromObj == null && stateToObj == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatedText('No data found for either state.')),
      );
      return;
    }

    List<String> contentFrom = [];
    List<String> contentTo = [];

    if (stateFromObj != null && stateFromObj['legal'] is Map) {
      final legalFrom = Map<String, dynamic>.from(stateFromObj['legal']);
      if (legalFrom[key] is List) contentFrom = List<String>.from(legalFrom[key]);
    }

    if (stateToObj != null && stateToObj['legal'] is Map) {
      final legalTo = Map<String, dynamic>.from(stateToObj['legal']);
      if (legalTo[key] is List) contentTo = List<String>.from(legalTo[key]);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _LegalComparisonPage(
          title: item['title'],
          stateFromName: widget.userFrom,
          stateToName: widget.userTo,
          contentFrom: contentFrom,
          contentTo: contentTo,
          icon: item['icon'] as IconData,
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context); // Dismiss loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: TranslatedText('Error loading data. Please try again.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const TranslatedText("⚖ Legal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, size: 28),
            tooltip: "Home",
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
IconButton(
  icon: Icon(Icons.translate),
  onPressed: () async {
    await clearTranslationCache();
    setState(() {});
  },
),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                if (value.text.isEmpty) return const Iterable<String>.empty();
                return legalItems
                    .map((e) => e['title'] as String)
                    .where((title) => title.toLowerCase().startsWith(value.text.toLowerCase()));
              },
              onSelected: (selected) {
                final match = legalItems.firstWhere((e) => e['title'] == selected);
                _onCardClicked(match);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search Legal Topics...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (v) {
                    final match = legalItems.firstWhere(
                      (it) => (it['title'] as String).toLowerCase() == v.toLowerCase(),
                      orElse: () => <String, dynamic>{},
                    );
                    if (match.isNotEmpty) {
                      _onCardClicked(match);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not found")));
                    }
                    onFieldSubmitted();
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                TranslatedText(
                  "⚖ Stay aware of rules & rights in your destination",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'RobotoMono',
                    color: Colors.indigo[900],
                    letterSpacing: 1.2,
                  ),
                  //textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                TranslatedText(
                  "“Navigate legal requirements with confidence.”",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[800],
                  ),
                  //textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: GridView.count(
              controller: _scrollController,
              crossAxisCount: 1,
              childAspectRatio: 1,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: legalItems.map((item) => _buildLegalCard(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _onCardClicked(item),
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item['icon'], size: 90, color: Colors.blueAccent),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TranslatedText(
                item['title'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono',
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalComparisonPage extends StatelessWidget {
  final String title;
  final String stateFromName;
  final String stateToName;
  final List<String> contentFrom;
  final List<String> contentTo;
  final IconData icon;
  final bool debugMode;

  const _LegalComparisonPage({
    super.key,
    required this.title,
    required this.stateFromName,
    required this.stateToName,
    required this.contentFrom,
    required this.contentTo,
    required this.icon,
    this.debugMode = false, // Set this to false to disable debug prints by default
  });

  Widget _buildComparisonRow({
    required String leftTitle,
    required String leftDesc,
    required String rightTitle,
    required String rightDesc,
    required String centerText,
    required IconData leftIcon,
    required IconData rightIcon,
    required int index,
  }) {
    if (debugMode) {
      debugPrint('Building comparison row $index');
      debugPrint('Left desc: $leftDesc');
      debugPrint('Right desc: $rightDesc');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildRuleCard(
            leftTitle,
            leftDesc,
            leftIcon,
            "${stateFromName}_$index",
          ),
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(2, 4),
                  )
                ],
              ),
              child: TranslatedText(
                centerText,
                uniqueKey: "point_${index + 1}_$stateFromName",
                debugMode: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: _buildRuleCard(
            rightTitle,
            rightDesc,
            rightIcon,
            "${stateToName}_$index",
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(String title, String desc, IconData icon, String uniqueKey) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: Colors.black87),
          const SizedBox(height: 8),
          TranslatedText(
            title,
            uniqueKey: "${uniqueKey}_title",
            debugMode: false,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          TranslatedText(
            desc,
            uniqueKey: "${uniqueKey}_desc",
            debugMode: false,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxLength = contentFrom.length > contentTo.length ? contentFrom.length : contentTo.length;

    if (debugMode) {
      debugPrint('Building LegalComparisonPage');
      debugPrint('Title: $title');
      debugPrint('From: $stateFromName, Content length: ${contentFrom.length}');
      debugPrint('To: $stateToName, Content length: ${contentTo.length}');
      debugPrint('Max length: $maxLength');
    }

    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(
          title,
          uniqueKey: "page_title_$title",
          debugMode: false,
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await clearTranslationCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Translation cache cleared')),
              );
            },
          ),
        ],
      ),
      body: maxLength == 0
          ? Center(
              child: TranslatedText(
                'No legal information available for this category.',
                uniqueKey: "no_data_message",
                debugMode: false,
                style: const TextStyle(fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TranslatedText(
                              stateFromName,
                              uniqueKey: "from_state_title_$stateFromName",
                              debugMode: false,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                          
                           const SizedBox(height: 4),
                            TranslatedText(
                              stateToName,
                              uniqueKey: "to_state_title_$stateToName",
                              debugMode: false,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  ...List.generate(maxLength, (index) {
                    final fromText = index < contentFrom.length ? contentFrom[index] : "No data available";
                    final toText = index < contentTo.length ? contentTo[index] : "No data available";

                    return Column(
                      children: [
                        _buildComparisonRow(
                          leftTitle: stateFromName,
                          leftDesc: fromText,
                          rightTitle: stateToName,
                          rightDesc: toText,
                          centerText: "Point ${index + 1}",
                          leftIcon: icon,
                          rightIcon: icon,
                          index: index,
                        ),
                        if (index < maxLength - 1) const SizedBox(height: 40),
                      ],
                    );
                  }),
                ],
              ),
            ),
    );
  }
}