import '../api/subsonic_client.dart';

enum DownloadQuality {
  original(label: 'Original', maxBitRate: null),
  high(label: 'Alta (320 kbps)', maxBitRate: 320),
  medium(label: 'Média (192 kbps)', maxBitRate: 192),
  low(label: 'Baixa (128 kbps)', maxBitRate: 128);

  const DownloadQuality({required this.label, required this.maxBitRate});

  final String label;
  final int? maxBitRate;

  String urlFor(SubsonicClient client, String trackId) {
    final bitRate = maxBitRate;
    return bitRate == null
        ? client.downloadUrl(trackId)
        : client.streamUrl(trackId, maxBitRate: bitRate);
  }

  static DownloadQuality fromStorage(String? value) {
    return DownloadQuality.values.where((quality) => quality.name == value).firstOrNull ??
        DownloadQuality.original;
  }
}
