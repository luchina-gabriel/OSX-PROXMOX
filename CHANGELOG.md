OpenCore Changelog
==================

#### Latest versions
- Check history of commits

#### v3.2.0

- Open SOURCE CODE of BINARY \o/
- Alter function '201 - Update Opencore ISO file' to download .ISO directly from repository;
- Add script in tools - CHECK-IOMMU.sh - Check if your IOMMU are ENABLED;
- Update macrecovery tool for Opencore 0.7.7;
- Update README;
- Adjustments to copyright terms.

#### v3.1.0

- Add support to run macOS in Cloud using this solution with VultR Provider;
- Add option to 'Remove Proxmox Subscription Notice';

#### v3.0.0

- Upgrade Opencore to 0.7.7;
- Upgrade Lilu and WhateverGreen Kexts;
- Add function '201 - Update Opencore ISO file';
- Add function '202 - Clear all Recovery Images';
- Add option to choose Storage in create VM;
- Fix minor bugs.

#### v2.0.1

- Fixed Opencore ISO disk size which was making booting impossible to install new virtual machines;

#### v2.0.0

- Upgrade to Opencore 0.7.6 (December/2021);
- Update Lilu (kext);
- Update VirtualSMC (kext);
- Fully compatible with Intel 12th and activate of all cores (P+E) and HT (Hyper-Threading);

#### v1.5.1

- Fix Menu Option - # 200;
- Cleaning some codes unnecessary in setup;

#### v1.5.0

- Fix QEMU 6.1 Passthrough in PVE 7.1+;
- Add option to "only ENTER" for exit osx-setup;

#### v1.4.0

- Add option to skip download and create recovery image of macOS;

#### v1.3.0

- Add script ```IOMMU-Groups.sh``` in tools;
- Add option 'Fix issues to start macOS (stuck at Apple logo) for Proxmox VE v7.1.XX';
- Add option 'Add Proxmox VE NO Subscription repository - for beta/non production upgrades';
- Remove option 'Activate support for Windows 11 natively'.

#### v1.2.0

- Remove PVE/Kernel version from ```osx-setup``` menu;
- Add option to define disk size in creation virtual machine section of ```osx-setup```;
- Add script in tools, for create macOS Install ```ISO``` from genuine macOS Installer .app.

#### v1.1.1

- Fix logic of messages in 'Activate support for Windows 11 natively' option;
- Fix typo's;

#### v1.1.0

- Including support for Proxmox VE v7 family;
- Fix for remove tmp directory;
- Including git for apt install option in install;
- Optimize procedure in 'Download & Create Recovery Image';
- Add return code for apt update/install in prereqs section and condition to exit/abort;
- Add support to install Windows 11 with TPM and Secure Boot;
- Update EFI ISO for including support to install Nvidia Web Drivers for High Sierra;

#### v1.0.0

- Initial version of OSX-Proxmox Solution
