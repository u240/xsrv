xsrv.libvirt

This role will install and configure [libvirt], a collection of software that provides a convenient way to manage virtual machines and other virtualization functionality, such as storage and network interface management.


## Requirements/dependencies/example playbook

- Ansible 2.10 or higher on ansible controller
- Debian GNU/Linux 10 on host


## Requirements/dependencies/example playbook

See [meta/main.yml](meta/main.yml)

```yaml
# playbook.yml
- hosts: my.CHANGEME.org
  roles:
    - nodiscc.xsrv.libvirt
```

See [defaults/main.yml](defaults/main.yml) for all configurable variables

## License


[GNU GPLv3](../../LICENSE)

## References

- https://stdout.root.sx/links/?searchterm=libvirt
- https://stdout.root.sx/links/?searchtags=virtualization

