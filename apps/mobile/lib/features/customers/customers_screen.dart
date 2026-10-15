import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/mobile_services.dart';
import '../../core/refresh.dart';
import '../../l10n/app_localizations.dart';
import 'customer_identity.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.services});

  final MobileServices services;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Map<String, dynamic>>> customers;
  bool saving = false;

  /// Kartvizit okuma ayrı bir bayrak kullanır.
  ///
  /// `saving` ile paylaşılsaydı, OCR bittikten sonra açılan müşteri formunun
  /// kendi kayıt yolu (`saveCustomer`, `if (saving) return;`) bayrağı hâlâ
  /// açık bulup sessizce hiçbir şey yapmazdı.
  bool scanning = false;

  bool get busy => saving || scanning;

  final searchController = TextEditingController();
  String query = '';
  final visibleCustomers = <Map<String, dynamic>>[];
  Timer? searchDebounce;
  bool hasMore = false;
  bool loadingMore = false;
  int loadGeneration = 0;

  @override
  void dispose() {
    searchDebounce?.cancel();
    widget.services.screenRevision.removeListener(_onScreenRevision);
    widget.services.activeTab.removeListener(_onActiveTabChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    customers = load();
    widget.services.screenRevision.addListener(_onScreenRevision);
    widget.services.activeTab.addListener(_onActiveTabChanged);
  }

  void _onScreenRevision() {
    if (mounted) {
      setState(() {
        visibleCustomers.clear();
        hasMore = false;
        customers = load();
      });
    }
  }

  void _onActiveTabChanged() {
    if (widget.services.activeTab.value == 1 && mounted) {
      setState(() {
        customers = load();
      });
    }
  }

  Future<List<Map<String, dynamic>>> load({bool append = false}) async {
    if (!widget.services.config.hasSupabase) return const [];
    final generation = append ? loadGeneration : ++loadGeneration;
    await widget.services.refreshContext();
    final search = query.isEmpty ? '' : '&q=${Uri.encodeQueryComponent(query)}';
    final offset = append ? visibleCustomers.length : 0;
    final result =
        await widget.services.api.get(
              '/api/customers?workspaceId=${widget.services.workspaceId}'
              '&limit=40&offset=$offset$search',
            )
            as Map<String, dynamic>;
    if (generation != loadGeneration) return visibleCustomers;
    final next = List<Map<String, dynamic>>.from(
      result['data'] as List? ?? const [],
    );
    if (!append) visibleCustomers.clear();
    visibleCustomers.addAll(next);
    hasMore = (result['page'] as Map?)?['hasMore'] == true;
    return List.unmodifiable(visibleCustomers);
  }

  void search(String value) {
    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        query = value.trim();
        customers = load();
      });
    });
  }

  Future<void> loadMoreCustomers() async {
    if (loadingMore || !hasMore) return;
    setState(() {
      loadingMore = true;
      customers = load(append: true);
    });
    await customers;
    if (mounted) setState(() => loadingMore = false);
  }

  /// Kartvizit kaynağını sorar.
  ///
  /// Mağaza izin gerekçelerinde kameranın alternatifi galeri olarak beyan
  /// edilir; kamera izni reddedilen kullanıcı buradan devam edebilmelidir.
  /// Alternatif sunulmadan fotoğraf izni istemek App Review 5.1.1 kapsamında
  /// gereksiz izin sayılır.
  Future<ImageSource?> _askImageSource() => showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.cameraTakePhoto),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              subtitle: Text(l10n.cameraPermissionOptional),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.cancel),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      );
    },
  );

  Future<void> scanCard() async {
    final l10n = AppLocalizations.of(context)!;
    if (busy) return;
    final source = await _askImageSource();
    if (!mounted || source == null) return;
    // Kamera/galeri izni reddedilirse image_picker fırlatır; sarmalanmazsa bu
    // yakalanmamış hata olarak uygulamayı çökertir.
    final XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.imagePickFailed)));
      return;
    }
    if (!mounted || image == null) return;

    // OCR modelde saniyeler sürüyor. Daha önce bu süre boyunca ekranda
    // hiçbir şey değişmiyor, düğmeler açık kalıyordu; kullanıcı ne olduğunu
    // anlamayıp "hata varmış gibi hissettiriyor" dedi ve ikinci bir tarama
    // başlatabiliyordu.
    setState(() => scanning = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.scanningBusinessCard),
        duration: Duration(seconds: 30),
      ),
    );
    _CustomerDraft? draft;
    try {
      final result =
          await widget.services.api.postFile(
                '/api/contacts/ocr',
                field: 'image',
                filePath: image.path,
              )
              as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(result['data'] as Map);
      draft = _CustomerDraft(
        companyName: data['companyName']?.toString() ?? '',
        firstName: data['firstName']?.toString() ?? '',
        lastName: data['lastName']?.toString() ?? '',
        title: data['title']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        email: data['email']?.toString() ?? '',
        website: data['website']?.toString() ?? '',
        // Adres formda vardı ama taramadan hiç doldurulmuyordu. Sunucu adresi
        // koordinata çevirdiği için boş adres, müşteriyi haritadan ve yakınlık
        // hatırlatmalarından tamamen dışarıda bırakıyordu.
        address: data['address']?.toString() ?? '',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.cardScanFailed)));
    } finally {
      if (mounted) {
        setState(() => scanning = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }
    // Form, `scanning` bırakıldıktan sonra açılır; aksi halde formun kendi
    // kayıt yolu bayrağı açık bulur.
    if (draft == null || !mounted) return;
    await openCustomerForm(initial: draft, fromOcr: true);
  }

  Future<void> openCustomerForm({
    _CustomerDraft? initial,
    bool fromOcr = false,
  }) async {
    // Arama alanı odaktayken form açılırsa Android klavyesi formun üzerine
    // taşınabiliyor ve ilk alanı/eylemleri kapatabiliyor. Yeni modal kendi
    // odağını kullanıcı seçene kadar almalı.
    FocusManager.instance.primaryFocus?.unfocus();
    final draft = await _showCustomerDialog(
      context,
      initial ?? const _CustomerDraft(),
      fromOcr: fromOcr,
    );
    if (draft == null || !mounted) return;
    await saveCustomer(draft);
  }

  Future<void> saveCustomer(_CustomerDraft draft) async {
    final l10n = AppLocalizations.of(context)!;
    if (saving) return;
    setState(() => saving = true);
    try {
      final companyResponse =
          await widget.services.api.post('/api/customers', {
                'workspaceId': widget.services.workspaceId,
                'organizationId': widget.services.organizationId,
                'name': draft.companyName.trim(),
                'displayName': draft.displayName.trim(),
                'phone': draft.phone.trim(),
                'email': draft.email.trim(),
                'website': draft.website.trim(),
                'address': draft.address.trim(),
                'clientMutationId': const Uuid().v4(),
              })
              as Map<String, dynamic>;
      final company = companyResponse['data'] as Map;
      final companyId = company['id'].toString();
      String? contactWarning;
      if (draft.firstName.trim().isNotEmpty) {
        try {
          await widget.services.api.post('/api/contacts', {
            'companyId': companyId,
            'workspaceId': widget.services.workspaceId,
            'organizationId': widget.services.organizationId,
            'firstName': draft.firstName.trim(),
            'lastName': draft.lastName.trim(),
            'title': draft.title.trim(),
            'phone': draft.phone.trim(),
            'email': draft.email.trim(),
          });
        } catch (_) {
          contactWarning = l10n.contactSaveFailed;
        }
      }
      if (!mounted) return;
      setState(() => customers = load());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(contactWarning ?? l10n.customerSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.customerSaveFailed)));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customers),
        actions: [
          IconButton(
            onPressed: busy ? null : () => openCustomerForm(),
            tooltip: l10n.manuallyAddCustomer,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          IconButton(
            onPressed: busy ? null : scanCard,
            tooltip: l10n.scanBusinessCard,
            icon: const Icon(Icons.document_scanner_outlined),
          ),
        ],
        bottom: scanning
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(minHeight: 4),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.customerSearchHint,
                border: const OutlineInputBorder(),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: l10n.clearSearch,
                        onPressed: () {
                          searchDebounce?.cancel();
                          searchController.clear();
                          setState(() {
                            query = '';
                            customers = load();
                          });
                        },
                      ),
              ),
              onSubmitted: (value) {
                searchDebounce?.cancel();
                setState(() {
                  query = value.trim();
                  customers = load();
                });
              },
              onChanged: search,
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() => FutureBuilder<List<Map<String, dynamic>>>(
    future: customers,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context)!;
      if (snapshot.connectionState != ConnectionState.done &&
          !snapshot.hasData &&
          visibleCustomers.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _ErrorView(
          message: l10n.customerLoadFailed,
          retry: () => setState(() => customers = load()),
          retryLabel: l10n.tryAgain,
        );
      }
      final items = snapshot.data ?? [];
      if (items.isEmpty) {
        // Arama kutusu eklendikten sonra klavye açıkken dar ekranda taşıyordu;
        // boş durum da kaydırılabilir olmalı.
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  query.isEmpty ? Icons.apartment_outlined : Icons.search_off,
                  size: 54,
                ),
                const SizedBox(height: 12),
                Text(
                  query.isEmpty ? l10n.noCustomers : l10n.noMatchingCustomers,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  query.isEmpty
                      ? l10n.noCustomersDescription
                      : l10n.noSearchResults(query),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: busy ? null : () => openCustomerForm(),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(l10n.manuallyAddCustomer),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : scanCard,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(l10n.scanBusinessCard),
                ),
              ],
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          final next = load();
          setState(() => customers = next);
          await settleRefresh(next);
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: items.length + (hasMore || loadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            if (index == items.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: loadingMore
                      ? const CircularProgressIndicator()
                      : OutlinedButton.icon(
                          onPressed: loadMoreCustomers,
                          icon: const Icon(Icons.expand_more),
                          label: Text(l10n.loadMoreCustomers),
                        ),
                ),
              );
            }
            final item = items[index];
            final name = customerDisplayName(
              item,
              fallback: l10n.companyFallback,
            );
            final legalName = customerLegalName(
              item,
              fallback: l10n.companyFallback,
            );
            final initials = name.isEmpty
                ? 'M'
                : name.substring(0, name.length < 2 ? name.length : 2);
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(initials.toUpperCase())),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    if (legalName != null) legalName,
                    item['address']?.toString() ?? l10n.addressNotProvided,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push('/customers/${item['id']}');
                  if (mounted) setState(() => customers = load());
                },
              ),
            );
          },
        ),
      );
    },
  );
}

