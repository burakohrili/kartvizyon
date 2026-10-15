// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'KartVizyon AI';

  @override
  String get summaryTab => 'Özet';

  @override
  String get customersTab => 'Müşteriler';

  @override
  String get visitsTab => 'Ziyaretler';

  @override
  String get tasksTab => 'Görevler';

  @override
  String get fieldSummary => 'Bugünün saha özeti';

  @override
  String get todayTab => 'Bugün';

  @override
  String get newVisit => 'Yeni ziyaret';

  @override
  String get visitTab => 'Ziyaret';

  @override
  String get menuTab => 'Menü';

  @override
  String get readOnlyBanner =>
      'Yalnız görüntüleme. Yeni işlemler için abonelik başlatın.';

  @override
  String get premiumTitle => 'Premium ve abonelik';

  @override
  String get premiumMonthly => 'Aylık';

  @override
  String get premiumAnnual => 'Yıllık';

  @override
  String get premiumUnlimited => 'Sınırsız';

  @override
  String get sandboxNotice =>
      'Sandbox test ortamı — canlı hesabınızdan ayrıdır.';

  @override
  String get trialPlanName => '14 günlük deneme';

  @override
  String get viewOnlyPlanName => 'Yalnız görüntüleme';

  @override
  String get activePlanName => 'Premium planı';

  @override
  String get organizationPlanName => 'Kurum planı';

  @override
  String get organizationPlanManaged =>
      'Bu çalışma alanının planı kurum yöneticiniz tarafından yönetilir.';

  @override
  String paymentsThroughStore(String store) {
    return 'Ödeme $store hesabınız üzerinden güvenle tamamlanır.';
  }

  @override
  String get premiumTrialDisclosure =>
      '14 gün ücretsiz deneyin. Kart gerekmez. Deneme sonunda otomatik ücret alınmaz. Devam etmek için abonelik başlatabilirsiniz.';

  @override
  String get premiumTrialQuota =>
      'Deneme: toplam 60 tarama · 120 dakika ses işleme · 60 AI özeti.';

  @override
  String get premiumIndividualQuota =>
      'Bireysel: ayda 125 tarama · 240 dakika ses işleme · 125 AI özeti. Güncel fiyat, mağaza hesabınızın ülke veya bölgesine göre satın alma düğmesinde gösterilir.';

  @override
  String get premiumTrialLastDay => 'Denemenizin son günü.';

  @override
  String premiumTrialDaysLeft(int days) {
    return 'Denemenizin bitmesine $days gün kaldı.';
  }

  @override
  String get premiumReadOnlyDisclosure =>
      'Yalnız görüntüleme: mevcut kayıtlarınız, dışa aktarma ve hesap silme açık kalır. Yeni kayıt oluşturmak veya AI özelliklerini kullanmak için abonelik başlatın.';

  @override
  String premiumUsageScans(String used, String limit) {
    return 'Tarama: $used / $limit';
  }

  @override
  String premiumUsageAudio(String used, String limit) {
    return 'Ses işleme: $used / $limit dakika';
  }

  @override
  String premiumUsageSummaries(String used, String limit) {
    return 'AI özeti: $used / $limit';
  }

  @override
  String get premiumQuotaPolicy =>
      'Ücretli abonelikte tam kota açılır. Kullanılmayan haklar devretmez. Kota aşımı otomatik ücret doğurmaz.';

  @override
  String get premiumRestorePurchases => 'Satın almaları geri yükle';

  @override
  String premiumManageSubscription(String store) {
    return 'Aboneliği $store’da yönet';
  }

  @override
  String get premiumAutoRenewalDisclosure =>
      'Abonelik seçtiğiniz dönemde otomatik yenilenir. Yenilemeyi mevcut dönem bitmeden mağaza hesap ayarlarınızdan kapatabilirsiniz.';

  @override
  String get premiumTermsOfUse => 'Kullanım Koşulları';

  @override
  String get premiumPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get billingLoadFailure => 'Premium bilgileri yüklenemedi.';

  @override
  String get billingConfigurationUnavailable =>
      'Mağaza ödeme yapılandırması henüz tamamlanmadı.';

  @override
  String get billingOfferingUnavailable =>
      'Bu mağaza için şu anda satın alınabilir plan bulunamadı.';

  @override
  String get billingSessionRequired => 'Devam etmek için lütfen giriş yapın.';

  @override
  String get billingPurchaseCancelled => 'Satın alma iptal edildi.';

  @override
  String get billingPurchaseFailed =>
      'Satın alma tamamlanamadı. Mağaza hesabınızı kontrol edip yeniden deneyin.';

  @override
  String get billingRestoreFailed =>
      'Satın almalar geri yüklenemedi. Mağaza hesabınızı kontrol edip yeniden deneyin.';

  @override
  String get billingPurchaseServerPending =>
      'Satın alma mağazada tamamlandı; sunucu doğrulaması bekleniyor. Kontrol etmek için bu ekranı biraz sonra yeniden açın.';

  @override
  String get billingRestoreServerPending =>
      'Geri yükleme mağazada tamamlandı; sunucu doğrulaması bekleniyor. Biraz sonra yeniden deneyin.';

  @override
  String get billingRestoreNoActivePurchase =>
      'Bu mağaza hesabında geri yüklenecek etkin bir satın alma bulunamadı.';

  @override
  String get billingPurchaseAwaitingStore =>
      'Satın alma alındı; mağaza doğrulaması bekleniyor.';

  @override
  String get billingSandboxLiveServerWarning =>
      'Test satın almanız mağazada etkin, ancak bu uygulama canlı sunucuya bağlı. Sandbox satın almaları canlı erişimi açmaz. Test sunucusuna bağlı TestFlight sürümünü kullanın. Tekrar satın almayın.';

  @override
  String get billingServerAccessPending =>
      'Premium mağazada etkin, ancak sunucu erişiminiz henüz açılmadı. Geri yükleme ve erişim doğrulaması tamamlanmadı. Tekrar satın almayın; destek ile iletişime geçin.';

  @override
  String get billingRestoreSuccess =>
      'Premium satın almanız geri yüklendi ve sunucu erişiminiz doğrulandı.';

  @override
  String get billingPurchaseSuccess =>
      'Premium etkinleşti ve sunucu erişiminiz doğrulandı.';

  @override
  String get billingSubscriptionManagementUnavailable =>
      'Abonelik yönetimi açılamadı. Lütfen biraz sonra yeniden deneyin.';

  @override
  String get trialBannerLastDay =>
      'Ücretsiz denemenizin son günü. Otomatik ücret alınmaz.';

  @override
  String trialBannerDays(int days) {
    return 'Ücretsiz deneme: $days gün kaldı. Otomatik ücret alınmaz.';
  }

  @override
  String get subscription => 'Abonelik';

  @override
  String get moreTitle => 'Daha fazla';

  @override
  String get interfaceLanguage => 'Uygulama dili';

  @override
  String get languageUpdateFailed =>
      'Dil tercihi kaydedilemedi. Tekrar deneyin.';

  @override
  String get fieldMap => 'Saha haritası';

  @override
  String get nearbyCustomersRoute => 'Yakındaki müşteriler ve ziyaret rotası';

  @override
  String get visitsVoiceNote => 'Ziyaretler ve sesli not';

  @override
  String get preApprovalPromise =>
      'Kullanıcı onayından önce kurumsal hafızaya eklenmez';

  @override
  String get syncCenter => 'Eşitleme merkezi';

  @override
  String get pendingRecordsErrors => 'Bekleyen kayıtlar ve hatalar';

  @override
  String get chooseWorkspace => 'Çalışma alanı seçin';

  @override
  String get workspace => 'Çalışma alanı';

  @override
  String get workspaceChangeFailed =>
      'Çalışma alanı değiştirilemedi. Tekrar deneyin.';

  @override
  String get switchWorkspace => 'Çalışma alanı değiştir';

  @override
  String get calendar => 'Takvim';

  @override
  String get plannedVisitsDatedTasks =>
      'Planlanan ziyaretler ve tarihli görevler';

  @override
  String get activity => 'Aktivite';

  @override
  String get activityHistory => 'Ziyaret, görev, fırsat ve sipariş geçmişi';

  @override
  String get reportsSummary => 'Rapor özeti';

  @override
  String get customerVisitTaskMetrics =>
      'Müşteri, ziyaret ve görev göstergeleri';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get commentsTasksApprovalEvents =>
      'Yorumlar, görevler ve onay olayları';

  @override
  String get opportunities => 'Fırsatlar';

  @override
  String get salesPipelineStages => 'Satış pipeline ve aşama görünümü';

  @override
  String get productsPrices => 'Ürün ve fiyatlar';

  @override
  String get activeProductCatalogPrices =>
      'Aktif ürün kataloğu ve liste fiyatları';

  @override
  String get orderDrafts => 'Sipariş taslakları';

  @override
  String get draftApprovalStatus => 'Taslak ve onay durumlarını görüntüleyin';

  @override
  String get documents => 'Belgeler';

  @override
  String get fileSecurityScanning => 'Dosya ve güvenlik tarama durumları';

  @override
  String get fieldForms => 'Saha formları';

  @override
  String get activeTemplatesSubmissions => 'Aktif şablonlar ve gönderimler';

  @override
  String get moduleNoPlannedVisits => 'Planlanmış ziyaret yok';

  @override
  String get moduleCalendarEmptyHint =>
      'Tarihli ziyaretler ve son tarihi olan görevler burada listelenir. Sağ alttaki düğmeyle yeni ziyaret planlayabilirsiniz.';

  @override
  String get moduleNoApprovedVisits => 'Henüz onaylanmış ziyaret yok';

  @override
  String get moduleActivityEmptyHint =>
      'Onayladığınız ziyaretler buraya düşer. Bir ziyaret notu gönderip özeti onayladığınızda ilk kayıt görünür.';

  @override
  String get moduleNoReportData => 'Gösterge üretecek kayıt yok';

  @override
  String get moduleReportsEmptyHint =>
      'Müşteri, ziyaret ve görev sayıları burada görüntülenir. İlk müşterinizi ekleyip ziyaret kaydettiğinizde göstergeler dolar.';

  @override
  String get moduleNoNotifications => 'Bildirim yok';

  @override
  String get moduleNotificationsEmptyHint =>
      'Yaklaşan ziyaretler, geciken görevler ve saha hatırlatmaları burada görünür.';

  @override
  String get moduleNoOpportunities => 'Fırsat kaydı yok';

  @override
  String get moduleOpportunitiesEmptyHint =>
      'Yeni fırsatı burada oluşturabilir, kaydı açarak satış aşamasını güncelleyebilirsiniz.';

  @override
  String get moduleNoProducts => 'Katalogda ürün yok';

  @override
  String get moduleProductsEmptyHint =>
      'Aktif ürün kataloğu ve liste fiyatları burada görünür. Yeni ürünü mobilde kataloğa ekleyebilirsiniz.';

  @override
  String get moduleNoOrderDrafts => 'Sipariş taslağı yok';

  @override
  String get moduleOrdersEmptyHint =>
      'Burada sipariş taslağı oluşturabilir; kaydı açarak onaya gönderebilir veya yetkiniz varsa sonuçlandırabilirsiniz.';

  @override
  String get moduleNoDocuments => 'Belge yok';

  @override
  String get moduleDocumentsEmptyHint =>
      'Yüklenen dosyalar ve zararlı yazılım tarama durumu burada görünür. Belgeyi fotoğraflayıp güvenlik taramasına gönderebilirsiniz.';

  @override
  String get moduleNoActiveForms => 'Aktif form yok';

  @override
  String get moduleFormsEmptyHint =>
      'Mağaza kontrolü, rakip analizi, servis kontrolü veya özel ziyaret kontrol listeleri oluşturup saha yanıtlarını görüntüleyin.';

  @override
  String get moduleNoNewNotifications => 'Şimdilik yeni bildiriminiz yok.';

  @override
  String get moduleFilteredOpportunitiesEmpty =>
      'Bu filtrede fırsat bulunmuyor.';

  @override
  String get moduleFilteredOrdersEmpty => 'Bu filtrede sipariş bulunmuyor.';

  @override
  String get moduleFilteredActivityEmpty => 'Bu filtrede aktivite bulunmuyor.';

  @override
  String moduleOpportunityOpenCount(int count) {
    return '$count açık fırsat';
  }

  @override
  String get moduleOpportunityOpen => 'Açık';

  @override
  String get moduleOpportunityWon => 'Kazanılan';

  @override
  String get moduleOpportunityLost => 'Kaybedilen';

  @override
  String get moduleAll => 'Tümü';

  @override
  String get moduleOrderApproved => 'Onaylandı';

  @override
  String get moduleOrderRejected => 'Reddedildi';

  @override
  String get moduleActivityVisits => 'Ziyaretler';

  @override
  String get moduleActivityTasks => 'Görevler';

  @override
  String get moduleActivityOpportunities => 'Fırsatlar';

  @override
  String get moduleActivityOrders => 'Siparişler';

  @override
  String moduleEstimateClose(String date) {
    return 'Tahmini kapanış: $date';
  }

  @override
  String moduleReason(String reason) {
    return 'Neden: $reason';
  }

  @override
  String moduleOrderTotal(String amount) {
    return 'Toplam: $amount';
  }

  @override
  String moduleDeliveryDate(String date) {
    return 'Teslim tarihi: $date';
  }

  @override
  String moduleNote(String note) {
    return 'Not: $note';
  }

  @override
  String moduleRejectedBy(String name) {
    return 'Reddeden: $name';
  }

  @override
  String moduleDate(String date) {
    return 'Tarih: $date';
  }

  @override
  String get moduleEditAndReturnToDraft => 'Düzenle ve taslağa al';

  @override
  String get moduleSubmitForApproval => 'Onaya gönder';

  @override
  String get moduleMakeDecision => 'Karar ver';

  @override
  String get modulePriceLists => 'Fiyat listeleri';

  @override
  String get modulePriceListFallback => 'Fiyat listesi';

  @override
  String get moduleDocumentFallback => 'Belge';

  @override
  String get moduleCleanPriceListHint =>
      'Güvenlik taraması tamamlanan PDF listelerini görüntüleyebilirsiniz.';

  @override
  String get moduleNoPriceLists => 'Fiyat listesi bulunmuyor.';

  @override
  String get moduleProductCatalog => 'Ürün kataloğu';

  @override
  String get moduleNoActiveProducts => 'Aktif ürün bulunmuyor.';

  @override
  String get moduleOpenDocument => 'Açmak için dokunun';

  @override
  String get moduleScanPending => 'Güvenlik taraması sürüyor; henüz açılamaz';

  @override
  String get moduleScanStatusPending => 'Tarama bekliyor';

  @override
  String get moduleScanStatusClean => 'Temiz';

  @override
  String get moduleScanStatusInfected => 'Zararlı içerik bulundu';

  @override
  String get moduleScanStatusError => 'Tarama hatası';

  @override
  String get moduleScanStatusUnknown => 'Durum bilinmiyor';

  @override
  String get moduleLoadFailed =>
      'Bu bölüm yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get moduleActionFailed => 'İşlem tamamlanamadı. Tekrar deneyin.';

  @override
  String get moduleRecordCreated => 'Kayıt oluşturuldu.';

  @override
  String get moduleEdit => 'Düzenle';

  @override
  String get moduleRefresh => 'Yenile';

  @override
  String get moduleFormSubmitted => 'Form yanıtı gönderildi.';

  @override
  String get modulePreferencesTitle => 'Bildirim tercihleri';

  @override
  String get moduleSystemNotificationsDisabled =>
      'Sistem bildirimleri kapalı. Hatırlatmalar uygulama içindeki Bildirimler ekranında görünmeye devam eder.';

  @override
  String get moduleVisitReminders => 'Ziyaret hatırlatmaları';

  @override
  String get moduleTaskReminders => 'Görev hatırlatmaları';

  @override
  String get moduleMorningReminder => 'Sabah saha hatırlatması';

  @override
  String get moduleMorningReminderTime => 'Planlı ziyaret olan günlerde 08.30';

  @override
  String get modulePreferencesSaved => 'Bildirim tercihleri kaydedildi.';

  @override
  String get modulePreferencesFailed =>
      'Bildirim tercihleri açılamadı veya kaydedilemedi. Tekrar deneyin.';

  @override
  String get moduleDocumentsFailed => 'Belge açılamadı. Tekrar deneyin.';

  @override
  String get moduleRegistrationFallback => 'Kayıt';

  @override
  String get moduleCustomerCount => 'Aktif müşteri';

  @override
  String get moduleApprovedVisitCount => 'Onaylanmış ziyaret';

  @override
  String get moduleReviewVisitCount => 'İnceleme bekleyen ziyaret';

  @override
  String get moduleOpenTaskCount => 'Açık görev';

  @override
  String get modulePlanVisit => 'Ziyaret planla';

  @override
  String get moduleNewOpportunity => 'Yeni fırsat';

  @override
  String get moduleNewProduct => 'Yeni ürün';

  @override
  String get moduleNewOrderDraft => 'Yeni taslak';

  @override
  String get moduleUploadDocument => 'Belge yükle';

  @override
  String get moduleNewForm => 'Yeni form';

  @override
  String get moduleStageLead => 'Aday';

  @override
  String get moduleStageQualified => 'Nitelikli';

  @override
  String get moduleStageProposal => 'Teklif';

  @override
  String get moduleStageNegotiation => 'Müzakere';

  @override
  String get moduleStageWon => 'Kazanıldı';

  @override
  String get moduleStageLost => 'Kaybedildi';

  @override
  String get moduleStageDraft => 'Taslak';

  @override
  String get moduleStagePendingApproval => 'Onay bekliyor';

  @override
  String get moduleStageApproved => 'Onaylandı';

  @override
  String get moduleStageRejected => 'Reddedildi';

  @override
  String get moduleOrderDraftExplanation =>
      'Taslak üzerinde değişiklik yapabilirsiniz.';

  @override
  String get moduleOrderPendingExplanation =>
      'Onaya gönderildi. Onaylanana veya reddedilene kadar düzenleme kapalıdır.';

  @override
  String get moduleOrderApprovedExplanation =>
      'Sipariş taslağı onaylandı. Bu kayıt KartVizyon içindeki onaylı satış kaydıdır.';

  @override
  String get moduleOrderRejectedExplanation =>
      'Sipariş taslağı reddedildi. Gerekli düzeltmeleri yapıp yeniden gönderebilirsiniz.';

  @override
  String get moduleCouldNotLoad =>
      'Bu bölüm yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get moduleDecisionReason => 'Neden';

  @override
  String get companyInfo => 'Firma bilgileri';

  @override
  String get editWorkspaceCompanyName =>
      'Çalışma alanınızın firma adını düzenleyin';

  @override
  String get premiumSubscription => 'Premium ve abonelik';

  @override
  String get viewPlanManagePurchase =>
      'Planınızı görüntüleyin veya mağaza satın alımını yönetin';

  @override
  String get locationPrivacy => 'Konum gizliliği';

  @override
  String get locationPrivacyBody =>
      'Sürekli GPS takibi yapılmaz. Konum yalnızca siz istediğinizde ya da saha modunu başlattığınızda alınır; saha modu çalışırken bunu gizlemez ve akşam kendiliğinden kapanır.';

  @override
  String get audioRetention => 'Ses saklama';

  @override
  String get audioRetentionBody =>
      'Sesli not yalnızca metne çevrilmek için gönderilir. Ham kayıt yöneticilere açılmaz ve 30 gün sonra sunucudan silinir.';

  @override
  String get privacyRights => 'KVKK ve veri hakları';

  @override
  String get privacyDataCenter => 'Aydınlatma, dışa aktarma ve silme merkezi';

  @override
  String get privacyScreenTitle => 'KVKK ve veri hakları';

  @override
  String get privacyIntro =>
      'Rıza tercihlerinizi yönetebilir, verilerinizin bir kopyasını veya silinmesini talep edebilirsiniz.';

  @override
  String get privacyConsentAnalytics => 'Ürün analitiği';

  @override
  String get privacyConsentAiProcessing => 'Notların yapay zekâ ile işlenmesi';

  @override
  String get privacyConsentEmailNotifications => 'E-posta bildirimleri';

  @override
  String get privacyDeleteConfirmTitle => 'Hesabımı kalıcı olarak sil';

  @override
  String get privacyDeleteConfirmBody =>
      'Bu talep, hesabınızı, müşteri ve ziyaret kayıtlarınızı, görevlerinizi ve diğer kişisel verilerinizi işlem tamamlandığında kalıcı olarak siler. Bu işlem geri alınamaz.';

  @override
  String get privacyDeleteAccountPermanently => 'Hesabımı kalıcı olarak sil';

  @override
  String get privacyExportRequestOpen => 'Dışa aktarma talebi açık';

  @override
  String get privacyDeletionRequestOpen => 'Hesap silme talebi açık';

  @override
  String get privacyExportMyData => 'Verilerimin kopyasını iste';

  @override
  String get privacyMyRequests => 'Taleplerim';

  @override
  String get privacyExportRequestKind => 'Veri dışa aktarma';

  @override
  String get privacyDeletionRequestKind => 'Hesap silme';

  @override
  String get privacyDownload => 'İndir';

  @override
  String get privacyStatusReceived => 'Alındı ve sıraya girdi';

  @override
  String get privacyStatusProcessing => 'Hazırlanıyor';

  @override
  String get privacyStatusReady => 'Hazır';

  @override
  String get privacyStatusCompleted => 'Tamamlandı';

  @override
  String get privacyStatusFailed => 'Hazırlanamadı';

  @override
  String get privacyStatusRejected => 'Reddedildi';

  @override
  String get privacyStatusUnknown => 'Durum bilgisi yok';

  @override
  String get privacyOpenDeletionRequest =>
      'Hesap silme talebiniz zaten açık. Durumunu Taleplerim bölümünden takip edebilirsiniz.';

  @override
  String get privacyOpenExportRequest =>
      'Dışa aktarma talebiniz zaten açık. Hazır olduğunda Taleplerim bölümünden indirebilirsiniz.';

  @override
  String get privacySignInRequired =>
      'Gizlilik tercihlerini ve veri taleplerini yönetmek için giriş yapın.';

  @override
  String get privacyLoadFailed =>
      'Gizlilik bilgileri yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get privacyConsentUpdateFailed =>
      'Bu tercih güncellenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get privacyRequestFailed =>
      'Talep gönderilemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get privacyDemoRequestUnavailable =>
      'Demo modunda gizlilik talebi oluşturulamaz.';

  @override
  String get privacyDeletionRequestSubmitted =>
      'Hesap silme talebiniz alındı. Kalıcı silme işlemi sıraya alınmıştır; bu mesaj silme işleminin tamamlandığı anlamına gelmez.';

  @override
  String get privacyRequestReceived => 'Talebiniz alındı.';

  @override
  String get privacyExportDownloadFailed =>
      'Veri dışa aktarma açılamadı. Lütfen biraz sonra yeniden deneyin.';

  @override
  String get privacyRequestRateLimited =>
      'Çok fazla talep gönderildi. Biraz sonra tekrar deneyin.';

  @override
  String get deleteAccount => 'Hesabımı sil';

  @override
  String get permanentlyDeletePersonalData =>
      'Hesabınızı ve kişisel verilerinizi kalıcı olarak silin';

  @override
  String get signOutAllDevices => 'Tüm cihazlardan çıkış';

  @override
  String get appVersion => 'Uygulama sürümü';

  @override
  String get versionLoading => 'Sürüm bilgisi yükleniyor…';

  @override
  String versionBuild(String version, String buildNumber) {
    return 'Sürüm $version · Derleme $buildNumber';
  }

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String greeting(String name) {
    return 'Merhaba $name';
  }

  @override
  String get greetingAnonymous => 'Merhaba';

  @override
  String todaySummaryForCompany(String company) {
    return '$company için bugünün saha özeti';
  }

  @override
  String get completeCompanyDetails => 'Firma bilgilerinizi tamamlayın';

  @override
  String get companyContextForSummary =>
      'Saha özetleri şirketinizin bağlamını doğru kullansın.';

  @override
  String get plannedVisit => 'Planlanan ziyaret';

  @override
  String get openVisit => 'Açık ziyaret';

  @override
  String get pendingReview => 'İnceleme bekleyen';

  @override
  String get openFollowUp => 'Açık takip';

  @override
  String get quickActions => 'Hızlı işlemler';

  @override
  String get visitNote => 'Ziyaret notu';

  @override
  String get scanBusinessCard => 'Kartvizit tara';

  @override
  String get sync => 'Eşitleme';

  @override
  String get nextVisit => 'Sıradaki ziyaret';

  @override
  String get viewBriefing => 'Brifingi görüntüle';

  @override
  String get firstCustomer => 'İlk müşterinizi ekleyin';

  @override
  String get addCustomerNextSteps =>
      'Müşteri kaydından sonra ziyaret ve takip oluşturabilirsiniz.';

  @override
  String get loginDescription => 'Saha müşteri hafızanıza güvenli erişim';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get wait => 'Bekleyin…';

  @override
  String get emailSent => 'E-posta gönderildi';

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get resendVerificationEmail => 'Doğrulama e-postasını yeniden gönder';

  @override
  String get existingAccount => 'Hesabım var';

  @override
  String get createNewAccount => 'Yeni hesap oluştur';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get continueWithGoogle => 'Google ile devam et';

  @override
  String get continueWithApple => 'Apple ile devam et';

  @override
  String get demoConfiguration =>
      'Demo yapılandırması etkin. Giriş yap düğmesi yerel önizlemeyi açar.';

  @override
  String get loginIncomplete =>
      'Giriş tamamlanmadı. Dilerseniz tekrar deneyin.';

  @override
  String get authFailed => 'Giriş tamamlanamadı. Lütfen tekrar deneyin.';

  @override
  String get authLinkExpired =>
      'Bağlantının süresi dolmuş veya daha önce kullanılmış. Aşağıdan yeni bir bağlantı isteyin.';

  @override
  String get authLinkWrongDevice =>
      'Bu bağlantı başka bir cihazda veya daha önce kullanılmış. Girişi bu cihazdan yeniden başlatın.';

  @override
  String get emailInvalid => 'Geçerli bir e-posta adresi girin.';

  @override
  String get passwordTooShort => 'Şifreniz en az 6 karakter olmalıdır.';

  @override
  String get accountCreating => 'Hesabınız oluşturuluyor…';

  @override
  String get signingIn => 'Giriş yapılıyor…';

  @override
  String get accountMayExist =>
      'Bu e-posta zaten kayıtlı olabilir. “Hesabım var” ile giriş yapın veya şifrenizi yenileyin.';

  @override
  String get confirmAccountEmail =>
      'Hesabınız oluşturuldu. E-postanıza gönderdiğimiz bağlantıya dokunun; doğrulama tamamlanınca uygulama otomatik açılır.';

  @override
  String get networkOperationFailed =>
      'İşlem tamamlanamadı. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get enterEmailFirst => 'Önce e-posta adresinizi girin.';

  @override
  String get passwordResetSent => 'Şifre yenileme e-postası gönderildi.';

  @override
  String get loginScreenCouldNotOpen =>
      'Giriş ekranı açılamadı. Lütfen tekrar deneyin.';

  @override
  String get verificationResent =>
      'Yeni doğrulama e-postası gönderildi. En son gelen e-postadaki bağlantıyı kullanın.';

  @override
  String get googleAuthOpening => 'Google güvenli giriş ekranı açılıyor…';

  @override
  String get appleAuthOpening => 'Apple güvenli giriş ekranı açılıyor…';

  @override
  String get cameraTakePhoto => 'Kamera ile çek';

  @override
  String get chooseFromGallery => 'Galeriden seç';

  @override
  String get cameraPermissionOptional => 'Kamera izni vermek istemiyorsanız';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get save => 'Kaydet';

  @override
  String get imagePickFailed =>
      'Görsel seçilemedi. Kamera veya fotoğraf izni verilmemiş olabilir.';

  @override
  String get scanningBusinessCard => 'Kartvizit okunuyor…';

  @override
  String get cardScanFailed => 'Kartvizit okunamadı. Tekrar deneyin.';

  @override
  String get customerSaved => 'Müşteri başarıyla kaydedildi.';

  @override
  String get customerDetailTitle => 'Müşteri kartı';

  @override
  String get customerLoadFailed =>
      'Müşteri yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String customerContactsCount(int count) {
    return 'İlgili kişiler ($count)';
  }

  @override
  String get addContact => 'Kişi ekle';

  @override
  String get archiveCustomerAction => 'Müşteriyi arşivle';

  @override
  String get editCustomer => 'Müşteriyi düzenle';

  @override
  String get openVisitBriefing => 'Ziyaret brifingini aç';

  @override
  String get locationPinnedAtSite => 'Konum sahada sabitlendi';

  @override
  String get locationEstimatedFromAddress => 'Konum adresten tahmin edildi';

  @override
  String get customerLocationMissing =>
      'Konum kayıtlı değil — yakınlık hatırlatması çalışmaz';

  @override
  String get updateCustomerLocation => 'Konumu buradan güncelle';

  @override
  String get pinCustomerLocation => 'Konumu buraya sabitle';

  @override
  String get pinCustomerLocationTitle => 'Konumu buraya sabitle';

  @override
  String pinCustomerLocationBody(String company) {
    return 'Şu anki konumunuz $company kaydına müşterinin konumu olarak yazılacak. Böylece saha modunda yakına geldiğinizde hatırlatma alabilirsiniz.';
  }

  @override
  String get pinCustomerLocationPrivacy =>
      'Yalnızca müşterinin konumu saklanır; sizin hareketleriniz kaydedilmez.';

  @override
  String get locationPermissionDeniedForCustomer =>
      'Konum izni verilmedi. Müşteri konumu kaydedilmedi.';

  @override
  String get customerLocationPinned => 'Müşteri konumu sabitlendi.';

  @override
  String get customerLocationPinFailed =>
      'Müşteri konumu kaydedilemedi. Tekrar deneyin.';

  @override
  String get customerUpdated => 'Müşteri bilgileri güncellendi.';

  @override
  String get customerUpdateFailed => 'Müşteri güncellenemedi. Tekrar deneyin.';

  @override
  String get contactAdded => 'İlgili kişi eklendi.';

  @override
  String get contactUpdated => 'İlgili kişi güncellendi.';

  @override
  String get contactSaveGenericFailed =>
      'İlgili kişi kaydedilemedi. Tekrar deneyin.';

  @override
  String get customerArchiveFailed => 'Müşteri arşivlenemedi. Tekrar deneyin.';

  @override
  String archiveCustomerTitle(String company) {
    return '$company arşivlensin mi?';
  }

  @override
  String get archiveCustomerIntro => 'Bu müşteriye bağlı kayıtlar:';

  @override
  String archiveContactsCount(int count) {
    return '$count ilgili kişi';
  }

  @override
  String archiveVisitsCount(int count) {
    return '$count ziyaret';
  }

  @override
  String archiveOpenTasksCount(int count) {
    return '$count açık görev';
  }

  @override
  String archiveOpportunitiesCount(int count) {
    return '$count fırsat';
  }

  @override
  String archiveOrdersCount(int count) {
    return '$count sipariş taslağı';
  }

  @override
  String archiveDocumentsCount(int count) {
    return '$count belge';
  }

  @override
  String get archivePreservesData =>
      'Bu kayıtlar silinmez. Müşteri etkin müşteri listenizden kaldırılır.';

  @override
  String get archive => 'Arşivle';

  @override
  String get newContact => 'Yeni ilgili kişi';

  @override
  String get editContact => 'İlgili kişiyi düzenle';

  @override
  String get firstNameRequired => 'Ad gerekli.';

  @override
  String get contactSaveFailed =>
      'Firma kaydedildi ancak ilgili kişi kaydedilemedi. Firma profilinden yeniden deneyebilirsiniz.';

  @override
  String get customers => 'Müşteriler';

  @override
  String get manuallyAddCustomer => 'Manuel müşteri ekle';

  @override
  String get customerSearchHint => 'Firma, adres veya e-posta ara';

  @override
  String get clearSearch => 'Aramayı temizle';

  @override
  String get noCustomers => 'Henüz müşteri yok';

  @override
  String get noMatchingCustomers => 'Aramaya uygun müşteri yok';

  @override
  String get noCustomersDescription =>
      'Bilgileri elle girebilir veya kartvizit tarayabilirsiniz.';

  @override
  String noSearchResults(String query) {
    return '$query için sonuç bulunamadı. Aramayı temizleyip listeye dönebilirsiniz.';
  }

  @override
  String get loadMoreCustomers => 'Daha fazla müşteri yükle';

  @override
  String get addressNotProvided => 'Adres belirtilmedi';

  @override
  String get verifyBusinessCardFields => 'Kartvizit alanlarını doğrulayın';

  @override
  String get companyName => 'Firma adı';

  @override
  String get companyNameRequired => 'Firma adı *';

  @override
  String get companyNameTooShort => 'Firma adı en az 2 karakter olmalı.';

  @override
  String get shortNameField => 'Kısa ad / saha adı';

  @override
  String get shortNameHelp => 'Uzun ticari unvan yerine listelerde görünür.';

  @override
  String get address => 'Adres';

  @override
  String get contactOptional => 'İlgili kişi (isteğe bağlı)';

  @override
  String get firstName => 'Ad';

  @override
  String get lastName => 'Soyad';

  @override
  String get jobTitle => 'Unvan';

  @override
  String get phone => 'Telefon';

  @override
  String get website => 'Web sitesi';

  @override
  String get aiDraftNotSaved =>
      'AI çıktısı siz kaydetmeden veritabanına eklenmez.';

  @override
  String get saveCustomer => 'Müşteriyi kaydet';

  @override
  String get startVisit => 'Yeni ziyaret';

  @override
  String get selectCustomerRequired => 'Müşteri seç *';

  @override
  String get visitPurpose => 'Ziyaret amacı';

  @override
  String get startVisitAction => 'Ziyareti başlat';

  @override
  String get visits => 'Ziyaretler';

  @override
  String get opening => 'Açılıyor…';

  @override
  String get visitQueuedOffline =>
      'Ziyaret çevrimdışı kuyruğa alındı; bağlantı gelince gönderilecek.';

  @override
  String get noVisits => 'Henüz ziyaret yok';

  @override
  String get startFirstVisitPrompt =>
      'İlk ziyaretinizi başlatmak için önce bir müşteri seçin.';

  @override
  String get visit => 'Ziyaret';

  @override
  String get approved => 'Onaylandı';

  @override
  String get review => 'İncele';

  @override
  String get addNote => 'Not ekle';

  @override
  String get briefingTitle => 'Ziyaret brifingi';

  @override
  String get noPreviousVisit => 'Bu müşteriyi henüz ziyaret etmediniz.';

  @override
  String lastApprovedVisit(String since) {
    return 'Son onaylanan ziyaret: $since';
  }

  @override
  String get customerMemoryCard => 'Müşteri hafıza kartı';

  @override
  String get updateRequired => 'Güncellenmeli';

  @override
  String get noApprovedSummary => 'Henüz onaylanmış ziyaret özeti bulunmuyor.';

  @override
  String promisesCount(int count) {
    return 'Verilen sözler ($count)';
  }

  @override
  String get noOpenPromises => 'Bu müşteriye verilmiş açık söz kaydı yok.';

  @override
  String openFollowUpsCount(int count) {
    return 'Açık takipler ($count)';
  }

  @override
  String get noOpenFollowUps => 'Bu müşteri için açık takip bulunmuyor.';

  @override
  String get startVisitAndTakeNote => 'Ziyareti başlat ve not al';

  @override
  String get startingVisit => 'Başlatılıyor…';

  @override
  String get openNavigation => 'Navigasyonu aç';

  @override
  String get today => 'bugün';

  @override
  String get yesterday => 'dün';

  @override
  String daysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String get customerFallback => 'Müşteri';

  @override
  String get promiseFallback => 'Verilen söz';

  @override
  String get taskFallback => 'Görev';

  @override
  String get overdue => 'gecikti';

  @override
  String dueDateLabel(Object date) {
    return 'Son tarih $date';
  }

  @override
  String get aiSummaryNotFound => 'İncelenecek AI özeti bulunamadı.';

  @override
  String get summaryMinLength => 'Özet en az 10 karakter olmalıdır.';

  @override
  String get visitApprovedMemory => 'Ziyaret onaylandı ve hafızaya eklendi.';

  @override
  String visitApprovedTasks(int count) {
    return 'Ziyaret onaylandı. Seçtiğiniz $count takip Görevler ekranına eklendi.';
  }

  @override
  String get rejectSummaryDialogTitle => 'AI özeti reddedilsin mi?';

  @override
  String get rejectSummaryDialogBody =>
      'Ziyaret kurumsal hafızaya eklenmez ve takip görevi oluşmaz. Notunuz ve ses kaydınız silinmez.';

  @override
  String get reject => 'Reddet';

  @override
  String get summaryRejected => 'Özet reddedildi; hafızaya eklenmedi.';

  @override
  String get summaryRejectFailed => 'Reddedilemedi. Tekrar deneyin.';

  @override
  String get reviewAiSummary => 'AI özetini incele';

  @override
  String get customerVisit => 'Müşteri ziyareti';

  @override
  String get aiOutputApprovalNotice =>
      'AI çıktısı siz onaylamadan kurumsal hafızaya eklenmez.';

  @override
  String get sensitiveDataWarning =>
      'Hassas kişisel veri olasılığı var. Onaylamadan önce özeti düzenleyin.';

  @override
  String get visitSummary => 'Ziyaret özeti';

  @override
  String get outcome => 'Sonuç';

  @override
  String get positive => 'Olumlu';

  @override
  String get neutral => 'Nötr';

  @override
  String get negative => 'Olumsuz';

  @override
  String get unknown => 'Belirsiz';

  @override
  String get suggestedFollowUps => 'Önerilen takipler';

  @override
  String get noFollowUpsFound => 'Takip önerisi bulunamadı.';

  @override
  String get followUpFallback => 'Takip';

  @override
  String get transcript => 'Kayıt metni';

  @override
  String get compareSummarySource => 'Özeti kaynağıyla karşılaştırın';

  @override
  String get approving => 'Onaylanıyor…';

  @override
  String get approveAndAddMemory => 'Onayla ve hafızaya ekle';

  @override
  String get rejectAiSummary => 'Özeti reddet';

  @override
  String dueDatePrefix(String date) {
    return 'Son tarih $date';
  }

  @override
  String get undated => 'Tarihsiz';

  @override
  String get nearbyCustomersTitle => 'Yakındaki müşteriler';

  @override
  String get mapLocationPrivacy =>
      'Sürekli GPS kullanılmaz. Konum yalnızca siz istediğinizde yakın ve gecikmiş müşterileri hesaplamak için alınır.';

  @override
  String get findingNearby => 'Hesaplanıyor…';

  @override
  String get findNearbyCustomers => 'Yakınımdakileri bul';

  @override
  String get locationServiceOff =>
      'Konum servisi kapalı. Cihaz ayarlarından açın.';

  @override
  String get nearbyLocationPermission =>
      'Yakındaki müşterileri göstermek için konum izni gerekiyor. Müşterilerinizi konum kullanmadan da arayabilirsiniz.';

  @override
  String get locationUnavailable =>
      'Konum alınamadı. Açık alanda tekrar deneyin ya da müşteri kartından \"konumu buraya sabitle\" seçeneğini kullanın.';

  @override
  String get locationSettingsRetry =>
      'Konum alınamadı. Konum ayarlarınızı kontrol edip tekrar deneyin.';

  @override
  String get serverNotConfigured =>
      'Sunucu bağlantısı yapılandırılmadığı için müşteri aranamadı.';

  @override
  String get locationNotStored =>
      'Konum yalnızca aday hesaplamak için kullanıldı; sunucuda saklanmadı.';

  @override
  String get nearbyFetchFailed =>
      'Yakındaki müşteriler getirilemedi. Tekrar deneyin.';

  @override
  String get noCustomersInArea => 'Bu bölgede kayıtlı müşteri bulunamadı.';

  @override
  String get companyFallback => 'Firma';

  @override
  String get distanceUnknown => 'Mesafe bilinmiyor';

  @override
  String get visitNever => 'Henüz ziyaret edilmedi';

  @override
  String lastVisitDays(int days) {
    return 'Son ziyaret: $days gün önce';
  }

  @override
  String overdueTaskCount(int count) {
    return '$count geciken görev';
  }

  @override
  String get noOverdueTasks => 'Geciken görev yok';

  @override
  String get briefing => 'Brifing';

  @override
  String get navigation => 'Navigasyon';

  @override
  String get debriefTitle => 'Ziyaret sonrası not';

  @override
  String get debriefPrivacyNotice =>
      'Bu kayıt müşteri görüşmesi değildir. Yalnızca ziyaret sonrası kişisel değerlendirmeniz kaydedilir.';

  @override
  String get noteAndAudioLanguage => 'Not ve ses dili';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'İngilizce';

  @override
  String recordingDuration(String duration) {
    return 'Kayıt sürüyor · $duration';
  }

  @override
  String voiceNoteReady(String duration) {
    return 'Sesli not hazır · $duration';
  }

  @override
  String get debriefDurationHint => '60–90 saniyelik debrief';

  @override
  String get longRecordingWarning =>
      'Kayıt uzuyor. Beş dakikayı aşan notlar gönderilemeyebilir.';

  @override
  String get stopRecording => 'Kaydı bitir';

  @override
  String get recordVoiceNote => 'Sesli not kaydet';

  @override
  String get manualNoteTranscript => 'Manuel not veya transkript';

  @override
  String get notePrompt => 'İhtiyaç, verilen söz ve sonraki adım…';

  @override
  String get sending => 'Gönderiliyor…';

  @override
  String get queueAndSend => 'Güvenli kuyruğa ekle ve gönder';

  @override
  String get microphonePermissionDenied =>
      'Mikrofon izni verilmedi. Metinle devam edebilirsiniz.';

  @override
  String get accessExpiredDraftSaved =>
      'Erişim süreniz doldu. Ses taslağınız korunur.';

  @override
  String get debriefQueuedOffline =>
      'Not cihazda güvenle kuyruklandı. Bağlantı gelince gönderilecek; durumunu Eşitleme merkezinden izleyebilirsiniz.';

  @override
  String get backToVisits => 'Ziyaretlere dön';

  @override
  String get deleteVoiceNote => 'Sesli notu sil';

  @override
  String get reopenTaskQuestion => 'Görev yeniden açılsın mı?';

  @override
  String taskCompletedWarning(String title) {
    return '“$title” tamamlandı olarak işaretli. Geri alırsanız tamamlanma zamanı silinir.';
  }

  @override
  String get reopen => 'Yeniden aç';

  @override
  String get newTask => 'Yeni görev';

  @override
  String get taskRequired => 'Görev *';

  @override
  String get selectCustomerOptional => 'Müşteri seç (isteğe bağlı)';

  @override
  String get removeCustomer => 'Müşteriyi kaldır';

  @override
  String get dueDateOptional => 'Bitiş tarihi (isteğe bağlı)';

  @override
  String get removeDate => 'Tarihi kaldır';

  @override
  String get taskSaved => 'Görev kaydedildi.';

  @override
  String get taskSaveFailed =>
      'Görev kaydedilemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get taskUpdateFailed => 'Görev güncellenemedi. Tekrar deneyin.';

  @override
  String get taskLoadFailed =>
      'Görevler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get offlineCenterTitle => 'Eşitleme merkezi';

  @override
  String offlineQueuedCount(int count) {
    return 'Bekleyen kayıtlar ($count)';
  }

  @override
  String get offlineStorageNotice =>
      'Taslaklar, oturum açmış kullanıcıya ait cihaz uygulama alanında tutulur.';

  @override
  String get syncNow => 'Şimdi eşitle';

  @override
  String get syncing => 'Eşitleniyor…';

  @override
  String syncResult(int sent, int remaining) {
    return '$sent kayıt gönderildi; $remaining kayıt bekliyor.';
  }

  @override
  String get syncAuthRefreshRequired => 'Oturumunuz yenilenmeli.';

  @override
  String get offlineDraftTitle => 'Çevrimdışı taslak';

  @override
  String get close => 'Kapat';

  @override
  String get offlineAudioDraftHint =>
      'Ses kaydı taslağı. Dinlemek için dışa aktarın.';

  @override
  String get deleteQueuedRecordTitle => 'Bu kayıt silinsin mi?';

  @override
  String get deleteQueuedRecordWarning =>
      'Bu kayıt gönderilmeden silinecek ve geri alınamaz. Varsa ekli sesli not da bu cihazdan kaldırılır.';

  @override
  String get delete => 'Sil';

  @override
  String get recordDeleted => 'Kayıt silindi.';

  @override
  String get syncBlockedStatus => 'Müdahale gerekiyor';

  @override
  String get syncSendingStatus => 'Gönderiliyor';

  @override
  String get syncWaitingStatus => 'Bekliyor';

  @override
  String syncAttemptsCount(String count) {
    return 'Deneme: $count';
  }

  @override
  String syncErrorCode(String code) {
    return 'Hata: $code';
  }

  @override
  String get syncEntityVisitNote => 'Ziyaret notu';

  @override
  String get syncEntityVisit => 'Ziyaret kaydı';

  @override
  String get syncEntityGeneric => 'Çevrimdışı kayıt';

  @override
  String get viewDraft => 'Taslağı görüntüle';

  @override
  String get exportDraft => 'Dışa aktar';

  @override
  String get retrySync => 'Tekrar dene';

  @override
  String get syncErrorWaiting => 'Gönderilmeyi bekliyor';

  @override
  String get syncErrorNetwork =>
      'Bağlantı kurulamadı. Ağ geldiğinde kendiliğinden denenecek.';

  @override
  String get syncErrorAuth => 'Oturum süresi doldu. Çıkıp yeniden giriş yapın.';

  @override
  String get syncErrorAccess =>
      'Etkin abonelik veya kullanılabilir kota gerekli. Taslağınız korunur; abonelik ekranını kontrol edip yeniden deneyebilirsiniz.';

  @override
  String get syncErrorVisitMissing =>
      'Bu notun bağlı olduğu ziyaret bulunamadı. Kaydı silebilirsiniz.';

  @override
  String get syncErrorProcessing =>
      'Bu not sunucuda hâlâ işleniyor. Kısa süre sonra kendiliğinden tamamlanacak.';

  @override
  String get syncErrorAudioTooLarge =>
      'Ses kaydı 25 MB sınırını aşıyor. Daha kısa bir not kaydedin ya da bu taslağı silin.';

  @override
  String get syncErrorAudioUnsupported =>
      'Ses biçimi sunucu tarafından kabul edilmedi. Taslağı silip yeniden kaydedin.';

  @override
  String get syncErrorRateLimit =>
      'Çok fazla istek gönderildi. Biraz sonra tekrar deneyin.';

  @override
  String get syncErrorUnsupportedEntity =>
      'Bu kayıt türü uygulamanın bu sürümü tarafından gönderilemiyor.';

  @override
  String get syncErrorServer =>
      'Sunucu şu an yanıt veremiyor. Kısa süre sonra tekrar denenecek.';

  @override
  String get syncErrorGeneric =>
      'Kayıt gönderilemedi. Tekrar deneyebilir ya da kaydı silebilirsiniz.';

  @override
  String get syncBlockedOne =>
      '1 kayıt gönderilemiyor. Aşağıdan tekrar deneyin ya da silin.';

  @override
  String syncBlockedCount(int count) {
    return '$count kayıt gönderilemiyor. Aşağıdan tekrar deneyin ya da silin.';
  }

  @override
  String get noTasksPrompt =>
      'Henüz görev yok. Yeni görev düğmesiyle ilk takibinizi oluşturun.';

  @override
  String openTasksCount(int count) {
    return 'Açık görevler ($count)';
  }

  @override
  String completedTasksCount(int count) {
    return 'Tamamlananlar ($count)';
  }

  @override
  String get generalTask => 'Genel görev';

  @override
  String get fieldModeOn => 'Saha modu açık';

  @override
  String get fieldModeOff => 'Saha modu kapalı';

  @override
  String fieldModeActiveDescription(String time) {
    return 'Yakınından geçtiğiniz müşteriler kontrol ediliyor. $time itibarıyla kendiliğinden kapanır.';
  }

  @override
  String get fieldModeInactiveDescription =>
      'Açtığınızda yakınınızdaki müşterileri ve onları en son ne zaman ziyaret ettiğinizi hatırlatır. Konumunuz kaydedilmez; saha modu kapalıyken konum kontrolü yapılmaz.';

  @override
  String get startFieldMode => 'Saha modunu başlat';

  @override
  String get stopFieldMode => 'Saha modunu bitir';

  @override
  String get fieldModeStopped => 'Saha modu kapatıldı.';

  @override
  String get fieldModeExpired =>
      'Saha modu oturum süresi dolduğu için kapandı.';

  @override
  String get fieldModeWorkspaceChanged =>
      'Çalışma alanı değiştiği için saha modu kapatıldı.';

  @override
  String get fieldModeLocationPermission =>
      'Konum izni verilmedi. Saha modu yerine Harita ekranından “Yakınımdakileri bul” diyebilirsiniz.';

  @override
  String get fieldModeAfterHours =>
      'Saha modu saat 21.00’den sonra başlatılamaz. Yarın çalışma saatinde yeniden deneyin.';

  @override
  String get fieldModeNotificationPermission =>
      'Bildirim izni verilmedi; saha modu hatırlatma gönderemez.';

  @override
  String get fieldModeLocationUnavailable =>
      'Konum alınamadı. Konum ayarlarınızı kontrol edip yeniden deneyin.';

  @override
  String get fieldModeSessionExpired =>
      'Oturumunuz sona erdi. Yeniden giriş yapın.';

  @override
  String get fieldModeAccessRequired =>
      'Saha modunu kullanmak için etkin bir abonelik gerekir.';

  @override
  String get fieldModeStartFailed =>
      'Saha modu başlatılamadı. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get fieldModeLocationCheckFailed =>
      'Konum alınamadı. Konum iznini ve GPS ayarını kontrol edin.';

  @override
  String get nearbyCustomersUpdateFailed =>
      'Yakındaki müşteriler güncellenemedi. Bağlantınızı kontrol edin.';

  @override
  String get fieldModeReminderTitle => 'Yakındaki müşteri';

  @override
  String get fieldModeNotificationChannel => 'Saha modu';

  @override
  String get fieldModeNotificationDescription =>
      'Saha modu açıkken yakınınızdaki müşteriyi hatırlatır.';

  @override
  String get fieldModeForegroundTitle => 'KartVizyon saha modu açık';

  @override
  String get fieldModeForegroundText =>
      'Yakınınızdaki müşterileri hatırlatıyor. Durdurmak için dokunun.';

  @override
  String distanceAway(String distance) {
    return '$distance uzakta';
  }

  @override
  String lastVisitedDays(int days) {
    return 'Son ziyaret $days gün önce';
  }

  @override
  String get notVisitedYet => 'Henüz ziyaret edilmedi';

  @override
  String overdueFollowUpCount(int count) {
    return '$count geciken takip';
  }

  @override
  String get moduleNewProductDialogTitle => 'Yeni ürün';

  @override
  String get moduleStockCodeRequired => 'Stok kodu *';

  @override
  String get moduleProductNameRequired => 'Ürün adı *';

  @override
  String get moduleListPriceTryRequired => 'Liste fiyatı (TRY) *';

  @override
  String get moduleAdd => 'Ekle';

  @override
  String get moduleCaptureDocument => 'Belgeyi fotoğraflayın';

  @override
  String get moduleChooseDocumentImage => 'Galeriden görsel seçin';

  @override
  String get moduleFieldFormFallback => 'Saha formu';

  @override
  String get moduleFieldRequired => 'Bu alan zorunlu.';

  @override
  String get moduleSend => 'Gönder';

  @override
  String get moduleOrderRejectTitle => 'Sipariş taslağını reddet';

  @override
  String get moduleRejectionReasonRequired => 'Red nedeni *';

  @override
  String get moduleRejectionReasonExample => 'Örn. Fiyat güncellenmeli';

  @override
  String get moduleSendForApproval => 'Onaya gönder';

  @override
  String get moduleApprove => 'Onayla';

  @override
  String get moduleReject => 'Reddet';

  @override
  String get customerPickerTitle => 'Müşteri seç';

  @override
  String get customerPickerClose => 'Kapat';

  @override
  String get customerPickerSearch => 'Kısa ad, firma, adres veya e-posta ara';

  @override
  String get customerPickerNone => 'Müşteri seçmeden devam et';

  @override
  String get customerPickerEmpty => 'Aramaya uygun müşteri bulunamadı.';

  @override
  String get customerPickerRetry => 'Tekrar dene';

  @override
  String get customerPickerLoadFailed =>
      'Müşteriler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get visitPlanTitle => 'Ziyaret planla';

  @override
  String get visitPlanCustomer => 'Müşteri';

  @override
  String get visitPlanCustomerRequired => 'Müşteri seçin.';

  @override
  String get visitPlanCustomerMissingSemantics =>
      'Müşteri seçilmedi, zorunlu alan';

  @override
  String visitPlanCustomerSelectedSemantics(Object name) {
    return 'Seçili müşteri $name';
  }

  @override
  String get visitPlanCustomerSelect => 'Müşteri seç *';

  @override
  String get visitPlanFutureStart => 'Gelecekte bir başlangıç seçin.';

  @override
  String get visitPlanOfflineQueued =>
      'Planlı ziyaret çevrimdışı kuyruğa alındı. Hatırlatmalar senkronizasyondan sonra oluşturulur.';

  @override
  String get visitPlanType => 'Ziyaret türü';

  @override
  String get visitPlanTypeSalesMeeting => 'Satış görüşmesi';

  @override
  String get visitPlanTypeQuoteFollowUp => 'Teklif takibi';

  @override
  String get visitPlanTypeOrderFollowUp => 'Sipariş takibi';

  @override
  String get visitPlanTypeIntroduction => 'Tanışma';

  @override
  String get visitPlanTypeTechnical => 'Teknik görüşme';

  @override
  String get visitPlanTypeOther => 'Diğer';

  @override
  String get visitPlanPurpose => 'Amaç *';

  @override
  String get visitPlanPurposeHint => 'Örn. Yeni teklif üzerinden geçmek';

  @override
  String get visitPlanPurposeMin => 'Amacı en az 2 karakter yazın.';

  @override
  String get visitPlanDateTime => 'Tarih ve saat';

  @override
  String get visitPlanDuration => 'Süre';

  @override
  String get visitPlanReminderTitle => 'Genel ziyaret hatırlatmaları';

  @override
  String get visitPlanReminderBody =>
      'Bildirim Merkezi ayarınız açıksa 1 gün ve 2 saat önce hatırlatma gönderilir.';

  @override
  String get visitPlanNote => 'Planlama notu';

  @override
  String get visitPlanNoteHint => 'Görüşme öncesi kısa hazırlık notu';

  @override
  String get visitPlanNoteHelper =>
      'Ziyaret sonrası değerlendirme notundan ayrıdır.';

  @override
  String visitPlanSelectedSummary(Object type, Object duration) {
    return 'Seçim: $type · $duration';
  }

  @override
  String visitPlanDurationMinutes(int count) {
    return '$count dk';
  }

  @override
  String get visitPlanDurationHour => '1 saat';

  @override
  String get visitPlanDurationHourHalf => '1 saat 30 dk';

  @override
  String get visitPlanDurationTwoHours => '2 saat';

  @override
  String get visitPlanSubmit => 'Ziyareti planla';

  @override
  String get visitPlanSubscriptionRequired => 'Abonelik gerekli';

  @override
  String get visitPlanSaveFailed =>
      'Ziyaret planlanamadı. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get companyIdentityOnboardingTitle => 'Başlamadan önce';

  @override
  String get companyIdentityTitle => 'Firma bilgileri';

  @override
  String get companyIdentityIntro =>
      'Sizi ve temsil ettiğiniz firmayı tanıyalım.';

  @override
  String get companyIdentityName => 'Ad Soyad';

  @override
  String get companyIdentityCompany => 'Firma adı';

  @override
  String get companyIdentityNameTooShort => 'Ad Soyad en az 2 karakter olmalı.';

  @override
  String get companyIdentityCompanyTooShort =>
      'Firma adı en az 2 karakter olmalı.';

  @override
  String get companyIdentitySaveFailed =>
      'Firma bilgileri kaydedilemedi. Tekrar deneyin.';

  @override
  String get companyIdentityReadOnly =>
      'Salt okunur erişimde firma adı değiştirilemez.';

  @override
  String get companyIdentitySaving => 'Kaydediliyor…';

  @override
  String get companyIdentitySave => 'Kaydet';

  @override
  String get companyIdentitySkip => 'Şimdilik geç';

  @override
  String get opportunityEditTitle => 'Fırsatı düzenle';

  @override
  String get opportunityNewTitle => 'Yeni fırsat';

  @override
  String get opportunityName => 'Fırsat adı *';

  @override
  String get opportunityNameTooShort => 'Fırsat adını en az 2 karakter yazın.';

  @override
  String get opportunityCustomerSelect => 'Müşteri seç *';

  @override
  String get opportunityCustomerRequired => 'Müşteri seçin.';

  @override
  String get opportunityEstimatedValue => 'Tahmini değer';

  @override
  String get opportunityInvalidAmount => 'Geçerli bir tutar yazın.';

  @override
  String get opportunityNegativeAmount => 'Tutar negatif olamaz.';

  @override
  String get opportunityAmountTooHigh => 'Tutar çok yüksek.';

  @override
  String get opportunityCurrency => 'Para birimi';

  @override
  String get opportunityStage => 'Aşama';

  @override
  String get opportunityStageLead => 'Potansiyel';

  @override
  String get opportunityStageQualified => 'Nitelikli';

  @override
  String get opportunityStageProposal => 'Teklif';

  @override
  String get opportunityStageNegotiation => 'Müzakere';

  @override
  String get opportunityStageWon => 'Kazanıldı';

  @override
  String get opportunityStageLost => 'Kaybedildi';

  @override
  String get opportunityWinProbability => 'Kazanma olasılığı';

  @override
  String get opportunityExpectedCloseChoose => 'Tahmini kapanış tarihi seç';

  @override
  String opportunityExpectedClose(Object date) {
    return 'Tahmini kapanış: $date';
  }

  @override
  String get opportunityRemoveDate => 'Tarihi kaldır';

  @override
  String get opportunityCompetitor => 'Rakip';

  @override
  String get opportunityOwner => 'Sorumlu';

  @override
  String get opportunityLossReason => 'Kaybetme nedeni *';

  @override
  String get opportunityLossReasonRequired => 'Kaybetme nedenini yazın.';

  @override
  String get opportunityModelNotice =>
      'Not ve sonraki adım alanları mevcut fırsat modelinde bulunmadığı için bu sürümde eklenmedi.';

  @override
  String get opportunityNetworkError =>
      'Fırsat kaydedilemedi. Form bilgileriniz korunuyor.';

  @override
  String get opportunitySave => 'Kaydet';

  @override
  String get opportunitySaving => 'Kaydediliyor…';

  @override
  String get opportunityUserFallback => 'Kullanıcı';

  @override
  String get opportunityMe => 'Ben';

  @override
  String get formTemplateTitle => 'Yeni saha formu';

  @override
  String get formTemplateIntro =>
      'Mağaza kontrolü, rakip analizi, servis kontrolü veya özel ziyaret kontrol listeleri oluşturun.';

  @override
  String get formTemplateName => 'Form adı *';

  @override
  String get formTemplateNameRequired => 'Form adını yazın.';

  @override
  String get formTemplateDescription => 'Açıklama';

  @override
  String get formTemplateFields => 'Alanlar';

  @override
  String get formTemplateRequired => 'Zorunlu';

  @override
  String get formTemplateRemoveField => 'Alanı kaldır';

  @override
  String get formTemplateAddField => 'Alan ekle';

  @override
  String get formTemplateNeedsField => 'En az bir alan ekleyin.';

  @override
  String get formTemplateCreate => 'Formu oluştur';

  @override
  String get formTemplateCreating => 'Oluşturuluyor…';

  @override
  String get formTemplateSaveFailed =>
      'Form kaydedilemedi. Girdileriniz korunuyor.';

  @override
  String get formTemplateAddFieldTitle => 'Alan ekle';

  @override
  String get formTemplateFieldTitle => 'Başlık *';

  @override
  String get formTemplateFieldType => 'Alan türü';

  @override
  String get formTemplateHelpText => 'Yardım metni';

  @override
  String get formTemplateOptions => 'Seçenekler *';

  @override
  String get formTemplateOptionsHint => 'Her satıra bir seçenek';

  @override
  String get formTemplateCancel => 'Vazgeç';

  @override
  String get formTemplateAdd => 'Ekle';

  @override
  String get formTemplateFieldTitleRequired =>
      'En az 2 karakterlik bir başlık girin; seçim alanlarına seçenek ekleyin.';

  @override
  String get formTemplateText => 'Kısa metin';

  @override
  String get formTemplateLongText => 'Uzun metin';

  @override
  String get formTemplateNumber => 'Sayı';

  @override
  String get formTemplateYesNo => 'Evet / Hayır';

  @override
  String get formTemplateSingleSelect => 'Tek seçim';

  @override
  String get formTemplateMultiSelect => 'Çoklu seçim';

  @override
  String get formTemplateDate => 'Tarih';

  @override
  String get orderDraftEditTitle => 'Sipariş taslağını düzenle';

  @override
  String get orderDraftNewTitle => 'Yeni sipariş taslağı';

  @override
  String get orderDraftSelectProduct => 'Ürün seç';

  @override
  String get orderDraftProduct => 'Ürün';

  @override
  String get orderDraftNoProducts => 'Bu para biriminde aktif ürün yok.';

  @override
  String get orderDraftSaveFailed =>
      'Sipariş taslağı kaydedilemedi. Form bilgileriniz korunuyor.';

  @override
  String get orderDraftCustomerSelect => 'Müşteri seç *';

  @override
  String get orderDraftCustomerRequired => 'Müşteri seçin.';

  @override
  String get orderDraftCurrency => 'Para birimi';

  @override
  String get orderDraftItems => 'Kalemler';

  @override
  String get orderDraftAddProduct => 'Ürün ekle';

  @override
  String get orderDraftNeedsProduct => 'En az bir ürün ekleyin.';

  @override
  String get orderDraftChooseDeliveryDate => 'Teslim tarihi seç';

  @override
  String orderDraftDeliveryDate(Object date) {
    return 'Teslim: $date';
  }

  @override
  String get orderDraftNotes => 'Not';

  @override
  String get orderDraftSubtotal => 'Ara toplam';

  @override
  String get orderDraftDiscount => 'İndirim';

  @override
  String get orderDraftTax => 'Vergi';

  @override
  String get orderDraftEstimatedTotal => 'Tahmini toplam';

  @override
  String get orderDraftEstimateNotice =>
      'Önizlemedir; kesin toplam sunucuda hesaplanır.';

  @override
  String get orderDraftSaving => 'Kaydediliyor…';

  @override
  String get orderDraftSave => 'Taslağı kaydet';

  @override
  String get orderDraftRemoveItem => 'Kalemi kaldır';

  @override
  String get orderDraftQuantity => 'Miktar *';

  @override
  String get orderDraftQuantityMustBePositive =>
      'Miktar sıfırdan büyük olmalı.';

  @override
  String orderDraftUnitPrice(Object currency) {
    return 'Birim fiyat ($currency) *';
  }

  @override
  String get orderDraftPriceNegative => 'Fiyat negatif olamaz.';

  @override
  String get orderDraftDiscountPercent => 'İndirim (%)';

  @override
  String get orderDraftDiscountRange => 'İndirim 0–100 arasında olmalı.';

  @override
  String get briefingLoadFailed =>
      'Müşteri brifingi yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get briefingRetry => 'Tekrar dene';

  @override
  String get briefingNeverVisited => 'Bu müşteriyi henüz ziyaret etmediniz.';

  @override
  String get briefingStartVisitFailed =>
      'Ziyaret başlatılamadı. Tekrar deneyin.';

  @override
  String get briefingDefaultVisitPurpose => 'Saha ziyareti';

  @override
  String get moduleActiveCustomer => 'Aktif müşteri';

  @override
  String get moduleApprovedVisit => 'Onaylanmış ziyaret';

  @override
  String get moduleReviewVisit => 'İnceleme bekleyen ziyaret';

  @override
  String get moduleOpenTask => 'Açık görev';

  @override
  String get moduleVisit => 'Ziyaret';

  @override
  String get moduleTask => 'Görev';

  @override
  String get moduleActivity => 'Aktivite';

  @override
  String get moduleNotification => 'Bildirim';

  @override
  String get moduleOpportunity => 'Fırsat';

  @override
  String get moduleProduct => 'Ürün';

  @override
  String get moduleOrderDraft => 'Sipariş taslağı';

  @override
  String get moduleFormTemplate => 'Form şablonu';

  @override
  String get moduleActiveFormTemplate => 'Aktif form şablonu';

  @override
  String get moduleSubmittedForm => 'Gönderilmiş form';

  @override
  String get summaryApprovalFailed =>
      'Ziyaret özeti onaylanamadı. Tekrar deneyin.';

  @override
  String get reviewLoadFailed =>
      'Ziyaret incelemesi yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get visitsLoadFailed =>
      'Ziyaretler yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get homeLoadFailed =>
      'Genel bakış yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get writeAccessRequired =>
      'Bu ziyaret notunu kaydetmek için etkin abonelik gerekli.';

  @override
  String get customerSaveFailed =>
      'Müşteri kaydedilemedi. Form bilgileriniz korunuyor.';
}
