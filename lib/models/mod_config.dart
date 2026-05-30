// Modların məlumat strukturunu təyin edən əsas model faylı
class ModFileOperation {
  final String sourceAssetPath; // Proqramın içindəki faylın/qovluğun yeri
  final String targetGamePath;  // Oyun qovluğunda hara kopyalanacağı
  final bool isDirectory;       // Bu bir fayldır, yoxsa qovluq?

  const ModFileOperation({
    required this.sourceAssetPath,
    required this.targetGamePath,
    this.isDirectory = false, // Standart olaraq fayl kimi qəbul edir
  });
}

class ModConfig {
  final String id;
  final String title;
  final String author;
  final String description;
  final String logoPath;
  final bool isLanguagePack;
  final bool isRequiredWithLang; // Dil faylı ilə məcburi yüklənməlidirmi?
  final int priority; // YENİ: Toqquşmaların qarşısını alan qrup nömrəsi (0: əsas/tərcümə, 1: font, 2: musiqi)
  final List<ModFileOperation> operations;

  const ModConfig({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.logoPath,
    required this.isLanguagePack,
    this.isRequiredWithLang = false,
    this.priority = 0, // Standart olaraq 0 qəbul edirik
    required this.operations,
  });
}