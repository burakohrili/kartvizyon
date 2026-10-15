import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/l10n/app_localizations.dart';

void main() {
  test(
    'shared navigation and access banners are translated in both locales',
    () async {
      final turkish = await AppLocalizations.delegate.load(const Locale('tr'));
      final english = await AppLocalizations.delegate.load(const Locale('en'));

      expect(turkish.todayTab, 'Bugün');
      expect(turkish.customersTab, 'Müşteriler');
      expect(turkish.newVisit, 'Yeni ziyaret');
      expect(turkish.readOnlyBanner, contains('görüntüleme'));
      expect(turkish.trialBannerDays(3), contains('3 gün'));
      expect(turkish.moreTitle, 'Daha fazla');
      expect(turkish.fieldMap, 'Saha haritası');
      expect(turkish.greeting('Burak'), 'Merhaba Burak');
      expect(turkish.signIn, 'Giriş yap');
      expect(turkish.email, 'E-posta');
      expect(turkish.customers, 'Müşteriler');
      expect(turkish.startVisitAction, 'Ziyareti başlat');
      expect(turkish.aiDraftNotSaved, contains('kaydetmeden'));
      expect(turkish.fieldModeOn, 'Saha modu açık');
      expect(turkish.fieldModeAfterHours, contains('21.00'));
      expect(turkish.distanceAway('300 m'), '300 m uzakta');
      expect(turkish.fieldModeNotificationChannel, 'Saha modu');
      expect(turkish.customerDetailTitle, 'Müşteri kartı');
      expect(turkish.editCustomer, 'Müşteriyi düzenle');
      expect(turkish.archivePreservesData, contains('silinmez'));
      expect(turkish.pinCustomerLocationPrivacy, contains('hareketleriniz'));

      expect(english.todayTab, 'Today');
      expect(english.customersTab, 'Customers');
      expect(english.newVisit, 'New visit');
      expect(english.readOnlyBanner, contains('View only'));
      expect(english.trialBannerDays(3), contains('3 days'));
      expect(english.moreTitle, 'More');
      expect(english.fieldMap, 'Field map');
      expect(english.greeting('Burak'), 'Hello Burak');
      expect(english.signIn, 'Sign in');
      expect(english.email, 'Email');
      expect(english.customers, 'Customers');
      expect(english.startVisitAction, 'Start visit');
      expect(english.aiDraftNotSaved, contains('until you save'));
      expect(english.fieldModeOn, 'Field Mode is on');
      expect(english.fieldModeAfterHours, contains('9:00 PM'));
      expect(english.distanceAway('300 m'), '300 m away');
      expect(english.fieldModeNotificationChannel, 'Field Mode');
      expect(english.customerDetailTitle, 'Customer record');
      expect(english.editCustomer, 'Edit customer');
      expect(english.archivePreservesData, contains('will not be deleted'));
      expect(english.pinCustomerLocationPrivacy, contains('movements'));
    },
  );
}
