String customerDisplayName(
  Map<dynamic, dynamic>? customer, {
  String fallback = 'Firma',
}) {
  final displayName = customer?['display_name']?.toString().trim() ?? '';
  if (displayName.isNotEmpty) return displayName;
  final legalName = customer?['name']?.toString().trim() ?? '';
  return legalName.isEmpty ? fallback : legalName;
}

String? customerLegalName(
  Map<dynamic, dynamic>? customer, {
  String fallback = 'Firma',
}) {
  final legalName = customer?['name']?.toString().trim() ?? '';
  if (legalName.isEmpty ||
      legalName == customerDisplayName(customer, fallback: fallback)) {
    return null;
  }
  return legalName;
}
