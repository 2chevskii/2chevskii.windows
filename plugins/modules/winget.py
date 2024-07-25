#!/usr/bin/python3

DOCUMENTATION = r'''
---
module: winget
short_description: Manages Windows packages using Winget
description:
  - Adds, removes, and updates Windows packages using Winget
options:
  id:
    description:
      - The package ID to manage. Must EXACTLY match package ID from the WinGet registry
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
      - Target package version, specified in Semantic Version or System.Version format
      - Cannot be used with state=latest
    type: str
author:
  - 2chevskii (prsroman3@gmail.com)
'''
