

import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String? uniqueKey;
  final bool debugMode; 

  const TranslatedText(
    this.text, {
    this.style,
    this.textAlign,
    this.uniqueKey,
    this.debugMode = false,
    super.key,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? translated;
  String _preferredLanguage = "en";
  final translator = GoogleTranslator();
  bool _isTranslating = false;

  
  static final Map<String, Map<String, String>> _contextCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  @override
  void initState() {
    super.initState();
    _loadLanguageAndTranslate();
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || 
        oldWidget.uniqueKey != widget.uniqueKey) {
      _loadLanguageAndTranslate();
    }
  }

  /// Loads preferred language from SharedPreferences
  Future<void> _loadLanguageAndTranslate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newLanguage = prefs.getString("preferredLanguage") ?? "en";
      
      if (widget.debugMode) {
        debugPrint('TranslatedText: Current language: $_preferredLanguage, New language: $newLanguage');
        debugPrint('TranslatedText: Text to translate: "${widget.text}"');
      }

      // Only retranslating if language changed or text changed
      if (newLanguage != _preferredLanguage || 
          (mounted && (translated == null || translated == widget.text))) {
        _preferredLanguage = newLanguage;
        await _translate();
      }
    } catch (e) {
      if (widget.debugMode) {
        debugPrint('TranslatedText: Error loading language: $e');
      }
      if (mounted) {
        setState(() {
          translated = widget.text;
        });
      }
    }
  }

  /// Translating the widget.text into preferred language
  Future<void> _translate() async {
    if (!mounted || _isTranslating) return;
    
    _isTranslating = true;
    
    try {
      final contextKey = widget.uniqueKey ?? 'default_${widget.text.hashCode}';
      final cacheKey = "${widget.text}_$_preferredLanguage";

      // Initializing context cache if not exists
      _contextCache[contextKey] ??= {};

      // Checking if cache is valid 
      final bool isCacheValid = _cacheTimestamps.containsKey(cacheKey) &&
          DateTime.now().difference(_cacheTimestamps[cacheKey]!).inHours < 1;

      // Using cache if available and valid for this context
      if (_contextCache[contextKey]!.containsKey(cacheKey) && isCacheValid) {
        if (mounted) {
          setState(() {
            translated = _contextCache[contextKey]![cacheKey];
          });
        }
        if (widget.debugMode) {
          debugPrint('TranslatedText: Using cached translation: "$translated"');
        }
        return;
      }

      
      if (_preferredLanguage == "en" || 
          widget.text.trim().isEmpty ||
          widget.text.length <= 2) {
        if (mounted) {
          setState(() {
            translated = widget.text;
          });
        }
        _contextCache[contextKey]![cacheKey] = widget.text;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        if (widget.debugMode) {
          debugPrint('TranslatedText: Skipping translation (English/empty/short text)');
        }
        return;
      }

      if (widget.debugMode) {
        debugPrint('TranslatedText: Translating to $_preferredLanguage...');
      }

      final result = await translator.translate(
        widget.text,
        to: _preferredLanguage,
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          translated = result.text;
        });
      }


      _contextCache[contextKey]![cacheKey] = result.text;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      if (widget.debugMode) {
        debugPrint('TranslatedText: Translation successful: "$result.text"');
      }

    } catch (e) {
      if (widget.debugMode) {
        debugPrint('TranslatedText: Translation failed: $e');
      }
    
      if (mounted) {
        setState(() {
          translated = widget.text;
        });
      }
    } finally {
      _isTranslating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = translated ?? widget.text;
    
    if (widget.debugMode) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          displayText,
          style: widget.style?.copyWith(
            backgroundColor: Colors.yellow.withOpacity(0.3),
          ) ?? TextStyle(backgroundColor: Colors.yellow.withOpacity(0.3)),
          textAlign: widget.textAlign,
        ),
      );
    }
    
    return Text(
      displayText,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}


Future<List<String>> translateList(List<String> texts, String contextKey) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final preferredLanguage = prefs.getString("preferredLanguage") ?? "en";
    
    if (preferredLanguage == "en" || texts.isEmpty) {
      return texts;
    }

    final translator = GoogleTranslator();
    final List<String> translatedTexts = [];
    
    for (final text in texts) {
      try {
        final result = await translator.translate(text, to: preferredLanguage);
        translatedTexts.add(result.text);
      } catch (e) {
        translatedTexts.add(text);
      }
    }
    
    return translatedTexts;
  } catch (e) {
    return texts;
  }
}


Future<void> clearTranslationCache() async {
  _TranslatedTextState._contextCache.clear();
  _TranslatedTextState._cacheTimestamps.clear();
}



extension TranslatedTextExtension on String {
  Widget toTranslated({
    TextStyle? style,
    TextAlign? textAlign,
    String? uniqueKey,
    bool debugMode = false,
  }) {
    return TranslatedText(
      this,
      style: style,
      textAlign: textAlign,
      uniqueKey: uniqueKey,
      debugMode: debugMode,
    );
  }
}