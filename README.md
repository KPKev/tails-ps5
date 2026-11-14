# Tails PS5

An experimental way to start **Tails 7.17 on a PS5** that already has a working PS5 Linux loader. In our physical test on **PS5 firmware 13.60**, Tails reached the Welcome screen, then a usable desktop. The keyboard, mouse, Terminal, Ethernet, Tor Connection, and Tor Browser worked. Tor Browser loaded [Tor's connection-check page](https://check.torproject.org/); the owner also reported a successful desktop and Tor connection after a fresh restart.

> **Read this first:** This is an *unofficial modified Tails build*, not a release from the Tails team. It has **not** had a complete security or anonymity audit on PS5 hardware. Do not depend on it for sensitive activity. See [what we actually checked](docs/SECURITY.md). It is also not a one-click PS5 jailbreak: you need a compatible, already working Linux-loader setup.

## What this does, in plain English

Think of the USB stick as a backpack holding Tails. The PS5 Linux loader starts a special PS5-compatible Linux kernel (`bzImage`). The kernel opens an early startup package (`initrd.img`), which gives it the drivers and display adjustments it needs. Then it opens the normal Tails files already on your USB stick and shows the Tails Welcome screen.

The **normal Tails files come from Tails**, not from this repo. Our changes replace the boot kernel and early startup package. A small text file (`cmdline.txt`) tells the loader which files to use and which USB stick contains Tails. The loader file (`ps5-linux-loader.elf`) is the [Sonic v13.60 release](https://github.com/soniciso1/ps5-linux-loader/releases/tag/v13.60), included in our release for convenience.

```text
PS5 home screen → your WebKit/Linux loader → special PS5 kernel
     → Tails startup files on USB → Tails Welcome → desktop → Tor
```

## What you need

- A PS5 with a **working PS5 Linux loader**. The physical test used system firmware **13.60** and the owner's WebKit/rest-mode sequence. Other firmware versions and PS5 models are **not tested by this project**.
- A **separate USB stick**, 8 GB or larger. Installing Tails erases that stick. Keep your working Ubuntu stick disconnected and unchanged.
- A Windows, Linux, or Mac computer to prepare the stick.
- A keyboard and mouse for the PS5.
- For the Tor test, an Ethernet cable from the PS5 to your router or switch. Wi-Fi support was not verified here.

## Download and prepare the USB stick

1. Download the **Tails 7.17 USB image** from [the official Tails download page](https://tails.net/install/download/). Use its verification instructions before installing it. For a new stick, follow [Tails' Windows installation guide](https://tails.net/install/windows/) or the guide for your computer. **Do not download Tails from this GitHub repo.**
2. Install Tails to the *spare* USB stick. This erases that stick. After installation, plug it back into the computer and open the small readable FAT partition. It contains a `live` folder; leave that folder and its contents alone.
3. Open [this project's release page](https://github.com/KPKev/tails-ps5/releases/tag/v0.1.0). Download its three files: `bzImage`, `initrd.img`, and `ps5-linux-loader.elf`. Check their SHA-256 values against [SHA256SUMS](SHA256SUMS). On Windows, open PowerShell in your Downloads folder and run `Get-FileHash .\bzImage -Algorithm SHA256`; repeat with the other two filenames. Compare the long result with the matching line in `SHA256SUMS`. A mismatched file should not be used.
4. Copy `bzImage` and `initrd.img` to the **top level** of the Tails FAT partition, beside the `live` folder. Keep the original Tails `live` folder. Copy `ps5-linux-loader.elf` there too.
5. On that same FAT partition, create folders named `ps5_autoloader` and `ps5_autoloader_webkit` if they are not already there. Put one copy of `ps5-linux-loader.elf` in **each** folder. In each folder, create `autoload.txt` containing exactly `ps5-linux-loader.elf` followed by a newline. If Windows hides file extensions, turn on **View → Show → File name extensions** so you do not accidentally make `autoload.txt.txt`. Existing loader installations may already have these files; back them up before replacing them.
6. Find the FAT partition's **volume ID**, which looks like `1234-ABCD`. On Windows, if that partition is `E:`, open Command Prompt and run `vol E:`. On Linux, `lsblk -f` shows the filesystem UUID. Use the ID of the **Tails FAT partition**, not your PC drive or another USB stick.
7. Download [cmdline.example.txt](cmdline.example.txt), replace `XXXX-XXXX` after `FSUUID=` with **your** FAT volume ID, and save the result as `cmdline.txt` at the top level of the Tails FAT partition. Keep it on **one line**. The sample deliberately leaves the optional diagnostic **off**, so it will not save hardware reports to your USB. The `nopersistence` option starts without unlocking old Persistent Storage.
8. Safely eject the USB stick from the computer. Keep your other Linux USB sticks disconnected during the PS5 test, since the loader can search more than one device.

Your readable FAT partition should now look roughly like this:

```text
Tails USB (FAT partition)
├── live/                         ← original Tails files; keep them
├── bzImage                       ← download from this project's release
├── initrd.img                    ← download from this project's release
├── cmdline.txt                   ← your volume ID, made from the example
├── ps5-linux-loader.elf
├── ps5_autoloader/
│   ├── autoload.txt
│   └── ps5-linux-loader.elf
└── ps5_autoloader_webkit/
    ├── autoload.txt
    └── ps5-linux-loader.elf
```

## Start Tails on the PS5

This is the **sequence used for the physical test**. The exact WebKit launcher depends on your existing PS5 setup; this repository does not install or configure that launcher.

1. Start the PS5 fresh and reach its normal PlayStation home screen. In our setup, the USB stick had to be **out during the fresh PS5 start**.
2. Plug in the prepared Tails USB stick after the PlayStation home screen appears. Keep other storage USB sticks disconnected.
3. Run the WebKit autoloader you normally use for PS5 Linux. In our setup, the PS5 entered rest mode automatically.
4. Wait for the orange rest-mode light to become steady. Press the PS5 power button once. The PS5 should resume into the Linux loader and then show **Welcome to Tails**.
5. Choose your language and click **Start Tails**. An Administration Password is **not required** for normal use. We did not unlock Persistent Storage during the test.
6. When the full desktop appears, open **Apps → Terminal** and run `echo TAILS-PS5-OK`. It should print `TAILS-PS5-OK`. This checks the desktop and keyboard, not privacy.

For Internet access, connect the PS5 Ethernet port to your **router or switch**, open Tails' Network settings, and make sure Wired IPv4 and DNS are set to **Automatic (DHCP)**. Then use the **Tor Connection** window. In the physical test, Tor connected and Tor Browser reached `https://check.torproject.org/`. A direct PS5-to-PC cable used in earlier testing had no Internet path. Do not add a manual `192.168.77.x` address unless you are deliberately setting up that isolated test network.

Shut Tails down from its top-right power menu before removing the USB stick. If the desktop ever sticks on a blue screen, our test unit could return to a usable shutdown screen with **Ctrl+Alt+F2** and then a short press of the PS5 power button. Wait until it is fully off before unplugging the stick.

## Troubleshooting

See [Troubleshooting](docs/TROUBLESHOOTING.md) for the white screen, blue screen, missing USB, wrong volume ID, Tor connection, and shutdown cases. The short version: check the three release-file hashes, the FAT volume ID in `cmdline.txt`, the `live` folder, and the exact PS5 startup sequence before changing anything else.

## How this was built and what is published

The [v0.1.0 release](https://github.com/KPKev/tails-ps5/releases/tag/v0.1.0) contains the boot files used for this experiment. The repository contains the changed startup scripts, the kernel configuration, checksums, and [build/provenance notes](docs/BUILD.md). It does **not** upload the Tails USB image, private console logs, photos, decrypted firmware, or the owner's Ubuntu stick. The included initrd has an **opt-in diagnostic** from development; the sample `cmdline.txt` keeps it off. See [Security](docs/SECURITY.md) before deciding whether this build is suitable for you.

This project is **unofficial** and not affiliated with or endorsed by Tails, Sony, PlayStation, or the PS5 Linux maintainers. Tails and PlayStation are trademarks of their respective owners. Thanks to the [Tails project](https://tails.net/), [PS5 Linux](https://github.com/ps5-linux), and [Sonic's 13.60 loader](https://github.com/soniciso1/ps5-linux-loader/releases/tag/v13.60).
