import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// The licences of the four fonts, opened from Settings (spec 0014 §2.2,
/// §4.2): each family's SIL Open Font License text, from the app bundle.
class LicencesScreen extends StatefulWidget {
  const LicencesScreen({super.key, this.bundle});

  /// Where the texts come from; null for the app bundle. A test passes a
  /// bundle that reads the files from disk.
  final AssetBundle? bundle;

  @override
  State<LicencesScreen> createState() => _LicencesScreenState();
}

class _LicencesScreenState extends State<LicencesScreen> {
  /// Each family with its licence text in assets/fonts/.
  static const _files = {
    Fonts.display: 'OFL-CormorantGaramond.txt',
    Fonts.body: 'OFL-AlegreyaSans.txt',
    Fonts.label: 'OFL-AlegreyaSansSC.txt',
    Fonts.number: 'OFL-Spectral.txt',
  };

  /// All four texts at once, so that each row of the list has its text when
  /// the list builds it.
  late final _texts = Future.wait([
    for (final file in _files.values)
      (widget.bundle ?? rootBundle).loadString('assets/fonts/$file'),
  ]);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(leading: const BackPlate(), title: const Text('Licences')),
      body: SafeArea(
        child: FutureBuilder(
          future: _texts,
          builder: (context, read) => ListView(
            padding: const EdgeInsets.all(gutter),
            children: [
              for (final (i, family) in _files.keys.indexed)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(family, style: text.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          _reflow(read.data?[i] ?? ''),
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [licence] with each paragraph on one line, so that it fits the width of a
/// phone. Blank lines still part the paragraphs. A heading in capitals at the
/// start of a paragraph, such as PREAMBLE, and each line of dashes keep their
/// own line. No word changes.
String _reflow(String licence) {
  bool alone(String line, int i) =>
      RegExp(r'^-+$').hasMatch(line) ||
      (i == 0 && !line.contains(RegExp('[a-z]')));
  final paragraphs = <String>[];
  for (final paragraph in licence.trim().split(RegExp(r'\n\s*\n'))) {
    final lines = [for (final l in paragraph.split('\n')) l.trim()];
    final out = StringBuffer(lines.first);
    for (var i = 1; i < lines.length; i++) {
      out
        ..write(alone(lines[i - 1], i - 1) || alone(lines[i], i) ? '\n' : ' ')
        ..write(lines[i]);
    }
    paragraphs.add('$out');
  }
  return paragraphs.join('\n\n');
}
