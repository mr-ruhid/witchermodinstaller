import '../../models/mod_config.dart';

// ---------------------------------------------------------
// RJ Geyim Paketi (Mod 5) üçün xüsusi məlumatlar
// Ana səhifə (Home) bu obyekti oxuyaraq ekranda göstərəcək
// ---------------------------------------------------------

final ModConfig mod5Config = ModConfig(
  id: 'mod5',
  title: 'RJ Geyim Paketi',
  author: 'Mr Ruhid',
  description: 'Oyunda xüsusi geyimlərdən istifadə edin.',
  logoPath: 'assets/mod/mod5/pp.webp', // Modun loqosu
  isLanguagePack: false,
  isRequiredWithLang: false,
  priority: 3, // Dərəcə 3: Digərlərinə nisbətən daha az əhəmiyyətli (və ya fərqli kateqoriya)
  isBeta: true, // YENİ: Bu modun Beta (sınaq) mərhələsində olduğunu bildirir
  operations: const [
    ModFileOperation(
      // Proqramın içindəki orjinal qovluğun yeri
      sourceAssetPath: 'assets/mod/mod5/mod/modRjGeyim',

      // Oyun qovluğunda kopyalanacağı hədəf.
      targetGamePath: 'mods/modRjGeyim',
      isDirectory: true, // Bunun bütöv bir qovluq olduğunu proqrama bildiririk
    ),
  ],
);