import '../../models/mod_config.dart';

// ---------------------------------------------------------
// Main Menu Music (Mod 3) üçün xüsusi məlumatlar
// Ana səhifə (Home) bu obyekti oxuyaraq ekranda göstərəcək
// ---------------------------------------------------------

final ModConfig mod3Config = ModConfig(
  id: 'mod3',
  title: 'Main Menu Music - Sara Qədimova Küsüb Getdi',
  author: 'Mr Ruhid',
  description: 'Milli musiqi ruhunu oyunda da yaşa',
  logoPath: 'assets/mod/mod3/pp.webp', // Modun loqosu
  isLanguagePack: false, // Bu dil faylı deyil
  isRequiredWithLang: false, // Məcburi deyil
  priority: 2, // ƏN ƏSAS: Bu musiqi modudur. Ana səhifə priority=2 olanlardan yalnız birini seçməyə icazə verəcək.
  operations: const [
    ModFileOperation(
      // Proqramın içindəki orjinal qovluğun yeri
      sourceAssetPath: 'assets/mod/mod3/mod/modRjMusic',

      // Oyun qovluğunda kopyalanacağı hədəf.
      targetGamePath: 'mods/modRjMusic',
      isDirectory: true, // Bunun bütöv bir qovluq olduğunu proqrama bildiririk
    ),
  ],
);