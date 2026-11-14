# Security and privacy status

This is an **experimental modified Tails build**. A successful Tor Browser check is a useful functional test; it is **not** a complete PS5 anonymity or leak-resistance certification.

## Seen on the tested PS5

- Firmware **13.60** booted Tails **7.17** to a full desktop. The owner used Terminal, keyboard, and mouse.
- One saved physical report showed Tails' firewall service and network namespace service active. It recorded IPv4 and IPv6 default-drop firewall policies, configured Tor redirects, five Tails network namespaces, and AppArmor enabled with enforced profiles.
- In a direct, isolated Ethernet test, three local pings to the PC succeeded. Three non-LAN ICMP probes were rejected locally, and the final firewall rejection counter increased by three packets and 252 bytes.
- With Ethernet connected to a router and the stale manual test address replaced by DHCP, Tails' Tor Connection reported success. Tor Browser loaded `https://check.torproject.org/`, which reported that browser configured for Tor. The owner reported a successful repeat after a fresh boot.

## Still unknown

- Whether **every** application and protocol is blocked from leaking outside Tor on this PS5 build.
- Whether the PS5 Ethernet MAC address is anonymized. We did not independently compare the permanent and observed addresses.
- Whether Wi-Fi works, and whether it would be safe to use in this build.
- Whether shutdown erases memory as intended. A VM shutdown test is not PS5 memory-wipe evidence.
- Whether any console firmware, loader, or other hardware behavior changes Tails' normal privacy model.
- Whether all other PS5 models or firmware versions work.

The PC packet recorder missed some traffic that was known to occur. Therefore, **missing packets in that capture cannot prove no traffic escaped**. The release's optional diagnostic can write hardware and system reports to the Tails USB when `ps5_graphics_diagnostic=1` is added to the command line. Those reports may contain private details. The sample command line leaves that option off. If you are relying on Tails for important privacy or safety, use an official supported Tails setup instead of assuming this experiment provides the same assurances.
