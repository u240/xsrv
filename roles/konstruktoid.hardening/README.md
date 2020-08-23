# ansible-role-hardening

Ansible role to make a CentOS, Debian, Fedora or Ubuntu server a bit more
secure, [systemd edition](https://freedesktop.org/wiki/Software/systemd/).

Requires [Ansible](https://www.ansible.com/) >= 2.8.

Available on [Ansible Galaxy](https://galaxy.ansible.com/konstruktoid/hardening).

## Distributions Tested using Vagrant

```yaml
bento/debian-10
bento/fedora-31
centos/8
ubuntu/bionic64
ubuntu/focal64
```

## Role Variables with defaults

### auditd

```yaml
auditd_mode: 1
```

Auditd failure mode. 0=silent 1=printk 2=panic.

```yaml
grub_audit_backlog_cmdline: "audit_backlog_limit=8192"
grub_audit_cmdline: "audit=1"
```

Enable `auditd` at boot using Grub.

### DNS

```yaml
dns: "127.0.0.1"
dnssec: allow-downgrade
fallback_dns: "1.1.1.1 9.9.9.9"
```

IPv4 and IPv6 addresses to use as system and fallback DNS servers.
If `dnssec` is set to "allow-downgrade" DNSSEC validation is attempted, but if
the server does not support DNSSEC properly, DNSSEC mode is automatically
disabled. [systemd](https://github.com/konstruktoid/hardening/blob/master/systemd.adoc#etcsystemdresolvedconf)
option.

### Disabled File System kernel modules

```yaml
fs_modules_blocklist:
  - cramfs
  - freevxfs
  - hfs
  - hfsplus
  - jffs2
  - squashfs
  - udf
  - vfat
```

Blocked file system kernel modules.

### File and Process limits

```yaml
limit_nofile_hard: 1024
limit_nofile_soft: 512
limit_nproc_hard: 1024
limit_nproc_soft: 512
```

Maximum number of processes and open files.

### Misc Disabled kernel modules

```yaml
misc_modules_blocklist:
  - bluetooth
  - bnep
  - btusb
  - cpia2
  - firewire-core
  - floppy
  - n_hdlc
  - net-pf-31
  - pcspkr
  - soundcore
  - thunderbolt
  - usb-midi
  - usb-storage
  - uvcvideo
  - v4l2_common
```

Blocked kernel modules.

### Disabled Network kernel modules

```yaml
net_modules_blocklist:
  - dccp
  - sctp
  - rds
  - tipc
```

Blocked kernel network modules.

### NTP

```yaml
ntp: "0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org"
fallback_ntp: "2.ubuntu.pool.ntp.org 3.ubuntu.pool.ntp.org"
```

NTP server host names or IP addresses. [systemd](https://github.com/konstruktoid/hardening/blob/master/systemd.adoc#etcsystemdtimesyncdconf)
option.

### Blocked packages

```yaml
packages_blocklist:
  - apport*
  - autofs
  - avahi*
  - avahi-*
  - beep
  - git
  - pastebinit
  - popularity-contest
  - rsh*
  - rsync
  - talk*
  - telnet*
  - tftp*
  - whoopsie
  - xinetd
  - yp-tools
  - ypbind
```

Packages to be removed.

### tcp_challenge_ack_limit kernel configuration

```yaml
random_ack_limit: "{{ 1000000 | random(start=1000) }}"
```

net.ipv4.tcp_challenge_ack_limit, see
[tcp: make challenge acks less predictable](https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=75ff39ccc1bd5d3c455b6822ab09e533c551f758).

### Ubuntu reboot

```yaml
reboot_ubuntu: false
```

If true an Ubuntu node will be rebooted if required, using
`pre_reboot_delay: "{{ 3600 | random(start=1) }}"`.

### RedHat RPM keys

```yaml
redhat_rpm_key:
  - 567E347AD0044ADE55BA8A5F199E2F91FD431D51
  - 47DB287789B21722B6D95DDE5326810137017186
```

[Red Hat RPM keys](https://access.redhat.com/security/team/key/)
for use when `ansible_distribution == "RedHat"`.

### OpenSSH daemon configuration

```yaml
sshd_admin_net:
  - 192.168.0.0/24
  - 192.168.1.0/24
sshd_allow_agent_forwarding: 'no'
sshd_allow_tcp_forwarding: 'no'
sshd_allow_groups: sudo
sshd_authentication_methods: any
sshd_log_level: VERBOSE
sshd_max_auth_tries: 3
sshd_max_sessions: 3
sshd_password_authentication: 'no'
sshd_port: 22
```

Only the network(s) defined in `sshd_admin_net` are allowed to
connect to `sshd_port`. Note that additional rules need to be set up in order
to allow access to additional services.

OpenSSH login is allowed only for users whose primary group or supplementary
group list matches one of the patterns in `sshd_allow_groups`.

`sshd_allow_agent_forwarding` specifies whether ssh-agent(1) forwarding is
permitted.

`sshd_allow_tcp_forwarding` specifies whether TCP forwarding is permitted.
The available options are `yes` or all to allow TCP forwarding, `no` to prevent
all TCP forwarding, `local` to allow local (from the perspective of ssh(1))
forwarding only or `remote` to allow remote forwarding only.

`sshd_authentication_methods` specifies the authentication methods that must
be successfully completed in order to grant access to a user.

`sshd_log_level` gives the verbosity level that is used when logging messages.

`sshd_max_auth_tries` and `sshd_max_sessions` specifies the maximum number of
SSH authentication attempts permitted per connection and the maximum number of
open shell, login or subsystem (e.g. sftp) sessions permitted per network
connection.

`sshd_password_authentication` specifies whether password authentication is allowed.

`sshd_port` specifies the port number that sshd(8) listens on.


## Recommended Reading

[CIS Distribution Independent Linux Benchmark v1.0.0](https://www.cisecurity.org/cis-benchmarks/)

[Common Configuration Enumeration](https://nvd.nist.gov/cce/index.cfm)

[Canonical Ubuntu 16.04 LTS STIG - Ver 1, Rel 2](https://public.cyber.mil/stigs/downloads/?_dl_facet_stigs=operating-systems%2Cunix-linux)

[Guide to the Secure Configuration of Red Hat Enterprise Linux 8](https://static.open-scap.org/ssg-guides/ssg-rhel8-guide-default.html)

[Red Hat Enterprise Linux 7 - Ver 2, Rel 3 STIG](https://public.cyber.mil/stigs/downloads/?_dl_facet_stigs=operating-systems%2Cunix-linux)

[Security focused systemd configuration](https://github.com/konstruktoid/hardening/blob/master/systemd.adoc)

## Contributing

Do you want to contribute? That's great! Contributions are always welcome,
no matter how large or small. If you found something odd, feel free to submit a
issue, improve the code by creating a pull request, or by
[sponsoring this project](https://github.com/sponsors/konstruktoid).

## License

Apache License Version 2.0

## Author Information

[https://github.com/konstruktoid](https://github.com/konstruktoid "github.com/konstruktoid")
