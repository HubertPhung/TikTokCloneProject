/// Model đại diện cho một video quảng cáo (Sponsored Video Ads)
class AdModel {
  final String adId;
  final String videoUri;
  final String sponsorName;
  final String description;
  final String ctaText;
  final String targetUrl;

  AdModel({
    required this.adId,
    required this.videoUri,
    required this.sponsorName,
    required this.description,
    this.ctaText = 'Tìm hiểu thêm',
    required this.targetUrl,
  });

  factory AdModel.fromMap(Map<String, dynamic> map, String id) {
    return AdModel(
      adId: id,
      videoUri: map['videoUri'] as String? ?? '',
      sponsorName: map['sponsorName'] as String? ?? 'Tài trợ',
      description: map['description'] as String? ?? '',
      ctaText: map['ctaText'] as String? ?? 'Tìm hiểu thêm',
      targetUrl: map['targetUrl'] as String? ?? 'https://google.com',
    );
  }

  Map<String, dynamic> toMap() => {
        'videoUri': videoUri,
        'sponsorName': sponsorName,
        'description': description,
        'ctaText': ctaText,
        'targetUrl': targetUrl,
      };
}
