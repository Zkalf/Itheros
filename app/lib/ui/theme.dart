import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

/// The colours of spec 0014 §2.1, and the neutrals that the spec uses without
/// a hex value (plan 0017). The look has no other colour, apart from the
/// quality colours of the game data and the band colours of `LevelBadge`.
abstract final class Quiet {
  /// The case: the background of each screen.
  static const caseBlack = Color(0xFF060708);

  /// Cards, sheets, dialogs, snack bars and both bars.
  static const plate = Color(0xFF171C21);

  /// Buttons and chips: a gradient from [slate] down to [slateLow].
  static const slate = Color(0xFF2B333B);
  static const slateLow = Color(0xFF1E242A);

  /// The thumb of a switch that is off.
  static const lit = Color(0xFF2E3740);

  /// A selected chip, segment or tab: teal at 35% over [slate] (spec 0014
  /// amendment 4). Its label is [white].
  static const selected = Color(0xFF4C6768);

  /// Main buttons, focus, earned things, "New", the rank and the loading
  /// bar. Text on teal is [onTeal].
  static const teal = Color(0xFF8AC7BC);
  static const onTeal = Color(0xFF0D1416);

  /// The banners of a report.
  static const deepTeal = Color(0xFF17292C);

  /// Bars ([steel]) and the step bank ([mist]).
  static const steel = Color(0xFFB9C2C9);
  static const mist = Color(0xFF8FA2AE);

  /// Body text, secondary text and small labels.
  static const text = Color(0xFFE3EAEC);
  static const muted = Color(0xFFA8B3B8);
  static const faint = Color(0xFF7F8A90);

  /// Inputs that the player does not have, and the word "Risky".
  static const short = Color(0xFFE08A7C);
  static const risky = Color(0xFFFBB15A);

  /// The border of each control (spec 0014 §2.2).
  static const black = Colors.black;
  static const white = Colors.white;
  static const transparent = Colors.transparent;

  /// The dark socket behind each image (spec 0014 §2.3, plan 0017): black,
  /// with a shade of [slate] at its centre.
  static const socket = black;

  /// The 1 dp teal hairline of a plate.
  static final hairline = teal.withValues(alpha: .24);
}

