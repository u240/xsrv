gitlab-runner
=============

This role will install [Gitlab Runner](https://docs.gitlab.com/runner/
), a [Continuous Integration](https://en.wikipedia.org/wiki/Continuous_integration) worker for use with [Gitlab CI](https://en.wikipedia.org/wiki/GitLab), a self-hosted, full featured Git/project management/DevOps tool.

Gitlab is not included. This role is useful if you have a separate machine running GitLab and want to setup distributed CI machines. The runner must be registered on your GitLab instance.


Requirements
------------

This role requires Ansible 2.7 or higher.


Role Variables
--------------


Dependencies
------------

None

Example Playbook
----------------


License
-------

MIT


References
------------------

- https://github.com/haroldb/ansible-gitlab-runner
- https://docs.gitlab.com/runner/install/linux-repository.html
