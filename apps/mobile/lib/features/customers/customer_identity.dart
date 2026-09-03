String customerDisplayName(Map<dynamic, dynamic>? customer) {
  final displayName = customer?['display_name']?.toString().trim() ?? '';
  if (displayName.isNotEmpty) return displayName;
  final legalName = customer?['name']?.toString().trim() ?? '';
  return legalName.isEmpty ? 'Firma' : legalName;
}

String? customerLegalName(Map<dynamic, dynamic>? customer) {
  final legalName = customer?['name']?.toString().trim() ?? '';
  if (legalName.isEmpty || legalName == customerDisplayName(customer)) {
    return null;
  }
  return legalName;
}
