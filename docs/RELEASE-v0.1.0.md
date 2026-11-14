# Tails PS5 v0.1.0 — experimental boot files

This release contains the three boot files used in the PS5/Tails 7.17 experiment:

- `bzImage` — PS5-compatible Linux 7.1.7 kernel with the firewall modules needed by Tails.
- `initrd.img` — matching early startup image with PS5 modules and display adjustments.
- `ps5-linux-loader.elf` — exact copy of Sonic's published v13.60 loader asset.

The physical test used PS5 system firmware **13.60**. It reached the Tails desktop; Ethernet, Tor Connection, and Tor Browser worked. The owner reported a successful repeat after a fresh restart. Other firmware, models, and privacy properties are not fully verified. **This is not an official or security-certified Tails release.**

Install the [official Tails 7.17 USB image](https://tails.net/install/download/) first, then follow the [setup guide](https://github.com/KPKev/tails-ps5#download-and-prepare-the-usb-stick). The official Tails image and its live filesystem are not included here. Compare downloaded file hashes with [SHA256SUMS](https://github.com/KPKev/tails-ps5/blob/main/SHA256SUMS).

The `initrd.img` includes an optional development diagnostic that can write hardware and system information to the USB. It is **disabled** by the published `cmdline.example.txt`, because that example does not include `ps5_graphics_diagnostic=1`. See [Security](https://github.com/KPKev/tails-ps5/blob/main/docs/SECURITY.md) and [Build provenance](https://github.com/KPKev/tails-ps5/blob/main/docs/BUILD.md).
