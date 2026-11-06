import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'images.dart';
import 'socket.dart';
import 'theme.dart';

/// The picture of [activity] in a socket of [size] dp (spec 0014 amendment
/// 8): an item of a craft or a reroll has the ring of its quality when it is
/// gear or a tool. A [number] stands in a small round badge on the top-left
/// corner (rule 6).
class ActionPicture extends StatelessWidget {
  const ActionPicture({
    super.key,
    required this.data,
    required this.activity,
    this.size = 48,
    this.number,
  });

  final GameData data;
  final Activity activity;
  final double size;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final thing = thingOf(data, activity);
    final picture = ImageScope.of(context).pictureOf(data, thing);
    final socket = switch (thing) {
      ItemThing(:final key) => PictureSocket.item(
        data,
        key,
        picture: picture,
        size: size,
      ),
      _ => PictureSocket(picture: picture, size: size),
    };
    final n = number;
    if (n == null) return socket;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        socket,
        Positioned(
          left: -6,
          top: -6,
          child: Container(
            key: const ValueKey('action-number'),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Quiet.slate,
              shape: BoxShape.circle,
              border: Border.all(width: 2),
            ),
            child: Text(
              '$n',
              // The badge keeps its size at each text size of the phone.
              textScaler: TextScaler.noScaling,
              style: numberStyle.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1,
                color: Quiet.text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
