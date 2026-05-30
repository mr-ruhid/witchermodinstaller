import '../../models/mod_config.dart';

// ---------------------------------------------------------
// AZE Dil Paketi (Mod 1) üçün xüsusi məlumatlar
// Ana səhifə (Home) bu obyekti oxuyaraq ekranda göstərəcək
// ---------------------------------------------------------

final ModConfig mod1Config = ModConfig(
  id: 'mod1',
  title: 'AZE Dil paketi',
  author: 'Mr Ruhid',
  description: 'Oyunu Azərbaycan dilində oynayın və həzz alın',
  logoPath: 'assets/mod/mod1/pp.webp', // Modun loqosu
  isLanguagePack: true, // Dil faylı olduğunu bildirən bayraq
  priority: 0,
  operations: const [
    ModFileOperation(
      // Proqramın içindəki orjinal dil faylının sənin qeyd etdiyin tam yeri
      sourceAssetPath: 'lib/mods/mod1/lang/en.w3strings',

      // Oyun qovluğunda dəyişdiriləcək faylın hədəf adı/yolu.
      targetGamePath: 'en.w3strings',
    ),
  ],
);