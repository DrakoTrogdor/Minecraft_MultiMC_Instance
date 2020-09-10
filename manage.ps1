<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Object
Parameter description

.PARAMETER ForegroundColor
Parameter description

.PARAMETER BackgroundColor
Parameter description

.PARAMETER Seperator
Parameter description

.PARAMETER NoNewLine
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
#############################
# Declare Script Parameters #
#############################
[CmdletBinding()]
param (
	[Parameter()]
	[switch]
	$WhatIF,
	[Parameter()]
	[switch]
	$ForcePull
)

#####################
# Declare Functions #
#####################
function Write-Console {
    # This function exists to make upgrading from terminal/console to an application easier.
	param (
		[Parameter(Mandatory=$true, Position = 0)][System.Object]$Object,
		[Parameter(Mandatory=$false)][ConsoleColor]$ForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
		[Parameter(Mandatory=$false)][ConsoleColor]$BackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
		[Parameter(Mandatory=$false)]$Seperator = ' ',
		[switch]$NoNewLine
	)
	Write-Host $Object -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewline:$NoNewLine -Separator $Seperator
}
function Write-DebugInfo {
	param (
		[Parameter(Mandatory=$true, Position = 0)][string[]]$String,
		[switch]$NoHeader,
		[switch]$NoFooter
	)
	if ($script:ShowDebugInfo) {
		[int]$dividerLength = 0
		$String | ForEach-Object { if (($_.Length + 8) -gt $dividerLength) { $dividerLength = $_.Length + 8 }}
		if (!$NoHeader) {
			Write-Console ('-' * $dividerLength) -ForegroundColor DarkGray
			Write-Console 'Debugging Information:' -ForegroundColor DarkGray
		}
		$String | ForEach-Object {Write-Console ("`t{0}" -f $_) -ForegroundColor DarkGray }
		if (!$NoFooter) {
			Write-Console ("-" * $dividerLength) -ForegroundColor DarkGray
		}
	}
}
Function ExitScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][string]$Path = $null
    )
	Write-Console "Exiting Script..."
	#PressAnyKey
    If (!($script:ShowDebugInfo)) { Clear-Host ; Clear-History}
    if (-not [string]::IsNullOrWhiteSpace($Path)) { Set-Location -Path $Path }
	Exit
}
Function PressAnyKey {
    Write-Console "Press any key to continue ..."
    [System.Boolean]$anyKey = $false
    do {
        [System.Management.Automation.Host.KeyInfo]$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,AllowCtrlC")
        switch ($x.VirtualKeyCode) {
            {$_ -in 16,17,18} { $anyKey = $false; break; } # Shift, Control, Alt
            {$_ -in 45, 46} {
                # Shift Insert (45)  or Delete (46) - Paste or Cut
                if ($x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::ShiftPressed) { $anyKey = $false}
                # CTRL Insert (45) - Copy
                elseif ($x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::LeftCtrlPressed -or $x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::RightCtrlPressed) { $anyKey = $false}
                else { $anyKey = $true}
                break
            }
            {$_ -in 65,67,86,88} {
                # CTRL A (65), C (67), V (86), or X(88) - Select all, Copy, Paste, or Cut
                if ($x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::LeftCtrlPressed -or $x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::RightCtrlPressed) { $anyKey = $false}
                # CTRL A (65), C (67), V (86), or X(88) - Select all, Copy, Paste, or Cut
                elseif ($x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::LeftAltPressed -or $x.ControlKeyState -eq [System.Management.Automation.Host.ControlKeyStates]::RightAltPressed) { $anyKey = $false}
                else { $anyKey = $true}
                break
            }
            Default { $anyKey = $true }
        }
    } while (-not $anyKey)
}
function YesOrNo {
	param (
		[Parameter(Mandatory=$false)][string]$Prompt = "Is the above information correct? [y|n]"
	)
	[string]$response = ""
	while ($response -notmatch "[y|n]"){
		$response = Read-Host $Prompt
	}
	if ($response -match "y") { Return $true }
	else { Return $false }
}
function Show-Choices {
	param (
		[Parameter(Mandatory=$false)][string]$Title = 'Select one of the following:',
		[Parameter(Mandatory=$false)][string]$Prompt = '',
		[Parameter(Mandatory=$true)]$List,
		[Parameter(Mandatory=$false)][string]$ObjectKey = '',
		[Parameter(Mandatory=$false)][boolean]$ClearScreen = $false,
		[Parameter(Mandatory=$false)][boolean]$ShowBack = $false,
        [Parameter(Mandatory=$false)][boolean]$ShowExit = $true,
        [Parameter(Mandatory=$false)][string]$ExitPath = $null,
        [Parameter()][switch]$NoSort
	)
	if ([string]::IsNullOrWhiteSpace($ObjectKey)) { $ObjectKey = "Name"}
	if ($List.Count -eq 1) {
		Write-DebugInfo -String 'List Count is 1'
		Return $List[0]
	} elseif ($List.Count -le 0) {
		Write-DebugInfo -String 'List Count is less than 1'
		Return $null
	} else {
		if ($ClearScreen -and !($script:ShowDebugInfo)) { Clear-Host }
		Write-Console $Title
		[string]$listType = $List.GetType().Fullname
		Write-DebugInfo -String "List Type: $listType","List Count: $($List.Count)"
		[string[]]$MenuItems = @()
		switch ($listType) {
			'System.Collections.Hashtable' {
                if($NoSort){ $MenuItems = ($List.Keys | ForEach-Object ToString) }
				else { $MenuItems = ($List.Keys | ForEach-Object ToString) | Sort-Object }
				break
			}
			'System.Object[]' {
				if($NoSort){
                    $List | ForEach-Object {
                        $MenuItem = $_
                        if ($MenuItem.GetType().FullName -eq 'System.Management.Automation.PSCustomObject') { $MenuItems += $MenuItem.$ObjectKey }
                        else { $MenuItems += $MenuItem }
                    }
                }
                else {
                    $List | Sort-Object | ForEach-Object {
                        $MenuItem = $_
                        if ($MenuItem.GetType().FullName -eq 'System.Management.Automation.PSCustomObject') { $MenuItems += $MenuItem.$ObjectKey }
                        else { $MenuItems += $MenuItem }
                    }
                }
                break
            }
            'SourceSubModule[]' {
                if($NoSort) { foreach ($listItem in $List) { $MenuItems += $listItem.GetFinalName() } }
                else { foreach ($listItem in ($List | Sort-Object -Property @{Expression = {$_.GetFinalName()};Descending = $false})) { $MenuItems += $listItem.GetFinalName() } }
                break
            }
            {$_ -in 'GitRepo[]','GitRepoForked[]'} {
                if($NoSort) { foreach ($listItem in $List) { $MenuItems += $listItem.Name } }
                else { foreach ($listItem in ($List | Sort-Object -Property Name)) { $MenuItems += $listItem.Name } }
                break
            }
            {$_ -in 'BuildType[]','BuildTypeJava[]','BuildTypeGradle[]','BuildTypeMaven[]'} {
                if($NoSort) { foreach ($listItem in $List) { $MenuItems += $listItem.Origin } }
                else { foreach ($listItem in ($List | Sort-Object -Property Origin)) { $MenuItems += $listItem.Origin } }
                break
            }
			Default {
                if($NoSort) { $MenuItems = $List }
                else { $MenuItems = $List | Sort-Object }
				break
			}
		}
		[int]$counter = 1
		$MenuItems | ForEach-Object {
			Write-Console("`t{0}.  {1}" -f $counter,$_)
			$counter += 1
		}
		[int]$lowerBound = 1
		[int]$upperBound = $MenuItems.Count
		if ($ShowBack) { [string]$showBackString = '|(B)ack' } else { [string]$showBackString = '' }
		if ($ShowExit) { [string]$showExitString = '"|(Q)uit' } else { [string]$showExitString = '' }
		Write-DebugInfo "Lower Bound: $lowerBound","Upper Bound: $upperBound"
		[string]$selectionString = "[{0}-{1}{2}{3}]" -f $lowerBound,$upperBound,$showBackString,$showExitString
		if (([string]::IsNullOrWhiteSpace($Prompt))) { $Prompt = "Enter {0}" -f $selectionString }
		else { $Prompt += " {0}" -f $selectionString }
		[boolean]$exitLoop = $false
		do {
			[string]$response = Read-Host $Prompt
			$response = $response.Trim()
			Write-DebugInfo -String "Response: $response" -NoFooter
			switch -regex ( $response ) {
				'[b|back]' {
					$return = $null
					$exitLoop = $true
					break
				}
				'[q|quit|e|exit]' {
					ExitScript -Path $ExitPath
					break
				}
				Default {
					try {
						[int]$choice = $null
						if ([int32]::TryParse($response, [ref]$choice)) {
							Write-DebugInfo -String "Choice: $choice" -NoHeader
						}
						else {
							$choice = -1
							Write-DebugInfo -String "Choice could not parse: $choice" -NoHeader
						}
					}
					catch { [int]$choice = -1 }
					if (($null -ne $choice) -and ($choice -ge $lowerBound) -and ($choice -le $upperBound)) {
						[int]$choice = $choice - 1
						if ($ClearScreen -and !($script:ShowDebugInfo)) { Clear-Host }
						switch ($listType) {
							'System.Collections.Hashtable' {
								$return = $List.Get_Item($MenuItems[$choice])
								break
							}
							'System.Object[]' {
								$List | ForEach-Object {
									if ($_.GetType().FullName -eq 'System.Management.Automation.PSCustomObject') {
										$return = ($List | Where-Object {$_.$ObjectKey -eq $MenuItems[$choice]} | Select-Object -First 1)
									} else {
										$return = ($List | Where-Object {$_ -eq $MenuItems[$choice]} | Select-Object -First 1)
									}
								}
								break
                            }
                            'SourceSubModule[]' {
                                $return = $List | Where-Object { $_.GetFinalName() -eq $MenuItems[$choice] } | Select-Object -First 1
								break
                            }
                            {$_ -in 'GitRepo[]','GitRepoForked[]'} {
                                $return = $List | Where-Object { $_.Name -eq $MenuItems[$choice] } | Select-Object -First 1
								break
                            }
                            {$_ -in 'BuildType[]','BuildTypeJava[]','BuildTypeGradle[]','BuildTypeMaven[]'} {
                                $return = $List | Where-Object { $_.Origin -eq $MenuItems[$choice] } | Select-Object -First 1
                                break
                            }
                            Default {
								$return = $MenuItems[$choice]
								break
							}
						}
						Write-Console("Selected:  {0}" -f $MenuItems[$choice])
						$exitLoop = $true
					} else {
						$exitLoop = $false
					}
					break
				}
			}
		} while (!$exitLoop)
		Return $return
	}
}
function Show-Menu {
	param (
		[Parameter(Mandatory=$true)][System.Collections.Hashtable]$HashTable,
		[Parameter(Mandatory=$false)][boolean]$ShowBack = $false
	)
	[boolean]$exitLoop = $false
	do {
		$choice = Show-Choices -Title 'Select menu item.' -List $HashTable -ClearScreen $true -ShowBack $ShowBack
		if ([string]::IsNullOrWhiteSpace($choice)) {
			$exitLoop = $true
		} else {
			if ($choice.GetType().FullName -eq 'System.Collections.HashTable') {
				Show-Menu -HashTable $choice -ShowBack $true
			} else {
				&($choice)
				if ($script:ShowPause) { PressAnyKey }
			}
		}
	} while (-not $exitLoop)
}
function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }

        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )

            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}
