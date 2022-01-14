# xsrv.monitoring_utils

This role will install and configure various [monitoring](../monitoring) and audit utilities:
- [lynis](https://cisofy.com/lynis/) security auditing tool
- [htop](https://hisham.hm/htop/) system monitor/process manager
- [nethogs](https://github.com/raboof/nethogs) network bandwidth monitor
- [ncdu](https://en.wikipedia.org/wiki/Ncdu) disk usage viewer, logwatch log analyzer

[![](https://screenshots.debian.net/screenshots/000/014/778/thumb.png)](https://screenshots.debian.net/package/htop)
[![](https://screenshots.debian.net/screenshots/000/014/778/thumb.png)](https://screenshots.debian.net/package/ncdu)

## Requirements/dependencies/example playbook

See [meta/main.yml](meta/main.yml)

```yaml
- hosts: my.CHANGEME.org
  roles:
    - nodiscc.xsrv.common # (optional) basic setup, hardening, firewall
    - nodiscc.xsrv.monitoring_utils
    # - nodiscc.xsrv.monitoring # (optional) full monitoring suite including monitoring_utils
```

See [defaults/main.yml](defaults/main.yml) for all configuration variables

### Usage

- Show htop process manager: `ssh -t user@my.CHANGEME.org sudo htop`
- Analyze disk usage by directory: `ssh -t user@my.CHANGEME.org sudo ncdu /`
- Show network bandwith usage by process: `ssh -t user@my.CHANGEME.org sudo nethogs`
- Show network connections: `ssh -t user@my.CHANGEME.org sudo watch -n 2 ss -laptu`
- Use [lnav](https://lnav.readthedocs.io/) to navigate/search/filter aggregated system logs:

```bash
# using https://xsrv.readthedocs.io/en/latest/
xsrv logs [project] [host]
# using ssh
ssh -t user@my.CHANGEME.org sudo lnav /var/log/syslog
```

Useful lnav commands:
- `:filter-in <expression>` only display messages matching filter expression
- `:set-min-log-level debug|info|warning|error` only display messages above a defined log level.
- `:<TAB><TAB>` display internal command list
- `Ctrl+R` clear all filters/reset session
- `?` lnav help
- `q` exit lnav

To be able to read system logs as a non-root/sudoer user, add your user to the `adm` group. Example using the [../common](common) role:

```yaml
linux_users:
   - name: "{{ ansible_user }}"
     groups: adm
     append: yes
     comment: "ansible user/allowed to read system logs"
```

## License

[GNU GPLv3](../../LICENSE)


## References

- https://stdout.root.sx/links/?searchtags=monitoring
- https://stdout.root.sx/links/?searchtags=security