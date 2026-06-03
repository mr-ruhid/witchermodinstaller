import '../../models/mod_config.dart';

// ---------------------------------------------------------
// Main Menu Music 2 (Mod 4) üçün xüsusi məlumatlar
// Ana səhifə (Home) bu obyekti oxuyaraq ekranda göstərəcək
// ---------------------------------------------------------

final ModConfig mod4Config = ModConfig(
  id: 'mod4',
  title: 'Imamyar Hasanov & Nermine Memmedova - Ay Isigi',
  author: 'Mr Ruhid',
  description: 'Milli musiqi ruhunu oyunda da yaşa', // Digər musiqi modunda olduğu kimi eyni açıqlamanı saxladım
  logoPath: 'assets/mod/mod4/pp.webp', // Modun loqosu
  isLanguagePack: false,
  isRequiredWithLang: false,
  priority: 2, // ƏN ƏSAS: Bu da musiqi modudur (mod3 kimi). Sistem toqquşmanın qarşısını alacaq.
  operations: const [
    ModFileOperation(
      // Proqramın içindəki orjinal qovluğun yeri
      sourceAssetPath: 'assets/mod/mod4/mod/modRj2Music.zip',

      // Oyun qovluğunda kopyalanacağı hədəf.
      targetGamePath: 'mods',
      isDirectory: true, // Bunun bütöv bir qovluq olduğunu proqrama bildiririk
    ),
  ],
);