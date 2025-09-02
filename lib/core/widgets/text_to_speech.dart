import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/tts_voice_model.dart';
import 'package:assign_erp/core/widgets/button/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech extends StatefulWidget {
  final String title;
  final String subTitle;
  final Map<String, dynamic> guides;

  const TextToSpeech({
    super.key,
    required this.title,
    required this.subTitle,
    required this.guides,
  });

  @override
  State<TextToSpeech> createState() => TextToSpeechState();
}

class TextToSpeechState extends State<TextToSpeech> {
  final FlutterTts _flutterTts = FlutterTts();
  List<TTSVoice> _voices = [];
  TTSVoice? _currentVoice;
  String? _currentlySpeakingKey; // Track the currently speaking text key
  int? _curWordStart, _curWordEnd;

  @override
  void initState() {
    super.initState();
    _initTTS();

    _flutterTts.setProgressHandler((text, start, end, currentWord) {
      // Handle highlight text in progress
      setState(() {
        _curWordStart = start;
        _curWordEnd = end;
      });
    });

    _flutterTts.setStartHandler(() {
      // Handle start of speech
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _currentlySpeakingKey = null;
        _curWordStart = null;
        _curWordEnd = null;
      });
    });
  }

  Future<void> _initTTS() async {
    try {
      final data = await _flutterTts.getVoices;
      final voicesList = List<TTSVoice>.from(
        data.map(
          (voice) => TTSVoice.fromMap(Map<String, dynamic>.from(voice as Map)),
        ),
      );

      setState(() {
        _voices = voicesList
            .where((voice) => voice.name.contains("en"))
            .toList();
        _currentVoice = _voices.isNotEmpty ? _voices.first : null;
        if (_currentVoice != null) {
          _setVoice(_currentVoice!);
        }
      });
      // debugPrint('Voices: $_voices');
    } catch (e) {
      debugPrint('Text-to-Speech Error: $e');
    }
  }

  Future<void> _setVoice(TTSVoice voice) async {
    await _flutterTts.setVoice({'name': voice.name, 'locale': voice.locale});
  }

  Future<void> _speak(String key, String text) async {
    if (_currentlySpeakingKey == key) {
      await _flutterTts.stop();
      setState(() {
        _currentlySpeakingKey = null;
        _curWordStart = null;
        _curWordEnd = null;
      });
    } else {
      await _flutterTts.speak(text);
      setState(() {
        _currentlySpeakingKey = key;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: widget.title,
      subTitle: widget.subTitle,
      children: [
        if (_voices.isNotEmpty) _speakerSelector(),
        ...widget.guides.entries.map(
          (entry) => _buildListItem(
            context,
            key: entry.key,
            content: entry.value,
            isSpeaking: _currentlySpeakingKey == entry.key,
            onPressed: () => _speak(entry.key, entry.value),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(
    BuildContext context, {
    required String key,
    required String content,
    bool isSpeaking = false,
    required Future<void> Function() onPressed,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(bottom: 0.0),
      title: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: context.textTheme.titleMedium?.copyWith(
                color: kPrimaryColor,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            tooltip: isSpeaking ? 'Pause speech' : 'Listen to speech',
            icon: Icon(
              isSpeaking ? Icons.pause : Icons.volume_up,
              color: context.colorScheme.error,
              size: 16,
            ),
            onPressed: onPressed,
          ),
        ],
      ),
      subtitle: RichText(
        softWrap: true,
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: kDarkTextColor),
          children: _buildTextSpans(content),
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(String content) {
    List<TextSpan> textSpans = [];
    final currentKey = _currentlySpeakingKey;
    final startIndex = _curWordStart ?? 0;
    final endIndex = _curWordEnd ?? 0;

    if (currentKey != null && content == widget.guides[currentKey]) {
      final preText = content.substring(0, startIndex);
      final highlightedText = content.substring(startIndex, endIndex);
      final postText = content.substring(endIndex);

      if (preText.isNotEmpty) {
        textSpans.add(TextSpan(text: preText));
      }
      if (highlightedText.isNotEmpty) {
        textSpans.add(
          TextSpan(
            text: highlightedText,
            style: const TextStyle(
              color: kWhiteColor,
              backgroundColor: kDangerColor,
            ),
          ),
        );
      }
      if (postText.isNotEmpty) {
        textSpans.add(TextSpan(text: postText));
      }
    } else {
      textSpans.add(TextSpan(text: content));
    }

    return textSpans;
  }

  Widget _speakerSelector() {
    final voiceNames = _voices.map((voice) => voice.name).toList();

    // Use _currentVoice's name if it's not null; otherwise, use the first item in the list if available
    final selectedVoiceName = _currentVoice?.name ?? voiceNames.first;

    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: StaticDropdown<String>(
        icon: const Icon(Icons.support_agent, color: kDangerColor),
        items: voiceNames,
        label: 'Voice Type',
        initialValue: selectedVoiceName,
        getValue: (type) => type,
        getDisplayText: (type) => type,
        onChanged: (String? value) {
          if (value != null) {
            final selectedVoice = _voices.firstWhere(
              (voice) => voice.name == value,
              orElse: () => _currentVoice ?? TTSVoice(name: '', locale: ''),
            );
            if (selectedVoice.isNotEmpty) {
              _setVoice(selectedVoice);
            }
          }
        },
      ),
    );
  }

  /*Widget _speakerSelector2() {
    // Create a list of voice names to display in the dropdown
    final voiceNames =
        _voices.map<String>((voice) => voice['name'] as String).toList();

    // Use _currentVoice's 'name' if it's not null; otherwise, use the first item in the list if available
    final selectedVoiceName = _currentVoice?['name'] ?? voiceNames.first;

    return CustomDropdown(
      isMenu: true,
      icon: const Icon(
        Icons.support_agent,
        color: kDangerColor,
      ),
      items: voiceNames,
      labelText: 'Voice Type',
      initialValue: selectedVoiceName,
      onValueChange: (String? value) {
        if (value != null) {
          final selectedVoice = _voices.firstWhere(
            (voice) => voice['name'] == value,
            orElse: () => _currentVoice ?? {},
          );
          if (selectedVoice.isNotEmpty) {
            _setVoice(selectedVoice);
          }
        }
      },
    );
  }*/
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final List<Widget> children;

  const _GuideCard({
    required this.title,
    required this.subTitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.ofTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ExpansionTile(
      dense: true,
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      title: _buildTitle(context, textTheme, colorScheme),
      subtitle: _buildSubtitle(),
      childrenPadding: const EdgeInsets.only(bottom: 20.0),
      children: [...children, _buildDoneText(textTheme)],
    );
  }

  Widget _buildSubtitle() {
    return Text(subTitle, textAlign: TextAlign.start);
  }

  Widget _buildTitle(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Text(
      title,
      textAlign: TextAlign.start,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
    );
  }

  Widget _buildDoneText(TextTheme textTheme) {
    return Text(
      'You\'re Done...Thanks',
      style: textTheme.titleMedium?.copyWith(
        color: kDangerColor,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
