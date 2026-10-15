import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'KartVizyon AI'**
  String get appTitle;

  /// No description provided for @summaryTab.
  ///
  /// In tr, this message translates to:
  /// **'Özet'**
  String get summaryTab;

  /// No description provided for @customersTab.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriler'**
  String get customersTab;

  /// No description provided for @visitsTab.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretler'**
  String get visitsTab;

  /// No description provided for @tasksTab.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get tasksTab;

  /// No description provided for @fieldSummary.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün saha özeti'**
  String get fieldSummary;

  /// No description provided for @todayTab.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get todayTab;

  /// No description provided for @newVisit.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ziyaret'**
  String get newVisit;

  /// No description provided for @visitTab.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret'**
  String get visitTab;

  /// No description provided for @menuTab.
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get menuTab;

  /// No description provided for @readOnlyBanner.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız görüntüleme. Yeni işlemler için abonelik başlatın.'**
  String get readOnlyBanner;

  /// No description provided for @premiumTitle.
  ///
  /// In tr, this message translates to:
  /// **'Premium ve abonelik'**
  String get premiumTitle;

  /// No description provided for @premiumMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get premiumMonthly;

  /// No description provided for @premiumAnnual.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get premiumAnnual;

  /// No description provided for @premiumUnlimited.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız'**
  String get premiumUnlimited;

  /// No description provided for @sandboxNotice.
  ///
  /// In tr, this message translates to:
  /// **'Sandbox test ortamı — canlı hesabınızdan ayrıdır.'**
  String get sandboxNotice;

  /// No description provided for @trialPlanName.
  ///
  /// In tr, this message translates to:
  /// **'14 günlük deneme'**
  String get trialPlanName;

  /// No description provided for @viewOnlyPlanName.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız görüntüleme'**
  String get viewOnlyPlanName;

  /// No description provided for @activePlanName.
  ///
  /// In tr, this message translates to:
  /// **'Premium planı'**
  String get activePlanName;

  /// No description provided for @organizationPlanName.
  ///
  /// In tr, this message translates to:
  /// **'Kurum planı'**
  String get organizationPlanName;

  /// No description provided for @organizationPlanManaged.
  ///
  /// In tr, this message translates to:
  /// **'Bu çalışma alanının planı kurum yöneticiniz tarafından yönetilir.'**
  String get organizationPlanManaged;

  /// No description provided for @paymentsThroughStore.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme {store} hesabınız üzerinden güvenle tamamlanır.'**
  String paymentsThroughStore(String store);

  /// No description provided for @premiumTrialDisclosure.
  ///
  /// In tr, this message translates to:
  /// **'14 gün ücretsiz deneyin. Kart gerekmez. Deneme sonunda otomatik ücret alınmaz. Devam etmek için abonelik başlatabilirsiniz.'**
  String get premiumTrialDisclosure;

  /// No description provided for @premiumTrialQuota.
  ///
  /// In tr, this message translates to:
  /// **'Deneme: toplam 60 tarama · 120 dakika ses işleme · 60 AI özeti.'**
  String get premiumTrialQuota;

  /// No description provided for @premiumIndividualQuota.
  ///
  /// In tr, this message translates to:
  /// **'Bireysel: ayda 125 tarama · 240 dakika ses işleme · 125 AI özeti. Güncel fiyat, mağaza hesabınızın ülke veya bölgesine göre satın alma düğmesinde gösterilir.'**
  String get premiumIndividualQuota;

  /// No description provided for @premiumTrialLastDay.
  ///
  /// In tr, this message translates to:
  /// **'Denemenizin son günü.'**
  String get premiumTrialLastDay;

  /// No description provided for @premiumTrialDaysLeft.
  ///
  /// In tr, this message translates to:
  /// **'Denemenizin bitmesine {days} gün kaldı.'**
  String premiumTrialDaysLeft(int days);

  /// No description provided for @premiumReadOnlyDisclosure.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız görüntüleme: mevcut kayıtlarınız, dışa aktarma ve hesap silme açık kalır. Yeni kayıt oluşturmak veya AI özelliklerini kullanmak için abonelik başlatın.'**
  String get premiumReadOnlyDisclosure;

  /// No description provided for @premiumUsageScans.
  ///
  /// In tr, this message translates to:
  /// **'Tarama: {used} / {limit}'**
  String premiumUsageScans(String used, String limit);

  /// No description provided for @premiumUsageAudio.
  ///
  /// In tr, this message translates to:
  /// **'Ses işleme: {used} / {limit} dakika'**
  String premiumUsageAudio(String used, String limit);

  /// No description provided for @premiumUsageSummaries.
  ///
  /// In tr, this message translates to:
  /// **'AI özeti: {used} / {limit}'**
  String premiumUsageSummaries(String used, String limit);

  /// No description provided for @premiumQuotaPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Ücretli abonelikte tam kota açılır. Kullanılmayan haklar devretmez. Kota aşımı otomatik ücret doğurmaz.'**
  String get premiumQuotaPolicy;

  /// No description provided for @premiumRestorePurchases.
  ///
  /// In tr, this message translates to:
  /// **'Satın almaları geri yükle'**
  String get premiumRestorePurchases;

  /// No description provided for @premiumManageSubscription.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliği {store}’da yönet'**
  String premiumManageSubscription(String store);

  /// No description provided for @premiumAutoRenewalDisclosure.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik seçtiğiniz dönemde otomatik yenilenir. Yenilemeyi mevcut dönem bitmeden mağaza hesap ayarlarınızdan kapatabilirsiniz.'**
  String get premiumAutoRenewalDisclosure;

  /// No description provided for @premiumTermsOfUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get premiumTermsOfUse;

  /// No description provided for @premiumPrivacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get premiumPrivacyPolicy;

  /// No description provided for @billingLoadFailure.
  ///
  /// In tr, this message translates to:
  /// **'Premium bilgileri yüklenemedi.'**
  String get billingLoadFailure;

  /// No description provided for @billingConfigurationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza ödeme yapılandırması henüz tamamlanmadı.'**
  String get billingConfigurationUnavailable;

  /// No description provided for @billingOfferingUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu mağaza için şu anda satın alınabilir plan bulunamadı.'**
  String get billingOfferingUnavailable;

  /// No description provided for @billingSessionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için lütfen giriş yapın.'**
  String get billingSessionRequired;

  /// No description provided for @billingPurchaseCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma iptal edildi.'**
  String get billingPurchaseCancelled;

  /// No description provided for @billingPurchaseFailed.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma tamamlanamadı. Mağaza hesabınızı kontrol edip yeniden deneyin.'**
  String get billingPurchaseFailed;

  /// No description provided for @billingRestoreFailed.
  ///
  /// In tr, this message translates to:
  /// **'Satın almalar geri yüklenemedi. Mağaza hesabınızı kontrol edip yeniden deneyin.'**
  String get billingRestoreFailed;

  /// No description provided for @billingPurchaseServerPending.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma mağazada tamamlandı; sunucu doğrulaması bekleniyor. Kontrol etmek için bu ekranı biraz sonra yeniden açın.'**
  String get billingPurchaseServerPending;

  /// No description provided for @billingRestoreServerPending.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme mağazada tamamlandı; sunucu doğrulaması bekleniyor. Biraz sonra yeniden deneyin.'**
  String get billingRestoreServerPending;

  /// No description provided for @billingRestoreNoActivePurchase.
  ///
  /// In tr, this message translates to:
  /// **'Bu mağaza hesabında geri yüklenecek etkin bir satın alma bulunamadı.'**
  String get billingRestoreNoActivePurchase;

  /// No description provided for @billingPurchaseAwaitingStore.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma alındı; mağaza doğrulaması bekleniyor.'**
  String get billingPurchaseAwaitingStore;

  /// No description provided for @billingSandboxLiveServerWarning.
  ///
  /// In tr, this message translates to:
  /// **'Test satın almanız mağazada etkin, ancak bu uygulama canlı sunucuya bağlı. Sandbox satın almaları canlı erişimi açmaz. Test sunucusuna bağlı TestFlight sürümünü kullanın. Tekrar satın almayın.'**
  String get billingSandboxLiveServerWarning;

  /// No description provided for @billingServerAccessPending.
  ///
  /// In tr, this message translates to:
  /// **'Premium mağazada etkin, ancak sunucu erişiminiz henüz açılmadı. Geri yükleme ve erişim doğrulaması tamamlanmadı. Tekrar satın almayın; destek ile iletişime geçin.'**
  String get billingServerAccessPending;

  /// No description provided for @billingRestoreSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Premium satın almanız geri yüklendi ve sunucu erişiminiz doğrulandı.'**
  String get billingRestoreSuccess;

  /// No description provided for @billingPurchaseSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Premium etkinleşti ve sunucu erişiminiz doğrulandı.'**
  String get billingPurchaseSuccess;

  /// No description provided for @billingSubscriptionManagementUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik yönetimi açılamadı. Lütfen biraz sonra yeniden deneyin.'**
  String get billingSubscriptionManagementUnavailable;

  /// No description provided for @trialBannerLastDay.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz denemenizin son günü. Otomatik ücret alınmaz.'**
  String get trialBannerLastDay;

  /// No description provided for @trialBannerDays.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz deneme: {days} gün kaldı. Otomatik ücret alınmaz.'**
  String trialBannerDays(int days);

  /// No description provided for @subscription.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik'**
  String get subscription;

  /// No description provided for @moreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla'**
  String get moreTitle;

  /// No description provided for @interfaceLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dili'**
  String get interfaceLanguage;

  /// No description provided for @languageUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dil tercihi kaydedilemedi. Tekrar deneyin.'**
  String get languageUpdateFailed;

  /// No description provided for @fieldMap.
  ///
  /// In tr, this message translates to:
  /// **'Saha haritası'**
  String get fieldMap;

  /// No description provided for @nearbyCustomersRoute.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki müşteriler ve ziyaret rotası'**
  String get nearbyCustomersRoute;

  /// No description provided for @visitsVoiceNote.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretler ve sesli not'**
  String get visitsVoiceNote;

  /// No description provided for @preApprovalPromise.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı onayından önce kurumsal hafızaya eklenmez'**
  String get preApprovalPromise;

  /// No description provided for @syncCenter.
  ///
  /// In tr, this message translates to:
  /// **'Eşitleme merkezi'**
  String get syncCenter;

  /// No description provided for @pendingRecordsErrors.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen kayıtlar ve hatalar'**
  String get pendingRecordsErrors;

  /// No description provided for @chooseWorkspace.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma alanı seçin'**
  String get chooseWorkspace;

  /// No description provided for @workspace.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma alanı'**
  String get workspace;

  /// No description provided for @workspaceChangeFailed.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma alanı değiştirilemedi. Tekrar deneyin.'**
  String get workspaceChangeFailed;

  /// No description provided for @switchWorkspace.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma alanı değiştir'**
  String get switchWorkspace;

  /// No description provided for @calendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get calendar;

  /// No description provided for @plannedVisitsDatedTasks.
  ///
  /// In tr, this message translates to:
  /// **'Planlanan ziyaretler ve tarihli görevler'**
  String get plannedVisitsDatedTasks;

  /// No description provided for @activity.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite'**
  String get activity;

  /// No description provided for @activityHistory.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret, görev, fırsat ve sipariş geçmişi'**
  String get activityHistory;

  /// No description provided for @reportsSummary.
  ///
  /// In tr, this message translates to:
  /// **'Rapor özeti'**
  String get reportsSummary;

  /// No description provided for @customerVisitTaskMetrics.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri, ziyaret ve görev göstergeleri'**
  String get customerVisitTaskMetrics;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @commentsTasksApprovalEvents.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar, görevler ve onay olayları'**
  String get commentsTasksApprovalEvents;

  /// No description provided for @opportunities.
  ///
  /// In tr, this message translates to:
  /// **'Fırsatlar'**
  String get opportunities;

  /// No description provided for @salesPipelineStages.
  ///
  /// In tr, this message translates to:
  /// **'Satış pipeline ve aşama görünümü'**
  String get salesPipelineStages;

  /// No description provided for @productsPrices.
  ///
  /// In tr, this message translates to:
  /// **'Ürün ve fiyatlar'**
  String get productsPrices;

  /// No description provided for @activeProductCatalogPrices.
  ///
  /// In tr, this message translates to:
  /// **'Aktif ürün kataloğu ve liste fiyatları'**
  String get activeProductCatalogPrices;

  /// No description provided for @orderDrafts.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş taslakları'**
  String get orderDrafts;

  /// No description provided for @draftApprovalStatus.
  ///
  /// In tr, this message translates to:
  /// **'Taslak ve onay durumlarını görüntüleyin'**
  String get draftApprovalStatus;

  /// No description provided for @documents.
  ///
  /// In tr, this message translates to:
  /// **'Belgeler'**
  String get documents;

  /// No description provided for @fileSecurityScanning.
  ///
  /// In tr, this message translates to:
  /// **'Dosya ve güvenlik tarama durumları'**
  String get fileSecurityScanning;

  /// No description provided for @fieldForms.
  ///
  /// In tr, this message translates to:
  /// **'Saha formları'**
  String get fieldForms;

  /// No description provided for @activeTemplatesSubmissions.
  ///
  /// In tr, this message translates to:
  /// **'Aktif şablonlar ve gönderimler'**
  String get activeTemplatesSubmissions;

  /// No description provided for @moduleNoPlannedVisits.
  ///
  /// In tr, this message translates to:
  /// **'Planlanmış ziyaret yok'**
  String get moduleNoPlannedVisits;

  /// No description provided for @moduleCalendarEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Tarihli ziyaretler ve son tarihi olan görevler burada listelenir. Sağ alttaki düğmeyle yeni ziyaret planlayabilirsiniz.'**
  String get moduleCalendarEmptyHint;

  /// No description provided for @moduleNoApprovedVisits.
  ///
  /// In tr, this message translates to:
  /// **'Henüz onaylanmış ziyaret yok'**
  String get moduleNoApprovedVisits;

  /// No description provided for @moduleActivityEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Onayladığınız ziyaretler buraya düşer. Bir ziyaret notu gönderip özeti onayladığınızda ilk kayıt görünür.'**
  String get moduleActivityEmptyHint;

  /// No description provided for @moduleNoReportData.
  ///
  /// In tr, this message translates to:
  /// **'Gösterge üretecek kayıt yok'**
  String get moduleNoReportData;

  /// No description provided for @moduleReportsEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri, ziyaret ve görev sayıları burada görüntülenir. İlk müşterinizi ekleyip ziyaret kaydettiğinizde göstergeler dolar.'**
  String get moduleReportsEmptyHint;

  /// No description provided for @moduleNoNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim yok'**
  String get moduleNoNotifications;

  /// No description provided for @moduleNotificationsEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan ziyaretler, geciken görevler ve saha hatırlatmaları burada görünür.'**
  String get moduleNotificationsEmptyHint;

  /// No description provided for @moduleNoOpportunities.
  ///
  /// In tr, this message translates to:
  /// **'Fırsat kaydı yok'**
  String get moduleNoOpportunities;

  /// No description provided for @moduleOpportunitiesEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni fırsatı burada oluşturabilir, kaydı açarak satış aşamasını güncelleyebilirsiniz.'**
  String get moduleOpportunitiesEmptyHint;

  /// No description provided for @moduleNoProducts.
  ///
  /// In tr, this message translates to:
  /// **'Katalogda ürün yok'**
  String get moduleNoProducts;

  /// No description provided for @moduleProductsEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Aktif ürün kataloğu ve liste fiyatları burada görünür. Yeni ürünü mobilde kataloğa ekleyebilirsiniz.'**
  String get moduleProductsEmptyHint;

  /// No description provided for @moduleNoOrderDrafts.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş taslağı yok'**
  String get moduleNoOrderDrafts;

  /// No description provided for @moduleOrdersEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Burada sipariş taslağı oluşturabilir; kaydı açarak onaya gönderebilir veya yetkiniz varsa sonuçlandırabilirsiniz.'**
  String get moduleOrdersEmptyHint;

  /// No description provided for @moduleNoDocuments.
  ///
  /// In tr, this message translates to:
  /// **'Belge yok'**
  String get moduleNoDocuments;

  /// No description provided for @moduleDocumentsEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenen dosyalar ve zararlı yazılım tarama durumu burada görünür. Belgeyi fotoğraflayıp güvenlik taramasına gönderebilirsiniz.'**
  String get moduleDocumentsEmptyHint;

  /// No description provided for @moduleNoActiveForms.
  ///
  /// In tr, this message translates to:
  /// **'Aktif form yok'**
  String get moduleNoActiveForms;

  /// No description provided for @moduleFormsEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza kontrolü, rakip analizi, servis kontrolü veya özel ziyaret kontrol listeleri oluşturup saha yanıtlarını görüntüleyin.'**
  String get moduleFormsEmptyHint;

  /// No description provided for @moduleNoNewNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik yeni bildiriminiz yok.'**
  String get moduleNoNewNotifications;

  /// No description provided for @moduleFilteredOpportunitiesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu filtrede fırsat bulunmuyor.'**
  String get moduleFilteredOpportunitiesEmpty;

  /// No description provided for @moduleFilteredOrdersEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu filtrede sipariş bulunmuyor.'**
  String get moduleFilteredOrdersEmpty;

  /// No description provided for @moduleFilteredActivityEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu filtrede aktivite bulunmuyor.'**
  String get moduleFilteredActivityEmpty;

  /// No description provided for @moduleOpportunityOpenCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} açık fırsat'**
  String moduleOpportunityOpenCount(int count);

  /// No description provided for @moduleOpportunityOpen.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get moduleOpportunityOpen;

  /// No description provided for @moduleOpportunityWon.
  ///
  /// In tr, this message translates to:
  /// **'Kazanılan'**
  String get moduleOpportunityWon;

  /// No description provided for @moduleOpportunityLost.
  ///
  /// In tr, this message translates to:
  /// **'Kaybedilen'**
  String get moduleOpportunityLost;

  /// No description provided for @moduleAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get moduleAll;

  /// No description provided for @moduleOrderApproved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get moduleOrderApproved;

  /// No description provided for @moduleOrderRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get moduleOrderRejected;

  /// No description provided for @moduleActivityVisits.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretler'**
  String get moduleActivityVisits;

  /// No description provided for @moduleActivityTasks.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get moduleActivityTasks;

  /// No description provided for @moduleActivityOpportunities.
  ///
  /// In tr, this message translates to:
  /// **'Fırsatlar'**
  String get moduleActivityOpportunities;

  /// No description provided for @moduleActivityOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişler'**
  String get moduleActivityOrders;

  /// No description provided for @moduleEstimateClose.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini kapanış: {date}'**
  String moduleEstimateClose(String date);

  /// No description provided for @moduleReason.
  ///
  /// In tr, this message translates to:
  /// **'Neden: {reason}'**
  String moduleReason(String reason);

  /// No description provided for @moduleOrderTotal.
  ///
  /// In tr, this message translates to:
  /// **'Toplam: {amount}'**
  String moduleOrderTotal(String amount);

  /// No description provided for @moduleDeliveryDate.
  ///
  /// In tr, this message translates to:
  /// **'Teslim tarihi: {date}'**
  String moduleDeliveryDate(String date);

  /// No description provided for @moduleNote.
  ///
  /// In tr, this message translates to:
  /// **'Not: {note}'**
  String moduleNote(String note);

  /// No description provided for @moduleRejectedBy.
  ///
  /// In tr, this message translates to:
  /// **'Reddeden: {name}'**
  String moduleRejectedBy(String name);

  /// No description provided for @moduleDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih: {date}'**
  String moduleDate(String date);

  /// No description provided for @moduleEditAndReturnToDraft.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle ve taslağa al'**
  String get moduleEditAndReturnToDraft;

  /// No description provided for @moduleSubmitForApproval.
  ///
  /// In tr, this message translates to:
  /// **'Onaya gönder'**
  String get moduleSubmitForApproval;

  /// No description provided for @moduleMakeDecision.
  ///
  /// In tr, this message translates to:
  /// **'Karar ver'**
  String get moduleMakeDecision;

  /// No description provided for @modulePriceLists.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat listeleri'**
  String get modulePriceLists;

  /// No description provided for @modulePriceListFallback.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat listesi'**
  String get modulePriceListFallback;

  /// No description provided for @moduleDocumentFallback.
  ///
  /// In tr, this message translates to:
  /// **'Belge'**
  String get moduleDocumentFallback;

  /// No description provided for @moduleCleanPriceListHint.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik taraması tamamlanan PDF listelerini görüntüleyebilirsiniz.'**
  String get moduleCleanPriceListHint;

  /// No description provided for @moduleNoPriceLists.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat listesi bulunmuyor.'**
  String get moduleNoPriceLists;

  /// No description provided for @moduleProductCatalog.
  ///
  /// In tr, this message translates to:
  /// **'Ürün kataloğu'**
  String get moduleProductCatalog;

  /// No description provided for @moduleNoActiveProducts.
  ///
  /// In tr, this message translates to:
  /// **'Aktif ürün bulunmuyor.'**
  String get moduleNoActiveProducts;

  /// No description provided for @moduleOpenDocument.
  ///
  /// In tr, this message translates to:
  /// **'Açmak için dokunun'**
  String get moduleOpenDocument;

  /// No description provided for @moduleScanPending.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik taraması sürüyor; henüz açılamaz'**
  String get moduleScanPending;

  /// No description provided for @moduleScanStatusPending.
  ///
  /// In tr, this message translates to:
  /// **'Tarama bekliyor'**
  String get moduleScanStatusPending;

  /// No description provided for @moduleScanStatusClean.
  ///
  /// In tr, this message translates to:
  /// **'Temiz'**
  String get moduleScanStatusClean;

  /// No description provided for @moduleScanStatusInfected.
  ///
  /// In tr, this message translates to:
  /// **'Zararlı içerik bulundu'**
  String get moduleScanStatusInfected;

  /// No description provided for @moduleScanStatusError.
  ///
  /// In tr, this message translates to:
  /// **'Tarama hatası'**
  String get moduleScanStatusError;

  /// No description provided for @moduleScanStatusUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Durum bilinmiyor'**
  String get moduleScanStatusUnknown;

  /// No description provided for @moduleLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get moduleLoadFailed;

  /// No description provided for @moduleActionFailed.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlanamadı. Tekrar deneyin.'**
  String get moduleActionFailed;

  /// No description provided for @moduleRecordCreated.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuldu.'**
  String get moduleRecordCreated;

  /// No description provided for @moduleEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get moduleEdit;

  /// No description provided for @moduleRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get moduleRefresh;

  /// No description provided for @moduleFormSubmitted.
  ///
  /// In tr, this message translates to:
  /// **'Form yanıtı gönderildi.'**
  String get moduleFormSubmitted;

  /// No description provided for @modulePreferencesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim tercihleri'**
  String get modulePreferencesTitle;

  /// No description provided for @moduleSystemNotificationsDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Sistem bildirimleri kapalı. Hatırlatmalar uygulama içindeki Bildirimler ekranında görünmeye devam eder.'**
  String get moduleSystemNotificationsDisabled;

  /// No description provided for @moduleVisitReminders.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret hatırlatmaları'**
  String get moduleVisitReminders;

  /// No description provided for @moduleTaskReminders.
  ///
  /// In tr, this message translates to:
  /// **'Görev hatırlatmaları'**
  String get moduleTaskReminders;

  /// No description provided for @moduleMorningReminder.
  ///
  /// In tr, this message translates to:
  /// **'Sabah saha hatırlatması'**
  String get moduleMorningReminder;

  /// No description provided for @moduleMorningReminderTime.
  ///
  /// In tr, this message translates to:
  /// **'Planlı ziyaret olan günlerde 08.30'**
  String get moduleMorningReminderTime;

  /// No description provided for @modulePreferencesSaved.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim tercihleri kaydedildi.'**
  String get modulePreferencesSaved;

  /// No description provided for @modulePreferencesFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim tercihleri açılamadı veya kaydedilemedi. Tekrar deneyin.'**
  String get modulePreferencesFailed;

  /// No description provided for @moduleDocumentsFailed.
  ///
  /// In tr, this message translates to:
  /// **'Belge açılamadı. Tekrar deneyin.'**
  String get moduleDocumentsFailed;

  /// No description provided for @moduleRegistrationFallback.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt'**
  String get moduleRegistrationFallback;

  /// No description provided for @moduleCustomerCount.
  ///
  /// In tr, this message translates to:
  /// **'Aktif müşteri'**
  String get moduleCustomerCount;

  /// No description provided for @moduleApprovedVisitCount.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanmış ziyaret'**
  String get moduleApprovedVisitCount;

  /// No description provided for @moduleReviewVisitCount.
  ///
  /// In tr, this message translates to:
  /// **'İnceleme bekleyen ziyaret'**
  String get moduleReviewVisitCount;

  /// No description provided for @moduleOpenTaskCount.
  ///
  /// In tr, this message translates to:
  /// **'Açık görev'**
  String get moduleOpenTaskCount;

  /// No description provided for @modulePlanVisit.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret planla'**
  String get modulePlanVisit;

  /// No description provided for @moduleNewOpportunity.
  ///
  /// In tr, this message translates to:
  /// **'Yeni fırsat'**
  String get moduleNewOpportunity;

  /// No description provided for @moduleNewProduct.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ürün'**
  String get moduleNewProduct;

  /// No description provided for @moduleNewOrderDraft.
  ///
  /// In tr, this message translates to:
  /// **'Yeni taslak'**
  String get moduleNewOrderDraft;

  /// No description provided for @moduleUploadDocument.
  ///
  /// In tr, this message translates to:
  /// **'Belge yükle'**
  String get moduleUploadDocument;

  /// No description provided for @moduleNewForm.
  ///
  /// In tr, this message translates to:
  /// **'Yeni form'**
  String get moduleNewForm;

  /// No description provided for @moduleStageLead.
  ///
  /// In tr, this message translates to:
  /// **'Aday'**
  String get moduleStageLead;

  /// No description provided for @moduleStageQualified.
  ///
  /// In tr, this message translates to:
  /// **'Nitelikli'**
  String get moduleStageQualified;

  /// No description provided for @moduleStageProposal.
  ///
  /// In tr, this message translates to:
  /// **'Teklif'**
  String get moduleStageProposal;

  /// No description provided for @moduleStageNegotiation.
  ///
  /// In tr, this message translates to:
  /// **'Müzakere'**
  String get moduleStageNegotiation;

  /// No description provided for @moduleStageWon.
  ///
  /// In tr, this message translates to:
  /// **'Kazanıldı'**
  String get moduleStageWon;

  /// No description provided for @moduleStageLost.
  ///
  /// In tr, this message translates to:
  /// **'Kaybedildi'**
  String get moduleStageLost;

  /// No description provided for @moduleStageDraft.
  ///
  /// In tr, this message translates to:
  /// **'Taslak'**
  String get moduleStageDraft;

  /// No description provided for @moduleStagePendingApproval.
  ///
  /// In tr, this message translates to:
  /// **'Onay bekliyor'**
  String get moduleStagePendingApproval;

  /// No description provided for @moduleStageApproved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get moduleStageApproved;

  /// No description provided for @moduleStageRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get moduleStageRejected;

  /// No description provided for @moduleOrderDraftExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Taslak üzerinde değişiklik yapabilirsiniz.'**
  String get moduleOrderDraftExplanation;

  /// No description provided for @moduleOrderPendingExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Onaya gönderildi. Onaylanana veya reddedilene kadar düzenleme kapalıdır.'**
  String get moduleOrderPendingExplanation;

  /// No description provided for @moduleOrderApprovedExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş taslağı onaylandı. Bu kayıt KartVizyon içindeki onaylı satış kaydıdır.'**
  String get moduleOrderApprovedExplanation;

  /// No description provided for @moduleOrderRejectedExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş taslağı reddedildi. Gerekli düzeltmeleri yapıp yeniden gönderebilirsiniz.'**
  String get moduleOrderRejectedExplanation;

  /// No description provided for @moduleCouldNotLoad.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get moduleCouldNotLoad;

  /// No description provided for @moduleDecisionReason.
  ///
  /// In tr, this message translates to:
  /// **'Neden'**
  String get moduleDecisionReason;

  /// No description provided for @companyInfo.
  ///
  /// In tr, this message translates to:
  /// **'Firma bilgileri'**
  String get companyInfo;

  /// No description provided for @editWorkspaceCompanyName.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma alanınızın firma adını düzenleyin'**
  String get editWorkspaceCompanyName;

  /// No description provided for @premiumSubscription.
  ///
  /// In tr, this message translates to:
  /// **'Premium ve abonelik'**
  String get premiumSubscription;

  /// No description provided for @viewPlanManagePurchase.
  ///
  /// In tr, this message translates to:
  /// **'Planınızı görüntüleyin veya mağaza satın alımını yönetin'**
  String get viewPlanManagePurchase;

  /// No description provided for @locationPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Konum gizliliği'**
  String get locationPrivacy;

  /// No description provided for @locationPrivacyBody.
  ///
  /// In tr, this message translates to:
  /// **'Sürekli GPS takibi yapılmaz. Konum yalnızca siz istediğinizde ya da saha modunu başlattığınızda alınır; saha modu çalışırken bunu gizlemez ve akşam kendiliğinden kapanır.'**
  String get locationPrivacyBody;

  /// No description provided for @audioRetention.
  ///
  /// In tr, this message translates to:
  /// **'Ses saklama'**
  String get audioRetention;

  /// No description provided for @audioRetentionBody.
  ///
  /// In tr, this message translates to:
  /// **'Sesli not yalnızca metne çevrilmek için gönderilir. Ham kayıt yöneticilere açılmaz ve 30 gün sonra sunucudan silinir.'**
  String get audioRetentionBody;

  /// No description provided for @privacyRights.
  ///
  /// In tr, this message translates to:
  /// **'KVKK ve veri hakları'**
  String get privacyRights;

  /// No description provided for @privacyDataCenter.
  ///
  /// In tr, this message translates to:
  /// **'Aydınlatma, dışa aktarma ve silme merkezi'**
  String get privacyDataCenter;

  /// No description provided for @privacyScreenTitle.
  ///
  /// In tr, this message translates to:
  /// **'KVKK ve veri hakları'**
  String get privacyScreenTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In tr, this message translates to:
  /// **'Rıza tercihlerinizi yönetebilir, verilerinizin bir kopyasını veya silinmesini talep edebilirsiniz.'**
  String get privacyIntro;

  /// No description provided for @privacyConsentAnalytics.
  ///
  /// In tr, this message translates to:
  /// **'Ürün analitiği'**
  String get privacyConsentAnalytics;

  /// No description provided for @privacyConsentAiProcessing.
  ///
  /// In tr, this message translates to:
  /// **'Notların yapay zekâ ile işlenmesi'**
  String get privacyConsentAiProcessing;

  /// No description provided for @privacyConsentEmailNotifications.
  ///
  /// In tr, this message translates to:
  /// **'E-posta bildirimleri'**
  String get privacyConsentEmailNotifications;

  /// No description provided for @privacyDeleteConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı kalıcı olarak sil'**
  String get privacyDeleteConfirmTitle;

  /// No description provided for @privacyDeleteConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu talep, hesabınızı, müşteri ve ziyaret kayıtlarınızı, görevlerinizi ve diğer kişisel verilerinizi işlem tamamlandığında kalıcı olarak siler. Bu işlem geri alınamaz.'**
  String get privacyDeleteConfirmBody;

  /// No description provided for @privacyDeleteAccountPermanently.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı kalıcı olarak sil'**
  String get privacyDeleteAccountPermanently;

  /// No description provided for @privacyExportRequestOpen.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarma talebi açık'**
  String get privacyExportRequestOpen;

  /// No description provided for @privacyDeletionRequestOpen.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silme talebi açık'**
  String get privacyDeletionRequestOpen;

  /// No description provided for @privacyExportMyData.
  ///
  /// In tr, this message translates to:
  /// **'Verilerimin kopyasını iste'**
  String get privacyExportMyData;

  /// No description provided for @privacyMyRequests.
  ///
  /// In tr, this message translates to:
  /// **'Taleplerim'**
  String get privacyMyRequests;

  /// No description provided for @privacyExportRequestKind.
  ///
  /// In tr, this message translates to:
  /// **'Veri dışa aktarma'**
  String get privacyExportRequestKind;

  /// No description provided for @privacyDeletionRequestKind.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silme'**
  String get privacyDeletionRequestKind;

  /// No description provided for @privacyDownload.
  ///
  /// In tr, this message translates to:
  /// **'İndir'**
  String get privacyDownload;

  /// No description provided for @privacyStatusReceived.
  ///
  /// In tr, this message translates to:
  /// **'Alındı ve sıraya girdi'**
  String get privacyStatusReceived;

  /// No description provided for @privacyStatusProcessing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor'**
  String get privacyStatusProcessing;

  /// No description provided for @privacyStatusReady.
  ///
  /// In tr, this message translates to:
  /// **'Hazır'**
  String get privacyStatusReady;

  /// No description provided for @privacyStatusCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get privacyStatusCompleted;

  /// No description provided for @privacyStatusFailed.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanamadı'**
  String get privacyStatusFailed;

  /// No description provided for @privacyStatusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get privacyStatusRejected;

  /// No description provided for @privacyStatusUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Durum bilgisi yok'**
  String get privacyStatusUnknown;

  /// No description provided for @privacyOpenDeletionRequest.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silme talebiniz zaten açık. Durumunu Taleplerim bölümünden takip edebilirsiniz.'**
  String get privacyOpenDeletionRequest;

  /// No description provided for @privacyOpenExportRequest.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarma talebiniz zaten açık. Hazır olduğunda Taleplerim bölümünden indirebilirsiniz.'**
  String get privacyOpenExportRequest;

  /// No description provided for @privacySignInRequired.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik tercihlerini ve veri taleplerini yönetmek için giriş yapın.'**
  String get privacySignInRequired;

  /// No description provided for @privacyLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik bilgileri yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get privacyLoadFailed;

  /// No description provided for @privacyConsentUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bu tercih güncellenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get privacyConsentUpdateFailed;

  /// No description provided for @privacyRequestFailed.
  ///
  /// In tr, this message translates to:
  /// **'Talep gönderilemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get privacyRequestFailed;

  /// No description provided for @privacyDemoRequestUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Demo modunda gizlilik talebi oluşturulamaz.'**
  String get privacyDemoRequestUnavailable;

  /// No description provided for @privacyDeletionRequestSubmitted.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silme talebiniz alındı. Kalıcı silme işlemi sıraya alınmıştır; bu mesaj silme işleminin tamamlandığı anlamına gelmez.'**
  String get privacyDeletionRequestSubmitted;

  /// No description provided for @privacyRequestReceived.
  ///
  /// In tr, this message translates to:
  /// **'Talebiniz alındı.'**
  String get privacyRequestReceived;

  /// No description provided for @privacyExportDownloadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Veri dışa aktarma açılamadı. Lütfen biraz sonra yeniden deneyin.'**
  String get privacyExportDownloadFailed;

  /// No description provided for @privacyRequestRateLimited.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla talep gönderildi. Biraz sonra tekrar deneyin.'**
  String get privacyRequestRateLimited;

  /// No description provided for @deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı sil'**
  String get deleteAccount;

  /// No description provided for @permanentlyDeletePersonalData.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı ve kişisel verilerinizi kalıcı olarak silin'**
  String get permanentlyDeletePersonalData;

  /// No description provided for @signOutAllDevices.
  ///
  /// In tr, this message translates to:
  /// **'Tüm cihazlardan çıkış'**
  String get signOutAllDevices;

  /// No description provided for @appVersion.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama sürümü'**
  String get appVersion;

  /// No description provided for @versionLoading.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm bilgisi yükleniyor…'**
  String get versionLoading;

  /// No description provided for @versionBuild.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {version} · Derleme {buildNumber}'**
  String versionBuild(String version, String buildNumber);

  /// No description provided for @tryAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get tryAgain;

  /// No description provided for @greeting.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba {name}'**
  String greeting(String name);

  /// No description provided for @greetingAnonymous.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba'**
  String get greetingAnonymous;

  /// No description provided for @todaySummaryForCompany.
  ///
  /// In tr, this message translates to:
  /// **'{company} için bugünün saha özeti'**
  String todaySummaryForCompany(String company);

  /// No description provided for @completeCompanyDetails.
  ///
  /// In tr, this message translates to:
  /// **'Firma bilgilerinizi tamamlayın'**
  String get completeCompanyDetails;

  /// No description provided for @companyContextForSummary.
  ///
  /// In tr, this message translates to:
  /// **'Saha özetleri şirketinizin bağlamını doğru kullansın.'**
  String get companyContextForSummary;

  /// No description provided for @plannedVisit.
  ///
  /// In tr, this message translates to:
  /// **'Planlanan ziyaret'**
  String get plannedVisit;

  /// No description provided for @openVisit.
  ///
  /// In tr, this message translates to:
  /// **'Açık ziyaret'**
  String get openVisit;

  /// No description provided for @pendingReview.
  ///
  /// In tr, this message translates to:
  /// **'İnceleme bekleyen'**
  String get pendingReview;

  /// No description provided for @openFollowUp.
  ///
  /// In tr, this message translates to:
  /// **'Açık takip'**
  String get openFollowUp;

  /// No description provided for @quickActions.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı işlemler'**
  String get quickActions;

  /// No description provided for @visitNote.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret notu'**
  String get visitNote;

  /// No description provided for @scanBusinessCard.
  ///
  /// In tr, this message translates to:
  /// **'Kartvizit tara'**
  String get scanBusinessCard;

  /// No description provided for @sync.
  ///
  /// In tr, this message translates to:
  /// **'Eşitleme'**
  String get sync;

  /// No description provided for @nextVisit.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki ziyaret'**
  String get nextVisit;

  /// No description provided for @viewBriefing.
  ///
  /// In tr, this message translates to:
  /// **'Brifingi görüntüle'**
  String get viewBriefing;

  /// No description provided for @firstCustomer.
  ///
  /// In tr, this message translates to:
  /// **'İlk müşterinizi ekleyin'**
  String get firstCustomer;

  /// No description provided for @addCustomerNextSteps.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri kaydından sonra ziyaret ve takip oluşturabilirsiniz.'**
  String get addCustomerNextSteps;

  /// No description provided for @loginDescription.
  ///
  /// In tr, this message translates to:
  /// **'Saha müşteri hafızanıza güvenli erişim'**
  String get loginDescription;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @wait.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyin…'**
  String get wait;

  /// No description provided for @emailSent.
  ///
  /// In tr, this message translates to:
  /// **'E-posta gönderildi'**
  String get emailSent;

  /// No description provided for @createAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluştur'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get signIn;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama e-postasını yeniden gönder'**
  String get resendVerificationEmail;

  /// No description provided for @existingAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabım var'**
  String get existingAccount;

  /// No description provided for @createNewAccount.
  ///
  /// In tr, this message translates to:
  /// **'Yeni hesap oluştur'**
  String get createNewAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get forgotPassword;

  /// No description provided for @continueWithGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile devam et'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile devam et'**
  String get continueWithApple;

  /// No description provided for @demoConfiguration.
  ///
  /// In tr, this message translates to:
  /// **'Demo yapılandırması etkin. Giriş yap düğmesi yerel önizlemeyi açar.'**
  String get demoConfiguration;

  /// No description provided for @loginIncomplete.
  ///
  /// In tr, this message translates to:
  /// **'Giriş tamamlanmadı. Dilerseniz tekrar deneyin.'**
  String get loginIncomplete;

  /// No description provided for @authFailed.
  ///
  /// In tr, this message translates to:
  /// **'Giriş tamamlanamadı. Lütfen tekrar deneyin.'**
  String get authFailed;

  /// No description provided for @authLinkExpired.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantının süresi dolmuş veya daha önce kullanılmış. Aşağıdan yeni bir bağlantı isteyin.'**
  String get authLinkExpired;

  /// No description provided for @authLinkWrongDevice.
  ///
  /// In tr, this message translates to:
  /// **'Bu bağlantı başka bir cihazda veya daha önce kullanılmış. Girişi bu cihazdan yeniden başlatın.'**
  String get authLinkWrongDevice;

  /// No description provided for @emailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi girin.'**
  String get emailInvalid;

  /// No description provided for @passwordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifreniz en az 6 karakter olmalıdır.'**
  String get passwordTooShort;

  /// No description provided for @accountCreating.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız oluşturuluyor…'**
  String get accountCreating;

  /// No description provided for @signingIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılıyor…'**
  String get signingIn;

  /// No description provided for @accountMayExist.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta zaten kayıtlı olabilir. “Hesabım var” ile giriş yapın veya şifrenizi yenileyin.'**
  String get accountMayExist;

  /// No description provided for @confirmAccountEmail.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız oluşturuldu. E-postanıza gönderdiğimiz bağlantıya dokunun; doğrulama tamamlanınca uygulama otomatik açılır.'**
  String get confirmAccountEmail;

  /// No description provided for @networkOperationFailed.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlanamadı. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get networkOperationFailed;

  /// No description provided for @enterEmailFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce e-posta adresinizi girin.'**
  String get enterEmailFirst;

  /// No description provided for @passwordResetSent.
  ///
  /// In tr, this message translates to:
  /// **'Şifre yenileme e-postası gönderildi.'**
  String get passwordResetSent;

  /// No description provided for @loginScreenCouldNotOpen.
  ///
  /// In tr, this message translates to:
  /// **'Giriş ekranı açılamadı. Lütfen tekrar deneyin.'**
  String get loginScreenCouldNotOpen;

  /// No description provided for @verificationResent.
  ///
  /// In tr, this message translates to:
  /// **'Yeni doğrulama e-postası gönderildi. En son gelen e-postadaki bağlantıyı kullanın.'**
  String get verificationResent;

  /// No description provided for @googleAuthOpening.
  ///
  /// In tr, this message translates to:
  /// **'Google güvenli giriş ekranı açılıyor…'**
  String get googleAuthOpening;

  /// No description provided for @appleAuthOpening.
  ///
  /// In tr, this message translates to:
  /// **'Apple güvenli giriş ekranı açılıyor…'**
  String get appleAuthOpening;

  /// No description provided for @cameraTakePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Kamera ile çek'**
  String get cameraTakePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden seç'**
  String get chooseFromGallery;

  /// No description provided for @cameraPermissionOptional.
  ///
  /// In tr, this message translates to:
  /// **'Kamera izni vermek istemiyorsanız'**
  String get cameraPermissionOptional;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @imagePickFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görsel seçilemedi. Kamera veya fotoğraf izni verilmemiş olabilir.'**
  String get imagePickFailed;

  /// No description provided for @scanningBusinessCard.
  ///
  /// In tr, this message translates to:
  /// **'Kartvizit okunuyor…'**
  String get scanningBusinessCard;

  /// No description provided for @cardScanFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kartvizit okunamadı. Tekrar deneyin.'**
  String get cardScanFailed;

  /// No description provided for @customerSaved.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri başarıyla kaydedildi.'**
  String get customerSaved;

  /// No description provided for @customerDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri kartı'**
  String get customerDetailTitle;

  /// No description provided for @customerLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get customerLoadFailed;

  /// No description provided for @customerContactsCount.
  ///
  /// In tr, this message translates to:
  /// **'İlgili kişiler ({count})'**
  String customerContactsCount(int count);

  /// No description provided for @addContact.
  ///
  /// In tr, this message translates to:
  /// **'Kişi ekle'**
  String get addContact;

  /// No description provided for @archiveCustomerAction.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriyi arşivle'**
  String get archiveCustomerAction;

  /// No description provided for @editCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriyi düzenle'**
  String get editCustomer;

  /// No description provided for @openVisitBriefing.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret brifingini aç'**
  String get openVisitBriefing;

  /// No description provided for @locationPinnedAtSite.
  ///
  /// In tr, this message translates to:
  /// **'Konum sahada sabitlendi'**
  String get locationPinnedAtSite;

  /// No description provided for @locationEstimatedFromAddress.
  ///
  /// In tr, this message translates to:
  /// **'Konum adresten tahmin edildi'**
  String get locationEstimatedFromAddress;

  /// No description provided for @customerLocationMissing.
  ///
  /// In tr, this message translates to:
  /// **'Konum kayıtlı değil — yakınlık hatırlatması çalışmaz'**
  String get customerLocationMissing;

  /// No description provided for @updateCustomerLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumu buradan güncelle'**
  String get updateCustomerLocation;

  /// No description provided for @pinCustomerLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumu buraya sabitle'**
  String get pinCustomerLocation;

  /// No description provided for @pinCustomerLocationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konumu buraya sabitle'**
  String get pinCustomerLocationTitle;

  /// No description provided for @pinCustomerLocationBody.
  ///
  /// In tr, this message translates to:
  /// **'Şu anki konumunuz {company} kaydına müşterinin konumu olarak yazılacak. Böylece saha modunda yakına geldiğinizde hatırlatma alabilirsiniz.'**
  String pinCustomerLocationBody(String company);

  /// No description provided for @pinCustomerLocationPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca müşterinin konumu saklanır; sizin hareketleriniz kaydedilmez.'**
  String get pinCustomerLocationPrivacy;

  /// No description provided for @locationPermissionDeniedForCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verilmedi. Müşteri konumu kaydedilmedi.'**
  String get locationPermissionDeniedForCustomer;

  /// No description provided for @customerLocationPinned.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri konumu sabitlendi.'**
  String get customerLocationPinned;

  /// No description provided for @customerLocationPinFailed.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri konumu kaydedilemedi. Tekrar deneyin.'**
  String get customerLocationPinFailed;

  /// No description provided for @customerUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri bilgileri güncellendi.'**
  String get customerUpdated;

  /// No description provided for @customerUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri güncellenemedi. Tekrar deneyin.'**
  String get customerUpdateFailed;

  /// No description provided for @contactAdded.
  ///
  /// In tr, this message translates to:
  /// **'İlgili kişi eklendi.'**
  String get contactAdded;

  /// No description provided for @contactUpdated.
  ///
  /// In tr, this message translates to:
  /// **'İlgili kişi güncellendi.'**
  String get contactUpdated;

  /// No description provided for @contactSaveGenericFailed.
  ///
  /// In tr, this message translates to:
  /// **'İlgili kişi kaydedilemedi. Tekrar deneyin.'**
  String get contactSaveGenericFailed;

  /// No description provided for @customerArchiveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri arşivlenemedi. Tekrar deneyin.'**
  String get customerArchiveFailed;

  /// No description provided for @archiveCustomerTitle.
  ///
  /// In tr, this message translates to:
  /// **'{company} arşivlensin mi?'**
  String archiveCustomerTitle(String company);

  /// No description provided for @archiveCustomerIntro.
  ///
  /// In tr, this message translates to:
  /// **'Bu müşteriye bağlı kayıtlar:'**
  String get archiveCustomerIntro;

  /// No description provided for @archiveContactsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} ilgili kişi'**
  String archiveContactsCount(int count);

  /// No description provided for @archiveVisitsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} ziyaret'**
  String archiveVisitsCount(int count);

  /// No description provided for @archiveOpenTasksCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} açık görev'**
  String archiveOpenTasksCount(int count);

  /// No description provided for @archiveOpportunitiesCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} fırsat'**
  String archiveOpportunitiesCount(int count);

  /// No description provided for @archiveOrdersCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} sipariş taslağı'**
  String archiveOrdersCount(int count);

  /// No description provided for @archiveDocumentsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} belge'**
  String archiveDocumentsCount(int count);

  /// No description provided for @archivePreservesData.
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıtlar silinmez. Müşteri etkin müşteri listenizden kaldırılır.'**
  String get archivePreservesData;

  /// No description provided for @archive.
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get archive;

  /// No description provided for @newContact.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ilgili kişi'**
  String get newContact;

  /// No description provided for @editContact.
  ///
  /// In tr, this message translates to:
  /// **'İlgili kişiyi düzenle'**
  String get editContact;

  /// No description provided for @firstNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ad gerekli.'**
  String get firstNameRequired;

  /// No description provided for @contactSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Firma kaydedildi ancak ilgili kişi kaydedilemedi. Firma profilinden yeniden deneyebilirsiniz.'**
  String get contactSaveFailed;

  /// No description provided for @customers.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriler'**
  String get customers;

  /// No description provided for @manuallyAddCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Manuel müşteri ekle'**
  String get manuallyAddCustomer;

  /// No description provided for @customerSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Firma, adres veya e-posta ara'**
  String get customerSearchHint;

  /// No description provided for @clearSearch.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı temizle'**
  String get clearSearch;

  /// No description provided for @noCustomers.
  ///
  /// In tr, this message translates to:
  /// **'Henüz müşteri yok'**
  String get noCustomers;

  /// No description provided for @noMatchingCustomers.
  ///
  /// In tr, this message translates to:
  /// **'Aramaya uygun müşteri yok'**
  String get noMatchingCustomers;

  /// No description provided for @noCustomersDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileri elle girebilir veya kartvizit tarayabilirsiniz.'**
  String get noCustomersDescription;

  /// No description provided for @noSearchResults.
  ///
  /// In tr, this message translates to:
  /// **'{query} için sonuç bulunamadı. Aramayı temizleyip listeye dönebilirsiniz.'**
  String noSearchResults(String query);

  /// No description provided for @loadMoreCustomers.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla müşteri yükle'**
  String get loadMoreCustomers;

  /// No description provided for @addressNotProvided.
  ///
  /// In tr, this message translates to:
  /// **'Adres belirtilmedi'**
  String get addressNotProvided;

  /// No description provided for @verifyBusinessCardFields.
  ///
  /// In tr, this message translates to:
  /// **'Kartvizit alanlarını doğrulayın'**
  String get verifyBusinessCardFields;

  /// No description provided for @companyName.
  ///
  /// In tr, this message translates to:
  /// **'Firma adı'**
  String get companyName;

  /// No description provided for @companyNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Firma adı *'**
  String get companyNameRequired;

  /// No description provided for @companyNameTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Firma adı en az 2 karakter olmalı.'**
  String get companyNameTooShort;

  /// No description provided for @shortNameField.
  ///
  /// In tr, this message translates to:
  /// **'Kısa ad / saha adı'**
  String get shortNameField;

  /// No description provided for @shortNameHelp.
  ///
  /// In tr, this message translates to:
  /// **'Uzun ticari unvan yerine listelerde görünür.'**
  String get shortNameHelp;

  /// No description provided for @address.
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get address;

  /// No description provided for @contactOptional.
  ///
  /// In tr, this message translates to:
  /// **'İlgili kişi (isteğe bağlı)'**
  String get contactOptional;

  /// No description provided for @firstName.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get lastName;

  /// No description provided for @jobTitle.
  ///
  /// In tr, this message translates to:
  /// **'Unvan'**
  String get jobTitle;

  /// No description provided for @phone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @website.
  ///
  /// In tr, this message translates to:
  /// **'Web sitesi'**
  String get website;

  /// No description provided for @aiDraftNotSaved.
  ///
  /// In tr, this message translates to:
  /// **'AI çıktısı siz kaydetmeden veritabanına eklenmez.'**
  String get aiDraftNotSaved;

  /// No description provided for @saveCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriyi kaydet'**
  String get saveCustomer;

  /// No description provided for @startVisit.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ziyaret'**
  String get startVisit;

  /// No description provided for @selectCustomerRequired.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seç *'**
  String get selectCustomerRequired;

  /// No description provided for @visitPurpose.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret amacı'**
  String get visitPurpose;

  /// No description provided for @startVisitAction.
  ///
  /// In tr, this message translates to:
  /// **'Ziyareti başlat'**
  String get startVisitAction;

  /// No description provided for @visits.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretler'**
  String get visits;

  /// No description provided for @opening.
  ///
  /// In tr, this message translates to:
  /// **'Açılıyor…'**
  String get opening;

  /// No description provided for @visitQueuedOffline.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret çevrimdışı kuyruğa alındı; bağlantı gelince gönderilecek.'**
  String get visitQueuedOffline;

  /// No description provided for @noVisits.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ziyaret yok'**
  String get noVisits;

  /// No description provided for @startFirstVisitPrompt.
  ///
  /// In tr, this message translates to:
  /// **'İlk ziyaretinizi başlatmak için önce bir müşteri seçin.'**
  String get startFirstVisitPrompt;

  /// No description provided for @visit.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret'**
  String get visit;

  /// No description provided for @approved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get approved;

  /// No description provided for @review.
  ///
  /// In tr, this message translates to:
  /// **'İncele'**
  String get review;

  /// No description provided for @addNote.
  ///
  /// In tr, this message translates to:
  /// **'Not ekle'**
  String get addNote;

  /// No description provided for @briefingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret brifingi'**
  String get briefingTitle;

  /// No description provided for @noPreviousVisit.
  ///
  /// In tr, this message translates to:
  /// **'Bu müşteriyi henüz ziyaret etmediniz.'**
  String get noPreviousVisit;

  /// No description provided for @lastApprovedVisit.
  ///
  /// In tr, this message translates to:
  /// **'Son onaylanan ziyaret: {since}'**
  String lastApprovedVisit(String since);

  /// No description provided for @customerMemoryCard.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri hafıza kartı'**
  String get customerMemoryCard;

  /// No description provided for @updateRequired.
  ///
  /// In tr, this message translates to:
  /// **'Güncellenmeli'**
  String get updateRequired;

  /// No description provided for @noApprovedSummary.
  ///
  /// In tr, this message translates to:
  /// **'Henüz onaylanmış ziyaret özeti bulunmuyor.'**
  String get noApprovedSummary;

  /// No description provided for @promisesCount.
  ///
  /// In tr, this message translates to:
  /// **'Verilen sözler ({count})'**
  String promisesCount(int count);

  /// No description provided for @noOpenPromises.
  ///
  /// In tr, this message translates to:
  /// **'Bu müşteriye verilmiş açık söz kaydı yok.'**
  String get noOpenPromises;

  /// No description provided for @openFollowUpsCount.
  ///
  /// In tr, this message translates to:
  /// **'Açık takipler ({count})'**
  String openFollowUpsCount(int count);

  /// No description provided for @noOpenFollowUps.
  ///
  /// In tr, this message translates to:
  /// **'Bu müşteri için açık takip bulunmuyor.'**
  String get noOpenFollowUps;

  /// No description provided for @startVisitAndTakeNote.
  ///
  /// In tr, this message translates to:
  /// **'Ziyareti başlat ve not al'**
  String get startVisitAndTakeNote;

  /// No description provided for @startingVisit.
  ///
  /// In tr, this message translates to:
  /// **'Başlatılıyor…'**
  String get startingVisit;

  /// No description provided for @openNavigation.
  ///
  /// In tr, this message translates to:
  /// **'Navigasyonu aç'**
  String get openNavigation;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'bugün'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In tr, this message translates to:
  /// **'dün'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce'**
  String daysAgo(int days);

  /// No description provided for @customerFallback.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri'**
  String get customerFallback;

  /// No description provided for @promiseFallback.
  ///
  /// In tr, this message translates to:
  /// **'Verilen söz'**
  String get promiseFallback;

  /// No description provided for @taskFallback.
  ///
  /// In tr, this message translates to:
  /// **'Görev'**
  String get taskFallback;

  /// No description provided for @overdue.
  ///
  /// In tr, this message translates to:
  /// **'gecikti'**
  String get overdue;

  /// No description provided for @dueDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Son tarih {date}'**
  String dueDateLabel(Object date);

  /// No description provided for @aiSummaryNotFound.
  ///
  /// In tr, this message translates to:
  /// **'İncelenecek AI özeti bulunamadı.'**
  String get aiSummaryNotFound;

  /// No description provided for @summaryMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Özet en az 10 karakter olmalıdır.'**
  String get summaryMinLength;

  /// No description provided for @visitApprovedMemory.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret onaylandı ve hafızaya eklendi.'**
  String get visitApprovedMemory;

  /// No description provided for @visitApprovedTasks.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret onaylandı. Seçtiğiniz {count} takip Görevler ekranına eklendi.'**
  String visitApprovedTasks(int count);

  /// No description provided for @rejectSummaryDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'AI özeti reddedilsin mi?'**
  String get rejectSummaryDialogTitle;

  /// No description provided for @rejectSummaryDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret kurumsal hafızaya eklenmez ve takip görevi oluşmaz. Notunuz ve ses kaydınız silinmez.'**
  String get rejectSummaryDialogBody;

  /// No description provided for @reject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get reject;

  /// No description provided for @summaryRejected.
  ///
  /// In tr, this message translates to:
  /// **'Özet reddedildi; hafızaya eklenmedi.'**
  String get summaryRejected;

  /// No description provided for @summaryRejectFailed.
  ///
  /// In tr, this message translates to:
  /// **'Reddedilemedi. Tekrar deneyin.'**
  String get summaryRejectFailed;

  /// No description provided for @reviewAiSummary.
  ///
  /// In tr, this message translates to:
  /// **'AI özetini incele'**
  String get reviewAiSummary;

  /// No description provided for @customerVisit.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri ziyareti'**
  String get customerVisit;

  /// No description provided for @aiOutputApprovalNotice.
  ///
  /// In tr, this message translates to:
  /// **'AI çıktısı siz onaylamadan kurumsal hafızaya eklenmez.'**
  String get aiOutputApprovalNotice;

  /// No description provided for @sensitiveDataWarning.
  ///
  /// In tr, this message translates to:
  /// **'Hassas kişisel veri olasılığı var. Onaylamadan önce özeti düzenleyin.'**
  String get sensitiveDataWarning;

  /// No description provided for @visitSummary.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret özeti'**
  String get visitSummary;

  /// No description provided for @outcome.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç'**
  String get outcome;

  /// No description provided for @positive.
  ///
  /// In tr, this message translates to:
  /// **'Olumlu'**
  String get positive;

  /// No description provided for @neutral.
  ///
  /// In tr, this message translates to:
  /// **'Nötr'**
  String get neutral;

  /// No description provided for @negative.
  ///
  /// In tr, this message translates to:
  /// **'Olumsuz'**
  String get negative;

  /// No description provided for @unknown.
  ///
  /// In tr, this message translates to:
  /// **'Belirsiz'**
  String get unknown;

  /// No description provided for @suggestedFollowUps.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen takipler'**
  String get suggestedFollowUps;

  /// No description provided for @noFollowUpsFound.
  ///
  /// In tr, this message translates to:
  /// **'Takip önerisi bulunamadı.'**
  String get noFollowUpsFound;

  /// No description provided for @followUpFallback.
  ///
  /// In tr, this message translates to:
  /// **'Takip'**
  String get followUpFallback;

  /// No description provided for @transcript.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt metni'**
  String get transcript;

  /// No description provided for @compareSummarySource.
  ///
  /// In tr, this message translates to:
  /// **'Özeti kaynağıyla karşılaştırın'**
  String get compareSummarySource;

  /// No description provided for @approving.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanıyor…'**
  String get approving;

  /// No description provided for @approveAndAddMemory.
  ///
  /// In tr, this message translates to:
  /// **'Onayla ve hafızaya ekle'**
  String get approveAndAddMemory;

  /// No description provided for @rejectAiSummary.
  ///
  /// In tr, this message translates to:
  /// **'Özeti reddet'**
  String get rejectAiSummary;

  /// No description provided for @dueDatePrefix.
  ///
  /// In tr, this message translates to:
  /// **'Son tarih {date}'**
  String dueDatePrefix(String date);

  /// No description provided for @undated.
  ///
  /// In tr, this message translates to:
  /// **'Tarihsiz'**
  String get undated;

  /// No description provided for @nearbyCustomersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki müşteriler'**
  String get nearbyCustomersTitle;

  /// No description provided for @mapLocationPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Sürekli GPS kullanılmaz. Konum yalnızca siz istediğinizde yakın ve gecikmiş müşterileri hesaplamak için alınır.'**
  String get mapLocationPrivacy;

  /// No description provided for @findingNearby.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplanıyor…'**
  String get findingNearby;

  /// No description provided for @findNearbyCustomers.
  ///
  /// In tr, this message translates to:
  /// **'Yakınımdakileri bul'**
  String get findNearbyCustomers;

  /// No description provided for @locationServiceOff.
  ///
  /// In tr, this message translates to:
  /// **'Konum servisi kapalı. Cihaz ayarlarından açın.'**
  String get locationServiceOff;

  /// No description provided for @nearbyLocationPermission.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki müşterileri göstermek için konum izni gerekiyor. Müşterilerinizi konum kullanmadan da arayabilirsiniz.'**
  String get nearbyLocationPermission;

  /// No description provided for @locationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. Açık alanda tekrar deneyin ya da müşteri kartından \"konumu buraya sabitle\" seçeneğini kullanın.'**
  String get locationUnavailable;

  /// No description provided for @locationSettingsRetry.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. Konum ayarlarınızı kontrol edip tekrar deneyin.'**
  String get locationSettingsRetry;

  /// No description provided for @serverNotConfigured.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu bağlantısı yapılandırılmadığı için müşteri aranamadı.'**
  String get serverNotConfigured;

  /// No description provided for @locationNotStored.
  ///
  /// In tr, this message translates to:
  /// **'Konum yalnızca aday hesaplamak için kullanıldı; sunucuda saklanmadı.'**
  String get locationNotStored;

  /// No description provided for @nearbyFetchFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki müşteriler getirilemedi. Tekrar deneyin.'**
  String get nearbyFetchFailed;

  /// No description provided for @noCustomersInArea.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölgede kayıtlı müşteri bulunamadı.'**
  String get noCustomersInArea;

  /// No description provided for @companyFallback.
  ///
  /// In tr, this message translates to:
  /// **'Firma'**
  String get companyFallback;

  /// No description provided for @distanceUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe bilinmiyor'**
  String get distanceUnknown;

  /// No description provided for @visitNever.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ziyaret edilmedi'**
  String get visitNever;

  /// No description provided for @lastVisitDays.
  ///
  /// In tr, this message translates to:
  /// **'Son ziyaret: {days} gün önce'**
  String lastVisitDays(int days);

  /// No description provided for @overdueTaskCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} geciken görev'**
  String overdueTaskCount(int count);

  /// No description provided for @noOverdueTasks.
  ///
  /// In tr, this message translates to:
  /// **'Geciken görev yok'**
  String get noOverdueTasks;

  /// No description provided for @briefing.
  ///
  /// In tr, this message translates to:
  /// **'Brifing'**
  String get briefing;

  /// No description provided for @navigation.
  ///
  /// In tr, this message translates to:
  /// **'Navigasyon'**
  String get navigation;

  /// No description provided for @debriefTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret sonrası not'**
  String get debriefTitle;

  /// No description provided for @debriefPrivacyNotice.
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt müşteri görüşmesi değildir. Yalnızca ziyaret sonrası kişisel değerlendirmeniz kaydedilir.'**
  String get debriefPrivacyNotice;

  /// No description provided for @noteAndAudioLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Not ve ses dili'**
  String get noteAndAudioLanguage;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get english;

  /// No description provided for @recordingDuration.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt sürüyor · {duration}'**
  String recordingDuration(String duration);

  /// No description provided for @voiceNoteReady.
  ///
  /// In tr, this message translates to:
  /// **'Sesli not hazır · {duration}'**
  String voiceNoteReady(String duration);

  /// No description provided for @debriefDurationHint.
  ///
  /// In tr, this message translates to:
  /// **'60–90 saniyelik debrief'**
  String get debriefDurationHint;

  /// No description provided for @longRecordingWarning.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt uzuyor. Beş dakikayı aşan notlar gönderilemeyebilir.'**
  String get longRecordingWarning;

  /// No description provided for @stopRecording.
  ///
  /// In tr, this message translates to:
  /// **'Kaydı bitir'**
  String get stopRecording;

  /// No description provided for @recordVoiceNote.
  ///
  /// In tr, this message translates to:
  /// **'Sesli not kaydet'**
  String get recordVoiceNote;

  /// No description provided for @manualNoteTranscript.
  ///
  /// In tr, this message translates to:
  /// **'Manuel not veya transkript'**
  String get manualNoteTranscript;

  /// No description provided for @notePrompt.
  ///
  /// In tr, this message translates to:
  /// **'İhtiyaç, verilen söz ve sonraki adım…'**
  String get notePrompt;

  /// No description provided for @sending.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor…'**
  String get sending;

  /// No description provided for @queueAndSend.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli kuyruğa ekle ve gönder'**
  String get queueAndSend;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon izni verilmedi. Metinle devam edebilirsiniz.'**
  String get microphonePermissionDenied;

  /// No description provided for @accessExpiredDraftSaved.
  ///
  /// In tr, this message translates to:
  /// **'Erişim süreniz doldu. Ses taslağınız korunur.'**
  String get accessExpiredDraftSaved;

  /// No description provided for @debriefQueuedOffline.
  ///
  /// In tr, this message translates to:
  /// **'Not cihazda güvenle kuyruklandı. Bağlantı gelince gönderilecek; durumunu Eşitleme merkezinden izleyebilirsiniz.'**
  String get debriefQueuedOffline;

  /// No description provided for @backToVisits.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretlere dön'**
  String get backToVisits;

  /// No description provided for @deleteVoiceNote.
  ///
  /// In tr, this message translates to:
  /// **'Sesli notu sil'**
  String get deleteVoiceNote;

  /// No description provided for @reopenTaskQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Görev yeniden açılsın mı?'**
  String get reopenTaskQuestion;

  /// No description provided for @taskCompletedWarning.
  ///
  /// In tr, this message translates to:
  /// **'“{title}” tamamlandı olarak işaretli. Geri alırsanız tamamlanma zamanı silinir.'**
  String taskCompletedWarning(String title);

  /// No description provided for @reopen.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden aç'**
  String get reopen;

  /// No description provided for @newTask.
  ///
  /// In tr, this message translates to:
  /// **'Yeni görev'**
  String get newTask;

  /// No description provided for @taskRequired.
  ///
  /// In tr, this message translates to:
  /// **'Görev *'**
  String get taskRequired;

  /// No description provided for @selectCustomerOptional.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seç (isteğe bağlı)'**
  String get selectCustomerOptional;

  /// No description provided for @removeCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriyi kaldır'**
  String get removeCustomer;

  /// No description provided for @dueDateOptional.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş tarihi (isteğe bağlı)'**
  String get dueDateOptional;

  /// No description provided for @removeDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarihi kaldır'**
  String get removeDate;

  /// No description provided for @taskSaved.
  ///
  /// In tr, this message translates to:
  /// **'Görev kaydedildi.'**
  String get taskSaved;

  /// No description provided for @taskSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görev kaydedilemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get taskSaveFailed;

  /// No description provided for @taskUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görev güncellenemedi. Tekrar deneyin.'**
  String get taskUpdateFailed;

  /// No description provided for @taskLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görevler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get taskLoadFailed;

  /// No description provided for @offlineCenterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eşitleme merkezi'**
  String get offlineCenterTitle;

  /// No description provided for @offlineQueuedCount.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen kayıtlar ({count})'**
  String offlineQueuedCount(int count);

  /// No description provided for @offlineStorageNotice.
  ///
  /// In tr, this message translates to:
  /// **'Taslaklar, oturum açmış kullanıcıya ait cihaz uygulama alanında tutulur.'**
  String get offlineStorageNotice;

  /// No description provided for @syncNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi eşitle'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In tr, this message translates to:
  /// **'Eşitleniyor…'**
  String get syncing;

  /// No description provided for @syncResult.
  ///
  /// In tr, this message translates to:
  /// **'{sent} kayıt gönderildi; {remaining} kayıt bekliyor.'**
  String syncResult(int sent, int remaining);

  /// No description provided for @syncAuthRefreshRequired.
  ///
  /// In tr, this message translates to:
  /// **'Oturumunuz yenilenmeli.'**
  String get syncAuthRefreshRequired;

  /// No description provided for @offlineDraftTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışı taslak'**
  String get offlineDraftTitle;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @offlineAudioDraftHint.
  ///
  /// In tr, this message translates to:
  /// **'Ses kaydı taslağı. Dinlemek için dışa aktarın.'**
  String get offlineAudioDraftHint;

  /// No description provided for @deleteQueuedRecordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt silinsin mi?'**
  String get deleteQueuedRecordTitle;

  /// No description provided for @deleteQueuedRecordWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt gönderilmeden silinecek ve geri alınamaz. Varsa ekli sesli not da bu cihazdan kaldırılır.'**
  String get deleteQueuedRecordWarning;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @recordDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt silindi.'**
  String get recordDeleted;

  /// No description provided for @syncBlockedStatus.
  ///
  /// In tr, this message translates to:
  /// **'Müdahale gerekiyor'**
  String get syncBlockedStatus;

  /// No description provided for @syncSendingStatus.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor'**
  String get syncSendingStatus;

  /// No description provided for @syncWaitingStatus.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get syncWaitingStatus;

  /// No description provided for @syncAttemptsCount.
  ///
  /// In tr, this message translates to:
  /// **'Deneme: {count}'**
  String syncAttemptsCount(String count);

  /// No description provided for @syncErrorCode.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {code}'**
  String syncErrorCode(String code);

  /// No description provided for @syncEntityVisitNote.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret notu'**
  String get syncEntityVisitNote;

  /// No description provided for @syncEntityVisit.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret kaydı'**
  String get syncEntityVisit;

  /// No description provided for @syncEntityGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışı kayıt'**
  String get syncEntityGeneric;

  /// No description provided for @viewDraft.
  ///
  /// In tr, this message translates to:
  /// **'Taslağı görüntüle'**
  String get viewDraft;

  /// No description provided for @exportDraft.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktar'**
  String get exportDraft;

  /// No description provided for @retrySync.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retrySync;

  /// No description provided for @syncErrorWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilmeyi bekliyor'**
  String get syncErrorWaiting;

  /// No description provided for @syncErrorNetwork.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı kurulamadı. Ağ geldiğinde kendiliğinden denenecek.'**
  String get syncErrorNetwork;

  /// No description provided for @syncErrorAuth.
  ///
  /// In tr, this message translates to:
  /// **'Oturum süresi doldu. Çıkıp yeniden giriş yapın.'**
  String get syncErrorAuth;

  /// No description provided for @syncErrorAccess.
  ///
  /// In tr, this message translates to:
  /// **'Etkin abonelik veya kullanılabilir kota gerekli. Taslağınız korunur; abonelik ekranını kontrol edip yeniden deneyebilirsiniz.'**
  String get syncErrorAccess;

  /// No description provided for @syncErrorVisitMissing.
  ///
  /// In tr, this message translates to:
  /// **'Bu notun bağlı olduğu ziyaret bulunamadı. Kaydı silebilirsiniz.'**
  String get syncErrorVisitMissing;

  /// No description provided for @syncErrorProcessing.
  ///
  /// In tr, this message translates to:
  /// **'Bu not sunucuda hâlâ işleniyor. Kısa süre sonra kendiliğinden tamamlanacak.'**
  String get syncErrorProcessing;

  /// No description provided for @syncErrorAudioTooLarge.
  ///
  /// In tr, this message translates to:
  /// **'Ses kaydı 25 MB sınırını aşıyor. Daha kısa bir not kaydedin ya da bu taslağı silin.'**
  String get syncErrorAudioTooLarge;

  /// No description provided for @syncErrorAudioUnsupported.
  ///
  /// In tr, this message translates to:
  /// **'Ses biçimi sunucu tarafından kabul edilmedi. Taslağı silip yeniden kaydedin.'**
  String get syncErrorAudioUnsupported;

  /// No description provided for @syncErrorRateLimit.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla istek gönderildi. Biraz sonra tekrar deneyin.'**
  String get syncErrorRateLimit;

  /// No description provided for @syncErrorUnsupportedEntity.
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt türü uygulamanın bu sürümü tarafından gönderilemiyor.'**
  String get syncErrorUnsupportedEntity;

  /// No description provided for @syncErrorServer.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu şu an yanıt veremiyor. Kısa süre sonra tekrar denenecek.'**
  String get syncErrorServer;

  /// No description provided for @syncErrorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt gönderilemedi. Tekrar deneyebilir ya da kaydı silebilirsiniz.'**
  String get syncErrorGeneric;

  /// No description provided for @syncBlockedOne.
  ///
  /// In tr, this message translates to:
  /// **'1 kayıt gönderilemiyor. Aşağıdan tekrar deneyin ya da silin.'**
  String get syncBlockedOne;

  /// No description provided for @syncBlockedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıt gönderilemiyor. Aşağıdan tekrar deneyin ya da silin.'**
  String syncBlockedCount(int count);

  /// No description provided for @noTasksPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Henüz görev yok. Yeni görev düğmesiyle ilk takibinizi oluşturun.'**
  String get noTasksPrompt;

  /// No description provided for @openTasksCount.
  ///
  /// In tr, this message translates to:
  /// **'Açık görevler ({count})'**
  String openTasksCount(int count);

  /// No description provided for @completedTasksCount.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlananlar ({count})'**
  String completedTasksCount(int count);

  /// No description provided for @generalTask.
  ///
  /// In tr, this message translates to:
  /// **'Genel görev'**
  String get generalTask;

  /// No description provided for @fieldModeOn.
  ///
  /// In tr, this message translates to:
  /// **'Saha modu açık'**
  String get fieldModeOn;

  /// No description provided for @fieldModeOff.
  ///
  /// In tr, this message translates to:
  /// **'Saha modu kapalı'**
  String get fieldModeOff;

  /// No description provided for @fieldModeActiveDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yakınından geçtiğiniz müşteriler kontrol ediliyor. {time} itibarıyla kendiliğinden kapanır.'**
  String fieldModeActiveDescription(String time);

  /// No description provided for @fieldModeInactiveDescription.
  ///
  /// In tr, this message translates to:
  /// **'Açtığınızda yakınınızdaki müşterileri ve onları en son ne zaman ziyaret ettiğinizi hatırlatır. Konumunuz kaydedilmez; saha modu kapalıyken konum kontrolü yapılmaz.'**
  String get fieldModeInactiveDescription;

  /// No description provided for @startFieldMode.
  ///
  /// In tr, this message translates to:
  /// **'Saha modunu başlat'**
  String get startFieldMode;

  /// No description provided for @stopFieldMode.
  ///
  /// In tr, this message translates to:
  /// **'Saha modunu bitir'**
  String get stopFieldMode;

  /// No description provided for @fieldModeStopped.
  ///
  /// In tr, this message translates to:
  /// **'Saha modu kapatıldı.'**
  String get fieldModeStopped;

  /// No description provided for @fieldModeExpired.
  ///
  /// In tr, this message translates to:
  /// **'Saha modu oturum süresi dolduğu için kapandı.'**
  String get fieldModeExpired;

  /// No description provided for @fieldModeWorkspaceChanged.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma alanı değiştiği için saha modu kapatıldı.'**
  String get fieldModeWorkspaceChanged;

  /// No description provided for @fieldModeLocationPermission.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verilmedi. Saha modu yerine Harita ekranından “Yakınımdakileri bul” diyebilirsiniz.'**
  String get fieldModeLocationPermission;

  /// No description provided for @fieldModeAfterHours.
  ///
  /// In tr, this message translates to:
  /// **'Saha modu saat 21.00’den sonra başlatılamaz. Yarın çalışma saatinde yeniden deneyin.'**
  String get fieldModeAfterHours;

  /// No description provided for @fieldModeNotificationPermission.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim izni verilmedi; saha modu hatırlatma gönderemez.'**
  String get fieldModeNotificationPermission;

  /// No description provided for @fieldModeLocationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. Konum ayarlarınızı kontrol edip yeniden deneyin.'**
  String get fieldModeLocationUnavailable;

  /// No description provided for @fieldModeSessionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Oturumunuz sona erdi. Yeniden giriş yapın.'**
  String get fieldModeSessionExpired;

  /// No description provided for @fieldModeAccessRequired.
  ///
  /// In tr, this message translates to:
  /// **'Saha modunu kullanmak için etkin bir abonelik gerekir.'**
  String get fieldModeAccessRequired;

  /// No description provided for @fieldModeStartFailed.
  ///
  /// In tr, this message translates to:
  /// **'Saha modu başlatılamadı. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get fieldModeStartFailed;

  /// No description provided for @fieldModeLocationCheckFailed.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. Konum iznini ve GPS ayarını kontrol edin.'**
  String get fieldModeLocationCheckFailed;

  /// No description provided for @nearbyCustomersUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki müşteriler güncellenemedi. Bağlantınızı kontrol edin.'**
  String get nearbyCustomersUpdateFailed;

  /// No description provided for @fieldModeReminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki müşteri'**
  String get fieldModeReminderTitle;

  /// No description provided for @fieldModeNotificationChannel.
  ///
  /// In tr, this message translates to:
  /// **'Saha modu'**
  String get fieldModeNotificationChannel;

  /// No description provided for @fieldModeNotificationDescription.
  ///
  /// In tr, this message translates to:
  /// **'Saha modu açıkken yakınınızdaki müşteriyi hatırlatır.'**
  String get fieldModeNotificationDescription;

  /// No description provided for @fieldModeForegroundTitle.
  ///
  /// In tr, this message translates to:
  /// **'KartVizyon saha modu açık'**
  String get fieldModeForegroundTitle;

  /// No description provided for @fieldModeForegroundText.
  ///
  /// In tr, this message translates to:
  /// **'Yakınınızdaki müşterileri hatırlatıyor. Durdurmak için dokunun.'**
  String get fieldModeForegroundText;

  /// No description provided for @distanceAway.
  ///
  /// In tr, this message translates to:
  /// **'{distance} uzakta'**
  String distanceAway(String distance);

  /// No description provided for @lastVisitedDays.
  ///
  /// In tr, this message translates to:
  /// **'Son ziyaret {days} gün önce'**
  String lastVisitedDays(int days);

  /// No description provided for @notVisitedYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ziyaret edilmedi'**
  String get notVisitedYet;

  /// No description provided for @overdueFollowUpCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} geciken takip'**
  String overdueFollowUpCount(int count);

  /// No description provided for @moduleNewProductDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ürün'**
  String get moduleNewProductDialogTitle;

  /// No description provided for @moduleStockCodeRequired.
  ///
  /// In tr, this message translates to:
  /// **'Stok kodu *'**
  String get moduleStockCodeRequired;

  /// No description provided for @moduleProductNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı *'**
  String get moduleProductNameRequired;

  /// No description provided for @moduleListPriceTryRequired.
  ///
  /// In tr, this message translates to:
  /// **'Liste fiyatı (TRY) *'**
  String get moduleListPriceTryRequired;

  /// No description provided for @moduleAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get moduleAdd;

  /// No description provided for @moduleCaptureDocument.
  ///
  /// In tr, this message translates to:
  /// **'Belgeyi fotoğraflayın'**
  String get moduleCaptureDocument;

  /// No description provided for @moduleChooseDocumentImage.
  ///
  /// In tr, this message translates to:
  /// **'Galeriden görsel seçin'**
  String get moduleChooseDocumentImage;

  /// No description provided for @moduleFieldFormFallback.
  ///
  /// In tr, this message translates to:
  /// **'Saha formu'**
  String get moduleFieldFormFallback;

  /// No description provided for @moduleFieldRequired.
  ///
  /// In tr, this message translates to:
  /// **'Bu alan zorunlu.'**
  String get moduleFieldRequired;

  /// No description provided for @moduleSend.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get moduleSend;

  /// No description provided for @moduleOrderRejectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş taslağını reddet'**
  String get moduleOrderRejectTitle;

  /// No description provided for @moduleRejectionReasonRequired.
  ///
  /// In tr, this message translates to:
  /// **'Red nedeni *'**
  String get moduleRejectionReasonRequired;

  /// No description provided for @moduleRejectionReasonExample.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Fiyat güncellenmeli'**
  String get moduleRejectionReasonExample;

  /// No description provided for @moduleSendForApproval.
  ///
  /// In tr, this message translates to:
  /// **'Onaya gönder'**
  String get moduleSendForApproval;

  /// No description provided for @moduleApprove.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get moduleApprove;

  /// No description provided for @moduleReject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get moduleReject;

  /// No description provided for @customerPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seç'**
  String get customerPickerTitle;

  /// No description provided for @customerPickerClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get customerPickerClose;

  /// No description provided for @customerPickerSearch.
  ///
  /// In tr, this message translates to:
  /// **'Kısa ad, firma, adres veya e-posta ara'**
  String get customerPickerSearch;

  /// No description provided for @customerPickerNone.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seçmeden devam et'**
  String get customerPickerNone;

  /// No description provided for @customerPickerEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Aramaya uygun müşteri bulunamadı.'**
  String get customerPickerEmpty;

  /// No description provided for @customerPickerRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get customerPickerRetry;

  /// No description provided for @customerPickerLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get customerPickerLoadFailed;

  /// No description provided for @visitPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret planla'**
  String get visitPlanTitle;

  /// No description provided for @visitPlanCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri'**
  String get visitPlanCustomer;

  /// No description provided for @visitPlanCustomerRequired.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seçin.'**
  String get visitPlanCustomerRequired;

  /// No description provided for @visitPlanCustomerMissingSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seçilmedi, zorunlu alan'**
  String get visitPlanCustomerMissingSemantics;

  /// No description provided for @visitPlanCustomerSelectedSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Seçili müşteri {name}'**
  String visitPlanCustomerSelectedSemantics(Object name);

  /// No description provided for @visitPlanCustomerSelect.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seç *'**
  String get visitPlanCustomerSelect;

  /// No description provided for @visitPlanFutureStart.
  ///
  /// In tr, this message translates to:
  /// **'Gelecekte bir başlangıç seçin.'**
  String get visitPlanFutureStart;

  /// No description provided for @visitPlanOfflineQueued.
  ///
  /// In tr, this message translates to:
  /// **'Planlı ziyaret çevrimdışı kuyruğa alındı. Hatırlatmalar senkronizasyondan sonra oluşturulur.'**
  String get visitPlanOfflineQueued;

  /// No description provided for @visitPlanType.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret türü'**
  String get visitPlanType;

  /// No description provided for @visitPlanTypeSalesMeeting.
  ///
  /// In tr, this message translates to:
  /// **'Satış görüşmesi'**
  String get visitPlanTypeSalesMeeting;

  /// No description provided for @visitPlanTypeQuoteFollowUp.
  ///
  /// In tr, this message translates to:
  /// **'Teklif takibi'**
  String get visitPlanTypeQuoteFollowUp;

  /// No description provided for @visitPlanTypeOrderFollowUp.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş takibi'**
  String get visitPlanTypeOrderFollowUp;

  /// No description provided for @visitPlanTypeIntroduction.
  ///
  /// In tr, this message translates to:
  /// **'Tanışma'**
  String get visitPlanTypeIntroduction;

  /// No description provided for @visitPlanTypeTechnical.
  ///
  /// In tr, this message translates to:
  /// **'Teknik görüşme'**
  String get visitPlanTypeTechnical;

  /// No description provided for @visitPlanTypeOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get visitPlanTypeOther;

  /// No description provided for @visitPlanPurpose.
  ///
  /// In tr, this message translates to:
  /// **'Amaç *'**
  String get visitPlanPurpose;

  /// No description provided for @visitPlanPurposeHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Yeni teklif üzerinden geçmek'**
  String get visitPlanPurposeHint;

  /// No description provided for @visitPlanPurposeMin.
  ///
  /// In tr, this message translates to:
  /// **'Amacı en az 2 karakter yazın.'**
  String get visitPlanPurposeMin;

  /// No description provided for @visitPlanDateTime.
  ///
  /// In tr, this message translates to:
  /// **'Tarih ve saat'**
  String get visitPlanDateTime;

  /// No description provided for @visitPlanDuration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get visitPlanDuration;

  /// No description provided for @visitPlanReminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Genel ziyaret hatırlatmaları'**
  String get visitPlanReminderTitle;

  /// No description provided for @visitPlanReminderBody.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Merkezi ayarınız açıksa 1 gün ve 2 saat önce hatırlatma gönderilir.'**
  String get visitPlanReminderBody;

  /// No description provided for @visitPlanNote.
  ///
  /// In tr, this message translates to:
  /// **'Planlama notu'**
  String get visitPlanNote;

  /// No description provided for @visitPlanNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Görüşme öncesi kısa hazırlık notu'**
  String get visitPlanNoteHint;

  /// No description provided for @visitPlanNoteHelper.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret sonrası değerlendirme notundan ayrıdır.'**
  String get visitPlanNoteHelper;

  /// No description provided for @visitPlanSelectedSummary.
  ///
  /// In tr, this message translates to:
  /// **'Seçim: {type} · {duration}'**
  String visitPlanSelectedSummary(Object type, Object duration);

  /// No description provided for @visitPlanDurationMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{count} dk'**
  String visitPlanDurationMinutes(int count);

  /// No description provided for @visitPlanDurationHour.
  ///
  /// In tr, this message translates to:
  /// **'1 saat'**
  String get visitPlanDurationHour;

  /// No description provided for @visitPlanDurationHourHalf.
  ///
  /// In tr, this message translates to:
  /// **'1 saat 30 dk'**
  String get visitPlanDurationHourHalf;

  /// No description provided for @visitPlanDurationTwoHours.
  ///
  /// In tr, this message translates to:
  /// **'2 saat'**
  String get visitPlanDurationTwoHours;

  /// No description provided for @visitPlanSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Ziyareti planla'**
  String get visitPlanSubmit;

  /// No description provided for @visitPlanSubscriptionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik gerekli'**
  String get visitPlanSubscriptionRequired;

  /// No description provided for @visitPlanSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret planlanamadı. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get visitPlanSaveFailed;

  /// No description provided for @companyIdentityOnboardingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlamadan önce'**
  String get companyIdentityOnboardingTitle;

  /// No description provided for @companyIdentityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Firma bilgileri'**
  String get companyIdentityTitle;

  /// No description provided for @companyIdentityIntro.
  ///
  /// In tr, this message translates to:
  /// **'Sizi ve temsil ettiğiniz firmayı tanıyalım.'**
  String get companyIdentityIntro;

  /// No description provided for @companyIdentityName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get companyIdentityName;

  /// No description provided for @companyIdentityCompany.
  ///
  /// In tr, this message translates to:
  /// **'Firma adı'**
  String get companyIdentityCompany;

  /// No description provided for @companyIdentityNameTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad en az 2 karakter olmalı.'**
  String get companyIdentityNameTooShort;

  /// No description provided for @companyIdentityCompanyTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Firma adı en az 2 karakter olmalı.'**
  String get companyIdentityCompanyTooShort;

  /// No description provided for @companyIdentitySaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Firma bilgileri kaydedilemedi. Tekrar deneyin.'**
  String get companyIdentitySaveFailed;

  /// No description provided for @companyIdentityReadOnly.
  ///
  /// In tr, this message translates to:
  /// **'Salt okunur erişimde firma adı değiştirilemez.'**
  String get companyIdentityReadOnly;

  /// No description provided for @companyIdentitySaving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor…'**
  String get companyIdentitySaving;

  /// No description provided for @companyIdentitySave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get companyIdentitySave;

  /// No description provided for @companyIdentitySkip.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik geç'**
  String get companyIdentitySkip;

  /// No description provided for @opportunityEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fırsatı düzenle'**
  String get opportunityEditTitle;

  /// No description provided for @opportunityNewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni fırsat'**
  String get opportunityNewTitle;

  /// No description provided for @opportunityName.
  ///
  /// In tr, this message translates to:
  /// **'Fırsat adı *'**
  String get opportunityName;

  /// No description provided for @opportunityNameTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Fırsat adını en az 2 karakter yazın.'**
  String get opportunityNameTooShort;

  /// No description provided for @opportunityCustomerSelect.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seç *'**
  String get opportunityCustomerSelect;

  /// No description provided for @opportunityCustomerRequired.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seçin.'**
  String get opportunityCustomerRequired;

  /// No description provided for @opportunityEstimatedValue.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini değer'**
  String get opportunityEstimatedValue;

  /// No description provided for @opportunityInvalidAmount.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir tutar yazın.'**
  String get opportunityInvalidAmount;

  /// No description provided for @opportunityNegativeAmount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar negatif olamaz.'**
  String get opportunityNegativeAmount;

  /// No description provided for @opportunityAmountTooHigh.
  ///
  /// In tr, this message translates to:
  /// **'Tutar çok yüksek.'**
  String get opportunityAmountTooHigh;

  /// No description provided for @opportunityCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Para birimi'**
  String get opportunityCurrency;

  /// No description provided for @opportunityStage.
  ///
  /// In tr, this message translates to:
  /// **'Aşama'**
  String get opportunityStage;

  /// No description provided for @opportunityStageLead.
  ///
  /// In tr, this message translates to:
  /// **'Potansiyel'**
  String get opportunityStageLead;

  /// No description provided for @opportunityStageQualified.
  ///
  /// In tr, this message translates to:
  /// **'Nitelikli'**
  String get opportunityStageQualified;

  /// No description provided for @opportunityStageProposal.
  ///
  /// In tr, this message translates to:
  /// **'Teklif'**
  String get opportunityStageProposal;

  /// No description provided for @opportunityStageNegotiation.
  ///
  /// In tr, this message translates to:
  /// **'Müzakere'**
  String get opportunityStageNegotiation;

  /// No description provided for @opportunityStageWon.
  ///
  /// In tr, this message translates to:
  /// **'Kazanıldı'**
  String get opportunityStageWon;

  /// No description provided for @opportunityStageLost.
  ///
  /// In tr, this message translates to:
  /// **'Kaybedildi'**
  String get opportunityStageLost;

  /// No description provided for @opportunityWinProbability.
  ///
  /// In tr, this message translates to:
  /// **'Kazanma olasılığı'**
  String get opportunityWinProbability;

  /// No description provided for @opportunityExpectedCloseChoose.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini kapanış tarihi seç'**
  String get opportunityExpectedCloseChoose;

  /// No description provided for @opportunityExpectedClose.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini kapanış: {date}'**
  String opportunityExpectedClose(Object date);

  /// No description provided for @opportunityRemoveDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarihi kaldır'**
  String get opportunityRemoveDate;

  /// No description provided for @opportunityCompetitor.
  ///
  /// In tr, this message translates to:
  /// **'Rakip'**
  String get opportunityCompetitor;

  /// No description provided for @opportunityOwner.
  ///
  /// In tr, this message translates to:
  /// **'Sorumlu'**
  String get opportunityOwner;

  /// No description provided for @opportunityLossReason.
  ///
  /// In tr, this message translates to:
  /// **'Kaybetme nedeni *'**
  String get opportunityLossReason;

  /// No description provided for @opportunityLossReasonRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kaybetme nedenini yazın.'**
  String get opportunityLossReasonRequired;

  /// No description provided for @opportunityModelNotice.
  ///
  /// In tr, this message translates to:
  /// **'Not ve sonraki adım alanları mevcut fırsat modelinde bulunmadığı için bu sürümde eklenmedi.'**
  String get opportunityModelNotice;

  /// No description provided for @opportunityNetworkError.
  ///
  /// In tr, this message translates to:
  /// **'Fırsat kaydedilemedi. Form bilgileriniz korunuyor.'**
  String get opportunityNetworkError;

  /// No description provided for @opportunitySave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get opportunitySave;

  /// No description provided for @opportunitySaving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor…'**
  String get opportunitySaving;

  /// No description provided for @opportunityUserFallback.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get opportunityUserFallback;

  /// No description provided for @opportunityMe.
  ///
  /// In tr, this message translates to:
  /// **'Ben'**
  String get opportunityMe;

  /// No description provided for @formTemplateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni saha formu'**
  String get formTemplateTitle;

  /// No description provided for @formTemplateIntro.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza kontrolü, rakip analizi, servis kontrolü veya özel ziyaret kontrol listeleri oluşturun.'**
  String get formTemplateIntro;

  /// No description provided for @formTemplateName.
  ///
  /// In tr, this message translates to:
  /// **'Form adı *'**
  String get formTemplateName;

  /// No description provided for @formTemplateNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Form adını yazın.'**
  String get formTemplateNameRequired;

  /// No description provided for @formTemplateDescription.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get formTemplateDescription;

  /// No description provided for @formTemplateFields.
  ///
  /// In tr, this message translates to:
  /// **'Alanlar'**
  String get formTemplateFields;

  /// No description provided for @formTemplateRequired.
  ///
  /// In tr, this message translates to:
  /// **'Zorunlu'**
  String get formTemplateRequired;

  /// No description provided for @formTemplateRemoveField.
  ///
  /// In tr, this message translates to:
  /// **'Alanı kaldır'**
  String get formTemplateRemoveField;

  /// No description provided for @formTemplateAddField.
  ///
  /// In tr, this message translates to:
  /// **'Alan ekle'**
  String get formTemplateAddField;

  /// No description provided for @formTemplateNeedsField.
  ///
  /// In tr, this message translates to:
  /// **'En az bir alan ekleyin.'**
  String get formTemplateNeedsField;

  /// No description provided for @formTemplateCreate.
  ///
  /// In tr, this message translates to:
  /// **'Formu oluştur'**
  String get formTemplateCreate;

  /// No description provided for @formTemplateCreating.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturuluyor…'**
  String get formTemplateCreating;

  /// No description provided for @formTemplateSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Form kaydedilemedi. Girdileriniz korunuyor.'**
  String get formTemplateSaveFailed;

  /// No description provided for @formTemplateAddFieldTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alan ekle'**
  String get formTemplateAddFieldTitle;

  /// No description provided for @formTemplateFieldTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlık *'**
  String get formTemplateFieldTitle;

  /// No description provided for @formTemplateFieldType.
  ///
  /// In tr, this message translates to:
  /// **'Alan türü'**
  String get formTemplateFieldType;

  /// No description provided for @formTemplateHelpText.
  ///
  /// In tr, this message translates to:
  /// **'Yardım metni'**
  String get formTemplateHelpText;

  /// No description provided for @formTemplateOptions.
  ///
  /// In tr, this message translates to:
  /// **'Seçenekler *'**
  String get formTemplateOptions;

  /// No description provided for @formTemplateOptionsHint.
  ///
  /// In tr, this message translates to:
  /// **'Her satıra bir seçenek'**
  String get formTemplateOptionsHint;

  /// No description provided for @formTemplateCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get formTemplateCancel;

  /// No description provided for @formTemplateAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get formTemplateAdd;

  /// No description provided for @formTemplateFieldTitleRequired.
  ///
  /// In tr, this message translates to:
  /// **'En az 2 karakterlik bir başlık girin; seçim alanlarına seçenek ekleyin.'**
  String get formTemplateFieldTitleRequired;

  /// No description provided for @formTemplateText.
  ///
  /// In tr, this message translates to:
  /// **'Kısa metin'**
  String get formTemplateText;

  /// No description provided for @formTemplateLongText.
  ///
  /// In tr, this message translates to:
  /// **'Uzun metin'**
  String get formTemplateLongText;

  /// No description provided for @formTemplateNumber.
  ///
  /// In tr, this message translates to:
  /// **'Sayı'**
  String get formTemplateNumber;

  /// No description provided for @formTemplateYesNo.
  ///
  /// In tr, this message translates to:
  /// **'Evet / Hayır'**
  String get formTemplateYesNo;

  /// No description provided for @formTemplateSingleSelect.
  ///
  /// In tr, this message translates to:
  /// **'Tek seçim'**
  String get formTemplateSingleSelect;

  /// No description provided for @formTemplateMultiSelect.
  ///
  /// In tr, this message translates to:
  /// **'Çoklu seçim'**
  String get formTemplateMultiSelect;

  /// No description provided for @formTemplateDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get formTemplateDate;

  /// No description provided for @orderDraftEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş taslağını düzenle'**
  String get orderDraftEditTitle;

  /// No description provided for @orderDraftNewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni sipariş taslağı'**
  String get orderDraftNewTitle;

  /// No description provided for @orderDraftSelectProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürün seç'**
  String get orderDraftSelectProduct;

  /// No description provided for @orderDraftProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürün'**
  String get orderDraftProduct;

  /// No description provided for @orderDraftNoProducts.
  ///
  /// In tr, this message translates to:
  /// **'Bu para biriminde aktif ürün yok.'**
  String get orderDraftNoProducts;

  /// No description provided for @orderDraftSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş taslağı kaydedilemedi. Form bilgileriniz korunuyor.'**
  String get orderDraftSaveFailed;

  /// No description provided for @orderDraftCustomerSelect.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seç *'**
  String get orderDraftCustomerSelect;

  /// No description provided for @orderDraftCustomerRequired.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri seçin.'**
  String get orderDraftCustomerRequired;

  /// No description provided for @orderDraftCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Para birimi'**
  String get orderDraftCurrency;

  /// No description provided for @orderDraftItems.
  ///
  /// In tr, this message translates to:
  /// **'Kalemler'**
  String get orderDraftItems;

  /// No description provided for @orderDraftAddProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürün ekle'**
  String get orderDraftAddProduct;

  /// No description provided for @orderDraftNeedsProduct.
  ///
  /// In tr, this message translates to:
  /// **'En az bir ürün ekleyin.'**
  String get orderDraftNeedsProduct;

  /// No description provided for @orderDraftChooseDeliveryDate.
  ///
  /// In tr, this message translates to:
  /// **'Teslim tarihi seç'**
  String get orderDraftChooseDeliveryDate;

  /// No description provided for @orderDraftDeliveryDate.
  ///
  /// In tr, this message translates to:
  /// **'Teslim: {date}'**
  String orderDraftDeliveryDate(Object date);

  /// No description provided for @orderDraftNotes.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get orderDraftNotes;

  /// No description provided for @orderDraftSubtotal.
  ///
  /// In tr, this message translates to:
  /// **'Ara toplam'**
  String get orderDraftSubtotal;

  /// No description provided for @orderDraftDiscount.
  ///
  /// In tr, this message translates to:
  /// **'İndirim'**
  String get orderDraftDiscount;

  /// No description provided for @orderDraftTax.
  ///
  /// In tr, this message translates to:
  /// **'Vergi'**
  String get orderDraftTax;

  /// No description provided for @orderDraftEstimatedTotal.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini toplam'**
  String get orderDraftEstimatedTotal;

  /// No description provided for @orderDraftEstimateNotice.
  ///
  /// In tr, this message translates to:
  /// **'Önizlemedir; kesin toplam sunucuda hesaplanır.'**
  String get orderDraftEstimateNotice;

  /// No description provided for @orderDraftSaving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor…'**
  String get orderDraftSaving;

  /// No description provided for @orderDraftSave.
  ///
  /// In tr, this message translates to:
  /// **'Taslağı kaydet'**
  String get orderDraftSave;

  /// No description provided for @orderDraftRemoveItem.
  ///
  /// In tr, this message translates to:
  /// **'Kalemi kaldır'**
  String get orderDraftRemoveItem;

  /// No description provided for @orderDraftQuantity.
  ///
  /// In tr, this message translates to:
  /// **'Miktar *'**
  String get orderDraftQuantity;

  /// No description provided for @orderDraftQuantityMustBePositive.
  ///
  /// In tr, this message translates to:
  /// **'Miktar sıfırdan büyük olmalı.'**
  String get orderDraftQuantityMustBePositive;

  /// No description provided for @orderDraftUnitPrice.
  ///
  /// In tr, this message translates to:
  /// **'Birim fiyat ({currency}) *'**
  String orderDraftUnitPrice(Object currency);

  /// No description provided for @orderDraftPriceNegative.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat negatif olamaz.'**
  String get orderDraftPriceNegative;

  /// No description provided for @orderDraftDiscountPercent.
  ///
  /// In tr, this message translates to:
  /// **'İndirim (%)'**
  String get orderDraftDiscountPercent;

  /// No description provided for @orderDraftDiscountRange.
  ///
  /// In tr, this message translates to:
  /// **'İndirim 0–100 arasında olmalı.'**
  String get orderDraftDiscountRange;

  /// No description provided for @briefingLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri brifingi yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get briefingLoadFailed;

  /// No description provided for @briefingRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get briefingRetry;

  /// No description provided for @briefingNeverVisited.
  ///
  /// In tr, this message translates to:
  /// **'Bu müşteriyi henüz ziyaret etmediniz.'**
  String get briefingNeverVisited;

  /// No description provided for @briefingStartVisitFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret başlatılamadı. Tekrar deneyin.'**
  String get briefingStartVisitFailed;

  /// No description provided for @briefingDefaultVisitPurpose.
  ///
  /// In tr, this message translates to:
  /// **'Saha ziyareti'**
  String get briefingDefaultVisitPurpose;

  /// No description provided for @moduleActiveCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Aktif müşteri'**
  String get moduleActiveCustomer;

  /// No description provided for @moduleApprovedVisit.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanmış ziyaret'**
  String get moduleApprovedVisit;

  /// No description provided for @moduleReviewVisit.
  ///
  /// In tr, this message translates to:
  /// **'İnceleme bekleyen ziyaret'**
  String get moduleReviewVisit;

  /// No description provided for @moduleOpenTask.
  ///
  /// In tr, this message translates to:
  /// **'Açık görev'**
  String get moduleOpenTask;

  /// No description provided for @moduleVisit.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret'**
  String get moduleVisit;

  /// No description provided for @moduleTask.
  ///
  /// In tr, this message translates to:
  /// **'Görev'**
  String get moduleTask;

  /// No description provided for @moduleActivity.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite'**
  String get moduleActivity;

  /// No description provided for @moduleNotification.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim'**
  String get moduleNotification;

  /// No description provided for @moduleOpportunity.
  ///
  /// In tr, this message translates to:
  /// **'Fırsat'**
  String get moduleOpportunity;

  /// No description provided for @moduleProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürün'**
  String get moduleProduct;

  /// No description provided for @moduleOrderDraft.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş taslağı'**
  String get moduleOrderDraft;

  /// No description provided for @moduleFormTemplate.
  ///
  /// In tr, this message translates to:
  /// **'Form şablonu'**
  String get moduleFormTemplate;

  /// No description provided for @moduleActiveFormTemplate.
  ///
  /// In tr, this message translates to:
  /// **'Aktif form şablonu'**
  String get moduleActiveFormTemplate;

  /// No description provided for @moduleSubmittedForm.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilmiş form'**
  String get moduleSubmittedForm;

  /// No description provided for @summaryApprovalFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret özeti onaylanamadı. Tekrar deneyin.'**
  String get summaryApprovalFailed;

  /// No description provided for @reviewLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret incelemesi yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get reviewLoadFailed;

  /// No description provided for @visitsLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get visitsLoadFailed;

  /// No description provided for @homeLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Genel bakış yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get homeLoadFailed;

  /// No description provided for @writeAccessRequired.
  ///
  /// In tr, this message translates to:
  /// **'Bu ziyaret notunu kaydetmek için etkin abonelik gerekli.'**
  String get writeAccessRequired;

  /// No description provided for @customerSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri kaydedilemedi. Form bilgileriniz korunuyor.'**
  String get customerSaveFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
