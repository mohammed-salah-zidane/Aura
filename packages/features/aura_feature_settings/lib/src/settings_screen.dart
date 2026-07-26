import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_feature_settings/src/settings_view_model.dart';
import 'package:aura_feature_settings/src/widgets/settings_group.dart';
import 'package:aura_feature_settings/src/widgets/settings_picker.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Units, notifications and what the app is.
///
/// Two rows the pen draws are not here. Appearance is a value rather than a
/// picker, because Aura's palette is one condition-driven theme and there is no
/// light mode to choose. The store rating row is absent, because it has no
/// listing to open and a button that opens nothing is worse than no button.
///
/// The pen's "Done" link is gone for the same reason the search screen's cross
/// is. Every choice here applies as it is made, so Done only closed the screen,
/// which is what the back button does on every other pushed screen.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({
    required this.onDone,
    required this.version,
    super.key,
  });

  /// Closes the screen.
  final VoidCallback onDone;

  /// The build the user is running, read from the package at the root.
  final String version;

  /// The pen's `Content` padding on this frame.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AuraSpacing.xl,
    AuraSpacing.xs,
    AuraSpacing.xl,
    AuraSpacing.xxl + AuraSpacing.xxs,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(settingsViewModelProvider).value;
    final viewModel = ref.read(settingsViewModelProvider.notifier);

    return AuraSky(
      kind: AuraSkyKind.systemBrand,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: _padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AuraSpacing.lgPlus,
            children: <Widget>[
              Row(
                spacing: AuraSpacing.md,
                children: <Widget>[
                  AuraCircleButton(
                    icon: AuraChevron.back(context),
                    size: AuraCircleButtonSize.back,
                    semanticLabel: l10n.commonBack,
                    onPressed: onDone,
                  ),
                  Expanded(
                    child: Text(
                      l10n.settingsTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuraText.titleSettings.copyWith(
                        color: AuraColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (state != null) ...<Widget>[
                _Units(state: state, viewModel: viewModel),
                _Notifications(state: state, viewModel: viewModel),
                const _General(),
                _About(version: version),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The three unit choices, each opening a picker.
class _Units extends StatelessWidget {
  const _Units({required this.state, required this.viewModel});

  final SettingsUiState state;
  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final units = state.units;
    return SettingsGroup(
      label: l10n.settingsUnits,
      rows: <Widget>[
        AuraSettingsRow(
          icon: AuraIcons.thermometer,
          label: l10n.settingsTemperature,
          value: _temperature(l10n, units.temperature),
          onTap: () async {
            final chosen = await showSettingsPicker<TemperatureUnit>(
              context: context,
              title: l10n.settingsTemperature,
              selected: units.temperature,
              options: <SettingsOption<TemperatureUnit>>[
                SettingsOption<TemperatureUnit>(
                  value: TemperatureUnit.celsius,
                  label: l10n.unitCelsius,
                ),
                SettingsOption<TemperatureUnit>(
                  value: TemperatureUnit.fahrenheit,
                  label: l10n.unitFahrenheit,
                ),
              ],
            );
            if (chosen != null) {
              await viewModel.selectTemperature(chosen);
            }
          },
        ),
        AuraSettingsRow(
          icon: AuraIcons.wind,
          label: l10n.settingsWindSpeed,
          value: _speed(l10n, units.speed),
          onTap: () async {
            final chosen = await showSettingsPicker<SpeedUnit>(
              context: context,
              title: l10n.settingsWindSpeed,
              selected: units.speed,
              options: <SettingsOption<SpeedUnit>>[
                SettingsOption<SpeedUnit>(
                  value: SpeedUnit.kilometersPerHour,
                  label: l10n.unitSpeedKilometersPerHour,
                ),
                SettingsOption<SpeedUnit>(
                  value: SpeedUnit.milesPerHour,
                  label: l10n.unitSpeedMilesPerHour,
                ),
              ],
            );
            if (chosen != null) {
              await viewModel.selectSpeed(chosen);
            }
          },
        ),
        AuraSettingsRow(
          icon: AuraIcons.umbrella,
          label: l10n.settingsPrecipitation,
          value: _precipitation(l10n, units.precipitation),
          onTap: () async {
            final chosen = await showSettingsPicker<PrecipitationUnit>(
              context: context,
              title: l10n.settingsPrecipitation,
              selected: units.precipitation,
              options: <SettingsOption<PrecipitationUnit>>[
                SettingsOption<PrecipitationUnit>(
                  value: PrecipitationUnit.millimeters,
                  label: l10n.unitMillimetres,
                ),
                SettingsOption<PrecipitationUnit>(
                  value: PrecipitationUnit.inches,
                  label: l10n.unitInches,
                ),
              ],
            );
            if (chosen != null) {
              await viewModel.selectPrecipitation(chosen);
            }
          },
        ),
      ],
    );
  }

  static String _temperature(AppLocalizations l10n, TemperatureUnit unit) =>
      switch (unit) {
        TemperatureUnit.celsius => l10n.unitCelsius,
        TemperatureUnit.fahrenheit => l10n.unitFahrenheit,
      };

  static String _speed(AppLocalizations l10n, SpeedUnit unit) => switch (unit) {
    SpeedUnit.kilometersPerHour => l10n.unitSpeedKilometersPerHour,
    SpeedUnit.milesPerHour => l10n.unitSpeedMilesPerHour,
  };

  static String _precipitation(
    AppLocalizations l10n,
    PrecipitationUnit unit,
  ) => switch (unit) {
    PrecipitationUnit.millimeters => l10n.unitMillimetres,
    PrecipitationUnit.inches => l10n.unitInches,
  };
}

/// The three notification switches.
class _Notifications extends StatelessWidget {
  const _Notifications({required this.state, required this.viewModel});

  final SettingsUiState state;
  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preferences = state.notifications;
    return SettingsGroup(
      label: l10n.settingsNotificationsSection,
      rows: <Widget>[
        AuraSettingsRow(
          icon: AuraIcons.calendarClock,
          label: l10n.settingsDailyForecast,
          trailing: AuraToggle(
            value: preferences.dailyForecast,
            semanticLabel: l10n.settingsDailyForecast,
            onChanged: (value) => viewModel.setDailyForecast(
              enabled: value,
              title: l10n.notificationDailyTitle(state.placeName),
              body: l10n.notificationDailyBody,
            ),
          ),
        ),
        AuraSettingsRow(
          icon: AuraIcons.alert,
          label: l10n.settingsSevereAlerts,
          trailing: AuraToggle(
            value: preferences.severeAlerts,
            semanticLabel: l10n.settingsSevereAlerts,
            onChanged: (value) => viewModel.setSevereAlerts(enabled: value),
          ),
        ),
        AuraSettingsRow(
          icon: AuraIcons.droplets,
          label: l10n.settingsPrecipitationStart,
          trailing: AuraToggle(
            value: preferences.precipitationStart,
            semanticLabel: l10n.settingsPrecipitationStart,
            onChanged: (value) =>
                viewModel.setPrecipitationStart(enabled: value),
          ),
        ),
      ],
    );
  }
}

/// What the app decides for itself.
class _General extends StatelessWidget {
  const _General();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsGroup(
      label: l10n.settingsGeneral,
      rows: <Widget>[
        AuraSettingsRow(
          icon: AuraIcons.moonStar,
          label: l10n.settingsAppearance,
          value: l10n.settingsAppearanceValue,
        ),
        AuraSettingsRow(
          icon: AuraIcons.cached,
          label: l10n.settingsDataSource,
          value: l10n.settingsDataSourceValue,
        ),
      ],
    );
  }
}

/// Which build this is.
class _About extends StatelessWidget {
  const _About({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      label: context.l10n.settingsAbout,
      rows: <Widget>[
        AuraSettingsRow(
          icon: AuraIcons.info,
          label: context.l10n.settingsVersion,
          value: version,
        ),
      ],
    );
  }
}
