import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/features/customers/customer_identity.dart';

void main() {
  test('kısa ad varsa listede onu gösterir, yasal adı korur', () {
    final company = {
      'name': 'Ohrili Makina Sanayi ve Ticaret Limited Şirketi',
      'display_name': 'Ohrili Makina',
    };
    expect(customerDisplayName(company), 'Ohrili Makina');
    expect(
      customerLegalName(company),
      'Ohrili Makina Sanayi ve Ticaret Limited Şirketi',
    );
  });

  test('kısa ad yoksa yasal ada geri düşer', () {
    final company = {'name': 'Atlas Medikal', 'display_name': null};
    expect(customerDisplayName(company), 'Atlas Medikal');
    expect(customerLegalName(company), isNull);
  });
}