function LoadManageJSON {
    param (
        [string]$JsonContentPath,
        [string]$JsonSchemaPath
    )
    
    # Load JSON and JSON schema into strings
    $stringJsonContent = Get-Content -Path $JsonContentPath -Raw
    $stringJsonSchema  = Get-Content -Path $JsonSchemaPath  -Raw

    # Test the JSON based on the schema and return an empty SourceSubModule array if there are any error
    if (Test-Json -Json $stringJsonContent -Schema $stringJsonSchema){
        # Convert the JSON content string into a JSON object
        [Hashtable]$script:ManageJSON = ConvertFrom-Json -InputObject $stringJsonContent -AsHashtable
    }
    else {
        [Hashtable]$script:ManageJSON = $null
    }


}
function LoadConfiguration {
    param (
        [Hashtable]$ConfigurationData
    )
    if (-not $null -eq $ConfigurationData) {
        ## URL for forked GIT Repositories
        [string]$script:myGit_URL = $ConfigurationData.myGit_URL

        ## JAVA_HOME alternatives
        $script:JAVA_HOME = $ConfigurationData.JAVA_HOME

        ## Show Debugging Information
        [boolean]$script:ShowDebugInfo = ($ConfigurationData.ShowDebugInfo)
    }
}
function LoadSourceSubModules {
    param (
        [Hashtable[]]$SubmodulesData,
        [ref]$SourcesArray
    )

    # Sets the initial return value as a blank array of [SourceSubModule]
    [SourceSubModule[]]$ReturnSources = [SourceSubModule[]]@()

    # If the SubmodulesData is not null proceed to iteratation
    if ($null -ne $SubmodulesData ) {
        # Iterate through the submodules
        foreach($item in $SubmodulesData){
            # Set the JAVA_HOME property if it exists
            if ($item.Build.Contains('JAVA_HOME')){
                [int]$version = $item.Build.JAVA_HOME
                [string]$path = $script:JAVA_HOME.$version
                $item.Build.JAVA_HOME = [string]::IsNullOrWhiteSpace($path) ? $null : $path
            }
            $ReturnSources += [SourceSubModule]::new($item)
        }
    }
    #return $ReturnSources
    $SourcesArray.Value = $ReturnSources
}
Function Invoke-CommandLine ($command, $workingDirectory, $timeout) {
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $env:ComSpec
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    if ($null -eq $workingDirectory) { $pinfo.WorkingDirectory = (Get-Location).Path }
    else { $pinfo.WorkingDirectory = $workingDirectory }
    $pinfo.Arguments = "/c $command"
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    if ($null -eq $timeout) { $timeout = 5 }
	Wait-Process $p.Id -Timeout $timeout -EA:0
	$stdOutput = $p.StandardOutput.ReadToEnd()
	$stdError  = $p.StandardError.ReadToEnd()
	$exitCode  = $p.ExitCode
    [pscustomobject]@{
        StandardOutput = $stdOutput
        StandardError = $stdError
        ExitCode = $exitCode
    }
}
function Show-WhatIfInfo() {
    if ($WhatIF) {
        if ($ForcePull) {
            Write-Host 'In WhatIF mode with Force Pull. Only a git pull will occur.' -ForegroundColor Black -BackgroundColor Yellow -NoNewline;Write-Host ' '
        }
        else {
            Write-Host 'In WhatIF mode. No changes will occur.' -ForegroundColor Black -BackgroundColor Yellow -NoNewline;Write-Host ' '
        }
    }
}
function Show-DirectoryInfo() {
    Write-Host "$('=' * 120)" -ForegroundColor Green
    Write-Host "Base Directories:" -ForegroundColor Green
    Write-Host "`tRoot:           $dirRoot" -ForegroundColor Green
    Write-Host "`tSources:        $dirSources" -ForegroundColor Green
    Write-Host "Server Directories:" -ForegroundColor Green
    Write-Host "`tServer:         $dirServer" -ForegroundColor Green
    Write-Host "`tPlugins:        $dirPlugins" -ForegroundColor Green
    Write-Host "`tData Packs:     $dirDataPacks" -ForegroundColor Green
    Write-Host "Client Directories:" -ForegroundColor Green
    Write-Host "`tClient Mods:    $dirModules" -ForegroundColor Green
    Write-Host "`tResource Packs: $dirResourcePacks" -ForegroundColor Green
    Write-Host "Configuration:" -ForegroundColor Green
    Write-Host "`tmyGit_URL:      $($script:myGit_URL)" -ForegroundColor Green
    foreach ($item in $script:JAVA_HOME) {
        [int]$spaces = 4 - ([string]($item.Keys[0])).Length
        $spaces = $spaces -gt 0 ? $spaces : 0
        Write-Host "`tJAVA_HOME($($item.Keys[0])):$(' ' * $spaces)$($item.Values[0])" -ForegroundColor Green
    }
    Write-Host "`tSubmodules:     $($sources.Count)" -ForegroundColor Green
    Write-Host "$('=' * 120)" -ForegroundColor Green
}

