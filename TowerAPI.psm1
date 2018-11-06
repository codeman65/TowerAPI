# Implement your module commands in this script.
#Create Connect-AnsibleTower function
function Connect-AnsibleTower {
    #Define Parameters
    Param (
        [Parameter(Mandatory = $True)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter(Mandatory = $true)]
        [string]$TowerURL
    )

    #Hard Set TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    #Create Empty Header to hold authorization token
    $global:header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

    #Collect login info
    $Credential.Password | ConvertFrom-SecureString
    $RestAPIPassword = $Credential.GetNetworkCredential().Password

    #Set Tower information and convert login info to proper format
    $BaseURL = $TowerURL + "/api/v2/"
    $TowerSessionURL = $BaseURL + "authtoken/"
    $User = @{ "username" = $Credential.UserName }
    $Pass = @{ "password" = $RestAPIPassword}
    $AuthField = $User + $Pass
    $Body = $AuthField | ConvertTo-Json
    $Type = "application/json"

    #Login to Tower API
    $TowerSessionRespon = Invoke-RestMethod -Uri $TowerSessionURL -Body $body -Method Post -ContentType $type

    #Create Authorization header
    $header.Add("Authorization", "Bearer " + $TowerSessionRespon.token)
}

function Get-TowerInventory {
    #Define parameters
    Param (
        [Parameter(Mandatory = $true)]
        [string]$TowerURL
    )

    #Hard Set TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    #Define Tower URL Inventory Endpoint
    $InventoryURL = $TowerURL + "/api/v2/inventories/"
    try {
        Invoke-RestMethod -Uri $InventoryURL -Method Get -Headers $header -ContentType "application/json" -ErrorAction stop | Select-Object -ExpandProperty Results | Select-Object -Property * -ExcludeProperty related
    }
    catch {
        Connect-AnsibleTower -TowerURL $TowerURL
        Get-TowerInventory -TowerURL $TowerURL
    }
}

function Get-TowerVersion {
    #Define parameters
    Param (
        [Parameter(Mandatory = $true)]
        [string]$TowerURL
    )

    #Hard Set TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    #Define ping endpoint to get Tower version
    $PingURL = $TowerURL + "/api/v2/ping"
    try {
        Invoke-RestMethod -Uri $PingURL -ErrorAction stop
    }
    catch {
        Write-Output "No response from Tower, are you sure $towerurl is correct?"
    }
}

function Get-TowerHosts{
    Param (
        [Parameter(Mandatory = $true)]
        [string]$TowerURL
    )
    #Hard Set TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $HostsURL = $TowerURL + "/api/v2/hosts/"

    try {
        $Hosts = Invoke-RestMethod -Uri $HostsURL -Method Get -Headers $header -ContentType "application/json" -ErrorAction stop
        $Loop = $hosts.next
        do{
            $NextURL = $TowerURL + $hosts.next
            $hosts = Invoke-RestMethod -Uri $NextURL -Method Get -Headers $header -ContentType "application/json"
            $loop = $hosts.next
            $hosts | Select-Object -ExpandProperty Results | Select-Object -Property * -ExcludeProperty related
        }While ($loop -ne $null)
    }
    catch {
        Connect-AnsibleTower -TowerURL $TowerURL
        Get-TowerHosts -TowerURL $TowerURL
    }
}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Export-ModuleMember -Function *-*
