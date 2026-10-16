String? requiredField(String? value) {
  if (value == null || value.trim().isEmpty) return 'Wajib diisi.';
  return null;
}
