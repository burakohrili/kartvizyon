import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';
import '../customers/customer_picker.dart';

class OrderDraftFormScreen extends StatefulWidget {
  const OrderDraftFormScreen({super.key, required this.services, this.order});

  final MobileServices services;
  final Map<String, dynamic>? order;

  @override
  State<OrderDraftFormScreen> createState() => _OrderDraftFormScreenState();
}

class _Line {
  _Line({
    required this.product,
    required num quantity,
    required num unitPrice,
    required num discount,
  }) : quantity = TextEditingController(text: '$quantity'),
       unitPrice = TextEditingController(text: '$unitPrice'),
       discount = TextEditingController(text: '$discount');
  final Map<String, dynamic> product;
  final TextEditingController quantity;
  final TextEditingController unitPrice;
  final TextEditingController discount;
  void dispose() {
    quantity.dispose();
    unitPrice.dispose();
    discount.dispose();
  }
}

class _OrderDraftFormScreenState extends State<OrderDraftFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController notes;
  CustomerChoice? customer;
  DateTime? deliveryDate;
  String currency = 'TRY';
  List<Map<String, dynamic>> products = [];
  final lines = <_Line>[];
  bool loading = true;
  bool submitting = false;
  bool attempted = false;

  bool get editing => widget.order != null;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    notes = TextEditingController(text: order?['notes']?.toString() ?? '');
    currency = order?['currency']?.toString() ?? 'TRY';
    deliveryDate = DateTime.tryParse(order?['delivery_date']?.toString() ?? '');
    if (order?['company'] is Map) {
      customer = CustomerChoice.fromMap(
        Map<String, dynamic>.from(order!['company'] as Map),
      );
    }
    for (final raw in List<Map<String, dynamic>>.from(
      order?['items'] as List? ?? const [],
    )) {
      final product = raw['product'];
      if (product is Map) {
        lines.add(
          _Line(
            product: Map<String, dynamic>.from(product),
            quantity: raw['quantity'] as num? ?? 1,
            unitPrice: raw['unit_price'] as num? ?? 0,
            discount: raw['discount_percent'] as num? ?? 0,
          ),
        );
      }
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await widget.services.api.get('/api/products') as Map;
      if (mounted) {
        setState(() {
          products = List<Map<String, dynamic>>.from(
            response['data'] as List? ?? const [],
          );
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    notes.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.dispose();
  }

  double _number(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickCustomer() async {
    final selected = await showCustomerPicker(
      context,
      services: widget.services,
    );
    if (selected != null && mounted) setState(() => customer = selected);
  }

  Future<void> _addLine() async {
    final available = products
        .where((product) => product['currency'] == currency)
        .toList();
    final product = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Ürün seç')),
            for (final item in available)
              ListTile(
                title: Text(item['name']?.toString() ?? 'Ürün'),
                subtitle: Text(
                  '${item['list_price']} $currency · KDV %${item['tax_rate']}',
                ),
                onTap: () => Navigator.pop(context, item),
              ),
            if (available.isEmpty)
              const ListTile(title: Text('Bu para biriminde aktif ürün yok.')),
          ],
        ),
      ),
    );
    if (product != null && mounted) {
      setState(
        () => lines.add(
          _Line(
            product: product,
            quantity: 1,
            unitPrice: product['list_price'] as num? ?? 0,
            discount: 0,
          ),
        ),
      );
    }
  }

  double get subtotal => lines.fold(
    0,
    (sum, line) =>
        sum + _number(line.quantity.text) * _number(line.unitPrice.text),
  );
  double get discountTotal => lines.fold(0, (sum, line) {
    final gross = _number(line.quantity.text) * _number(line.unitPrice.text);
    return sum + gross * _number(line.discount.text) / 100;
  });
  double get taxTotal => lines.fold(0, (sum, line) {
    final gross = _number(line.quantity.text) * _number(line.unitPrice.text);
    final net = gross * (1 - _number(line.discount.text) / 100);
    return sum +
        net * ((line.product['tax_rate'] as num?)?.toDouble() ?? 0) / 100;
  });

  Future<void> _submit() async {
    if (submitting) return;
    setState(() => attempted = true);
    if (!(formKey.currentState?.validate() ?? false) ||
        customer == null ||
        lines.isEmpty) {
      return;
    }
    setState(() => submitting = true);
    final body = {
      if (editing) 'id': widget.order!['id'],
      if (!editing) 'workspaceId': widget.services.workspaceId,
      'companyId': customer!.id,
      'opportunityId': null,
      'deliveryDate': deliveryDate == null ? null : _date(deliveryDate!),
      'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      'currency': currency,
      'items': [
        for (final line in lines)
          {
            'productId': line.product['id'],
            'quantity': _number(line.quantity.text),
            'unitPrice': _number(line.unitPrice.text),
            'discountPercent': _number(line.discount.text),
          },
      ],
    };
    try {
      await widget.services.requireWriteAccess();
      if (editing) {
        await widget.services.api.patch('/api/orders', body);
      } else {
        await widget.services.api.post('/api/orders', body);
      }
      if (mounted) Navigator.pop(context, true);
    } on MobileApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı kurulamadı. Form bilgileriniz korunuyor.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        editing ? 'Sipariş taslağını düzenle' : 'Yeni sipariş taslağı',
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Card(
            child: ListTile(
              minTileHeight: 64,
              leading: const Icon(Icons.apartment_outlined),
              title: Text(customer?.name ?? 'Müşteri seç *'),
              subtitle: customer?.address == null
                  ? null
                  : Text(customer!.address!),
              trailing: const Icon(Icons.search),
              onTap: submitting ? null : _pickCustomer,
            ),
          ),
          if (attempted && customer == null)
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'Müşteri seçin.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: currency,
            decoration: const InputDecoration(
              labelText: 'Para birimi',
              border: OutlineInputBorder(),
            ),
            items: const ['TRY', 'USD', 'EUR']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: lines.isNotEmpty || submitting
                ? null
                : (value) => setState(() => currency = value!),
          ),
          const SizedBox(height: 16),
          Text('Kalemler', style: Theme.of(context).textTheme.titleMedium),
          for (var index = 0; index < lines.length; index++) _lineCard(index),
          OutlinedButton.icon(
            onPressed: loading || submitting ? null : _addLine,
            icon: const Icon(Icons.add),
            label: const Text('Ürün ekle'),
          ),
          if (attempted && lines.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'En az bir ürün ekleyin.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: submitting
                ? null
                : () async {
                    final now = DateTime.now();
                    final result = await showDatePicker(
                      context: context,
                      initialDate: deliveryDate ?? now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 5),
                    );
                    if (result != null && mounted) {
                      setState(() => deliveryDate = result);
                    }
                  },
            icon: const Icon(Icons.event_outlined),
            label: Text(
              deliveryDate == null
                  ? 'Teslim tarihi seç'
                  : 'Teslim: ${_date(deliveryDate!)}',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notes,
            minLines: 2,
            maxLines: 5,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Not',
              border: OutlineInputBorder(),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _totalRow('Ara toplam', subtotal),
                  _totalRow('İndirim', discountTotal),
                  _totalRow('Vergi', taxTotal),
                  const Divider(),
                  _totalRow(
                    'Tahmini toplam',
                    subtotal - discountTotal + taxTotal,
                    strong: true,
                  ),
                  const SizedBox(height: 6),
                  const Text('Önizlemedir; kesin toplam sunucuda hesaplanır.'),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: submitting || !widget.services.canWrite ? null : _submit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(submitting ? 'Kaydediliyor…' : 'Taslağı kaydet'),
        ),
      ),
    ),
  );

  Widget _lineCard(int index) {
    final line = lines[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.product['name']?.toString() ?? 'Ürün',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Kalemi kaldır',
                  onPressed: submitting
                      ? null
                      : () => setState(() {
                          lines.removeAt(index);
                          line.dispose();
                        }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Text(
              '${line.product['currency']} · KDV %${line.product['tax_rate']}',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: line.quantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Miktar *',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) => _number(value ?? '') <= 0
                  ? 'Miktar sıfırdan büyük olmalı.'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: line.unitPrice,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Birim fiyat ($currency) *',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) =>
                  _number(value ?? '') < 0 ? 'Fiyat negatif olamaz.' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: line.discount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'İndirim %',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final number = _number(value ?? '');
                return number < 0 || number > 100
                    ? 'İndirim 0–100 arasında olmalı.'
                    : null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool strong = false}) =>
      Semantics(
        label: '$label ${value.toStringAsFixed(2)} $currency',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: strong
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
              ),
              Text(
                '${value.toStringAsFixed(2)} $currency',
                style: strong
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
            ],
          ),
        ),
      );
}
