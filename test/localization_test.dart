import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:customer_app/core/utils/extensions.dart';

void main() {
  group('Localization Tests', () {
    test('AppLocalizations supports en, si, and ta', () {
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode), [
        'en',
        'si',
        'ta',
      ]);
    });

    test('English localizations return correct strings', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(l10n.appTitle, 'JobHive');
      expect(l10n.welcomeHeroTitle, 'Expert Services,\nRight at Your Door');
      expect(l10n.onDemandHomeServices, 'ON-DEMAND HOME SERVICES');
      expect(l10n.fastArrival, 'Fast Arrival');
      expect(l10n.guaranteed, 'Guaranteed');
      expect(l10n.ratingBadge, '4.9/5 Rating');
      expect(l10n.getStarted, 'Get Started');
      expect(l10n.tabHome, 'Home');
      expect(l10n.tabJobs, 'Jobs');
      expect(l10n.tabAlerts, 'Alerts');
      expect(l10n.tabProfile, 'Profile');
      expect(l10n.resendCodeIn(30), 'Resend code in 30s');
      expect(l10n.alertsAndNotifications, 'Alerts & Notifications');
      expect(l10n.signOut, 'Sign Out');
      expect(l10n.memberSince('2026'), 'Member since 2026');
    });

    test('Sinhala localizations return correct strings', () {
      final l10n = lookupAppLocalizations(const Locale('si'));
      expect(l10n.appTitle, 'ජොබ්හයිව්');
      expect(l10n.welcomeHeroTitle, 'විශේෂඥ සේවාවන්,\nඔබගේ දොරකඩටම');
      expect(l10n.onDemandHomeServices, 'ඉල්ලුම මත නිවාස සේවා');
      expect(l10n.fastArrival, 'ක්ෂණික පැමිණීම');
      expect(l10n.guaranteed, 'වගකීම සහතිකයි');
      expect(l10n.ratingBadge, '4.9/5 ශ්‍රේණිගත කිරීම');
      expect(l10n.getStarted, 'ආරම්භ කරන්න');
      expect(l10n.tabHome, 'මුල් පිටුව');
      expect(l10n.tabJobs, 'සේවා');
      expect(l10n.tabAlerts, 'දැනුම්දීම්');
      expect(l10n.tabProfile, 'පැතිකඩ');
      expect(l10n.resendCodeIn(30), 'තත්පර 30කින් නැවත එවන්න');
      expect(l10n.alertsAndNotifications, 'දැනුම්දීම් සහ නිවේදන');
      expect(l10n.signOut, 'ඉවත් වන්න');
      expect(l10n.memberSince('2026'), '2026 සිට සාමාජිකයෙකි');
    });

    test('Tamil localizations return correct strings', () {
      final l10n = lookupAppLocalizations(const Locale('ta'));
      expect(l10n.appTitle, 'ஜாப்ஹைவ்');
      expect(l10n.welcomeHeroTitle, 'நிபுணர் சேவைகள்,\nஉங்கள் வீட்டு வாசலில்');
      expect(l10n.onDemandHomeServices, 'தேவைக்கேற்ற வீட்டு சேவைகள்');
      expect(l10n.fastArrival, 'விரைவான வருகை');
      expect(l10n.guaranteed, 'உத்தரவாதம்');
      expect(l10n.ratingBadge, '4.9/5 மதிப்பீடு');
      expect(l10n.getStarted, 'தொடங்குங்கள்');
      expect(l10n.tabHome, 'முகப்பு');
      expect(l10n.tabJobs, 'பணிகள்');
      expect(l10n.tabAlerts, 'அறிவிப்புகள்');
      expect(l10n.tabProfile, 'சுயவிவரம்');
      expect(l10n.resendCodeIn(30), '30 வினாடிகளில் மீண்டும் அனுப்புங்கள்');
      expect(l10n.alertsAndNotifications, 'எச்சரிக்கைகள் & அறிவிப்புகள்');
      expect(l10n.signOut, 'வெளியேறு');
      expect(l10n.memberSince('2026'), '2026 முதல் உறுப்பினர்');
    });

    testWidgets('LocalizedBuildContext extension provides localized strings in widget tree', (
      tester,
    ) async {
      late String welcomeTitle;
      late String tabHomeText;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('si'),
          home: Builder(
            builder: (context) {
              welcomeTitle = context.loc.welcomeHeroTitle;
              tabHomeText = context.loc.tabHome;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(welcomeTitle, 'විශේෂඥ සේවාවන්,\nඔබගේ දොරකඩටම');
      expect(tabHomeText, 'මුල් පිටුව');
    });
  });
}
