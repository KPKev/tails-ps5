# Troubleshooting

Start with the easiest checks. Change **one thing at a time**, and keep your known-working Ubuntu USB separate.

| What you see | What to check |
|---|---|
| PS5 returns to its normal home screen | Your WebKit/Linux loader might not have started. Use the same loader sequence that already works on your console. Wait for steady orange rest-mode light before pressing power. This does not by itself prove that Tails is broken. |
| Loader cannot find a kernel or USB | Put `bzImage`, `initrd.img`, and `cmdline.txt` at the **top level** of the Tails FAT partition. Keep the Tails `live` folder. Disconnect other storage USB sticks, because the loader may search more than one. Check the two `ps5_autoloader` folders and `autoload.txt` files. |
| Tails cannot find its live filesystem | Check the `FSUUID=` value in `cmdline.txt`: it must match the Tails FAT partition's volume ID, with the same hyphen. Check that the official Tails `live` folder was not removed. |
| Solid white screen | Earlier test images reached this state before the 1080p/display fixes. Confirm the release file hashes and that `amdgpu.force_1080p=1` is in your `cmdline.txt`. Try a 1080p-capable display/input. Do not keep blindly rebooting the same broken setup. |
| Tails Welcome appears, but the screen turns blue after **Start Tails** | Earlier images made the GNOME desktop crash. Confirm you downloaded the **v0.1.0** initrd and matching kernel; old images will give misleading results. A blue background with only the top bar is **not** a complete desktop. |
| No keyboard or mouse response | Try another PS5 USB port or a simple wired keyboard/mouse. Do not remove the Tails boot USB while the console is on. |
| Tor says it cannot connect | First check that Ethernet goes to your **router**, not just directly to a PC. In Tails Network settings, choose **Automatic (DHCP)** for IPv4 and DNS. A leftover manual `192.168.77.1` / `192.168.77.2` test setup blocked Internet in our run. Also check the clock: a date that is days wrong can stop Tor connecting. |
| `eth0` says unavailable | Check the physical Ethernet cable and router port. The PS5's built-in Wi-Fi was not verified in this project. |
| You want `sudo` but it asks for a password | Set a temporary **Administration Password** in Tails' Welcome screen *before* clicking Start Tails. It is not required for ordinary browsing. Do not post your password in an issue or screenshot. |
| Shutdown menu is missing on a blue screen | In our test, **Ctrl+Alt+F2** changed to a screen from which a short PS5 power-button press shut down. Wait until the console is fully off before removing the USB. |

## If it still fails

Open a GitHub issue with: your PS5 model and firmware, Tails version, which of the steps above you reached, exact error text, and SHA-256 hashes of your three downloaded boot files. **Do not upload** logs or photos containing IP addresses, MAC addresses, USB IDs, usernames, passwords, Tor activity, or other personal details. Do not claim a screenshot of Tor Browser proves all traffic is protected.
