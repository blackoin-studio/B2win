// Base Url
const String baseUrl = "https://b2win-qgvn.onrender.com/api/v1";
const String imageUrl = "https://b2win-qgvn.onrender.com/public";

/// Resolves a media path (relative filename or full URL) into a valid network URL.
/// Returns empty string if the path is null, empty, or a default placeholder.
String resolveMediaUrl(String? path) {
  if (path == null) return '';
  final trimmed = path.trim();
  if (trimmed.isEmpty || trimmed.startsWith('no-')) {
    return '';
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return '$imageUrl/$trimmed';
}
