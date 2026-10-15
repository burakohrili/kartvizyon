// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KartVizyon AI';

  @override
  String get summaryTab => 'Summary';

  @override
  String get customersTab => 'Customers';

  @override
  String get visitsTab => 'Visits';

  @override
  String get tasksTab => 'Tasks';

  @override
  String get fieldSummary => 'Today\'s field summary';

  @override
  String get todayTab => 'Today';

  @override
  String get newVisit => 'New visit';

  @override
  String get visitTab => 'Visit';

  @override
  String get menuTab => 'Menu';

  @override
  String get readOnlyBanner =>
      'View only. Start a subscription to create new records.';

  @override
  String get premiumTitle => 'Premium and subscription';

  @override
  String get premiumMonthly => 'Monthly';

  @override
  String get premiumAnnual => 'Annual';

  @override
  String get premiumUnlimited => 'Unlimited';

  @override
  String get sandboxNotice =>
      'Sandbox test environment — separate from your live account.';

  @override
  String get trialPlanName => '14-day trial';

  @override
  String get viewOnlyPlanName => 'View only';

  @override
  String get activePlanName => 'Premium plan';

  @override
  String get organizationPlanName => 'Organization plan';

  @override
  String get organizationPlanManaged =>
      'This workspace plan is managed by your organization administrator.';

  @override
  String paymentsThroughStore(String store) {
    return 'Payment is securely completed through your $store account.';
  }

  @override
  String get premiumTrialDisclosure =>
      'Try it free for 14 days. No card is required. You will not be charged automatically when the trial ends. Start a subscription if you want to continue.';

  @override
  String get premiumTrialQuota =>
      'Trial: 60 scans total · 120 minutes of audio processing · 60 AI summaries.';

  @override
  String get premiumIndividualQuota =>
      'Individual: 125 scans per month · 240 minutes of audio processing · 125 AI summaries. The current price is shown on the purchase button and depends on your store account\'s country or region.';

  @override
  String get premiumTrialLastDay => 'Your trial ends today.';

  @override
  String premiumTrialDaysLeft(int days) {
    return 'Your trial ends in $days days.';
  }

  @override
  String get premiumReadOnlyDisclosure =>
      'View only: your existing records, export, and account deletion remain available. Start a subscription to create records or use AI features.';

  @override
  String premiumUsageScans(String used, String limit) {
    return 'Scans: $used / $limit';
  }

  @override
  String premiumUsageAudio(String used, String limit) {
    return 'Audio processing: $used / $limit minutes';
  }

  @override
  String premiumUsageSummaries(String used, String limit) {
    return 'AI summaries: $used / $limit';
  }

  @override
  String get premiumQuotaPolicy =>
      'A paid subscription unlocks the full quota. Unused usage does not roll over. Exceeding a quota does not trigger an automatic charge.';

  @override
  String get premiumRestorePurchases => 'Restore purchases';

  @override
  String premiumManageSubscription(String store) {
    return 'Manage subscription in $store';
  }

  @override
  String get premiumAutoRenewalDisclosure =>
      'Your subscription renews for the selected period. You can turn off renewal in your store account settings before the current period ends.';

  @override
  String get premiumTermsOfUse => 'Terms of Use';

  @override
  String get premiumPrivacyPolicy => 'Privacy Policy';

  @override
  String get billingLoadFailure => 'Could not load premium information.';

  @override
  String get billingConfigurationUnavailable =>
      'Store billing is not configured yet.';

  @override
  String get billingOfferingUnavailable =>
      'No plans are currently available in this store.';

  @override
  String get billingSessionRequired => 'Please sign in to continue.';

  @override
  String get billingPurchaseCancelled => 'Purchase was cancelled.';

  @override
  String get billingPurchaseFailed =>
      'Purchase could not be completed. Check your store account and try again.';

  @override
  String get billingRestoreFailed =>
      'Purchases could not be restored. Check your store account and try again.';

  @override
  String get billingPurchaseServerPending =>
      'The store completed the purchase, but server verification is pending. Reopen this screen shortly to check.';

  @override
  String get billingRestoreServerPending =>
      'The store completed the restore, but server verification is pending. Try again shortly.';

  @override
  String get billingRestoreNoActivePurchase =>
      'No active purchase was found for this store account to restore.';

  @override
  String get billingPurchaseAwaitingStore =>
      'Purchase received; store confirmation is pending.';

  @override
  String get billingSandboxLiveServerWarning =>
      'Your test purchase is active in the store, but this app is connected to the live server. Sandbox purchases do not grant live access. Use the TestFlight build connected to the test server. Do not purchase again.';

  @override
  String get billingServerAccessPending =>
      'Premium is active in the store, but server access has not been enabled. Restore and access verification are incomplete. Do not purchase again; contact support.';

  @override
  String get billingRestoreSuccess =>
      'Your Premium purchase was restored and server access was verified.';

  @override
  String get billingPurchaseSuccess =>
      'Premium is active and server access was verified.';

  @override
  String get billingSubscriptionManagementUnavailable =>
      'Could not open subscription management. Please try again shortly.';

  @override
  String get trialBannerLastDay =>
      'Your free trial ends today. You will not be charged automatically.';

  @override
  String trialBannerDays(int days) {
    return 'Free trial: $days days left. You will not be charged automatically.';
  }

  @override
  String get subscription => 'Subscription';

  @override
  String get moreTitle => 'More';

  @override
  String get interfaceLanguage => 'App language';

  @override
  String get languageUpdateFailed =>
      'Could not save the language preference. Try again.';

  @override
  String get fieldMap => 'Field map';

  @override
  String get nearbyCustomersRoute => 'Nearby customers and visit routes';

  @override
  String get visitsVoiceNote => 'Visits and voice notes';

  @override
  String get preApprovalPromise =>
      'Not added to shared customer records before your approval';

  @override
  String get syncCenter => 'Sync center';

  @override
  String get pendingRecordsErrors => 'Pending records and errors';

  @override
  String get chooseWorkspace => 'Choose a workspace';

  @override
  String get workspace => 'Workspace';

  @override
  String get workspaceChangeFailed =>
      'Could not switch workspaces. Please try again.';

  @override
  String get switchWorkspace => 'Switch workspace';

  @override
  String get calendar => 'Calendar';

  @override
  String get plannedVisitsDatedTasks => 'Planned visits and dated tasks';

  @override
  String get activity => 'Activity';

  @override
  String get activityHistory => 'Visit, task, opportunity, and order history';

  @override
  String get reportsSummary => 'Reports overview';

  @override
  String get customerVisitTaskMetrics => 'Customer, visit, and task metrics';

  @override
  String get notifications => 'Notifications';

  @override
  String get commentsTasksApprovalEvents =>
      'Comments, tasks, and approval events';

  @override
  String get opportunities => 'Opportunities';

  @override
  String get salesPipelineStages => 'Sales pipeline and stage view';

  @override
  String get productsPrices => 'Products and prices';

  @override
  String get activeProductCatalogPrices =>
      'Active product catalog and list prices';

  @override
  String get orderDrafts => 'Order drafts';

  @override
  String get draftApprovalStatus => 'View draft and approval statuses';

  @override
  String get documents => 'Documents';

  @override
  String get fileSecurityScanning => 'File and security scan status';

  @override
  String get fieldForms => 'Field forms';

  @override
  String get activeTemplatesSubmissions => 'Active templates and submissions';

  @override
  String get moduleNoPlannedVisits => 'No planned visits';

  @override
  String get moduleCalendarEmptyHint =>
      'Planned visits and tasks with due dates appear here. Use the button to plan a visit.';

  @override
  String get moduleNoApprovedVisits => 'No approved visits yet';

  @override
  String get moduleActivityEmptyHint =>
      'Visits you approve appear here. Approve a visit summary to see the first record.';

  @override
  String get moduleNoReportData => 'No records to show metrics yet';

  @override
  String get moduleReportsEmptyHint =>
      'Customer, visit, and task counts appear here. Add a customer and record a visit to populate metrics.';

  @override
  String get moduleNoNotifications => 'No notifications';

  @override
  String get moduleNotificationsEmptyHint =>
      'Upcoming visits, overdue tasks, and Field Mode reminders will appear here.';

  @override
  String get moduleNoOpportunities => 'No opportunity records';

  @override
  String get moduleOpportunitiesEmptyHint =>
      'Create an opportunity here and update its sales stage by opening the record.';

  @override
  String get moduleNoProducts => 'No products in the catalog';

  @override
  String get moduleProductsEmptyHint =>
      'Active products and list prices appear here. You can add products to the catalog from the mobile app.';

  @override
  String get moduleNoOrderDrafts => 'No order drafts';

  @override
  String get moduleOrdersEmptyHint =>
      'Create an order draft here. Open a record to submit it for approval or finalize it if you have permission.';

  @override
  String get moduleNoDocuments => 'No documents';

  @override
  String get moduleDocumentsEmptyHint =>
      'Uploaded files and malware scan status appear here. Photograph a document to submit it for security scanning.';

  @override
  String get moduleNoActiveForms => 'No active forms';

  @override
  String get moduleFormsEmptyHint =>
      'Create store checks, competitor analyses, service checks, or custom visit checklists and review field responses.';

  @override
  String get moduleNoNewNotifications =>
      'You have no new notifications for now.';

  @override
  String get moduleFilteredOpportunitiesEmpty =>
      'No opportunities match this filter.';

  @override
  String get moduleFilteredOrdersEmpty => 'No orders match this filter.';

  @override
  String get moduleFilteredActivityEmpty => 'No activity matches this filter.';

  @override
  String moduleOpportunityOpenCount(int count) {
    return '$count open opportunities';
  }

  @override
  String get moduleOpportunityOpen => 'Open';

  @override
  String get moduleOpportunityWon => 'Won';

  @override
  String get moduleOpportunityLost => 'Lost';

  @override
  String get moduleAll => 'All';

  @override
  String get moduleOrderApproved => 'Approved';

  @override
  String get moduleOrderRejected => 'Rejected';

  @override
  String get moduleActivityVisits => 'Visits';

  @override
  String get moduleActivityTasks => 'Tasks';

  @override
  String get moduleActivityOpportunities => 'Opportunities';

  @override
  String get moduleActivityOrders => 'Orders';

  @override
  String moduleEstimateClose(String date) {
    return 'Estimated close: $date';
  }

  @override
  String moduleReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String moduleOrderTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String moduleDeliveryDate(String date) {
    return 'Delivery date: $date';
  }

  @override
  String moduleNote(String note) {
    return 'Note: $note';
  }

  @override
  String moduleRejectedBy(String name) {
    return 'Rejected by: $name';
  }

  @override
  String moduleDate(String date) {
    return 'Date: $date';
  }

  @override
  String get moduleEditAndReturnToDraft => 'Edit and return to draft';

  @override
  String get moduleSubmitForApproval => 'Submit for approval';

  @override
  String get moduleMakeDecision => 'Make a decision';

  @override
  String get modulePriceLists => 'Price lists';

  @override
  String get modulePriceListFallback => 'Price list';

  @override
  String get moduleDocumentFallback => 'Document';

  @override
  String get moduleCleanPriceListHint =>
      'You can view PDF price lists after the security scan is complete.';

  @override
  String get moduleNoPriceLists => 'No price lists found.';

  @override
  String get moduleProductCatalog => 'Product catalog';

  @override
  String get moduleNoActiveProducts => 'No active products.';

  @override
  String get moduleOpenDocument => 'Tap to open';

  @override
  String get moduleScanPending =>
      'Security scan in progress; not available yet';

  @override
  String get moduleScanStatusPending => 'Scan pending';

  @override
  String get moduleScanStatusClean => 'Clean';

  @override
  String get moduleScanStatusInfected => 'Malicious content found';

  @override
  String get moduleScanStatusError => 'Scan error';

  @override
  String get moduleScanStatusUnknown => 'Unknown status';

  @override
  String get moduleLoadFailed =>
      'Could not load this section. Check your connection and try again.';

  @override
  String get moduleActionFailed =>
      'Action could not be completed. Please try again.';

  @override
  String get moduleRecordCreated => 'Record created.';

  @override
  String get moduleEdit => 'Edit';

  @override
  String get moduleRefresh => 'Refresh';

  @override
  String get moduleFormSubmitted => 'Form response submitted.';

  @override
  String get modulePreferencesTitle => 'Notification preferences';

  @override
  String get moduleSystemNotificationsDisabled =>
      'System notifications are off. Reminders will still appear in the in-app Notifications screen.';

  @override
  String get moduleVisitReminders => 'Visit reminders';

  @override
  String get moduleTaskReminders => 'Task reminders';

  @override
  String get moduleMorningReminder => 'Morning Field Mode reminder';

  @override
  String get moduleMorningReminderTime =>
      'At 8:30 on days with a planned visit';

  @override
  String get modulePreferencesSaved => 'Notification preferences saved.';

  @override
  String get modulePreferencesFailed =>
      'Could not open or save notification preferences. Please try again.';

  @override
  String get moduleDocumentsFailed =>
      'Could not open the document. Please try again.';

  @override
  String get moduleRegistrationFallback => 'Record';

  @override
  String get moduleCustomerCount => 'Active customers';

  @override
  String get moduleApprovedVisitCount => 'Approved visits';

  @override
  String get moduleReviewVisitCount => 'Visits awaiting review';

  @override
  String get moduleOpenTaskCount => 'Open tasks';

  @override
  String get modulePlanVisit => 'Plan a visit';

  @override
  String get moduleNewOpportunity => 'New opportunity';

  @override
  String get moduleNewProduct => 'New product';

  @override
  String get moduleNewOrderDraft => 'New order draft';

  @override
  String get moduleUploadDocument => 'Upload document';

  @override
  String get moduleNewForm => 'New form';

  @override
  String get moduleStageLead => 'Lead';

  @override
  String get moduleStageQualified => 'Qualified';

  @override
  String get moduleStageProposal => 'Proposal';

  @override
  String get moduleStageNegotiation => 'Negotiation';

  @override
  String get moduleStageWon => 'Won';

  @override
  String get moduleStageLost => 'Lost';

  @override
  String get moduleStageDraft => 'Draft';

  @override
  String get moduleStagePendingApproval => 'Awaiting approval';

  @override
  String get moduleStageApproved => 'Approved';

  @override
  String get moduleStageRejected => 'Rejected';

  @override
  String get moduleOrderDraftExplanation => 'You can edit this draft.';

  @override
  String get moduleOrderPendingExplanation =>
      'Submitted for approval. Editing is unavailable until it is approved or rejected.';

  @override
  String get moduleOrderApprovedExplanation =>
      'Order draft approved. This is the approved sales record in KartVizyon.';

  @override
  String get moduleOrderRejectedExplanation =>
      'Order draft rejected. Make the necessary changes and submit it again.';

  @override
  String get moduleCouldNotLoad =>
      'Could not load this section. Check your connection and try again.';

  @override
  String get moduleDecisionReason => 'Reason';

  @override
  String get companyInfo => 'Company information';

  @override
  String get editWorkspaceCompanyName => 'Edit your workspace company name';

  @override
  String get premiumSubscription => 'Premium and subscription';

  @override
  String get viewPlanManagePurchase =>
      'View your plan or manage store purchases';

  @override
  String get locationPrivacy => 'Location privacy';

  @override
  String get locationPrivacyBody =>
      'We do not continuously track GPS. Location is accessed only when you request it or start Field Mode. It is not hidden while Field Mode is active, and Field Mode does not turn itself off in the evening.';

  @override
  String get audioRetention => 'Audio retention';

  @override
  String get audioRetentionBody =>
      'Voice notes are sent only for transcription. Raw recordings are not exposed to managers and are deleted from the server after 30 days.';

  @override
  String get privacyRights => 'Privacy and data rights';

  @override
  String get privacyDataCenter =>
      'Privacy notice, data export, and deletion center';

  @override
  String get privacyScreenTitle => 'Privacy and data rights';

  @override
  String get privacyIntro =>
      'Manage consent preferences and request a copy or deletion of your data.';

  @override
  String get privacyConsentAnalytics => 'Product analytics';

  @override
  String get privacyConsentAiProcessing => 'AI processing of notes';

  @override
  String get privacyConsentEmailNotifications => 'Email notifications';

  @override
  String get privacyDeleteConfirmTitle => 'Permanently delete my account';

  @override
  String get privacyDeleteConfirmBody =>
      'This request will permanently delete your account, customer and visit records, tasks, and other personal data after processing. This cannot be undone.';

  @override
  String get privacyDeleteAccountPermanently => 'Permanently delete my account';

  @override
  String get privacyExportRequestOpen => 'Data export request in progress';

  @override
  String get privacyDeletionRequestOpen =>
      'Account deletion request in progress';

  @override
  String get privacyExportMyData => 'Request a copy of my data';

  @override
  String get privacyMyRequests => 'My requests';

  @override
  String get privacyExportRequestKind => 'Data export';

  @override
  String get privacyDeletionRequestKind => 'Account deletion';

  @override
  String get privacyDownload => 'Download';

  @override
  String get privacyStatusReceived => 'Received and queued';

  @override
  String get privacyStatusProcessing => 'Being prepared';

  @override
  String get privacyStatusReady => 'Ready';

  @override
  String get privacyStatusCompleted => 'Completed';

  @override
  String get privacyStatusFailed => 'Could not be prepared';

  @override
  String get privacyStatusRejected => 'Declined';

  @override
  String get privacyStatusUnknown => 'Status unavailable';

  @override
  String get privacyOpenDeletionRequest =>
      'An account deletion request is already open. Track its status in My requests.';

  @override
  String get privacyOpenExportRequest =>
      'A data export request is already open. Download it from My requests when it is ready.';

  @override
  String get privacySignInRequired =>
      'Sign in to manage privacy preferences and data requests.';

  @override
  String get privacyLoadFailed =>
      'Could not load privacy information. Check your connection and try again.';

  @override
  String get privacyConsentUpdateFailed =>
      'Could not update this preference. Check your connection and try again.';

  @override
  String get privacyRequestFailed =>
      'Could not submit the request. Check your connection and try again.';

  @override
  String get privacyDemoRequestUnavailable =>
      'Privacy requests are unavailable in demo mode.';

  @override
  String get privacyDeletionRequestSubmitted =>
      'Your account deletion request was received. Permanent deletion will be processed; this screen does not mean deletion has already completed.';

  @override
  String get privacyRequestReceived => 'Your request was received.';

  @override
  String get privacyExportDownloadFailed =>
      'Could not open the data export. Please try again shortly.';

  @override
  String get privacyRequestRateLimited =>
      'Too many requests. Please try again shortly.';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get permanentlyDeletePersonalData =>
      'Permanently delete your account and personal data';

  @override
  String get signOutAllDevices => 'Sign out of all devices';

  @override
  String get appVersion => 'App version';

  @override
  String get versionLoading => 'Loading version information…';

  @override
  String versionBuild(String version, String buildNumber) {
    return 'Version $version · Build $buildNumber';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String greeting(String name) {
    return 'Hello $name';
  }

  @override
  String get greetingAnonymous => 'Hello';

  @override
  String todaySummaryForCompany(String company) {
    return 'Today\'s field summary for $company';
  }

  @override
  String get completeCompanyDetails => 'Complete your company details';

  @override
  String get companyContextForSummary =>
      'Help field summaries use your company\'s context accurately.';

  @override
  String get plannedVisit => 'Planned visit';

  @override
  String get openVisit => 'Open visit';

  @override
  String get pendingReview => 'Awaiting review';

  @override
  String get openFollowUp => 'Open follow-up';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get visitNote => 'Visit note';

  @override
  String get scanBusinessCard => 'Scan business card';

  @override
  String get sync => 'Sync';

  @override
  String get nextVisit => 'Next visit';

  @override
  String get viewBriefing => 'View briefing';

  @override
  String get firstCustomer => 'Add your first customer';

  @override
  String get addCustomerNextSteps =>
      'After adding a customer, you can create visits and follow-ups.';

  @override
  String get loginDescription => 'Secure access to your field customer memory';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get wait => 'Please wait…';

  @override
  String get emailSent => 'Email sent';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get resendVerificationEmail => 'Resend verification email';

  @override
  String get existingAccount => 'I already have an account';

  @override
  String get createNewAccount => 'Create a new account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get demoConfiguration =>
      'Demo configuration is active. Sign in opens a local preview.';

  @override
  String get loginIncomplete => 'Sign-in was not completed. You can try again.';

  @override
  String get authFailed => 'Could not sign in. Please try again.';

  @override
  String get authLinkExpired =>
      'This link has expired or was already used. Request a new link below.';

  @override
  String get authLinkWrongDevice =>
      'This link was opened on another device or was already used. Restart sign-in on this device.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get passwordTooShort => 'Your password must be at least 6 characters.';

  @override
  String get accountCreating => 'Creating your account…';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get accountMayExist =>
      'This email may already be registered. Sign in with “I already have an account” or reset your password.';

  @override
  String get confirmAccountEmail =>
      'Your account was created. Tap the link we sent to your email; the app will open automatically after verification.';

  @override
  String get networkOperationFailed =>
      'Could not complete the request. Check your connection and try again.';

  @override
  String get enterEmailFirst => 'Enter your email address first.';

  @override
  String get passwordResetSent => 'Password reset email sent.';

  @override
  String get loginScreenCouldNotOpen =>
      'Could not open the sign-in screen. Please try again.';

  @override
  String get verificationResent =>
      'A new verification email was sent. Use the link in the latest email.';

  @override
  String get googleAuthOpening => 'Opening secure Google sign-in…';

  @override
  String get appleAuthOpening => 'Opening secure Apple sign-in…';

  @override
  String get cameraTakePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get cameraPermissionOptional =>
      'If you prefer not to grant camera access';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get imagePickFailed =>
      'Could not select the image. Camera or photo access may not be granted.';

  @override
  String get scanningBusinessCard => 'Reading business card…';

  @override
  String get cardScanFailed =>
      'Could not read the business card. Please try again.';

  @override
  String get customerSaved => 'Customer saved successfully.';

  @override
  String get customerDetailTitle => 'Customer record';

  @override
  String get customerLoadFailed =>
      'Could not load this customer. Check your connection and try again.';

  @override
  String customerContactsCount(int count) {
    return 'Contacts ($count)';
  }

  @override
  String get addContact => 'Add contact';

  @override
  String get archiveCustomerAction => 'Archive customer';

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get openVisitBriefing => 'Open visit briefing';

  @override
  String get locationPinnedAtSite => 'Location was pinned in the field';

  @override
  String get locationEstimatedFromAddress =>
      'Location estimated from the address';

  @override
  String get customerLocationMissing =>
      'No location saved — nearby reminders are unavailable';

  @override
  String get updateCustomerLocation => 'Update location from here';

  @override
  String get pinCustomerLocation => 'Pin location here';

  @override
  String get pinCustomerLocationTitle => 'Pin customer location here';

  @override
  String pinCustomerLocationBody(String company) {
    return 'Your current location will be saved to $company as the customer\'s location. This lets Field Mode remind you when you are nearby.';
  }

  @override
  String get pinCustomerLocationPrivacy =>
      'Only the customer\'s location is saved; your movements are not recorded.';

  @override
  String get locationPermissionDeniedForCustomer =>
      'Location permission was not granted. The customer location was not saved.';

  @override
  String get customerLocationPinned => 'Customer location saved.';

  @override
  String get customerLocationPinFailed =>
      'Could not save the customer location. Please try again.';

  @override
  String get customerUpdated => 'Customer details updated.';

  @override
  String get customerUpdateFailed =>
      'Could not update the customer. Please try again.';

  @override
  String get contactAdded => 'Contact added.';

  @override
  String get contactUpdated => 'Contact updated.';

  @override
  String get contactSaveGenericFailed =>
      'Could not save the contact. Please try again.';

  @override
  String get customerArchiveFailed =>
      'Could not archive the customer. Please try again.';

  @override
  String archiveCustomerTitle(String company) {
    return 'Archive $company?';
  }

  @override
  String get archiveCustomerIntro => 'This customer has:';

  @override
  String archiveContactsCount(int count) {
    return '$count contacts';
  }

  @override
  String archiveVisitsCount(int count) {
    return '$count visits';
  }

  @override
  String archiveOpenTasksCount(int count) {
    return '$count open tasks';
  }

  @override
  String archiveOpportunitiesCount(int count) {
    return '$count opportunities';
  }

  @override
  String archiveOrdersCount(int count) {
    return '$count order drafts';
  }

  @override
  String archiveDocumentsCount(int count) {
    return '$count documents';
  }

  @override
  String get archivePreservesData =>
      'These records will not be deleted. The customer will be removed from your active customer list.';

  @override
  String get archive => 'Archive';

  @override
  String get newContact => 'New contact';

  @override
  String get editContact => 'Edit contact';

  @override
  String get firstNameRequired => 'First name is required.';

  @override
  String get contactSaveFailed =>
      'Company saved, but the contact could not be saved. You can try again from the company profile.';

  @override
  String get customers => 'Customers';

  @override
  String get manuallyAddCustomer => 'Add customer manually';

  @override
  String get customerSearchHint => 'Search company, address, or email';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noCustomers => 'No customers yet';

  @override
  String get noMatchingCustomers => 'No matching customers';

  @override
  String get noCustomersDescription =>
      'Enter the details manually or scan a business card.';

  @override
  String noSearchResults(String query) {
    return 'No results for $query. Clear the search to return to the list.';
  }

  @override
  String get loadMoreCustomers => 'Load more customers';

  @override
  String get addressNotProvided => 'No address provided';

  @override
  String get verifyBusinessCardFields => 'Review business card details';

  @override
  String get companyName => 'Company name';

  @override
  String get companyNameRequired => 'Company name *';

  @override
  String get companyNameTooShort =>
      'Company name must be at least 2 characters.';

  @override
  String get shortNameField => 'Short name / field name';

  @override
  String get shortNameHelp => 'Shown in lists instead of the full legal name.';

  @override
  String get address => 'Address';

  @override
  String get contactOptional => 'Contact (optional)';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get jobTitle => 'Job title';

  @override
  String get phone => 'Phone';

  @override
  String get website => 'Website';

  @override
  String get aiDraftNotSaved =>
      'AI-generated details are not added to the database until you save them.';

  @override
  String get saveCustomer => 'Save customer';

  @override
  String get startVisit => 'New visit';

  @override
  String get selectCustomerRequired => 'Select a customer *';

  @override
  String get visitPurpose => 'Visit purpose';

  @override
  String get startVisitAction => 'Start visit';

  @override
  String get visits => 'Visits';

  @override
  String get opening => 'Opening…';

  @override
  String get visitQueuedOffline =>
      'Visit queued offline and will be sent when you\'re back online.';

  @override
  String get noVisits => 'No visits yet';

  @override
  String get startFirstVisitPrompt =>
      'Choose a customer first to start your first visit.';

  @override
  String get visit => 'Visit';

  @override
  String get approved => 'Approved';

  @override
  String get review => 'Review';

  @override
  String get addNote => 'Add note';

  @override
  String get briefingTitle => 'Visit briefing';

  @override
  String get noPreviousVisit => 'You have not visited this customer yet.';

  @override
  String lastApprovedVisit(String since) {
    return 'Last approved visit: $since';
  }

  @override
  String get customerMemoryCard => 'Customer memory card';

  @override
  String get updateRequired => 'Needs an update';

  @override
  String get noApprovedSummary => 'There is no approved visit summary yet.';

  @override
  String promisesCount(int count) {
    return 'Promises ($count)';
  }

  @override
  String get noOpenPromises => 'There are no open promises for this customer.';

  @override
  String openFollowUpsCount(int count) {
    return 'Open follow-ups ($count)';
  }

  @override
  String get noOpenFollowUps =>
      'There are no open follow-ups for this customer.';

  @override
  String get startVisitAndTakeNote => 'Start visit and take a note';

  @override
  String get startingVisit => 'Starting visit…';

  @override
  String get openNavigation => 'Open navigation';

  @override
  String get today => 'today';

  @override
  String get yesterday => 'yesterday';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get customerFallback => 'Customer';

  @override
  String get promiseFallback => 'Promise';

  @override
  String get taskFallback => 'Task';

  @override
  String get overdue => 'overdue';

  @override
  String dueDateLabel(Object date) {
    return 'Due $date';
  }

  @override
  String get aiSummaryNotFound => 'No AI summary is available to review.';

  @override
  String get summaryMinLength => 'The summary must be at least 10 characters.';

  @override
  String get visitApprovedMemory => 'Visit approved and added to memory.';

  @override
  String visitApprovedTasks(int count) {
    return 'Visit approved. $count selected follow-ups were added to Tasks.';
  }

  @override
  String get rejectSummaryDialogTitle => 'Reject the AI summary?';

  @override
  String get rejectSummaryDialogBody =>
      'The visit will not be added to shared memory and no follow-up tasks will be created. Your note and audio recording will not be deleted.';

  @override
  String get reject => 'Reject';

  @override
  String get summaryRejected => 'Summary rejected; it was not added to memory.';

  @override
  String get summaryRejectFailed =>
      'Could not reject the summary. Please try again.';

  @override
  String get reviewAiSummary => 'Review AI summary';

  @override
  String get customerVisit => 'Customer visit';

  @override
  String get aiOutputApprovalNotice =>
      'AI output is not added to shared memory until you approve it.';

  @override
  String get sensitiveDataWarning =>
      'This may contain sensitive personal data. Edit the summary before approving it.';

  @override
  String get visitSummary => 'Visit summary';

  @override
  String get outcome => 'Outcome';

  @override
  String get positive => 'Positive';

  @override
  String get neutral => 'Neutral';

  @override
  String get negative => 'Negative';

  @override
  String get unknown => 'Unknown';

  @override
  String get suggestedFollowUps => 'Suggested follow-ups';

  @override
  String get noFollowUpsFound => 'No follow-up suggestions were found.';

  @override
  String get followUpFallback => 'Follow-up';

  @override
  String get transcript => 'Transcript';

  @override
  String get compareSummarySource => 'Compare the summary with its source';

  @override
  String get approving => 'Approving…';

  @override
  String get approveAndAddMemory => 'Approve and add to memory';

  @override
  String get rejectAiSummary => 'Reject summary';

  @override
  String dueDatePrefix(String date) {
    return 'Due $date';
  }

  @override
  String get undated => 'No date';

  @override
  String get nearbyCustomersTitle => 'Nearby customers';

  @override
  String get mapLocationPrivacy =>
      'GPS is not used continuously. Your location is accessed only when you ask us to find nearby customers and overdue follow-ups.';

  @override
  String get findingNearby => 'Finding nearby customers…';

  @override
  String get findNearbyCustomers => 'Find nearby customers';

  @override
  String get locationServiceOff =>
      'Location Services are off. Turn them on in your device settings.';

  @override
  String get nearbyLocationPermission =>
      'Location access is needed to find nearby customers. You can still search customers without sharing your location.';

  @override
  String get locationUnavailable =>
      'Could not get your location. Try outdoors or pin the location from a customer record.';

  @override
  String get locationSettingsRetry =>
      'Could not get your location. Check your location settings and try again.';

  @override
  String get serverNotConfigured =>
      'Customers could not be searched because the server connection is not configured.';

  @override
  String get locationNotStored =>
      'Your location was used only to find nearby customers and was not stored on the server.';

  @override
  String get nearbyFetchFailed =>
      'Could not load nearby customers. Please try again.';

  @override
  String get noCustomersInArea => 'No customers are saved in this area.';

  @override
  String get companyFallback => 'Company';

  @override
  String get distanceUnknown => 'Distance unavailable';

  @override
  String get visitNever => 'Not visited yet';

  @override
  String lastVisitDays(int days) {
    return 'Last visit: $days days ago';
  }

  @override
  String overdueTaskCount(int count) {
    return '$count overdue tasks';
  }

  @override
  String get noOverdueTasks => 'No overdue tasks';

  @override
  String get briefing => 'Briefing';

  @override
  String get navigation => 'Navigation';

  @override
  String get debriefTitle => 'Post-visit note';

  @override
  String get debriefPrivacyNotice =>
      'This is not a recording of the customer conversation. Only your personal post-visit reflection is saved.';

  @override
  String get noteAndAudioLanguage => 'Note and audio language';

  @override
  String get turkish => 'Turkish';

  @override
  String get english => 'English';

  @override
  String recordingDuration(String duration) {
    return 'Recording · $duration';
  }

  @override
  String voiceNoteReady(String duration) {
    return 'Voice note ready · $duration';
  }

  @override
  String get debriefDurationHint => '60–90 second debrief';

  @override
  String get longRecordingWarning =>
      'This recording is getting long. Notes over five minutes may fail to upload.';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get recordVoiceNote => 'Record voice note';

  @override
  String get manualNoteTranscript => 'Manual note or transcript';

  @override
  String get notePrompt => 'Needs, commitments, and next steps…';

  @override
  String get sending => 'Sending…';

  @override
  String get queueAndSend => 'Queue securely and send';

  @override
  String get microphonePermissionDenied =>
      'Microphone access was not granted. You can continue with text.';

  @override
  String get accessExpiredDraftSaved =>
      'Your access expired. Your audio draft is preserved.';

  @override
  String get debriefQueuedOffline =>
      'Your note is safely queued on this device. It will be sent when you are online. You can check its status in Sync center.';

  @override
  String get backToVisits => 'Back to visits';

  @override
  String get deleteVoiceNote => 'Delete voice note';

  @override
  String get reopenTaskQuestion => 'Reopen this task?';

  @override
  String taskCompletedWarning(String title) {
    return '“$title” is marked as completed. Reopening it will clear its completion time.';
  }

  @override
  String get reopen => 'Reopen';

  @override
  String get newTask => 'New task';

  @override
  String get taskRequired => 'Task *';

  @override
  String get selectCustomerOptional => 'Choose a customer (optional)';

  @override
  String get removeCustomer => 'Remove customer';

  @override
  String get dueDateOptional => 'Due date (optional)';

  @override
  String get removeDate => 'Remove date';

  @override
  String get taskSaved => 'Task saved.';

  @override
  String get taskSaveFailed =>
      'Could not save the task. Check your connection and try again.';

  @override
  String get taskUpdateFailed => 'Could not update the task. Try again.';

  @override
  String get taskLoadFailed =>
      'Could not load tasks. Check your connection and try again.';

  @override
  String get offlineCenterTitle => 'Sync center';

  @override
  String offlineQueuedCount(int count) {
    return 'Queued records ($count)';
  }

  @override
  String get offlineStorageNotice =>
      'Drafts are kept in the app\'s local data area for the signed-in user.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncing => 'Syncing…';

  @override
  String syncResult(int sent, int remaining) {
    return '$sent records sent; $remaining still waiting.';
  }

  @override
  String get syncAuthRefreshRequired => 'Your session needs to be refreshed.';

  @override
  String get offlineDraftTitle => 'Offline draft';

  @override
  String get close => 'Close';

  @override
  String get offlineAudioDraftHint => 'Audio draft. Export it to listen.';

  @override
  String get deleteQueuedRecordTitle => 'Delete this record?';

  @override
  String get deleteQueuedRecordWarning =>
      'This record will be deleted before it is sent and cannot be recovered. Any attached voice note will also be removed from this device.';

  @override
  String get delete => 'Delete';

  @override
  String get recordDeleted => 'Record deleted.';

  @override
  String get syncBlockedStatus => 'Action required';

  @override
  String get syncSendingStatus => 'Sending';

  @override
  String get syncWaitingStatus => 'Waiting';

  @override
  String syncAttemptsCount(String count) {
    return 'Attempts: $count';
  }

  @override
  String syncErrorCode(String code) {
    return 'Error: $code';
  }

  @override
  String get syncEntityVisitNote => 'Visit note';

  @override
  String get syncEntityVisit => 'Visit record';

  @override
  String get syncEntityGeneric => 'Offline record';

  @override
  String get viewDraft => 'View draft';

  @override
  String get exportDraft => 'Export';

  @override
  String get retrySync => 'Try again';

  @override
  String get syncErrorWaiting => 'Waiting to send';

  @override
  String get syncErrorNetwork =>
      'Could not connect. This will retry automatically when you are back online.';

  @override
  String get syncErrorAuth =>
      'Your session expired. Sign out and sign in again.';

  @override
  String get syncErrorAccess =>
      'An active subscription or available usage quota is required. Your draft is preserved; check your subscription and try again.';

  @override
  String get syncErrorVisitMissing =>
      'The visit linked to this note could not be found. You can delete this record.';

  @override
  String get syncErrorProcessing =>
      'This note is still processing on the server. It should finish automatically shortly.';

  @override
  String get syncErrorAudioTooLarge =>
      'The audio file exceeds the 25 MB limit. Record a shorter note or delete this draft.';

  @override
  String get syncErrorAudioUnsupported =>
      'The server could not accept this audio format. Delete the draft and record it again.';

  @override
  String get syncErrorRateLimit =>
      'Too many requests. Please try again shortly.';

  @override
  String get syncErrorUnsupportedEntity =>
      'This app version cannot send this type of record.';

  @override
  String get syncErrorServer =>
      'The server is unavailable right now. This will retry automatically shortly.';

  @override
  String get syncErrorGeneric =>
      'Could not send this record. Try again or delete it.';

  @override
  String get syncBlockedOne =>
      '1 record could not be sent. Try again or delete it below.';

  @override
  String syncBlockedCount(int count) {
    return '$count records could not be sent. Try again or delete them below.';
  }

  @override
  String get noTasksPrompt =>
      'No tasks yet. Use New task to create your first follow-up.';

  @override
  String openTasksCount(int count) {
    return 'Open tasks ($count)';
  }

  @override
  String completedTasksCount(int count) {
    return 'Completed ($count)';
  }

  @override
  String get generalTask => 'General task';

  @override
  String get fieldModeOn => 'Field Mode is on';

  @override
  String get fieldModeOff => 'Field Mode is off';

  @override
  String fieldModeActiveDescription(String time) {
    return 'Nearby customers are being checked. It will turn off automatically at $time.';
  }

  @override
  String get fieldModeInactiveDescription =>
      'When you turn it on, KartVizyon reminds you about nearby customers and when you last visited them. Your location is not saved; location checks do not run while Field Mode is off.';

  @override
  String get startFieldMode => 'Start Field Mode';

  @override
  String get stopFieldMode => 'Stop Field Mode';

  @override
  String get fieldModeStopped => 'Field Mode stopped.';

  @override
  String get fieldModeExpired =>
      'Field Mode ended because its session expired.';

  @override
  String get fieldModeWorkspaceChanged =>
      'Field Mode stopped because you changed workspaces.';

  @override
  String get fieldModeLocationPermission =>
      'Location permission was not granted. You can use Find nearby customers on the Map screen instead.';

  @override
  String get fieldModeAfterHours =>
      'Field Mode cannot start after 9:00 PM. Try again during working hours tomorrow.';

  @override
  String get fieldModeNotificationPermission =>
      'Notification permission was not granted, so Field Mode cannot send reminders.';

  @override
  String get fieldModeLocationUnavailable =>
      'Could not get your location. Check your location settings and try again.';

  @override
  String get fieldModeSessionExpired => 'Your session expired. Sign in again.';

  @override
  String get fieldModeAccessRequired =>
      'An active subscription is required to use Field Mode.';

  @override
  String get fieldModeStartFailed =>
      'Could not start Field Mode. Check your connection and try again.';

  @override
  String get fieldModeLocationCheckFailed =>
      'Could not check location. Check location access and GPS settings.';

  @override
  String get nearbyCustomersUpdateFailed =>
      'Nearby customers could not be refreshed. Check your connection.';

  @override
  String get fieldModeReminderTitle => 'Nearby customer';

  @override
  String get fieldModeNotificationChannel => 'Field Mode';

  @override
  String get fieldModeNotificationDescription =>
      'Reminds you about nearby customers while Field Mode is on.';

  @override
  String get fieldModeForegroundTitle => 'KartVizyon Field Mode is on';

  @override
  String get fieldModeForegroundText =>
      'Reminding you about nearby customers. Tap to stop.';

  @override
  String distanceAway(String distance) {
    return '$distance away';
  }

  @override
  String lastVisitedDays(int days) {
    return 'Last visited $days days ago';
  }

  @override
  String get notVisitedYet => 'Not visited yet';

  @override
  String overdueFollowUpCount(int count) {
    return '$count overdue follow-ups';
  }

  @override
  String get moduleNewProductDialogTitle => 'New product';

  @override
  String get moduleStockCodeRequired => 'SKU *';

  @override
  String get moduleProductNameRequired => 'Product name *';

  @override
  String get moduleListPriceTryRequired => 'List price (TRY) *';

  @override
  String get moduleAdd => 'Add';

  @override
  String get moduleCaptureDocument => 'Take a photo of the document';

  @override
  String get moduleChooseDocumentImage => 'Choose an image from gallery';

  @override
  String get moduleFieldFormFallback => 'Field form';

  @override
  String get moduleFieldRequired => 'This field is required.';

  @override
  String get moduleSend => 'Submit';

  @override
  String get moduleOrderRejectTitle => 'Reject order draft';

  @override
  String get moduleRejectionReasonRequired => 'Rejection reason *';

  @override
  String get moduleRejectionReasonExample =>
      'For example, the price needs to be updated';

  @override
  String get moduleSendForApproval => 'Submit for approval';

  @override
  String get moduleApprove => 'Approve';

  @override
  String get moduleReject => 'Reject';

  @override
  String get customerPickerTitle => 'Choose a customer';

  @override
  String get customerPickerClose => 'Close';

  @override
  String get customerPickerSearch => 'Search alias, company, address, or email';

  @override
  String get customerPickerNone => 'Continue without a customer';

  @override
  String get customerPickerEmpty => 'No matching customers found.';

  @override
  String get customerPickerRetry => 'Try again';

  @override
  String get customerPickerLoadFailed =>
      'Could not load customers. Check your connection and try again.';

  @override
  String get visitPlanTitle => 'Plan a visit';

  @override
  String get visitPlanCustomer => 'Customer';

  @override
  String get visitPlanCustomerRequired => 'Choose a customer.';

  @override
  String get visitPlanCustomerMissingSemantics =>
      'No customer selected; required field';

  @override
  String visitPlanCustomerSelectedSemantics(Object name) {
    return 'Selected customer $name';
  }

  @override
  String get visitPlanCustomerSelect => 'Choose customer *';

  @override
  String get visitPlanFutureStart => 'Choose a start time in the future.';

  @override
  String get visitPlanOfflineQueued =>
      'Visit saved for offline sync. Reminders will be scheduled after synchronization.';

  @override
  String get visitPlanType => 'Visit type';

  @override
  String get visitPlanTypeSalesMeeting => 'Sales meeting';

  @override
  String get visitPlanTypeQuoteFollowUp => 'Quote follow-up';

  @override
  String get visitPlanTypeOrderFollowUp => 'Order follow-up';

  @override
  String get visitPlanTypeIntroduction => 'Introduction';

  @override
  String get visitPlanTypeTechnical => 'Technical meeting';

  @override
  String get visitPlanTypeOther => 'Other';

  @override
  String get visitPlanPurpose => 'Purpose *';

  @override
  String get visitPlanPurposeHint => 'e.g. Review the new proposal';

  @override
  String get visitPlanPurposeMin =>
      'Enter at least 2 characters for the purpose.';

  @override
  String get visitPlanDateTime => 'Date and time';

  @override
  String get visitPlanDuration => 'Duration';

  @override
  String get visitPlanReminderTitle => 'General visit reminders';

  @override
  String get visitPlanReminderBody =>
      'If notifications are enabled, reminders arrive 1 day and 2 hours before the visit.';

  @override
  String get visitPlanNote => 'Planning note';

  @override
  String get visitPlanNoteHint => 'A short preparation note before the meeting';

  @override
  String get visitPlanNoteHelper =>
      'This is separate from the post-visit debrief.';

  @override
  String visitPlanSelectedSummary(Object type, Object duration) {
    return 'Selected: $type · $duration';
  }

  @override
  String visitPlanDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String get visitPlanDurationHour => '1 hour';

  @override
  String get visitPlanDurationHourHalf => '1 hr 30 min';

  @override
  String get visitPlanDurationTwoHours => '2 hours';

  @override
  String get visitPlanSubmit => 'Plan visit';

  @override
  String get visitPlanSubscriptionRequired => 'Subscription required';

  @override
  String get visitPlanSaveFailed =>
      'Could not plan the visit. Check your connection and try again.';

  @override
  String get companyIdentityOnboardingTitle => 'Before you begin';

  @override
  String get companyIdentityTitle => 'Company details';

  @override
  String get companyIdentityIntro =>
      'Tell us about you and the company you represent.';

  @override
  String get companyIdentityName => 'Full name';

  @override
  String get companyIdentityCompany => 'Company name';

  @override
  String get companyIdentityNameTooShort =>
      'Full name must be at least 2 characters.';

  @override
  String get companyIdentityCompanyTooShort =>
      'Company name must be at least 2 characters.';

  @override
  String get companyIdentitySaveFailed =>
      'Could not save company details. Please try again.';

  @override
  String get companyIdentityReadOnly =>
      'Company details cannot be changed in read-only access.';

  @override
  String get companyIdentitySaving => 'Saving…';

  @override
  String get companyIdentitySave => 'Save';

  @override
  String get companyIdentitySkip => 'Skip for now';

  @override
  String get opportunityEditTitle => 'Edit opportunity';

  @override
  String get opportunityNewTitle => 'New opportunity';

  @override
  String get opportunityName => 'Opportunity name *';

  @override
  String get opportunityNameTooShort =>
      'Enter an opportunity name with at least 2 characters.';

  @override
  String get opportunityCustomerSelect => 'Choose customer *';

  @override
  String get opportunityCustomerRequired => 'Choose a customer.';

  @override
  String get opportunityEstimatedValue => 'Estimated value';

  @override
  String get opportunityInvalidAmount => 'Enter a valid amount.';

  @override
  String get opportunityNegativeAmount => 'Amount cannot be negative.';

  @override
  String get opportunityAmountTooHigh => 'Amount is too high.';

  @override
  String get opportunityCurrency => 'Currency';

  @override
  String get opportunityStage => 'Stage';

  @override
  String get opportunityStageLead => 'Lead';

  @override
  String get opportunityStageQualified => 'Qualified';

  @override
  String get opportunityStageProposal => 'Proposal';

  @override
  String get opportunityStageNegotiation => 'Negotiation';

  @override
  String get opportunityStageWon => 'Won';

  @override
  String get opportunityStageLost => 'Lost';

  @override
  String get opportunityWinProbability => 'Win probability';

  @override
  String get opportunityExpectedCloseChoose => 'Choose expected close date';

  @override
  String opportunityExpectedClose(Object date) {
    return 'Expected close: $date';
  }

  @override
  String get opportunityRemoveDate => 'Remove date';

  @override
  String get opportunityCompetitor => 'Competitor';

  @override
  String get opportunityOwner => 'Owner';

  @override
  String get opportunityLossReason => 'Loss reason *';

  @override
  String get opportunityLossReasonRequired =>
      'Enter the reason for losing this opportunity.';

  @override
  String get opportunityModelNotice =>
      'Notes and next-step fields are not available in the current opportunity model.';

  @override
  String get opportunityNetworkError =>
      'Could not save the opportunity. Your form details are still here.';

  @override
  String get opportunitySave => 'Save';

  @override
  String get opportunitySaving => 'Saving…';

  @override
  String get opportunityUserFallback => 'User';

  @override
  String get opportunityMe => 'Me';

  @override
  String get formTemplateTitle => 'New field form';

  @override
  String get formTemplateIntro =>
      'Create store checks, competitor analyses, service checks, or custom visit checklists.';

  @override
  String get formTemplateName => 'Form name *';

  @override
  String get formTemplateNameRequired => 'Enter a form name.';

  @override
  String get formTemplateDescription => 'Description';

  @override
  String get formTemplateFields => 'Fields';

  @override
  String get formTemplateRequired => 'Required';

  @override
  String get formTemplateRemoveField => 'Remove field';

  @override
  String get formTemplateAddField => 'Add field';

  @override
  String get formTemplateNeedsField => 'Add at least one field.';

  @override
  String get formTemplateCreate => 'Create form';

  @override
  String get formTemplateCreating => 'Creating…';

  @override
  String get formTemplateSaveFailed =>
      'Could not save the form. Your entries are still here.';

  @override
  String get formTemplateAddFieldTitle => 'Add field';

  @override
  String get formTemplateFieldTitle => 'Label *';

  @override
  String get formTemplateFieldType => 'Field type';

  @override
  String get formTemplateHelpText => 'Help text';

  @override
  String get formTemplateOptions => 'Options *';

  @override
  String get formTemplateOptionsHint => 'One option per line';

  @override
  String get formTemplateCancel => 'Cancel';

  @override
  String get formTemplateAdd => 'Add';

  @override
  String get formTemplateFieldTitleRequired =>
      'Use a label with at least 2 characters and add options for selection fields.';

  @override
  String get formTemplateText => 'Short text';

  @override
  String get formTemplateLongText => 'Long text';

  @override
  String get formTemplateNumber => 'Number';

  @override
  String get formTemplateYesNo => 'Yes / No';

  @override
  String get formTemplateSingleSelect => 'Single select';

  @override
  String get formTemplateMultiSelect => 'Multiple select';

  @override
  String get formTemplateDate => 'Date';

  @override
  String get orderDraftEditTitle => 'Edit order draft';

  @override
  String get orderDraftNewTitle => 'New order draft';

  @override
  String get orderDraftSelectProduct => 'Select a product';

  @override
  String get orderDraftProduct => 'Product';

  @override
  String get orderDraftNoProducts => 'No active products in this currency.';

  @override
  String get orderDraftSaveFailed =>
      'Could not save the order draft. Your form details are still here.';

  @override
  String get orderDraftCustomerSelect => 'Choose customer *';

  @override
  String get orderDraftCustomerRequired => 'Choose a customer.';

  @override
  String get orderDraftCurrency => 'Currency';

  @override
  String get orderDraftItems => 'Line items';

  @override
  String get orderDraftAddProduct => 'Add product';

  @override
  String get orderDraftNeedsProduct => 'Add at least one product.';

  @override
  String get orderDraftChooseDeliveryDate => 'Choose delivery date';

  @override
  String orderDraftDeliveryDate(Object date) {
    return 'Delivery: $date';
  }

  @override
  String get orderDraftNotes => 'Notes';

  @override
  String get orderDraftSubtotal => 'Subtotal';

  @override
  String get orderDraftDiscount => 'Discount';

  @override
  String get orderDraftTax => 'Tax';

  @override
  String get orderDraftEstimatedTotal => 'Estimated total';

  @override
  String get orderDraftEstimateNotice =>
      'Estimate only; the final total is calculated by the server.';

  @override
  String get orderDraftSaving => 'Saving…';

  @override
  String get orderDraftSave => 'Save draft';

  @override
  String get orderDraftRemoveItem => 'Remove line item';

  @override
  String get orderDraftQuantity => 'Quantity *';

  @override
  String get orderDraftQuantityMustBePositive =>
      'Quantity must be greater than zero.';

  @override
  String orderDraftUnitPrice(Object currency) {
    return 'Unit price ($currency) *';
  }

  @override
  String get orderDraftPriceNegative => 'Price cannot be negative.';

  @override
  String get orderDraftDiscountPercent => 'Discount (%)';

  @override
  String get orderDraftDiscountRange => 'Discount must be between 0 and 100.';

  @override
  String get briefingLoadFailed =>
      'Could not load the customer briefing. Check your connection and try again.';

  @override
  String get briefingRetry => 'Try again';

  @override
  String get briefingNeverVisited => 'You have not visited this customer yet.';

  @override
  String get briefingStartVisitFailed =>
      'Could not start the visit. Please try again.';

  @override
  String get briefingDefaultVisitPurpose => 'Field visit';

  @override
  String get moduleActiveCustomer => 'Active customers';

  @override
  String get moduleApprovedVisit => 'Approved visits';

  @override
  String get moduleReviewVisit => 'Visits awaiting review';

  @override
  String get moduleOpenTask => 'Open tasks';

  @override
  String get moduleVisit => 'Visit';

  @override
  String get moduleTask => 'Task';

  @override
  String get moduleActivity => 'Activity';

  @override
  String get moduleNotification => 'Notification';

  @override
  String get moduleOpportunity => 'Opportunity';

  @override
  String get moduleProduct => 'Product';

  @override
  String get moduleOrderDraft => 'Order draft';

  @override
  String get moduleFormTemplate => 'Form template';

  @override
  String get moduleActiveFormTemplate => 'Active form template';

  @override
  String get moduleSubmittedForm => 'Submitted form';

  @override
  String get summaryApprovalFailed =>
      'Could not approve the visit summary. Please try again.';

  @override
  String get reviewLoadFailed =>
      'Could not load the visit review. Check your connection and try again.';

  @override
  String get visitsLoadFailed =>
      'Could not load visits. Check your connection and try again.';

  @override
  String get homeLoadFailed =>
      'Could not load your overview. Check your connection and try again.';

  @override
  String get writeAccessRequired =>
      'An active subscription is required to record this visit note.';

  @override
  String get customerSaveFailed =>
      'Could not save the customer. Your form details are still here.';
}
