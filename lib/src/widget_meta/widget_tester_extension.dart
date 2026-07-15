import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Holds the value of the class that has members that are strings. Typically, this is the S class in i18n.dart
/// of the intl package. However, it can by any class of the structure:
///
///     class MyTextHolder {
///       static String title => 'The Book of Avocados';
///       static String body => 'Once upon a time there was an avocado....
///     }
///
dynamic _s;

enum _WidgetActionPumpMode {
  none,
  once,
  forDuration,
  untilSettled,
}

/// Controls how [WidgetTester] advances frames after a widget action.
final class WidgetActionPumpPolicy {
  /// Returns immediately after the action without pumping a frame.
  const WidgetActionPumpPolicy.none()
      : _mode = _WidgetActionPumpMode.none,
        _duration = null,
        _timeout = null;

  /// Pumps exactly one frame after the action.
  const WidgetActionPumpPolicy.once()
      : _mode = _WidgetActionPumpMode.once,
        _duration = null,
        _timeout = null;

  /// Pumps one frame after advancing the test clock by [duration].
  const WidgetActionPumpPolicy.forDuration(
    Duration duration,
  )   : _mode = _WidgetActionPumpMode.forDuration,
        _duration = duration,
        _timeout = null;

  /// Pumps frames separated by [step] until the app settles or [timeout]
  /// expires.
  const WidgetActionPumpPolicy.untilSettled({
    Duration step = const Duration(milliseconds: 100),
    Duration timeout = const Duration(minutes: 10),
  })  : _mode = _WidgetActionPumpMode.untilSettled,
        _duration = step,
        _timeout = timeout;

  final _WidgetActionPumpMode _mode;
  final Duration? _duration;
  final Duration? _timeout;

  Future<void> _pump(WidgetTester tester) async {
    switch (_mode) {
      case _WidgetActionPumpMode.none:
        return;
      case _WidgetActionPumpMode.once:
        await tester.pump();
      case _WidgetActionPumpMode.forDuration:
        await tester.pump(_duration);
      case _WidgetActionPumpMode.untilSettled:
        await tester.pumpAndSettle(
          _duration!,
          EnginePhase.sendSemanticsUpdate,
          _timeout!,
        );
    }
  }
}

extension WidgetTesterExtension on WidgetTester {
  /// Set a class that has members that are strings (see [_s] for more detail)
  static set s(dynamic value) => _s = value;

  /// Get the class that has members that are strings (see [_s] for more detail)
  static dynamic get s => _s;

  String _getStringFromFinder(
    Finder finder,
    String Function(dynamic s) intl,
  ) =>
      intl(_s);

  /// Returns a [Finder] for Widgets that match one or more parameters
  ///
  /// [intl] receives the `intl` package `S` object and returns the String to find.
  /// [text] is a String to find.
  /// [widgetType] is the Type of widget to find.
  /// [key] is the key to find.
  ///
  /// You can pass no String, [intl], or [text], but not both.
  /// If [key] and [widgetType] are BOTH null, [widgetType] is assumed to be Text
  Finder findBy({
    String Function(dynamic s)? intl,
    String? text,
    Type? widgetType,
    Key? key,
  }) {
    assert(intl == null || text == null);

    final Type? soughtType =
        key == null && widgetType == null ? Text : widgetType;

    late Finder finder;

    if (key != null) {
      finder = find.byKey(key);
      if (soughtType == Text && (intl != null || text != null)) {
        final String widgetText = text ?? _getStringFromFinder(finder, intl!);
        expect(find.text(widgetText).evaluate(), finder.evaluate());
      }
    } else {
      finder = find.byType(soughtType!);
      if (intl != null || text != null) {
        final String widgetText = text ?? _getStringFromFinder(finder, intl!);
        if (soughtType == Text) {
          finder = find.text(widgetText);
        }
      }
    }

    return finder;
  }

  /// See [findBy] for param descriptions.
  ///
  /// Usage:
  ///
  ///    expectWidget(intl: (s) => s.someText, key: MyWidgetKeys.someText)
  ///
  void expectWidget({
    String Function(dynamic s)? intl,
    String? text,
    Type? widgetType,
    Key? key,
    Matcher matcher = findsOneWidget,
  }) {
    final Finder finder =
        findBy(intl: intl, text: text, widgetType: widgetType, key: key);
    expect(finder, matcher);
  }

  /// See [findBy] for finder parameter descriptions.
  ///
  /// [pumpPolicy] explicitly controls frame advancement after the tap. When it
  /// is omitted, [shouldPumpAndSettle] preserves the legacy behavior of
  /// calling [WidgetTester.pumpAndSettle] by default.
  Future<void> tapWidget({
    required String Function(dynamic s) intl,
    String? text,
    Type? widgetType,
    Key? key,
    @Deprecated(
      'Use pumpPolicy. This parameter will be removed in 2.0.0.',
    )
    bool shouldPumpAndSettle = true,
    WidgetActionPumpPolicy? pumpPolicy,
  }) async {
    final Finder finder =
        findBy(intl: intl, text: text, widgetType: widgetType, key: key);
    expect(finder, findsOneWidget);
    await tap(finder);
    if (pumpPolicy case final policy?) {
      await policy._pump(this);
    } else if (shouldPumpAndSettle) {
      await pumpAndSettle();
    }
  }
}
