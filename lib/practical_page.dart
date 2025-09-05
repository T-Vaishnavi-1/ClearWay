
import 'package:clearway/translated_text.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:convert';

class PracticalPage extends StatefulWidget {
  final String userFrom;
  final String userTo;

  const PracticalPage({Key? key, required this.userFrom, required this.userTo})
      : super(key: key);

  @override
  _PracticalPageState createState() => _PracticalPageState();
}

class _PracticalPageState extends State<PracticalPage> {
  final List<Map<String, dynamic>> practicalItems = [
    {"title": "Driving", "key": "driving", "icon": Icons.directions_car},
    {"title": "Accommodation", "key": "accommodation", "icon": Icons.home},
    {"title": "Packing & Shipping", "key": "packingAndShipping", "icon": Icons.local_shipping},
    {"title": "Healthcare Preparations", "key": "healthcarePreparations", "icon": Icons.local_hospital},
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

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch both state objects
      final stateFromObj = await _findStateObject(widget.userFrom);
      final stateToObj = await _findStateObject(widget.userTo);

      Navigator.pop(context); // Dismiss loading indicator

      if (stateFromObj == null && stateToObj == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('No data found for either state.')),
        );
        return;
      }

      List<String> contentFrom = [];
      List<String> contentTo = [];

      if (stateFromObj != null && stateFromObj['practical'] is Map) {
        final practicalFrom = Map<String, dynamic>.from(stateFromObj['practical']);
        if (practicalFrom[key] is List) contentFrom = List<String>.from(practicalFrom[key]);
      }

      if (stateToObj != null && stateToObj['practical'] is Map) {
        final practicalTo = Map<String, dynamic>.from(stateToObj['practical']);
        if (practicalTo[key] is List) contentTo = List<String>.from(practicalTo[key]);
      }

     
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _PracticalComparisonPage(
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
      Navigator.pop(context); 
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
        title: const TranslatedText("🛠 Practical"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, size: 28),
            tooltip: "Home",
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
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
                return practicalItems
                    .map((e) => e['title'] as String)
                    .where((title) => title.toLowerCase().startsWith(value.text.toLowerCase()));
              },
              onSelected: (selected) {
                final match = practicalItems.firstWhere((e) => e['title'] == selected);
                _onCardClicked(match);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search Practical Topics...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (v) {
                    final match = practicalItems.firstWhere(
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
                  "🚆 Get reliable info on transport, connections, and safe routes to your destination",
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
                  "“Plan your journey with practical insights.”",
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
              children: practicalItems.map((item) => _buildPracticalCard(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticalCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _onCardClicked(item),
      child: Container(
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

class _PracticalComparisonPage extends StatelessWidget {
  final String title;
  final String stateFromName;
  final String stateToName;
  final List<String> contentFrom;
  final List<String> contentTo;
  final IconData icon;

  const _PracticalComparisonPage({
    super.key,
    required this.title,
    required this.stateFromName,
    required this.stateToName,
    required this.contentFrom,
    required this.contentTo,
    required this.icon,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildRuleCard(
            leftTitle,
            leftDesc,
            leftIcon,
            "practical_left_$index",
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
                uniqueKey: "practical_center_$index",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        Expanded(
          child: _buildRuleCard(
            rightTitle,
            rightDesc,
            rightIcon,
            "practical_right_$index",
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(
      String title, String desc, IconData icon, String uniqueKey) {
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          TranslatedText(
            desc,
            uniqueKey: "${uniqueKey}_desc",
            style: const TextStyle(
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxLength =
        contentFrom.length > contentTo.length ? contentFrom.length : contentTo.length;

    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(
          title,
          uniqueKey: "practical_page_title",
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
                'No practical information available for this category.',
                uniqueKey: "no_practical_info",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Headers
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TranslatedText(
                              stateFromName,
                              uniqueKey: "practical_from_state",
                              textAlign: TextAlign.center,
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
                              uniqueKey: "practical_to_state",
                              textAlign: TextAlign.center,
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
                    final fromText =
                        index < contentFrom.length ? contentFrom[index] : "No data available";
                    final toText =
                        index < contentTo.length ? contentTo[index] : "No data available";

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
