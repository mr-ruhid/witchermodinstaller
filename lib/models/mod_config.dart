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
  final bool isRequiredWithLang;
  final int priority;
  final bool isBeta;
  final List<ModFileOperation> operations; // XƏTANI HƏLL EDƏN SƏTİR: Bu sətir əlavə olundu

  const ModConfig({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.logoPath,
    required this.isLanguagePack,
    this.isRequiredWithLang = false,
    this.priority = 0,
    this.isBeta = false,
    required this.operations,
  });
}