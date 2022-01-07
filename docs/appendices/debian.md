# Debian

# Installation

## From your hosting provider

Most hosting/VPS providers will offer an option to install and preconfigure Debian on your server, and provide SSH connection details at the end of the installation process.

## From ISO image

- Download a [Debian 11 netinstall image](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/).
- Load the ISO image in your virtual machine's CD drive, or write the image to a 1GB+ USB drive (Linux: [`dd`](https://wiki.archlinux.org/index.php/USB_flash_installation_media#In_GNU.2FLinux), [GNOME disks](https://www.techrepublic.com/article/how-to-create-disk-images-using-gnome-disk/), Windows: [win32diskimager](http://sourceforge.net/projects/win32diskimager/)).
- Boot the server from the installer ISO image/USB.
- Select `Advanced > Graphical advanced install`.
- Follow the installation procedure, using the following options:
  - Set the machine's locale/language to English (`en_US.UTF-8`).
  - Set the correct keyboard layout for the keyboard that will be used for physical/console access in case of emergency.
  - IP address: either:
    - A static IP address and the correct network mask/gateway.
    - Or use automatic configuration/DHCP.
  - DNS resolver: either:
    - Your hosting/Internet provider's DNS resolver.
    - Or a [public DNS resolver](https://en.wikipedia.org/wiki/Public_recursive_name_server).
    - Or your private DNS server (for example a [pfSense](../appendices/pfsense.md) instance).
    - If using automatic network configuration/DHCP, a DNS resolver should be configured automatically.
  - Enable the `root` account, set a strong password and store it somewhere safe like a [KeepassXC](https://en.wikipedia.org/wiki/KeePassXC) database.
  - Do not create an additional user account yet.
  - Disk partitioning: use the appropriate partitioning scheme. Generic recommendations:
    - Use LVM (Logical Volumes) instead of raw partitions/disks if possible. This will greatly facilitate disk management (resizing, adding drives...).
    - Define a separate `/var` partition, make it as large as possible (services/user data is stored under `/var/`).
    - 10-15GB should be enough for the root `/` partition.
    - Set a size of 1GB for the `/boot` partition.
    - Add a small swap partition.
    - `noatime` and `nodiratime` mount options are recommended for better disk performance
    - Setup RAID if you need to keep services available in case of disk failure (RAID is not a backup)
  - When asked, only install `Standard system utilities` and `SSH server`
  - Finish installation and reboot to disk.

# Ansible requirements

From the server console, login as `root`:
- install requirements for remote admin/ansible access: `apt update && apt --no-install-recommends install python aptitude sudo openssh-server`
- create a user account for remote administration (replace `deploy` with the desired account name): `useradd --create-home --groups ssh,sudo --shell /bin/bash deploy`
- set the sudo password for this user account: `passwd deploy`
- lock the console: `logout`

# Automated installation

If the host is a VM running on your own hypervisor, you may want to save the initial Debian installation as a VM template, and reuse it for future deployments.
Use the virtualization platform's tools to create and reuse VM templates. See [virt-manager](../appendices/virt-manager.md).