#################
# Declare Enums #
#################
enum SubModuleType {
    Other
    Server
	Script
	Plugin
	Module
	DataPack
	ResourcePack
	NodeDependancy
}

###################
# Declare Classes #
###################
class BuildType {
    [string]$Command
    [string]$InitCommand
	[string]$PreCommand
	[string]$PostCommand
	[string]$VersionCommand
	[string]$Output
    [System.Boolean]$PerformBuild
    [string] hidden $generatedRawVersion = $null
    [string] hidden $generatedCleanVersion = $null
    [void] hidden Init([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild) {
		$this.Command = $Command
		$this.InitCommand = $InitCommand
		$this.PreCommand = $PreCommand
		$this.PostCommand = $PostCommand
		$this.VersionCommand = $VersionCommand
		$this.Output = $Output
		$this.PerformBuild = $PerformBuild
    }
    BuildType() {
        $this.Init($null, $null, $null, $null, $null, $null, $true)
    }
	BuildType([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild){
		$this.Init($Command, $InitCommand, $PreCommand, $PostCommand, $VersionCommand, $Output, $PerformBuild)
    }
    BuildType([Hashtable]$Value){
        if($Value.Contains('Command'))          { $this.Command         = $this.FlattenString($Value.Command)        }
        if($Value.Contains('InitCommand'))      { $this.InitCommand     = $this.FlattenString($Value.InitCommand)    }
        if($Value.Contains('PreCommand'))       { $this.PreCommand      = $this.FlattenString($Value.PreCommand)     }
        if($Value.Contains('PostCommand'))      { $this.PostCommand     = $this.FlattenString($Value.PostCommand)    }
        if($Value.Contains('VersionCommand'))   { $this.VersionCommand  = $this.FlattenString($Value.VersionCommand) }
        if($Value.Contains('Output'))           { $this.Output          = [string]$Value.Output                }
        if($Value.Contains('PerformBuild'))     { $this.PerformBuild    = [System.Boolean]$Value.PerformBuild  }
        else { $this.PerformBuild = $true }
    }
    [string]GetOutput()	        		{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Output)         ? $null : $this.Output);                                return $return; }
    [string]GetOutputFileName()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Output)         ? $null : (Split-Path -Path $this.Output -Leaf));       return $return; }
    [string]GetOutputFileBase()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Output)         ? $null : (Split-Path -Path $this.Output -LeafBase));   return $return; }
    [string]GetOutputExtension()		{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Output)         ? $null : (Split-Path -Path $this.Output -Extension));  return $return; }
    [string]GetCommand()				{ [string]$return = ([string]::IsNullOrWhiteSpace($this.Command)        ? $null : $this.Command);                               return $return; }
    [string]GetInitCommand()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.InitCommand)    ? $null : $this.InitCommand);                           return $return; }
    [string]GetPreCommand()				{ [string]$return = ([string]::IsNullOrWhiteSpace($this.PreCommand)     ? $null : $this.PreCommand);                            return $return; }
    [string]GetPostCommand()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.PreCommand)     ? $null : $this.PostCommand);                           return $return; }
    [string]GetVersionCommand()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.VersionCommand) ? $null : $this.VersionCommand);                        return $return; }

    [string]GetVersion() {
        return $this.GetVersion($false)
    }
    [string]GetVersion([switch]$RawVersion) {
        if([string]::IsNullOrWhiteSpace($this.generatedRawVersion))   { $this.generatedRawVersion   = $this.VersionCommand }
        if([string]::IsNullOrWhiteSpace($this.generatedCleanVersion)) { $this.generatedCleanVersion = $this.CleanVersion($this.generatedRawVersion) }
        if($RawVersion) { return $this.generatedRawVersion }
        else { return $this.generatedCleanVersion }
    }

    [System.Boolean]HasCommand()        { return -not [string]::IsNullOrWhiteSpace($this.PreCommand)     }
    [System.Boolean]HasInitCommand()    { return -not [string]::IsNullOrWhiteSpace($this.InitCommand)    }
    [System.Boolean]HasPreCommand()     { return -not [string]::IsNullOrWhiteSpace($this.PreCommand)     }
    [System.Boolean]HasPostCommand()    { return -not [string]::IsNullOrWhiteSpace($this.PostCommand)    }
    [System.Boolean]HasVersionCommand() { return -not [string]::IsNullOrWhiteSpace($this.VersionCommand) }
    [System.Boolean]HasOutput()         { return -not [string]::IsNullOrWhiteSpace($this.Output)         }
    [string]FlattenString($Value) {
        [string]$return = $null
        switch (($Value.GetType()).FullName) {
            'System.String'   { $return = $Value;              break  }
            'System.String[]' { $return = $Value -join "`r`n"; break  }
            'System.Object[]' { $return = $Value -join "`r`n"; break  }
            Default           { $return = ($Value.GetType()).FullName }
        }
        return $return
    }
    [string]CleanVersion([string]$Value) {
        if ([string]::IsNullOrWhiteSpace($Value)) { return '' }

        [string]$ver = "1\.16(?:\.[0-3])?"
        $return = ($Value -replace "[$(-join ([System.Io.Path]::GetInvalidPathChars()| ForEach-Object {"\x$([Convert]::ToString([byte]$_,16).PadLeft(2,'0'))"}))]", '').Trim()

        if ($return -match "^[1-9]\d*\.\d+.\d+$") { return $return }
        if ($return -match "^1\.16$")             { return '1.16.0' }

        [string]$sep = '[' + [System.Text.RegularExpressions.Regex]::Escape('-+') + ']'
        [string[]]$removables = @('custom','local','snapshot','(alpha|beta|dev|fabric|pre|rc)(\.?\d+)*','\d{2}w\d{2}[a-z]',"v\d{6,}","$ver")
		foreach ($item in $removables) {
            [System.Boolean]$matchFound = $false
            do {
                $matchFound = $false
                if ($return -imatch "^\s*(?:(?'before'.+)$($sep)+)?$($item)(?:$($sep)+(?'after'.+))?\s*`$") {
                    if (-not [string]::IsNullOrWhiteSpace($Matches['before']) -and [string]::IsNullOrWhiteSpace($Matches['after'])) { $return = $Matches['before'] }
                    elseif ([string]::IsNullOrWhiteSpace($Matches['before']) -and -not [string]::IsNullOrWhiteSpace($Matches['after'])) { $return = $Matches['after'] }
                    else { $return = $Matches['before'] + '-' + $Matches['after'] }
                    $matchFound = $true
                }
            } while ($matchFound)
		}
		if ($return -imatch "^\s*v?(?'match'\d+)\s*$") { $return = "$($Matches['match']).0.0"}
		if ($return -imatch "^\s*v?(?'match'\d+\.\d+)\s*$") { $return = "$($Matches['match']).0"}
        if ($return -imatch "^\s*v?0*(?'match'\d+\.\d+\.\d+)\s*$") { $return = "$($Matches['match'])"}
		return $return
	}
}
class BuildTypeJava : BuildType {
	[System.Boolean]$UseNewJAVA_HOME = $false
	[string]$JAVA_HOME
    [string] hidden $originalJAVA_HOME
    [void] hidden Init($JAVA_HOME) {
		$this.UseNewJAVA_HOME = -not [string]::IsNullOrWhiteSpace($JAVA_HOME)
		$this.JAVA_HOME  = $JAVA_HOME
		$this.originalJAVA_HOME = $env:JAVA_HOME
    }
    BuildTypeJava() : base() {}
	BuildTypeJava([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base ($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild) {
        $this.Init($JAVA_HOME)
    }
    BuildTypeJava([Hashtable]$Value) : base ($Value) {
        if($Value.Contains('JAVA_HOME')) { $this.Init($Value.JAVA_HOME) }
    }
	[string] hidden GetJAVA_HOME(){
		if ($this.UseNewJAVA_HOME) { return $this.JAVA_HOME }
		else { return $env:JAVA_HOME }
	}
	[void]PushJAVA_HOME() { if ($this.UseNewJAVA_HOME) { $env:JAVA_HOME = $this.GetJAVA_HOME } }
	[void]PopJAVA_HOME() { if ($this.UseNewJAVA_HOME) { $env:JAVA_HOME = $this.originalJAVA_HOME } }
}
class BuildTypeGradle : BuildTypeJava {
	BuildTypeGradle() : base('build',$null,$null,$null,'properties','build\libs\*.jar',$true,$null) {}
	BuildTypeGradle([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild,$JAVA_HOME) {}
    BuildTypeGradle([Hashtable]$Value) : base ($Value) {
        if(-not $Value.Contains('Command')) { $this.Command = 'build' }
        if(-not $Value.Contains('VersionCommand')) { $this.VersionCommand = 'properties' }
        if(-not $Value.Contains('Output')) { $this.Output = 'build\libs\*.jar' }
    }
	[string]GetCommand() {
		[string]$buildCommand = [string]::IsNullOrWhiteSpace($this.Command) ? 'build' : $this.Command
		return ".\gradlew.bat $buildCommand $($this.UseNewJAVA_HOME ? "-``"Dorg.gradle.java.home``"=``"$($this.GetJAVA_HOME())``"" : '') --no-daemon -`"Dorg.gradle.logging.level`"=`"quiet`" -`"Dorg.gradle.warning.mode`"=`"none`" -`"Dorg.gradle.console`"=`"rich`""
    }
    [string]GetVersion(){ return $this.GetVersion($false) }
	[string]GetVersion([switch]$RawVersion) {
        if([string]::IsNullOrWhiteSpace($this.generatedRawVersion)) {
            [string]$versionCommand = [string]::IsNullOrWhiteSpace($this.VersionCommand) ? 'properties' : $this.VersionCommand
            [string]$return = ''
            if ($versionCommand -match '^\"(.*)\"$'){
                $return = $Matches[1]
            }
            else {
                $this.CheckGradleInstall()
                [Object[]]$tempReturn = $tempReturn = (.\gradlew.bat $versionCommand $($this.UseNewJAVA_HOME ? "-`"Dorg.gradle.java.home`"=`"$($this.GetJAVA_HOME())`"" : '') --no-daemon -"Dorg.gradle.logging.level"="quiet" -"Dorg.gradle.warning.mode"="none" -"Dorg.gradle.console"="rich")
                [string]$tempReturn = $null -eq $tempReturn ? 'ERROR CHECKING VERSION' : [System.String]::Join("`r`n",$tempReturn)
                if ($tempReturn -imatch '(?:^|\r?\n)(full|build|mod_|project|projectBase)[vV]ersion: (?''version''.*)(?:\r?\n|\z|$)') { $return = $Matches['version'] }
                elseif ($tempReturn -imatch '(?:^|\r?\n)[vV]ersion: (?''version''.*)(?:\r?\n|\z|$)') { $return = $Matches['version'] }
                else { $return = '' }
            }
            $this.generatedRawVersion = $return
        }
        if(-not $RawVersion -and [string]::IsNullOrWhiteSpace($this.generatedCleanVersion)) {
            $this.generatedCleanVersion = $this.CleanVersion($this.generatedRawVersion)
        }
        if ($RawVersion) { return $this.generatedRawVersion }
        else { return $this.generatedCleanVersion }
    }
    [void] hidden CheckGradleInstall(){
        if (-not (Test-Path -Path '.\gradlew.bat')) {
            $url = 'https://services.gradle.org/distributions/gradle-6.6-bin.zip'
            $file = Split-Path -Path "$url" -Leaf
            Invoke-WebRequest -Uri $url -OutFile $file
            Expand-Archive -Path $file -DestinationPath .
            .\gradle-6.6\bin\gradle.bat wrapper --no-daemon
        }
    }
}
class BuildTypeMaven : BuildTypeJava {
	BuildTypeMaven() : base('install',$null,$null,$null,$null,'target\*.jar',$true,$null) {}
	#BuildTypeMaven([string]$Output) : base('install',$null,$null,$null,$null,$Output,$true,$null) {}
	BuildTypeMaven([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild,$JAVA_HOME) {}
    BuildTypeMaven([Hashtable]$Value) : base ($Value) {
        if(-not $Value.Contains('Command')) { $this.Command = 'install' }
        if(-not $Value.Contains('VersionCommand')) { $this.VersionCommand = 'project.version' }
        if(-not $Value.Contains('Output')) { $this.Output = 'target\*.jar' }
    }
	[string]GetCommand() {
		[string]$buildCommand = [string]::IsNullOrWhiteSpace($this.Command) ? 'install' : $this.Command
		return "mvn $buildCommand -q" 
	}
    [string]GetVersion(){ return $this.GetVersion($false) }
	[string]GetVersion([switch]$RawVersion) {
        if([string]::IsNullOrWhiteSpace($this.generatedRawVersion)) {
            [string]$versionCommand = [string]::IsNullOrWhiteSpace($this.VersionCommand) ? 'project.version' : $this.VersionCommand
            [string]$return = ''
            if ($versionCommand -match '^\"(.*)\"$'){
                $return = $Matches[1]
            }
            else {
                $this.PushJAVA_HOME()
                $return = (mvn help:evaluate -Dexpression="$versionCommand" -q -DforceStdout)
                if ([string]::IsNullOrWhiteSpace($return)) { $return = 'ERROR CHECKING VERSION' }
                $this.PopJAVA_HOME()
            }
            $this.generatedRawVersion = $return
        }
        if(-not $RawVersion -and [string]::IsNullOrWhiteSpace($this.generatedCleanVersion)) {
            $this.generatedCleanVersion = $this.CleanVersion($this.generatedRawVersion)
        }
        if ($RawVersion) { return $this.generatedRawVersion }
        else { return $this.generatedCleanVersion }
    }
}
class BuildTypeNPM : BuildType {
    [string]$Name
    [string[]]$Dependancies
    BuildTypeNPM(){}
}
class GitRepo {
	[string]$Name
	[string]$Origin
	[string]$Branch
	[System.Boolean]$Pull
	[GitRepo[]]$SubModules
	[void] hidden Init([string]$Name, [string]$Origin, [string]$Branch, [System.Boolean]$Pull, [GitRepo[]]$SubModules)
	{
        if ([string]::IsNullOrWhiteSpace($Name) -and -not [string]::IsNullOrWhiteSpace($Origin)) {
            $this.Name = (Split-Path -Path $Origin -Leaf) -replace '^(.*)\.git$', '$1'
            $this.Origin = $Origin
        }
        elseif ([string]::IsNullOrWhiteSpace($Origin) -and -not [string]::IsNullOrWhiteSpace($Name)) {
            $this.Name = $Name
            $this.Origin = "$($script:myGit_URL)/$Name" }
        else {
            $this.Name = $Name
            $this.Origin = $Origin
        }
        if([string]::IsNullOrWhiteSpace($Branch)){ $this.Branch = 'master' }
        else { $this.Branch = $Branch }
        if ($null -eq $Pull) { $this.Pull = $true }
        else { $this.Pull = $Pull }
        if ($null -eq $SubModules) { $this.SubModules = [GitRepo[]]@() }
        else { $this.SubModules = $SubModules }
    }
    GitRepo()                                                                                               { $this.init($null, $null,   'master', $true, [GitRepo[]]@()) }
    GitRepo([string]$Name, [string]$Origin, [string]$Branch, [System.Boolean]$Pull, [GitRepo[]]$SubModules)	{ $this.Init($Name, $Origin, $Branch,  $Pull, $SubModules)    }
    GitRepo([Hashtable]$Value) {
        $tmpName        = $Value.Contains('Name')       ? [string]$Value.Name          : $null
        $tmpOrigin      = $Value.Contains('Origin')     ? [string]$Value.Origin        : $null
        $tmpBranch      = $Value.Contains('Branch')     ? [string]$Value.Branch        : 'master'
        $tmpPull        = $Value.Contains('Pull')       ? [System.Boolean]$Value.Pull  : $true
        $tmpSubModules =  [GitRepo[]]@()
        if ($Value.Contains('SubModules')){
            foreach ($submodule in $Value.Contains('SubModules')){
                $tmpSubModules += [GitRepo]::new([Hashtable]$submodule)
            }
            
        }
        $this.Init($tmpName, $tmpOrigin, $tmpBranch,  $tmpPull, $tmpSubModules)
    }
    [string]GetCommit(){
        [string]$return = (git rev-parse --short=7 HEAD)
        return $return
    }
    [string]GetURLCheck(){
        [string]$return = (git config --get remote.origin.url)
        if ($return -like $this.Origin) { $return += " (Same)" } else { $return += " (Changed from `"$($this.Origin)`")" }
        return $return
    }
    [string]GetBranchCheck(){
        [string]$return = (git branch --show-current)
        if ($return -like $this.Branch) { $return += " (Same)" } else { $return += " (Changed from `"$($this.Branch)`")" }
        return $return
    }
    [void]InvokeClean(){
        if ($this.Pull) {
            if ($script:WhatIF) { Write-Host 'WhatIF: git clean -fd' }
            else {
                Start-Process "git" -ArgumentList @('clean','-fd') -NoNewWindow -Wait
            }
        }
    }
    [void]InvokePull(){
        if ($this.Pull) {
            if ($script:WhatIF -and -not $script:ForcePull) { Write-Host 'WhatIF: git pull' }
            else {
                [string]$tmpBranch = $null
                try { $tmpBranch = git symbolic-ref HEAD }
                catch { Write-Host "$($_.Exception.Message)" }
                if ([string]::IsNullOrWhiteSpace($tmpBranch)) {
                    git checkout $this.Branch
                }
                Start-Process "git" -ArgumentList @('pull') -NoNewWindow -Wait
            }
        }
    }
}
class GitRepoForked : GITRepo {
	[string]$Upstream
	GITRepoForked() : base() {}
    GITRepoForked([string]$Name, [string]$Origin, [string]$Branch, [System.Boolean]$Pull, [string]$Upstream, [GitRepo[]]$SubModules) : base($Name, $Origin, $Branch, $Pull, $SubModules) { $this.Upstream = $Upstream }
    GITRepoForked([Hashtable]$Value) : base ($Value) { $this.Upstream ? $Value.Contains('Upstream') : $Value.Upstream }
}
class SourceSubModule {
	[string]$Name
	[SubModuleType]$SubModuleType
	[GitRepo]$Repo
	[BuildType]$Build
    [string]$FinalName
    Init([string]$Name, [SubModuleType]$SubModuleType, [GitRepo]$Repo, [BuildType]$Build, [string]$FinalName) {
        $this.Name = $Name
        $this.SubModuleType = $SubModuleType
        $this.Repo = $Repo
        $this.Build = $Build
        $this.FinalName = $FinalName
    }
	SourceSubModule([string]$Name, [SubModuleType]$SubModuleType, [GitRepo]$Repo, [BuildType]$Build) {
		$this.Init($Name, $SubModuleType, $Repo, $Build, $null)
	}
	SourceSubModule ([string]$Name, [SubModuleType]$SubModuleType, [GitRepo]$Repo, [BuildType]$Build, [string]$FinalName) {
		$this.Init($Name, $SubModuleType, $Repo, $Build, $FinalName)
    }
    SourceSubModule([Hashtable]$Value) {
        # Set the Name string
        [string]$tmpName = $Value.Contains('Name') ? [string]$Value.Name : $null

        # Set the Submodule Type enum
        [SubModuleType]$tmpSubModuleType = [SubModuleType]::Other
        if ($Value.Contains('SubmoduleType')){
            switch ($Value.SubmoduleType) {
                "Other"          { $tmpSubModuleType = [SubModuleType]::Other;          break }
                "Server"         { $tmpSubModuleType = [SubModuleType]::Server;         break }
                "Script"         { $tmpSubModuleType = [SubModuleType]::Script;         break }
                "Plugin"         { $tmpSubModuleType = [SubModuleType]::Plugin;         break }
                "Module"         { $tmpSubModuleType = [SubModuleType]::Module;         break }
                "DataPack"       { $tmpSubModuleType = [SubModuleType]::DataPack;       break }
                "ResourcePack"   { $tmpSubModuleType = [SubModuleType]::ResourcePack;   break }
                "NodeDependancy" { $tmpSubModuleType = [SubModuleType]::NodeDependancy; break }
                default          { $tmpSubModuleType = [SubModuleType]::Other                 }
            }
        }

        # Create a GitRepo class
        [GitRepo]$tmpRepo = $Value.Contains('Repo') ? [GitRepo]::new($Value.Repo) : [GitRepo]::new()

        # Create a Build Type class or derived class
        [BuildType]$tmpBuild = $null
        if ($Value.Build.Contains('Type')) {
            switch ($Value.Build.Type) {
                "Base"   { $tmpBuild = [BuildType]::new($Value.Build);       break }
                "Java"   { $tmpBuild = [BuildTypeJava]::new($Value.Build);   break }
                "Gradle" { $tmpBuild = [BuildTypeGradle]::new($Value.Build); break }
                "Maven"  { $tmpBuild = [BuildTypeMaven]::new($Value.Build);  break }
                "NPM"    { $tmpBuild = [BuildTypeNPM]::new($Value.Build);    break }
                Default  { $tmpBuild = [BuildType]::new($Value.Build)              }
            }
        }
        else {
            $tmpBuild = [BuildType]::new($Value.Build)
        }

        # Retrieve Final Name string
        [string]$tmpFinalName =  $Value.Contains('FinalName')       ? [string]$Value.FinalName          : $null

        # Complete constructor by executing the Init function
        $this.Init($tmpName, $tmpSubModuleType, $tmpRepo, $tmpBuild, $tmpFinalName)
    }
	[string]GetFinalName() {
		if ([string]::IsNullOrWhiteSpace($this.FinalName)){ return $this.Name }
		else { return $this.FinalName }
	}
    [System.Boolean] hidden SafeCopy([string]$Source,[string]$Destination,[switch]$WhatIF,[switch]$Compare){
        if ([string]::IsNullOrWhiteSpace($Source)){
            Write-Host "Source file is empty."
            return $false
        }
        if ([string]::IsNullOrWhiteSpace($Destination)) {
            Write-Host "Destination file is empty."
            return $false
        }
        if ($Compare -and ($null -eq (Compare-Object -ReferenceObject (Get-Content -Path $Source) -DifferenceObject (Get-Content -Path $Destination)))) {
            Write-Host "`"$Source`" and `"$Destination`" are identical." -ForegroundColor DarkGreen
            return $false
        }
        else {
            Write-Host "Copying `"$Source`" to `"$Destination`"..."
            try {
                if ($WhatIF) { Write-Host "WhatIF: Copy-Item -Path $Source -Destination $Destination -Force"}
                else { Copy-Item -Path $Source -Destination $Destination -Force }
                Write-Host "Copied `"$Source`" to `"$Destination`"." -ForegroundColor Green
                return $true
            }
            catch {
                Write-Host "Error copying file `"$Source`" to `"$Destination`"." -ForegroundColor Red
                return $false
            }
        }
    }
    [string]InvokeBuild (
            [string]$PathSource,
            [string]$PathServer,
            [string]$PathScript,
            [string]$PathPlugin,
            [string]$PathModule,
            [string]$PathDataPack,
            [string]$PathResourcePack,
            [string]$PathNodeDependancy,
            [switch]$WhatIF
        ){
        [string]$updatedFile = $null
        $dirCurrentSource = Join-Path -Path $PathSource -ChildPath $this.Name

        Write-Host "$('=' * 120)`r`nName:      $($this.Name)`r`nDirectory: $dirCurrentSource`r`n$('=' * 120)" -ForegroundColor red
        Set-Location -Path $dirCurrentSource

        $this.Repo.InvokeClean()
        $this.Repo.InvokePull()

        if ($this.Build.HasInitCommand()) { 
            if ($WhatIF) { Write-Host "WhatIF: $($this.Build.GetInitCommand())"}
            else { Invoke-Expression $($this.Build.GetInitCommand()) }
        }

        $commit = ($this.Repo.GetCommit())
        $version = ($this.Build.GetVersion())

        # Determine the copy to output file directory
        [string]$copyToFilePath = ''
        switch ($this.SubModuleType) {
            Server          { $copyToFilePath = $PathServer;            break; }
            Script          { $copyToFilePath = $PathScript;            break; }
            Plugin          { $copyToFilePath = $PathPlugin;            break; }
            Module          { $copyToFilePath = $PathModule;            break; }
            DataPack        { $copyToFilePath = $PathDataPack;          break; }
            ResourcePack    { $copyToFilePath = $PathResourcePack;      break; }
            NodeDependancy  { $copyToFilePath = $PathNodeDependancy;    break; }
        }

        # Determine the copy to output file name
        [string]$copyToFileName = ''
        if ( $this.SubModuleType -eq [SubModuleType]::Script ) {
            $copyToFileName = $this.Build.GetOutputFileName()
        }
        else {
            $copyToFileName =  "$($this.GetFinalName())-$version-CUSTOM+$commit$($this.Build.GetOutputExtension())"
        }

        # Determine the copy to full file name
        [string]$copyToFileFullName = Join-Path -Path $copyToFilePath -ChildPath $copyToFileName

        # Show current values before checking if a build is required
        Write-Host "URL:          $($this.Repo.GetURLCheck())`r`nBranch:       $($this.Repo.GetBranchCheck())`r`nCommit:       $commit`r`nBuild Output: $($this.Build.GetOutput())`r`nVersion:      $version`r`Copy To:      $copyToFileFullName" -ForegroundColor Yellow

        if ($this.Build.PerformBuild) {
            [string]$copyToExistingFilter = '^' + [System.Text.RegularExpressions.Regex]::Escape($copyToFileName) + '(\.disabled|\.backup)*$'
            $copyToExistingFiles = Get-ChildItem -File -Path $copyToFilePath | Where-Object { $_.Name -match $copyToExistingFilter }

            if ($this.SubModuleType -eq [SubModuleType]::Script) { 
                [string]$copyFromFileName = Join-Path -Path $dirCurrentSource -ChildPath ($this.Build.GetOutput())
                if ($this.SafeCopy($copyFromFileName,$copyToFileFullName,$WhatIF,$true)) { $updatedFile = $copyToFileFullName }
            }
            elseif ($copyToExistingFiles.Count -eq 0) {
                if ($this.Build.HasPreCommand()) { 
                    if ($WhatIF) { Write-Host "WhatIF: $($this.Build.GetPreCommand())"}
                    else { Invoke-Expression $($this.Build.GetPreCommand()) }
                }
                $currentBuildCommand = $this.Build.GetCommand()
                if ($WhatIF) { Write-Host "WhatIF: $($env:ComSpec) /c $currentBuildCommand"}
                else {
                    $currentProcess = Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c $currentBuildCommand" -NoNewWindow -PassThru
                    $currentProcess.WaitForExit()
                }
                $lastHour = (Get-Date).AddDays(-1)
                $copyFromExistingFiles = Get-ChildItem -Path $(Join-Path -Path $dirCurrentSource -ChildPath $this.Build.GetOutput()) -File -Exclude @('*-dev.jar','*-sources.jar','*-fatjavadoc.jar','*-noshade.jar') -EA:0 | Where-Object {$_.CreationTime -ge $lastHour} | Sort-Object -Descending CreationTime | Select-Object -First 1
                if ( $null -ne $copyFromExistingFiles -or $WhatIF ) {
                    $renameOldFileFilter = [System.Text.RegularExpressions.Regex]::Escape("$($this.GetFinalName())-") + '.*\-CUSTOM\+.*' + [System.Text.RegularExpressions.Regex]::Escape($this.Build.GetOutputExtension()) + '$'
                    $renameOldFiles = Get-ChildItem -File -Path $copyToFilePath | Where-Object { $_.Name -match $renameOldFileFilter }
                    foreach ($renameOldFile in $renameOldFiles) {
                        Write-Host "Renaming `"$($renameOldFile.FullName)`" to `"$($renameOldFile.FullName).disabled`""
                        if ($WhatIF) { Write-Host "WhatIF: Rename-Item -Path `"$($renameOldFile.FullName)`" -NewName `"$($renameOldFile.FullName).disabled`" -Force -EA:0" }
                        else { Rename-Item -Path "$($renameOldFile.FullName)" -NewName "$($renameOldFile.FullName).disabled" -Force -EA:0 }
                    }
                    [string]$copyFromFileFullName = ($WhatIF ? '<buildOutputFile>' : $copyFromExistingFiles.FullName)
                    if ($this.SafeCopy($copyFromFileFullName,$copyToFileFullName,$WhatIF,$false)) { $updatedFile = $copyToFileFullName }
                    if ($this.Build.HasPostCommand()) {
                        if ($WhatIF) { Write-Host "'WhatIF: $($this.Build.GetPostCommand())"}
                        else { Invoke-Expression $($this.Build.GetPostCommand()) }
                    }
                }
                else { Write-Host "No build output file `"$copyFromExistingFiles`" found." -ForegroundColor Red }
            }
            else { Write-Host "`"$(($copyToExistingFiles|Select-Object -First 1).FullName)`" is already up to date." -ForegroundColor DarkGreen }
        }
        else { Write-Host "Building of this submodule is currently disabled." -ForegroundColor Magenta }
        return $updatedFile
    }
}

#####################
# Declare Variables #
#####################
## Base directories
$dirStartup = (Get-Location).Path
$dirRoot = Split-Path ($MyInvocation.MyCommand.Path)
$dirSources = Join-Path -Path $dirRoot -ChildPath src

## Server directories
$dirServer = $dirRoot
$dirPlugins = Join-Path -Path $dirServer -ChildPath plugins
$dirWorlds = Join-Path -Path $dirServer -ChildPath worlds -AdditionalChildPath world
$dirDataPacks = Join-Path -Path $dirWorlds -ChildPath datapacks

## Client directories
$dirModules = Join-Path -Path $dirRoot -ChildPath .minecraft -AdditionalChildPath mods
$dirResourcePacks = Join-Path -Path $dirRoot -ChildPath .minecraft -AdditionalChildPath resourcepacks

## Blank [SourceSubModule] array
[SourceSubModule[]]$sources = @()

## Load configuration and submodule hashtables from manage.json
LoadManageJSON -JsonContentPath "$dirRoot\manage.json" -JsonSchemaPath "$dirRoot\manage.schema.json"

## Load script configuration values from hashtable
LoadConfiguration -ConfigurationData $script:ManageJSON.configuration

## Load submodules from hashtable
LoadSourceSubModules -SubmodulesData $script:ManageJSON.submodules -SourcesArray ([ref]$sources)

do { # Main loop
    Clear-Host
    Show-WhatIfInfo
    Show-DirectoryInfo
	$choice = Show-Choices -Title 'Select an action' -List @('Build','Build One','Clean','Archive','Get Versions','Test','Toggle: WhatIF','Toggle: ForcePull','Reload Configuration','Reload Submodules') -NoSort -ExitPath $dirStartup
	switch ($choice) {
		'Archive'{
            Push-Location -Path $dirRoot -StackName 'MainLoop'
            $files = @()
            $exceptions = @(
                '-x', 'backups/',
                '-x', 'cache/',
                '-x', 'logs/',
                '-x', 'plugins/00 - Previous Versions/',
                '-x', 'plugins/bStats/',
                '-x', 'plugins/Chunkmaster/chunkmaster.db',
                '-x', 'plugins/CoreProtect/database.db',
                '-x', 'plugins/dynmap/',
                '-x', 'plugins/WorldEdit/sessions/',
                '-x', 'src/SpigotBuild/',
                '-x', 'Untracked/',
                '-x', 'worlds/',
                '-x', '????-??-??@??-??-untracked.zip'
                '-x', '*.log',
                '-x', '*.old',
                '-x', '.console_history',
                '-x', 'server.jar'
            )
            $additions = @(
                "$dirSources/Minecraft-Server-BASH-Script/aws_instance_request.conf",
                "$dirSources/Minecraft-Server-BASH-Script/aws_instance_start.conf",
                "$dirSources/Minecraft-Server-BASH-Script/aws_instance_stop.conf",
                "$dirSources/Minecraft-Server-BASH-Script/Request-AWSSpotInstance_Minecwaft.ps1"
            )
            $filesRoot = (git ls-files . --other @exceptions)
            foreach ($file in $filesRoot) {
                $files += Resolve-Path -Path "$dirRoot\$file"
            }
            
            foreach ($file in $additions) {
                if (Test-Path -Path $file){ $files += Resolve-Path -Path "$file" }
            }
            
            $archiveFile = $(Join-Path -Path $dirRoot -ChildPath "$(Get-Date -Format 'yyyy-MM-dd@HH-mm')-untracked.zip")
            $archive = [System.IO.Compression.ZipFile]::Open($archiveFile,[System.IO.Compression.ZipArchiveMode]::Create)
            foreach ($file in $files) {
                [string]$fullName = $file
                [string]$partName = $(Resolve-Path -Path $fullName -Relative) -replace '\.\\',''
                Write-Host "Adding $fullName as $partName"
                try {
                    $zipEntry = $archive.CreateEntry($partName)
                    $zipEntryWriter = New-Object -TypeName System.IO.BinaryWriter $zipEntry.Open()
                    $zipEntryWriter.Write([System.IO.File]::ReadAllBytes($fullName))
                    $zipEntryWriter.Flush()
                    $zipEntryWriter.Close()
                }
                catch {
                    Write-Host $_.Exception.Message
                }
            }
            $archive.Dispose()
            PressAnyKey
			break
		}
		'Clean'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
			git submodule foreach 'remote="$(git remote)";branch="$(git branch|sed -n ''s/^\* \(.*\)$/\1/p'');echo $remote/$branch;git reset --hard $remote/$branch --recurse-submodules;git clean -xfd;echo'
            PressAnyKey
			break
		}
		'Build'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            [string[]]$updatedFiles = @()
			foreach ( $currentSource in $sources ) {
                [string]$buildReturn = $currentSource.InvokeBuild($dirSources,$dirServer,$dirServer,$dirPlugins,$dirModules,$dirDataPacks,$dirResourcePacks,'',$WhatIF)
                if (-not [string]::IsNullOrWhiteSpace($buildReturn)) { $updatedFiles += $buildReturn }
            }
            if ($updatedFiles.Count -gt 0) {
				Write-Host "Updated Files...`r`n$('=' * 120)" -ForegroundColor Green
				foreach ($item in $updatedFiles) {
					Write-Host "`t$item" -ForegroundColor Green
				}
            }
            PressAnyKey
			break
        }
        'Build One'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            $currentSource = Show-Choices -Title 'Select an action' -List $sources -ExitPath $dirStartup
            [string]$buildReturn = $currentSource.InvokeBuild($dirSources,$dirServer,$dirServer,$dirPlugins,$dirModules,$dirDataPacks,$dirResourcePacks,'',$WhatIF)
            if (-not [string]::IsNullOrWhiteSpace($buildReturn)) { Write-Host "Updated Files...`r`n$('=' * 120)`r`n`t$buildReturn" -ForegroundColor Green }
            PressAnyKey
            break
        }
        'Get Versions'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
			foreach ( $currentSource in $sources ) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                Write-Host $currentSource.GetFinalName()
                Write-Host "`tRaw Version  : $($currentSource.Build.GetVersion($true))"
                Write-Host "`tClean Version: $($currentSource.Build.GetVersion())"
            }
            PressAnyKey
            break
        }
        'Reload Configuration' {
            LoadManageJSON -JsonContentPath "$dirRoot\manage.json" -JsonSchemaPath "$dirRoot\manage.schema.json"
            LoadConfiguration -ConfigurationData $script:ManageJSON.configuration
        }
        'Reload Submodules' {
            LoadManageJSON -JsonContentPath "$dirRoot\manage.json" -JsonSchemaPath "$dirRoot\manage.schema.json"
            LoadSourceSubModules -SubmodulesData $script:ManageJSON.submodules -SourcesArray ([ref]$sources)
        }
        'Toggle: WhatIF' { $WhatIF = -not $WhatIF; break; }
        'Toggle: ForcePull' { $ForcePull = -not $ForcePull; break; }
		Default {
            Write-Host $choice
            PressAnyKey
		}
	}
    Pop-Location -StackName 'MainLoop' -ErrorAction Ignore
} while($true)
if ($WhatIF) {
	Write-Host 'In WhatIF mode. No changes have occured.' -ForegroundColor Black -BackgroundColor Yellow -NoNewline
	Write-Host ' '
}