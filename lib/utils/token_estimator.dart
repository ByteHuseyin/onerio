int estimateTokens(String text) {
  final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return (cleaned.length / 4).ceil(); // Ortalama 1 token ≈ 4 karakter
}