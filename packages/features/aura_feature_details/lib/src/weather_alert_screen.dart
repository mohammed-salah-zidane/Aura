import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:aura_feature_details/src/widgets/detail_host.dart';
import 'package:aura_feature_details/src/widgets/detail_scaffold.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// The active alert, in the issuing service's own words.
///
/// Every line on this screen is the issuer's: the event, the headline, the
/// description, the instruction and the areas. Nothing is summarised, which is
/// why it reads as an official notice rather than an account of one.
class WeatherAlertScreen extends StatelessWidget {
  /// Creates the alert screen.
  const WeatherAlertScreen({required this.onBack, super.key});

  /// Goes back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DetailHost(
      title: context.l10n.alertTitle,
      sky: (state) => AuraSkyKind.weatherAlert,
      onBack: onBack,
      builder: (context, state) {
        final l10n = context.l10n;
        final format = AuraFormat(l10n: l10n, units: state.units);
        final alert = state.snapshot.headlineAlert;
        if (alert == null) {
          return <Widget>[
            DetailCard(
              children: <Widget>[
                Text(
                  l10n.alertNone,
                  style: AuraText.bodySmall.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ];
        }

        final actions = _actions(alert.instruction);
        return <Widget>[
          _Hero(alert: alert),
          _Timing(alert: alert, format: format, today: state.now),
          if (alert.description.isNotEmpty) ...<Widget>[
            DetailSectionLabel(l10n.alertWhatToExpect),
            DetailCard(
              radius: AuraRadii.detailCard,
              padding: const EdgeInsets.all(AuraSpacing.lg),
              children: <Widget>[
                Text(
                  alert.description,
                  style: AuraText.body.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (actions.isNotEmpty) ...<Widget>[
            DetailSectionLabel(l10n.alertRecommendedActions),
            DetailCard(
              radius: AuraRadii.detailCard,
              padding: const EdgeInsets.all(AuraSpacing.lg),
              children: <Widget>[
                for (final action in actions) _Action(text: action),
              ],
            ),
          ],
          if (alert.areas.isNotEmpty) ...<Widget>[
            DetailSectionLabel(l10n.alertAreasAffected),
            Wrap(
              spacing: AuraSpacing.sm,
              runSpacing: AuraSpacing.sm,
              children: <Widget>[
                for (final area in alert.areas) AuraChip(label: area),
              ],
            ),
          ],
          Text(
            l10n.alertSource,
            style: AuraText.unitLabel.copyWith(
              color: AuraColors.textTertiary,
            ),
          ),
        ];
      },
    );
  }

  /// The issuer's instruction, split where they broke it.
  ///
  /// Split on line breaks only. Issuers write in paragraphs and often list
  /// their advice a line at a time; splitting on sentences instead would invent
  /// a structure the notice never had.
  static List<String> _actions(String instruction) => instruction
      .split(RegExp(r'[\r\n]+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

/// The event, how serious it is, and the issuer's own headline.
class _Hero extends StatelessWidget {
  const _Hero({required this.alert});

  final WeatherAlert alert;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DetailCard(
      gap: AuraSpacing.md,
      fill: AuraColors.alertPanel,
      borderColor: AuraColors.alertPanelBorder,
      children: <Widget>[
        Row(
          spacing: AuraSpacing.md,
          children: <Widget>[
            Container(
              width: AuraSizes.alertTile,
              height: AuraSizes.alertTile,
              decoration: BoxDecoration(
                color: AuraColors.alertTile,
                borderRadius: BorderRadius.circular(AuraRadii.chip),
              ),
              child: const Center(
                child: Icon(
                  AuraIcons.alert,
                  size: AuraSizes.iconUi,
                  color: AuraColors.alertIcon,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AuraSpacing.xxsPlus,
                children: <Widget>[
                  Text(
                    alert.event,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AuraText.titleCardSmall.copyWith(
                      color: AuraColors.textPrimary,
                    ),
                  ),
                  Row(
                    spacing: AuraSpacing.sm,
                    children: <Widget>[
                      if (_severity(l10n, alert.severity) case final word?)
                        Text(
                          word.toUpperCase(),
                          style: AuraText.metaLabel
                              .forScript(context)
                              .copyWith(color: AuraColors.alertIcon),
                        ),
                      Flexible(
                        child: Text(
                          alert.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AuraText.caption.copyWith(
                            color: AuraColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (alert.headline.isNotEmpty)
          Text(
            alert.headline,
            style: AuraText.body.copyWith(color: AuraColors.textSecondary),
          ),
      ],
    );
  }

  /// The issuer's grade, or nothing when they sent one this table cannot name.
  static String? _severity(AppLocalizations l10n, AlertSeverity severity) =>
      switch (severity) {
        AlertSeverity.minor => l10n.alertSeverityMinor,
        AlertSeverity.moderate => l10n.alertSeverityModerate,
        AlertSeverity.severe => l10n.alertSeveritySevere,
        AlertSeverity.extreme => l10n.alertSeverityExtreme,
        AlertSeverity.unknown => null,
      };
}

/// When the notice starts and when it stops.
class _Timing extends StatelessWidget {
  const _Timing({
    required this.alert,
    required this.format,
    required this.today,
  });

  final WeatherAlert alert;
  final AuraFormat format;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuraGlass(
      radius: AuraRadii.row,
      shadow: AuraShadows.panel,
      padding: const EdgeInsets.symmetric(
        vertical: AuraSpacing.mdPlus,
        horizontal: AuraSpacing.xxs,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _Moment(
              label: l10n.alertEffective,
              value: _at(l10n, alert.effective),
            ),
          ),
          const SizedBox(
            width: AuraSizes.divider,
            height: AuraSizes.alertTimingDividerHeight,
            child: ColoredBox(color: AuraColors.border),
          ),
          Expanded(
            child: _Moment(
              label: l10n.alertExpires,
              value: _at(l10n, alert.expires),
            ),
          ),
        ],
      ),
    );
  }

  /// A time the issuer gave, said relative to today where that reads better.
  String _at(AppLocalizations l10n, DateTime? moment) {
    if (moment == null) return '';
    final local = moment.toLocal();
    final clock = format.clock(local);
    final isToday =
        local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
    return isToday
        ? l10n.alertTimeToday(clock)
        : l10n.alertTimeOn(format.shortDate(local), clock);
  }
}

/// One half of the timing card.
class _Moment extends StatelessWidget {
  const _Moment({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AuraSpacing.hairline,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AuraText.metaLabel
              .forScript(context)
              .copyWith(color: AuraColors.textTertiary),
        ),
        Text(
          value,
          maxLines: 1,
          style: AuraText.metaValue.copyWith(color: AuraColors.textPrimary),
        ),
      ],
    );
  }
}

/// One line of what the issuer advises.
class _Action extends StatelessWidget {
  const _Action({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuraSpacing.smPlus,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: AuraSpacing.hairline),
          child: Icon(
            AuraIcons.success,
            size: AuraSizes.iconUi,
            color: AuraColors.accent,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AuraText.bodyTight.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
