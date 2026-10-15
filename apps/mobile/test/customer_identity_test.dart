import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/features/customers/customer_identity.dart';

void main() {
  test('empty customer names use the active UI language fallback', () {
    expect(customerDisplayName({}, fallback: 'Company'), 'Company');
    expect(customerDisplayName({}), 'Firma');
  });

  test('user-provided customer names are never rewritten', () {
    const company = {'name': 'İzmir Makina', 'display_name': 'İzmir'};
    expect(customerDisplayName(company, fallback: 'Company'), 'İzmir');
    expect(customerLegalName(company, fallback: 'Company'), 'İzmir Makina');
  });
}
