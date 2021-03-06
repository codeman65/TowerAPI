﻿# TowerAPI
This module is for interacting with the Ansible Tower/AWX API via PowerShell.

## Examples
```powershell
Get-TowerVersion -TowerURL https://awx.company.com
    instance_groups : {@{instances=System.Object[]; capacity=57; name=tower}}
    instances       : {@{node=localhost; heartbeat=2018-11-07T13:34:59.899959Z; version=3.3.0; capacity=57}}
    ha              : False
    version         : 3.3.0
    active_node     : localhost

Connect-AnsibleTower -TowerURL https://awx.company.com -credential $cred

Get-TowerInventory -TowerURL https://awx.company.com

Get-TowerHosts -TowerURL https://awx.company.com
```
