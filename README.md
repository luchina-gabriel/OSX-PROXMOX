# OSX-PROXMOX - Run macOS on ANY Computer - AMD & Intel

Install Proxmox VE v7.02 - Next, Next & Finish (NNF).

Open Proxmox Web Console -> Datacenter > NAME OF YOUR HOST > Shell.

Copy, paste and execute.

Voilà, install macOS! This is really and magic **easiest way**!

## COPY & PASTE - in shell of Proxmox

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/luchina-gabriel/OSX-PROXMOX/main/install.sh)"
```

## Versions of macOS Supported
* macOS High Sierra - 10.13
* macOS Mojave - 10.14
* macOS Catalina - 10.15
* macOS Big Sur - 11
* macOS Monterey - 12

## Versions of Proxmox VE Supported
* 7.0-2 ~ 7.0-11

## Opencore version
* November/2021 - 0.7.5 with SIP Enabled, DMG only signed by Apple and all features of securities.

## Disclaimer

- FOR DEV/STUDENT/TEST ONLY PURPOSES.
- I'm not responsible for any problem and/or equipment damage or loss of files. Always back up everything before any changes to your computer.

## Credits

- Opencore/Acidanthera Team
- Corpnewt for Applications (ProperTree, genSMBIOS, etc)
- Apple for macOS
- Proxmox - Excelent and better documentation for Virtualization
