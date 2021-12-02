OpenCore Changelog
==================

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
