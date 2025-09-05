
import 'package:clearway/translated_text.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:convert';

class EmotionalPage extends StatefulWidget {
  final String userFrom;
  final String userTo;

  const EmotionalPage({Key? key, required this.userFrom, required this.userTo})
      : super(key: key);

  @override
  _EmotionalPageState createState() => _EmotionalPageState();
}

class _EmotionalPageState extends State<EmotionalPage> {
  final List<Map<String, dynamic>> emotionalItems = [
    {
      "title": "Adaptability",
      "key": "adaptability",
      "icon": Icons.psychology
    },
    {
      "title": "Support Systems",
      "key": "supportSystems",
      "icon": Icons.support
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

      Navigator.pop(context); // Dismissing loading indicator

      if (stateFromObj == null && stateToObj == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('No data found for either state.')),
        );
        return;
      }

      List<String> contentFrom = [];
      List<String> contentTo = [];

      if (stateFromObj != null && stateFromObj['emotional'] is Map) {
        final emotionalFrom = Map<String, dynamic>.from(stateFromObj['emotional']);
        if (emotionalFrom[key] is List) contentFrom = List<String>.from(emotionalFrom[key]);
      }

      if (stateToObj != null && stateToObj['emotional'] is Map) {
        final emotionalTo = Map<String, dynamic>.from(stateToObj['emotional']);
        if (emotionalTo[key] is List) contentTo = List<String>.from(emotionalTo[key]);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _EmotionalComparisonPage(
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
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const TranslatedText("💖 Emotional"),
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
                return emotionalItems
                    .map((e) => e['title'] as String)
                    .where((title) => title.toLowerCase().startsWith(value.text.toLowerCase()));
              },
              onSelected: (selected) {
                final match = emotionalItems.firstWhere((e) => e['title'] == selected);
                _onCardClicked(match);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search Emotional Topics...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (v) {
                    final match = emotionalItems.firstWhere(
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
              children: const [
                TranslatedText(
                  "🧠💖",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'RobotoMono',
                    color: Colors.pink,
                    letterSpacing: 1.2,
                  ),
                  //textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                TranslatedText(
                  "Build resilience for new challenges.",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
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
             // mainAxisSpering: 16,
              crossAxisSpacing: 16,
              children: emotionalItems.map((item) => _buildEmotionalCard(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionalCard(Map<String, dynamic> item) {
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
            Icon(item['icon'], size: 90, color: Colors.pink),
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
class _EmotionalComparisonPage extends StatelessWidget {
  final String title;
  final String stateFromName;
  final String stateToName;
  final List<String> contentFrom;
  final List<String> contentTo;
  final IconData icon;

  const _EmotionalComparisonPage({
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
            "left_rule_$index",
          ),
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink,
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
                uniqueKey: "center_text_$index",
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
            "right_rule_$index",
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
          uniqueKey: "emotional_page_title",
        ),
        backgroundColor: Colors.pink,
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
                'No emotional information available for this category.',
                uniqueKey: "no_emotional_info",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
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
                              uniqueKey: "from_state_name",
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
                              uniqueKey: "to_state_name",
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