/// The status bar with light icons (spec 0014 §2.1). The status bar is
/// transparent: below Android 15, Flutter's Android activity otherwise keeps
/// a band of 25% black under it. The style gives the navigation bar no
/// colour, so the navigation bar keeps the look of the window theme.
const lightStatusBar = SystemUiOverlayStyle(
  statusBarColor: Quiet.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

/// The status bar with dark icons, on the splash picture (spec 0014 §2.1),
/// transparent as in [lightStatusBar].
const darkStatusBar = SystemUiOverlayStyle(
  statusBarColor: Quiet.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

/// The four families of spec 0014 §2.2, as pubspec.yaml names them.
abstract final class Fonts {
  /// The wordmark, titles and names.
  static const display = 'Cormorant Garamond';

  /// Body text and tab labels.
  static const body = 'Alegreya Sans';

  /// Button labels and list headings, in small caps.
  static const label = 'Alegreya Sans SC';

  /// Numbers that stand alone.
  static const number = 'Spectral';
}

/// The space between plates, and between a plate and the edge of the screen
/// (spec 0014 §2.2).
const gutter = 6.0;

/// The 2 dp black border of each button, tab, chip, segment and switch.
const _border = BorderSide(width: 2);

/// The thin black outline of each button label but a teal button's (spec
/// 0014 amendment 4): four black shadows of 0.8 dp, one on each side.
const labelOutline = [
  Shadow(offset: Offset(-.8, 0)),
  Shadow(offset: Offset(.8, 0)),
  Shadow(offset: Offset(0, -.8)),
  Shadow(offset: Offset(0, .8)),
];

/// The font of a number that stands alone (spec 0014 §2.2). The size and the
/// weight come from the text around it.
const numberStyle = TextStyle(fontFamily: Fonts.number);

/// [text] with each number in Spectral (spec 0014 §2.2): the words keep the
/// font of the text, and the digits of each number are a span of their own.
TextSpan numberSpan(String text, {TextStyle? style}) {
  final spans = <TextSpan>[];
  var at = 0;
  for (final m in RegExp(r'\d+(?:[.,]\d+)*%?').allMatches(text)) {
    if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
    spans.add(TextSpan(text: m[0], style: numberStyle));
    at = m.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return TextSpan(style: style, children: spans);
}

/// The style of a list heading: Alegreya Sans SC (spec 0014 §2.2).
TextStyle headingStyle(BuildContext context) =>
    Theme.of(context).textTheme.labelLarge!.copyWith(color: Quiet.muted);

/// The style of the title of a row that names a thing of the game, such as
/// a monster, a spot, a teacher, an item or an achievement: Cormorant
/// Garamond (spec 0014 §2.2). A row with a label as its title keeps the body
/// text.
TextStyle? nameStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium;

/// The shape of a plate: radius 16 and a 1 dp teal hairline (spec 0014
/// §2.2). A [selected] plate has a 2 dp teal edge.
ShapeBorder plateShape({bool selected = false}) => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
  side: selected
      ? const BorderSide(color: Quiet.teal, width: 2)
      : BorderSide(color: Quiet.hairline),
);

/// A plate drawn as a box, for the bars and the parts of a screen that are not
/// a Card.
final plateDecoration = ShapeDecoration(
  color: Quiet.plate,
  shape: plateShape(),
);

/// The look of each kind of button (spec 0014 §2.2, plan 0017): teal for
/// today's filled buttons, ghost for Cancel, Not now, Keep it and Skip all,
/// slate for all other buttons.
final tealButton = _button(
  fill: Quiet.teal,
  label: Quiet.onTeal,
  // Its dark label gets heavier with the outline, not clearer.
  outline: false,
  shade: [
    Quiet.white.withValues(alpha: .18),
    Quiet.black.withValues(alpha: .1),
  ],
  pressed: [
    Quiet.black.withValues(alpha: .16),
    Quiet.white.withValues(alpha: .06),
  ],
);
final slateButton = _slate();
final ghostButton = _button(fill: Quiet.transparent, label: Quiet.text);

/// A slate button: the gradient from slate down to slate low, which turns
/// over while the button is pressed (spec 0014 §2.1).
ButtonStyle _slate({
  double radius = 12,
  EdgeInsets padding = _padding,
  Size minimumSize = const Size(64, 44),
}) => _button(
  fill: Quiet.slate,
  label: Quiet.text,
  shade: const [Quiet.slate, Quiet.slateLow],
  pressed: const [Quiet.slateLow, Quiet.slate],
  radius: radius,
  padding: padding,
  minimumSize: minimumSize,
);

const _padding = EdgeInsets.symmetric(horizontal: 18, vertical: 8);

/// Padding that moves the label of a pressed button 1 dp down, so that the
/// button sinks (spec 0014 §2.2).
WidgetStateProperty<EdgeInsetsGeometry> sinkingPadding(EdgeInsets p) =>
    WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.pressed)
          ? EdgeInsets.fromLTRB(p.left, p.top + 1, p.right, p.bottom - 1)
          : p,
    );

ButtonStyle _button({
  required Color fill,
  required Color label,
  List<Color>? shade,
  List<Color>? pressed,
  double radius = 12,
  EdgeInsets padding = _padding,
  Size minimumSize = const Size(64, 44),
  bool outline = true,
}) {
  bool off(Set<WidgetState> s) => s.contains(WidgetState.disabled);
  bool down(Set<WidgetState> s) => s.contains(WidgetState.pressed);
  return ButtonStyle(
    textStyle: WidgetStatePropertyAll(
      outline ? _label(15).copyWith(shadows: labelOutline) : _label(15),
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (s) => off(s) && shade != null ? Quiet.plate : fill,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (s) => off(s) ? Quiet.faint : label,
    ),
    overlayColor: WidgetStateProperty.resolveWith(
      (s) => down(s)
          ? Quiet.black.withValues(alpha: .18)
          : s.contains(WidgetState.hovered)
          ? Quiet.white.withValues(alpha: .04)
          : Quiet.transparent,
    ),
    shadowColor: const WidgetStatePropertyAll(Quiet.black),
    surfaceTintColor: const WidgetStatePropertyAll(Quiet.transparent),
    // The drop shadow goes while the button is pressed.
    elevation: WidgetStateProperty.resolveWith(
      (s) => shade == null || off(s) || down(s) ? 0 : 2,
    ),
    padding: sinkingPadding(padding),
    minimumSize: WidgetStatePropertyAll(minimumSize),
    // A state shows at once: a button that becomes enabled has its label
    // colour in the same frame.
    animationDuration: Duration.zero,
    side: const WidgetStatePropertyAll(_border),
    shape: WidgetStateProperty.resolveWith(
      (s) => _ButtonShape(
        borderRadius: BorderRadius.circular(radius),
        side: _border,
        shade: off(s) ? null : (down(s) ? pressed : shade),
        ring: s.contains(WidgetState.focused),
      ),
    ),
  );
}

