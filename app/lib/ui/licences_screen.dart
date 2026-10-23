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
                        // A line that goes on in lower case joins the line
                        // above it, so the text fits the width of a phone.
                        Text(
                          (read.data?[i] ?? '').replaceAll(
                            RegExp(r'\n(?=[a-z])'),
                            ' ',
                          ),
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
