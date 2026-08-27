<div align="center">
  
# 🚀 OSX-PROXMOX - Run macOS on ANY Computer (AMD & Intel)

![GitHub stars](https://img.shields.io/github/stars/luchina-gabriel/osx-proxmox?style=flat-square)
![GitHub forks](https://img.shields.io/github/forks/luchina-gabriel/OSX-PROXMOX?style=flat-square)
![GitHub license](https://img.shields.io/github/license/luchina-gabriel/osx-proxmox?style=flat-square)
![GitHub issues](https://img.shields.io/github/issues/luchina-gabriel/osx-proxmox?style=flat-square)

</div>

![v15 - Sequoia](https://github.com/user-attachments/assets/4efd8874-dbc8-48b6-a485-73f7c38a5e06)
Easily install macOS on Proxmox VE with just a few steps! This guide provides the simplest and most effective way to set up macOS on Proxmox, whether you're using AMD or Intel hardware.

---

## 🛠 Installation Guide

1. Install a **FRESH/CLEAN** version of Proxmox VE (v7.X.XX ~ 9.X.XX) - just follow the Next, Next & Finish (NNF) approach.
2. Open the **Proxmox Web Console** → Navigate to `Datacenter > YOUR_HOST_NAME > Shell`.
3. Copy, paste, and execute the command below:

```bash
/bin/bash -c "$(curl -fsSL https://install.osx-proxmox.com)"
```

## 🎉 Voilà! You can now install macOS!

<img width="1358" height="761" alt="osx-terminal" src="https://github.com/user-attachments/assets/5220cf15-6b2a-454e-a2c9-f5499c50ed0d" />

## 🔧 Additional Configuration

### Install EFI Package in macOS (Disable Gatekeeper First)

```bash
sudo spctl --master-disable
```

---

## 🍏 macOS Versions Supported
✅ macOS High Sierra - 10.13  
✅ macOS Mojave - 10.14  
✅ macOS Catalina - 10.15  
✅ macOS Big Sur - 11  
✅ macOS Monterey - 12  
✅ macOS Ventura - 13  
✅ macOS Sonoma - 14  
✅ macOS Sequoia - 15  
✅ macOS Tahoe - 26  

---

## 🖥 Proxmox VE Versions Supported
✅ v7.XX.XX ~ 9.XX.XX

### 🔄 OpenCore Version
- **March/2026 - 1.0.7** → with SIP Enabled, DMG only signed by Apple and all features of securities

---

## ☁️ Cloud Support (Run Hackintosh in the Cloud!)
- [🌍 VultR](https://www.vultr.com/?ref=9035565-8H)
- [📺 Video Tutorial](https://youtu.be/8QsMyL-PNrM) (Enable captions for better understanding)
- Now has configurable bridges, and can add as many bridges and specify the subnet for them.

---

## ⚠️ Disclaimer

🚨 **FOR DEVELOPMENT, STUDENT, AND TESTING PURPOSES ONLY.**

I am **not responsible** for any issues, damage, or data loss. Always back up your system before making any changes.

---

## 📌 Requirements

Since macOS Monterey, your host must have a **working TSC (timestamp counter)**. Otherwise, if you assign multiple cores to the VM, macOS may **crash due to time inconsistencies**. To check if your host is compatible, run the following command in Proxmox:

```bash
dmesg | grep -i -e tsc -e clocksource
```

### ✅ Expected Output (for working hosts):
```
clocksource: Switched to clocksource tsc
```

### ❌ Problematic Output (for broken hosts):
```
tsc: Marking TSC unstable due to check_tsc_sync_source failed
clocksource: Switched to clocksource hpet
```

### 🛠 Possible Fixes
1. Disable "ErP mode" and **all C-state power-saving modes** in your BIOS. Then power off your machine completely and restart.
2. Try forcing TSC in GRUB:
   - Edit `/etc/default/grub` and add:
     ```bash
     clocksource=tsc tsc=reliable
     ```
   - Run `update-grub` and reboot (This may cause instability).
3. Verify the TSC clock source:
   ```bash
   cat /sys/devices/system/clocksource/clocksource0/current_clocksource
   ```
   The output **must be `tsc`**.

[Read More](https://www.nicksherlock.com/2022/10/installing-macos-13-ventura-on-proxmox/comment-page-1/#comment-55532)

---

## 🔍 Troubleshooting

### ❌ High Sierra & Below - *Recovery Server Could Not Be Contacted*

If you encounter this error, you need to switch from **HTTPS** to **HTTP** in the installation URL:

1. When the error appears, leave the window open.
2. Open **Installer Log** (`Window > Installer Log`).
3. Search for "Failed to load catalog" → Copy the log entry.
4. Close the error message and return to `macOS Utilities`.
5. Open **Terminal**, paste the copied data, and **remove everything except the URL** (e.g., `https://example.sucatalog`).
6. Change `https://` to `http://`.
7. Run the command:

   ```bash
   nvram IASUCatalogURL="http://your-http-url.sucatalog"
   ```

8. Quit Terminal and restart the installation.

[Reference & More Details](https://mrmacintosh.com/how-to-fix-the-recovery-server-could-not-be-contacted-error-high-sierra-recovery-is-still-online-but-broken/)

### ❌ Problem for GPU Passthrough

If you see an Apple logo and the bar doesn’t move on your external display, you need to disable “above 4g decoding” in the motherboard’s BIOS.

In some environments it is necessary to segment the IOMMU Groups to be able to pass the GPU to the VM.

1. Add the content `pcie_acs_override=downstream,multifunction pci=nommconf` in the file `/etc/default/grub` at the end of the line `GRUB_CMDLINE_LINUX_DEFAULT`;
2. After changing the grub file, run the command `update-grub` and reboot your PVE.

---

## 🎥 Demonstration (in Portuguese)

📽️ [Watch on YouTube](https://youtu.be/dil6iRWiun0)  
*(Enable auto-translate captions for English subtitles!)*

---

## 🎖 Credits

- **OpenCore/Acidanthera Team** - Open-source bootloader
- **Corpnewt** - Tools (ProperTree, GenSMBIOS, etc.)
- **Apple** - macOS
- **Proxmox** - Fantastic virtualization platform & documentation

---

## 🌎 Join Our Community - Universo Hackintosh Discord

💬 [**Join Here!**](https://discord.universohackintosh.com.br)