/// The shape of a button. It paints the gradient of the face, the 2 dp black
/// border and, while the button has the focus, a 2 dp teal ring 2 dp outside
/// the border (the kit of spec 0014). The shape paints them, so the button
/// needs no builder and does not clip the ring.
class _ButtonShape extends RoundedRectangleBorder {
  const _ButtonShape({
    super.side,
    super.borderRadius,
    this.shade,
    this.ring = false,
  });

  /// The gradient over the colour of the button, from the top down.
  final List<Color>? shade;
  final bool ring;

  @override
  _ButtonShape copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => _ButtonShape(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
    shade: shade,
    ring: ring,
  );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final outer = borderRadius.resolve(textDirection).toRRect(rect);
    if (shade case final colours?) {
      canvas.drawRRect(
        outer.deflate(side.width),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colours,
          ).createShader(rect),
      );
    }
    super.paint(canvas, rect, textDirection: textDirection);
    if (ring) {
      canvas.drawRRect(
        outer.inflate(side.width + 1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Quiet.teal,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _ButtonShape &&
      super == other &&
      listEquals(other.shade, shade) &&
      other.ring == ring;

  @override
  int get hashCode => Object.hash(
    side,
    borderRadius,
    ring,
    shade == null ? null : Object.hashAll(shade!),
  );
}

/// A box with the 2 dp black border, for a control that draws no button of
/// its own: a tab, the item list of "Until I have N", an option of the gender
/// dialog (spec 0014 §2.2). Ink from the control inside shows on the box.
class ControlBox extends StatelessWidget {
  const ControlBox({super.key, required this.child, this.fill = Quiet.slate});

  final Widget child;
  final Color fill;

  @override
  Widget build(BuildContext context) => Material(
    color: fill,
    // The text inside keeps the style of the control, not the Material's.
    textStyle: DefaultTextStyle.of(context).style,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: _border,
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

/// A plate in the top bar that holds its buttons, so that no button stands on
/// the case (spec 0014 §2.2).
class BarPlate extends StatelessWidget {
  const BarPlate({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: gutter),
      child: DecoratedBox(
        decoration: plateDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    ),
  );
}

/// The leading part of the top bar of a pushed page: Flutter's Back button
/// on its plate. A pushed page shows no other button (plan 0017, choice 7).
class BackPlate extends StatelessWidget {
  const BackPlate({super.key});

  @override
  Widget build(BuildContext context) =>
      const BarPlate(children: [BackButton()]);
}

/// A status chip, such as Active or New: an outline with the border of each
/// chip, and the label in [colour] (spec 0014 §2.2).
Widget statusChip(String label, Color colour, {Key? key, Widget? avatar}) =>
    Chip(
      key: key,
      avatar: avatar,
      label: Text(label),
      // A status chip is not a button: no outline (spec 0014 amendment 4).
      labelStyle: TextStyle(color: colour, shadows: const []),
      color: const WidgetStatePropertyAll(Quiet.transparent),
    );

TextStyle _display(double size) => TextStyle(
  fontFamily: Fonts.display,
  fontSize: size,
  fontWeight: FontWeight.w600,
  height: 1.15,
  letterSpacing: 0,
  color: Quiet.text,
);

// Lining figures: Alegreya Sans draws old-style figures by default, and its
// "0" then reads as an "o".
TextStyle _body(double size, [Color colour = Quiet.text]) => TextStyle(
  fontFamily: Fonts.body,
  fontSize: size,
  fontWeight: FontWeight.w400,
  height: 1.35,
  letterSpacing: 0,
  color: colour,
  fontFeatures: const [FontFeature.liningFigures()],
);

TextStyle _label(double size, [Color colour = Quiet.text]) => TextStyle(
  fontFamily: Fonts.label,
  fontSize: size,
  fontWeight: FontWeight.w700,
  height: 1.2,
  letterSpacing: size * .08,
  color: colour,
);

/// The one theme of the app, for each phone setting (spec 0014 decision 2).
final ThemeData quietTheme = _quietTheme();

ThemeData _quietTheme() {
  WidgetStateProperty<T> by<T>(T selected, T other, [T? disabled]) =>
      WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? selected
            : s.contains(WidgetState.disabled) && disabled != null
            ? disabled
            : other,
      );
  final hairline = BorderSide(color: Quiet.hairline);
  final radius12 = BorderRadius.circular(12);
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Quiet.teal,
    onPrimary: Quiet.onTeal,
    primaryContainer: Quiet.deepTeal,
    onPrimaryContainer: Quiet.text,
    secondary: Quiet.steel,
    onSecondary: Quiet.caseBlack,
    secondaryContainer: Quiet.slate,
    onSecondaryContainer: Quiet.text,
    tertiary: Quiet.mist,
    onTertiary: Quiet.caseBlack,
    tertiaryContainer: Quiet.deepTeal,
    onTertiaryContainer: Quiet.text,
    error: Quiet.short,
    onError: Quiet.caseBlack,
    errorContainer: Quiet.plate,
    onErrorContainer: Quiet.short,
    surface: Quiet.caseBlack,
    onSurface: Quiet.text,
    onSurfaceVariant: Quiet.muted,
    surfaceDim: Quiet.caseBlack,
    // Lit is only the thumb of a switch that is off (spec 0014 amendment 4).
    surfaceBright: Quiet.selected,
    surfaceContainerLowest: Quiet.caseBlack,
    surfaceContainerLow: Quiet.plate,
    surfaceContainer: Quiet.plate,
    surfaceContainerHigh: Quiet.slateLow,
    surfaceContainerHighest: Quiet.slate,
    outline: Quiet.black,
    outlineVariant: Quiet.hairline,
    shadow: Quiet.black,
    scrim: Quiet.black,
    inverseSurface: Quiet.text,
    onInverseSurface: Quiet.plate,
    inversePrimary: Quiet.deepTeal,
    surfaceTint: Quiet.transparent,
  );
  final text = TextTheme(
    displayLarge: _display(44),
    displayMedium: _display(38),
    displaySmall: _display(34),
    headlineLarge: _display(32),
    headlineMedium: _display(30),
    headlineSmall: _display(28),
    titleLarge: _display(24),
    titleMedium: _display(20),
    titleSmall: _display(17),
    bodyLarge: _body(16),
    bodyMedium: _body(15),
    bodySmall: _body(13, Quiet.muted),
    labelLarge: _label(15),
    labelMedium: _body(13),
    labelSmall: _label(12),
  );
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: Fonts.body,
    textTheme: text,
    // ThemeData's own dark defaults (#CCCCCC, #616161, greys) are outside
    // §2.1, so each colour is set here.
    canvasColor: Quiet.plate,
    cardColor: Quiet.plate,
    scaffoldBackgroundColor: Quiet.caseBlack,
    disabledColor: Quiet.faint,
    dividerColor: Quiet.hairline,
    focusColor: Quiet.teal.withValues(alpha: .12),
    hoverColor: Quiet.white.withValues(alpha: .04),
    highlightColor: Quiet.white.withValues(alpha: .06),
    splashColor: Quiet.white.withValues(alpha: .1),
    hintColor: Quiet.faint,
    primaryColor: Quiet.teal,
    primaryColorDark: Quiet.deepTeal,
    primaryColorLight: Quiet.teal,
    secondaryHeaderColor: Quiet.plate,
    shadowColor: Quiet.black,
    unselectedWidgetColor: Quiet.muted,
    iconTheme: const IconThemeData(color: Quiet.text),
    appBarTheme: AppBarThemeData(
      backgroundColor: Quiet.caseBlack,
      surfaceTintColor: Quiet.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leadingWidth: 64,
      titleSpacing: 8,
      titleTextStyle: _display(26),
      systemOverlayStyle: lightStatusBar,
    ),
    filledButtonTheme: FilledButtonThemeData(style: tealButton),
    outlinedButtonTheme: OutlinedButtonThemeData(style: slateButton),
    textButtonTheme: TextButtonThemeData(style: slateButton),
    iconButtonTheme: IconButtonThemeData(
      style: _slate(
        radius: 11,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(44, 40),
      ).copyWith(iconSize: const WidgetStatePropertyAll(22)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          _label(14).copyWith(shadows: labelOutline),
        ),
        backgroundColor: by(Quiet.selected, Quiet.slate, Quiet.plate),
        foregroundColor: by(Quiet.white, Quiet.text, Quiet.faint),
        iconColor: by(Quiet.white, Quiet.muted, Quiet.faint),
        overlayColor: WidgetStatePropertyAll(
          Quiet.white.withValues(alpha: .04),
        ),
        side: const WidgetStatePropertyAll(_border),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      color: by(Quiet.selected, Quiet.slate, Quiet.plate),
      side: _border,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      labelStyle: _label(13).copyWith(
        letterSpacing: .5,
        shadows: labelOutline,
        color: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Quiet.white
              : s.contains(WidgetState.disabled)
              ? Quiet.faint
              : Quiet.text,
        ),
      ),
      iconTheme: const IconThemeData(color: Quiet.muted, size: 16),
      showCheckmark: false,
      elevation: 0,
      pressElevation: 0,
      surfaceTintColor: Quiet.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: by(Quiet.text, Quiet.lit),
      trackColor: by(Quiet.teal.withValues(alpha: .75), Quiet.caseBlack),
      trackOutlineColor: const WidgetStatePropertyAll(Quiet.black),
      trackOutlineWidth: const WidgetStatePropertyAll(2),
    ),
    cardTheme: CardThemeData(
      color: Quiet.plate,
      surfaceTintColor: Quiet.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: gutter),
      shape: plateShape(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Quiet.plate,
      surfaceTintColor: Quiet.transparent,
      shape: plateShape(),
      titleTextStyle: _display(26),
      contentTextStyle: _body(16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Quiet.plate,
      contentTextStyle: _body(15),
      actionTextColor: Quiet.teal,
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
      shape: plateShape(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Quiet.plate,
      modalBackgroundColor: Quiet.plate,
      surfaceTintColor: Quiet.transparent,
      elevation: 0,
      modalElevation: 0,
      modalBarrierColor: Quiet.black.withValues(alpha: .62),
      showDragHandle: true,
      dragHandleColor: Quiet.faint,
      clipBehavior: Clip.antiAlias,
      // The full width, also when the content is narrow.
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        side: hairline,
      ),
    ),
    // No icon colour: an icon button in a row keeps its own label colour,
    // and the other icons are muted. A value at the end of a row is body
    // text, not a label.
    listTileTheme: ListTileThemeData(
      textColor: Quiet.text,
      selectedColor: Quiet.teal,
      leadingAndTrailingTextStyle: _body(15, Quiet.muted),
    ),
    dividerTheme: DividerThemeData(color: Quiet.hairline, thickness: 1),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Quiet.caseBlack,
      labelStyle: _body(15, Quiet.muted),
      floatingLabelStyle: _body(15, Quiet.teal),
      hintStyle: _body(15, Quiet.faint),
      counterStyle: _body(12, Quiet.faint),
      border: OutlineInputBorder(borderRadius: radius12, borderSide: hairline),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius12,
        borderSide: hairline,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius12,
        borderSide: const BorderSide(color: Quiet.teal, width: 2),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Quiet.white,
      unselectedLabelColor: Quiet.text,
      labelStyle: _body(15)
          .copyWith(fontWeight: FontWeight.w700, shadows: labelOutline),
      unselectedLabelStyle: _body(15)
          .copyWith(fontWeight: FontWeight.w700, shadows: labelOutline),
      labelPadding: const EdgeInsets.symmetric(horizontal: 3),
      indicator: const BoxDecoration(),
      dividerHeight: 0,
      overlayColor: const WidgetStatePropertyAll(Quiet.transparent),
      splashFactory: NoSplash.splashFactory,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Quiet.steel,
      linearTrackColor: Quiet.caseBlack,
      linearMinHeight: 8,
      borderRadius: BorderRadius.all(Radius.circular(4)),
      refreshBackgroundColor: Quiet.plate,
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: Quiet.teal,
      textColor: Quiet.onTeal,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: Quiet.transparent,
      surfaceTintColor: Quiet.transparent,
      elevation: 0,
      indicatorColor: Quiet.transparent,
      labelPadding: const EdgeInsets.only(top: 2),
      labelTextStyle: by(
        _body(
          13,
          Quiet.white,
        ).copyWith(fontWeight: FontWeight.w700, shadows: labelOutline),
        _body(13, Quiet.muted).copyWith(shadows: labelOutline),
      ),
      iconTheme: by(
        const IconThemeData(color: Quiet.white, size: 22),
        const IconThemeData(color: Quiet.muted, size: 22),
      ),
    ),
  );
}
