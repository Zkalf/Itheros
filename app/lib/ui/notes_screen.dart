import 'package:flutter/material.dart';

import '../release_notes.dart';
import 'controller_scope.dart';
import 'theme.dart';

/// "New in Itheros": the notes of each version that the player has not
/// seen, newest first, before the level-up cards (spec 0018 §3.1, §3.2).
/// Only "Continue" closes it, not the back gesture.
class NewNotesScreen extends StatelessWidget {
  const NewNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New in Itheros'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(gutter),
            children: [
              for (final v in c.newNotes)
                NotesPlate(heading: 'Itheros $v', text: c.notes.versions[v]!),
              // Continue stands on a plate, as on the away report.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    key: const ValueKey('new-notes-continue'),
                    onPressed: c.dismissNewNotes,
                    child: const Text('Continue'),
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

/// "New in Itheros" from Settings: the notes of each version up to the one
/// that the player has, newest first (spec 0018 §3.4). The owner's build
/// starts with `releases/next.md`.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final next = c.notes.next;
    return Scaffold(
      appBar: AppBar(
        leading: const BackPlate(),
        title: const Text('New in Itheros'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(gutter),
          children: [
            // Only the owner's build has a test walk (spec 0007 §4).
            if (c.testWalkAllowed && next != null)
              NotesPlate(heading: 'Next release (test build)', text: next),
            for (final v in c.notes.upTo(c.version))
              NotesPlate(heading: 'Itheros $v', text: c.notes.versions[v]!),
          ],
        ),
      ),
    );
  }
}

/// The notes of one version on a plate, under [heading], in the format of
/// spec 0018 §3.3 and its amendment 1.
class NotesPlate extends StatelessWidget {
  const NotesPlate({super.key, required this.heading, required this.text});

  final String heading;
  final String text;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: styles.titleMedium),
            for (final block in parseNotes(text))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _block(block),
              ),
          ],
        ),
      ),
    );
  }

  Widget _block(NoteBlock block) {
    final words = Text.rich(
      TextSpan(
        children: [
          for (final p in block.parts)
            TextSpan(
              text: p.text,
              style: p.bold
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
        ],
      ),
    );
    if (block.depth == 0) return words;
    // Each list one step further in than the list around it.
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * (block.depth - 1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•'),
          const SizedBox(width: 8),
          Expanded(child: words),
        ],
      ),
    );
  }
}
