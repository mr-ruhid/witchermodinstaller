<div align="center">
  <img src="https://ruhidjavadov.site/app/tw3/photo/logo.webp" alt="Witcher 3 Mod Manager Logo" width="300"/>
  <h1>The Witcher 3 · Mod Manager & Localizer ⚔️</h1>
  <p><b>An advanced, AAA-style desktop application for managing mods and localizing The Witcher 3: Wild Hunt.</b></p>
  
  <a href="https://ruhidjavadov.site/app/tw3/#">Download App</a> • 
  <a href="https://discord.gg/epPgUekEU2">Discord Community</a>
</div>

<br>

## 📜 About the Project

**The Witcher 3 Mod Manager & Localizer** is a robust, beautifully designed desktop application built with Flutter. Originally created to seamlessly deliver the **Azerbaijani language pack** and custom fonts to the local community, it has evolved into a fully-fledged mod manager. 

Featuring a modern Glassmorphism UI with immersive particle effects, this tool allows players to install, toggle, and prioritize third-party mods, bypass default launchers, and safely edit game configuration files with zero manual effort.

## ✨ Key Features

* 🚀 **Smart Path Detection:** Automatically locates your game directory (Steam/GOG) and the `Documents\The Witcher 3` folder. Features a "Deep Scan" fallback for custom install locations.
* 📦 **Universal Mod Extraction:** Drag & drop support for `.zip`, `.rar`, and `.7z` archives. The app uses an intelligent algorithm to find nested `mod...` folders and extracts them perfectly to the game directory using an integrated `7za.exe` engine.
* 🛡️ **Conflict Resolution (Priority System):** Automatically updates the `mods.settings` file. When you install a mod, it assigns priorities and safely disables (`Enabled=0`) older conflicting mods in the same category.
* ⚡ **Clean Launch (Bypass):** Launch the game directly from the app or via a generated desktop shortcut, completely bypassing the CDPR Red Launcher for a faster startup.
* 🌐 **Built-in Translation Toolkit:** Includes a direct shortcut to launch `w3strings.exe` (with its required DLLs) directly from the app's assets, empowering community translators.
* 🔄 **Auto-Updater:** Built-in JSON-based version checker that notifies users instantly when a new release is available on the server.
* 🎨 **Immersive UI:** A stunning, borderless AAA launcher interface with dynamic fire/ember particle systems and smooth transitions.

## 📥 How to Download & Install

1. Download the latest `Setup.exe` from our official website:<br>
   👉 **[Download Mod Manager](https://ruhidjavadov.site/app/tw3/#)**
2. Run the installer. It will automatically install the app and create a desktop shortcut.
3. **IMPORTANT:** Right-click the installed app and select **"Run as Administrator"**. This is required because Windows prevents standard apps from writing files to the `C:\Program Files` directory where your game might be installed.

## 🕹️ How to Use

* **Installing Official Packs:** Select the Language Pack or Fonts from the Home screen and click "Install".
* **Adding Third-Party Mods:** Navigate to the **Mod Manager** tab, click "Install External Mod", and select your downloaded archive (`.rar`, `.7z`, `.zip`).
* **Managing Mods:** Toggle mods on/off or adjust their load priority directly from the Mod Manager interface. Changes are instantly saved to `mods.settings`.

## 🛠️ Technologies Used

* **Frontend:** Flutter (Dart) for Windows Desktop
* **Window Management:** `window_manager` for custom, borderless frames.
* **Extraction Engine:** `archive` (Dart) for ZIPs, and integrated `7-Zip CLI` for RAR/7Z archives.
* **Installer Setup:** Inno Setup 6 (Customized with Azerbaijani localization).
* **Backend:** PHP & JSON (for the community translation database and auto-updater).

## ☕ Support & Donate

This project is completely **free and open-source**. If you appreciate the hundreds of hours spent building this tool and translating the game, consider supporting the development. Your motivation keeps this project alive!

* ☕ **Kofe.al:** [@ruhidjavadoff](https://kofe.al/ruhidjavadoff)
* 🍵 **Çayvoy:** [ruhid4715](https://cayvoy.com/donate/ruhid4715)
* 💳 **PayPal:** `ruhidjavadoff@gmail.com`
* 🪙 **Crypto (USDT - BNB Smart Chain):** `0x9a4AD41762D6B07B8C266b312Cf0dBe31FAd890c`

<br>

<p align="center">
  <i>The Witcher® 3: Wild Hunt © CD PROJEKT RED. <br>This is an unofficial community/fan-made tool.</i>
</p>

