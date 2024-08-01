#!/usr/bin/python3

DOCUMENTATION = r'''
---
module: powershell_get_module
short_description: Manages PowerShell modules using PowerShellGet
description:
  - Adds, removes, and updates PowerShell modules using PowerShellGet
options:
  name:
    description:
      - The name of the module to manage
    type: str
    required: true
  state:
    description:
      - Target package state
    type: str
    choices: [ present, latest, absent ]
    default: present
  version:
    description:
      - Target package version
      - Cannot be used with state=latest
    type: str
  scope:
    description:
      - The package scope
    type: str
    choices: [ current_user, all_users ]
    default: current_user
author:
  - 2chevskii (prsroman3@gmail.com)
'''
