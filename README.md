# Ansible Collection - 2chevskii.windows

This collection contains plugins and roles built to manage windows hosts using Ansible

## Installation

Before using plugins and roles provided, you need to install the collection,
to make it's code available to your control node

### Ansible Galaxy

You can install collection using the `ansible-galaxy` CLI by invoking the following command

```sh
ansible-galaxy collection install 2chevskii.windows
```

Another option is to include the collection into your `requirements.yml` file like that

```yaml
---
collections:
  - name: 2chevskii.windows
```

Then, you can ensure installation by calling the `ansible-galaxy` CLI in the following way

```sh
ansible-galaxy collection install --requirements-file requirements.yml
```

## Modules

This collection provides the following modules

### WinGet (`2chevskii.windows.winget`)

This module manages Windows packages using the WinGet package manager

#### Module usage

Module usage resembles that of other package-management modules (like `ansible.builtin.apt`, for example)

```yaml
2chevskii.windows.winget:
  id: Package.Id # Must exactly match required package's ID, required
  state: present # One of present, latest, absent (default: present)
  version: 1.0.0 # Package version to install (incompatible with state=present)
```
