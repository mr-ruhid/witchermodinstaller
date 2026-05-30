// Bu sinif modun ekranda necə görünəcəyini və hansı faylları dəyişdirəcəyini təyin edir
class ModFileOperation {
  final String sourceAssetPath; // Proqramın içindəki faylın yeri (assets)
  final String targetGamePath;  // Oyun qovluğunda hara kopyalanacağı

  const ModFileOperation({
    required this.sourceAssetPath,
    required this.targetGamePath,
  });
}

class ModConfig {
  final String id;
  final String title;
  final String author;
  final String description;
  final String logoPath;
  final bool isLanguagePack;
  final List<ModFileOperation> operations;

  const ModConfig({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.logoPath,
    required this.isLanguagePack,
    required this.operations,
  });
}

// ---------------------------------------------------------
// AZE Dil Paketi (Mod 1) üçün xüsusi məlumatlar
// Ana səhifə (Home) bu obyekti oxuyaraq ekranda göstərəcək
// ---------------------------------------------------------

final ModConfig mod1Config = ModConfig(
  id: 'mod1',
  title: 'AZE Dil paketi',
  author: 'Mr Ruhid',
  description: 'Oyunu Azərbaycan dilində oynayın və həzz alın',
  logoPath: 'assets/mod/mod1/pp.png', // Modun loqosu
  isLanguagePack: true, // Dil faylı olduğunu bildirən bayraq
  operations: [
    ModFileOperation(
      // Proqramın içindəki orjinal dil faylının yeri
      sourceAssetPath: 'assets/mods/mod1/lang/en.w3strings',

      // Oyun qovluğunda dəyişdiriləcək faylın hədəf adı/yolu.
      // Qeyd: Witcher 3-də dil faylları adətən "content\content0\en.w3strings" kimi yerlərdə olur.
      // Proqram oyun qovluğunu tapanda bu yolu onun üzərinə əlavə edib faylı dəyişəcək.
      targetGamePath: 'en.w3strings',
    ),
  ],
);