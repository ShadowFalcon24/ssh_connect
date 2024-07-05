# Check if SSHUtils module is installed, install it if not
if (-not (Get-Module -ListAvailable -Name SSHUtils)) {
    Install-Module -Name SSHUtils -Force
}

# Path to the configuration file
$configFilePath = Join-Path -Path $PSScriptRoot -ChildPath "ssh_connections.json"

# Function to load connection data from the configuration file
function Load-ConnectionData {
    param (
        [string]$ConfigFilePath
    )

    if (Test-Path $ConfigFilePath) {
        try {
            return Get-Content $ConfigFilePath | ConvertFrom-Json
        } catch {
            Write-Host "Error reading configuration file: $_"
            return @()
        }
    } else {
        Write-Host "No configuration file found at $ConfigFilePath. Creating a new one with example data."
        # Create example connection data
        $exampleConnections = @(
            @{
                Name = "Server1";
                Host = "server1.example.com";
                Port = 22;
                Username = "your_username";
                Password = ConvertTo-SecureString "your_password" -AsPlainText -Force
            },
            @{
                Name = "Server2";
                Host = "server2.example.com";
                Port = 22;
                Username = "your_username";
                Password = ConvertTo-SecureString "your_password" -AsPlainText -Force
            }
        )

        # Save example connection data to the configuration file
        Save-ConnectionData -ConfigFilePath $ConfigFilePath -Connections $exampleConnections

        # Return the example connections
        return $exampleConnections
    }
}

# Function to save connection data to the configuration file
function Save-ConnectionData {
    param (
        [string]$ConfigFilePath,
        [array]$Connections
    )

    try {
        $Connections | ConvertTo-Json | Set-Content $ConfigFilePath -Force
    } catch {
        Write-Host "Error saving configuration file: $_"
    }
}

# Load connection data from the configuration file
$connections = Load-ConnectionData -ConfigFilePath $configFilePath

# Function to display connection menu and let user choose a connection
function Show-ConnectionMenu {
    Write-Host "Available connections:"
    for ($i = 0; $i -lt $connections.Count; $i++) {
        Write-Host "$($i+1). $($connections[$i].Name)"
    }
    $choice = Read-Host "Enter the number of the connection to connect to"
    if ($choice -le 0 -or $choice -gt $connections.Count) {
        Write-Host "Invalid selection. Please choose a valid connection number."
        return $null
    }
    return $connections[$choice - 1]
}

# Function to establish SSH connection
function Connect-ToSSH {
    param (
        [string]$Host,
        [int]$Port,
        [string]$Username,
        [securestring]$Password
    )

    try {
        $session = New-SSHSession -ComputerName $Host -Port $Port -Credential (New-Object System.Management.Automation.PSCredential ($Username, $Password))

        if ($session) {
            Write-Host "Connected to $Host via SSH."
            # Additional commands or operations can be performed here using the SSH session
            Enter-PSSession $session
        } else {
            Write-Host "Failed to connect to $Host."
        }
    } catch {
        Write-Host "Error occurred while trying to connect: $_"
    }
}

# Main script
if ($connections.Count -eq 0) {
    Write-Host "No connections found. Please configure connections first."
    $exampleConnections = @(
        @{
            Name = "Server1";
            Host = "server1.example.com";
            Port = 22;
            Username = "your_username";
            Password = ConvertTo-SecureString "your_password" -AsPlainText -Force
        },
        @{
            Name = "Server2";
            Host = "server2.example.com";
            Port = 22;
            Username = "your_username";
            Password = ConvertTo-SecureString "your_password" -AsPlainText -Force
        }
    )
    Save-ConnectionData -ConfigFilePath $configFilePath -Connections $exampleConnections
    $connections = $exampleConnections
}

# Show menu and let user choose a connection
$selectedConnection = Show-ConnectionMenu

# Establish SSH connection if a valid selection was made
if ($selectedConnection) {
    Connect-ToSSH -Host $selectedConnection.Host -Port $selectedConnection.Port -Username $selectedConnection.Username -Password $selectedConnection.Password
}