Future<_CustomerDraft?> _showCustomerDialog(
  BuildContext context,
  _CustomerDraft initial, {
  required bool fromOcr,
}) {
  final l10n = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();
  final companyName = TextEditingController(text: initial.companyName);
  final displayName = TextEditingController(text: initial.displayName);
  final address = TextEditingController(text: initial.address);
  final firstName = TextEditingController(text: initial.firstName);
  final lastName = TextEditingController(text: initial.lastName);
  final title = TextEditingController(text: initial.title);
  final phone = TextEditingController(text: initial.phone);
  final email = TextEditingController(text: initial.email);
  final website = TextEditingController(text: initial.website);
  return showDialog<_CustomerDraft>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      // Dialog klavye boşluğunu kendisi ekler (Flutter dialog.dart: effectivePadding
      // = MediaQuery.viewInsetsOf(context) + insetPadding). Burada ikinci kez
      // eklenirse içerik görünür alanın tamamen dışına taşar ve boş kutu görünür.
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(dialogContext).height * .88,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    fromOcr
                        ? l10n.verifyBusinessCardFields
                        : l10n.manuallyAddCustomer,
                    style: Theme.of(dialogContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: companyName,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.companyNameRequired,
                            ),
                            validator: (value) =>
                                (value?.trim().length ?? 0) < 2
                                ? l10n.companyNameTooShort
                                : null,
                          ),
                          TextFormField(
                            controller: displayName,
                            textInputAction: TextInputAction.next,
                            maxLength: 80,
                            decoration: InputDecoration(
                              labelText: l10n.shortNameField,
                              helperText: l10n.shortNameHelp,
                            ),
                          ),
                          TextFormField(
                            controller: address,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.address,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.contactOptional,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextFormField(
                            controller: firstName,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.firstName,
                            ),
                          ),
                          TextFormField(
                            controller: lastName,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.lastName,
                            ),
                          ),
                          TextFormField(
                            controller: title,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.jobTitle,
                            ),
                          ),
                          TextFormField(
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(labelText: l10n.phone),
                          ),
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(labelText: l10n.email),
                          ),
                          TextFormField(
                            controller: website,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: l10n.website,
                            ),
                          ),
                          if (fromOcr) ...[
                            const SizedBox(height: 12),
                            Text(l10n.aiDraftNotSaved),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Dar ekranda (360 dp) iki buton tek satıra sığmıyor; Wrap
                  // taşma yerine alt satıra indirir.
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(
                            dialogContext,
                            _CustomerDraft(
                              companyName: companyName.text,
                              displayName: displayName.text,
                              address: address.text,
                              firstName: firstName.text,
                              lastName: lastName.text,
                              title: title.text,
                              phone: phone.text,
                              email: email.text,
                              website: website.text,
                            ),
                          );
                        },
                        child: Text(l10n.saveCustomer),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ).whenComplete(() {
    companyName.dispose();
    displayName.dispose();
    address.dispose();
    firstName.dispose();
    lastName.dispose();
    title.dispose();
    phone.dispose();
    email.dispose();
    website.dispose();
  });
}

class _CustomerDraft {
  const _CustomerDraft({
    this.companyName = '',
    this.displayName = '',
    this.address = '',
    this.firstName = '',
    this.lastName = '',
    this.title = '',
    this.phone = '',
    this.email = '',
    this.website = '',
  });

  final String companyName;
  final String displayName;
  final String address;
  final String firstName;
  final String lastName;
  final String title;
  final String phone;
  final String email;
  final String website;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.retry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback retry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: retry, child: Text(retryLabel)),
        ],
      ),
    ),
  );
}
