const String sessionMediaBaseUrl = "https://htlabsapp.io.vn/media";
const String defaultSessionImageUrl =
    "$sessionMediaBaseUrl/images/sessions/deep_work_1.webp";

String normalizeSessionImageUrl(String imageUrl, {String? sessionId}) {
  final value = imageUrl.trim();
  if (value.isEmpty) return value;

  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == "http" || uri.scheme == "https")) {
    return value;
  }

  if (value.startsWith("assets/images/sessions/")) {
    final fileName = value.split("/").last;
    final dotIndex = fileName.lastIndexOf(".");
    final imageName = dotIndex == -1
        ? fileName
        : fileName.substring(0, dotIndex);
    if (imageName.isNotEmpty) {
      return "$sessionMediaBaseUrl/images/sessions/$imageName.webp";
    }
  }

  if (value.startsWith("assets/")) {
    final id = sessionId?.trim();
    if (id != null && id.isNotEmpty && !id.startsWith("personal_")) {
      return "$sessionMediaBaseUrl/images/sessions/$id.webp";
    }
    return defaultSessionImageUrl;
  }

  return value;
}

bool isOnlineImageUrl(String imageUrl) {
  final uri = Uri.tryParse(imageUrl.trim());
  return uri != null && (uri.scheme == "http" || uri.scheme == "https");
}
