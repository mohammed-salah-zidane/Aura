import 'dart:convert';
import 'dart:io';

import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// intl exports a TextDirection of its own, which shadows the one every widget
// in this test uses.
import 'package:intl/intl.dart' hide TextDirection;

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Message keys, without the `@key` metadata entries or the `@@locale` header.
Iterable<String> _messages(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@'));

void main() {
  final en = _arb('en');
  final ar = _arb('ar');

  group('ARB files', () {
    test('both locales carry exactly the same keys', () {
      expect(_messages(ar).toSet(), _messages(en).toSet());
    });

    test('no Arabic value is the English one copied over', () {
      // A copied value is the failure mode that survives review: it compiles,
      // it renders, and it is only wrong to someone who reads Arabic.
      //
      // A message made only of placeholders and punctuation is exempt, because
      // there is no word in it to translate. `{high} {low}` is the same string
      // in every language.
      final hasWords = RegExp('[A-Za-z]');
      for (final key in _messages(en)) {
        final source = (en[key]! as String).replaceAll(
          RegExp(r'\{\w+\}'),
          '',
        );
        if (!hasWords.hasMatch(source)) continue;
        expect(
          ar[key],
          isNot(en[key]),
          reason: '$key was never translated',
        );
      }
    });

    test('no Arabic value is left empty or marked as pending', () {
      for (final key in _messages(ar)) {
        final value = ar[key]! as String;
        expect(value.trim(), isNotEmpty, reason: '$key is blank');
        expect(
          value.toUpperCase(),
          isNot(contains('TODO')),
          reason: '$key is still a placeholder',
        );
      }
    });

    test('every message in the template carries a description', () {
      for (final key in _messages(en)) {
        final meta = en['@$key'] as Map<String, dynamic>?;
        expect(meta, isNotNull, reason: '$key has no metadata');
        expect(
          (meta!['description'] as String?)?.trim(),
          isNotEmpty,
          reason: '$key has no description',
        );
      }
    });

    test('placeholders survive into the Arabic value', () {
      final placeholder = RegExp(r'\{(\w+)\}');
      for (final key in _messages(en)) {
        final source = placeholder
            .allMatches(en[key]! as String)
            .map((m) => m.group(1))
            .toSet();
        final target = placeholder
            .allMatches(ar[key]! as String)
            .map((m) => m.group(1))
            .toSet();
        expect(target, source, reason: '$key lost or renamed a placeholder');
      }
    });

    test('no copy carries an em-dash', () {
      // House style: full stops and commas, never a dash as a dramatic pause.
      for (final arb in <Map<String, dynamic>>[en, ar]) {
        for (final key in _messages(arb)) {
          expect(
            arb[key]! as String,
            isNot(contains('—')),
            reason: '$key reads as machine-written',
          );
        }
      }
    });
  });

  group('supported locales', () {
    test('English comes first, so it is the fallback', () {
      // MaterialApp falls back to the first entry when the device asks for a
      // language Aura does not ship. Generated alphabetically, that was Arabic.
      expect(AppLocalizations.supportedLocales.first, const Locale('en'));
    });

    test('exactly English and Arabic ship', () {
      expect(AppLocalizations.supportedLocales, <Locale>[
        const Locale('en'),
        const Locale('ar'),
      ]);
    });

    test('a device set to Egyptian Arabic resolves to the Arabic build', () {
      expect(
        basicLocaleListResolution(const <Locale>[
          Locale('ar', 'EG'),
        ], AppLocalizations.supportedLocales),
        const Locale('ar'),
      );
    });

    test('an unsupported language falls back to English', () {
      expect(
        basicLocaleListResolution(const <Locale>[
          Locale('fr'),
        ], AppLocalizations.supportedLocales),
        const Locale('en'),
      );
    });
  });

  group('numbering system', () {
    // The whole app's digits ride on this. Widening the Arabic locale to ar_EG
    // would flip every temperature to Arabic-Indic, and the 98 point hero would
    // be drawn by the fallback face instead of Fraunces.
    tearDown(() => Intl.defaultLocale = null);

    test('Arabic formats numbers with Western digits', () {
      AuraLocales.adopt(const Locale('ar'));
      expect(NumberFormat.decimalPattern('ar').format(35), '35');
    });

    test('Arabic dates and times use Western digits', () async {
      await AuraLocales.loadDateSymbols();
      AuraLocales.adopt(const Locale('ar'));
      final noon = DateTime(2026, 7, 25, 14, 34);
      expect(DateFormat('d MMM', 'ar').format(noon), contains('25'));
      expect(DateFormat.jm('ar').format(noon), contains('2:34'));
    });

    test('Arabic still translates the words around the digits', () {
      // Western digits are a numbering choice, not a fallback to English.
      expect(
        DateFormat('MMMM', 'ar').format(DateTime(2026, 7, 25)),
        isNot(equals('July')),
      );
    });

    test('adopt makes the locale the default for an unqualified format', () {
      AuraLocales.adopt(const Locale('ar'));
      expect(Intl.defaultLocale, 'ar');
      expect(NumberFormat.decimalPattern().format(35), '35');
    });
  });

  group('AppLocalizations', () {
    testWidgets('context.l10n reaches the copy for the active locale', (
      tester,
    ) async {
      late String english;
      late String arabic;

      Widget host(Locale locale, void Function(String) capture) =>
          Localizations(
            locale: locale,
            delegates: AppLocalizations.localizationsDelegates,
            child: Builder(
              builder: (context) {
                capture(context.l10n.permissionTitle);
                return const SizedBox.shrink();
              },
            ),
          );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: host(const Locale('en'), (v) => english = v),
        ),
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: host(const Locale('ar'), (v) => arabic = v),
        ),
      );

      expect(english, 'Enable Location');
      expect(arabic, isNot(english));
      expect(arabic, ar['permissionTitle']);
    });
  });
}
