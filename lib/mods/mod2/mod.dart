import '../../models/mod_config.dart';

// ---------------------------------------------------------
// RJ Aze Font (Mod 2) üçün xüsusi məlumatlar
// Ana səhifə (Home) bu obyekti oxuyaraq ekranda göstərəcək
// ---------------------------------------------------------

final ModConfig mod2Config = ModConfig(
  id: 'mod2',
  title: 'RJ Aze Font',
  author: 'Mr Ruhid',
  description: 'Oyunda Azərbaycan dilinə spesifik hərflərin normal görünməsi üçün önəmlidir.',
  logoPath: 'assets/mod/mod2/pp.webp', // Modun loqosu
  isLanguagePack: false, // Bu dil faylı deyil, font modudur
  isRequiredWithLang: true, // ƏN ƏSAS: Dil faylı yüklənəndə bu da mütləq yüklənməlidir
  priority: 1,
  operations: const [
    ModFileOperation(
      // Proqramın içindəki orjinal qovluğun yeri
      sourceAssetPath: 'assets/mod/mod2/mod/modURW_DinLite.zip',

      // Oyun qovluğunda kopyalanacağı hədəf.
      targetGamePath: 'mods',
      isDirectory: true, // Bunun bütöv bir qovluq olduğunu proqrama bildiririk
    ),
  ],
);