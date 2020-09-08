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
    Write-Host "$('=' * 120)" -ForegroundColor Green
}

#################
# Declare Enums #
#################
enum SubModuleType {
	Server = 0
	Script = 1
	Plugin = 2
	Module = 3
	DataPack = 4
	ResourcePack = 5
	NodeDependancy = 6
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
	BuildType([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild){
		$this.Command = $Command
		$this.InitCommand = $InitCommand
		$this.PreCommand = $PreCommand
		$this.PostCommand = $PostCommand
		$this.VersionCommand = $VersionCommand
		$this.Output = $Output
		$this.PerformBuild = $PerformBuild
    }
    BuildType([Hashtable]$Value){
        if($Value.Contains('Command'))          { $this.Command         = [string]$Value.Command              }
        if($Value.Contains('InitCommand'))      { $this.InitCommand     = [string]$Value.InitCommand          }
        if($Value.Contains('PreCommand'))       { $this.PreCommand      = [string]$Value.PreCommand           }
        if($Value.Contains('PostCommand'))      { $this.PostCommand     = [string]$Value.PostCommand          }
        if($Value.Contains('VersionCommand'))   { $this.VersionCommand  = [string]$Value.VersionCommand       }
        if($Value.Contains('Output'))           { $this.Output          = [string]$Value.Output               }
        if($Value.Contains('PerformBuild'))     { $this.PerformBuild    = [System.Boolean]$Value.PerformBuild }
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

    [string]CleanVersion([string]$Value) {
        if ([string]::IsNullOrWhiteSpace($Value)) { return '' }

        [string]$ver = "1\.16(?:\.[0-3])?"
        $return = ($Value -replace "[$(-join ([System.Io.Path]::GetInvalidPathChars()| ForEach-Object {"\x$([Convert]::ToString([byte]$_,16).PadLeft(2,'0'))"}))]", '').Trim()

        if ($return -match "^$($ver)$") { return $return }

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
	BuildTypeJava([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base ($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild) {
        $this.Init($JAVA_HOME)
    }
    BuildTypeJava([Hashtable]$Value) : base ($value) {
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
	BuildTypeGradle([string]$Output) : base('build',$null,$null,$null,'properties',$Output,$true,$null) {}
	BuildTypeGradle([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild,$JAVA_HOME) {}
    BuildTypeGradle([Hashtable]$Value) : base ($value) {
        if(-not $Value.Contains('Command')) { $this.Command = 'build' }
        if(-not $Value.Contains('VersionCommand')) { $this.VersionCommand = 'properties' }
        if(-not $Value.Contains('Output')) { $this.Output = 'build\libs\*.jar' }
    }
	[string]GetCommand() {
		[string]$buildCommand = [string]::IsNullOrWhiteSpace($this.Command) ? 'build' : $this.Command
		return ".\gradlew.bat -q $buildCommand $($this.UseNewJAVA_HOME ? "-``"Dorg.gradle.java.home``"=``"$($this.GetJAVA_HOME())``"" : '') --no-daemon"
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
                [Object[]]$tempReturn = $tempReturn = (.\gradlew.bat -q $versionCommand $($this.UseNewJAVA_HOME ? "-`"Dorg.gradle.java.home`"=`"$($this.GetJAVA_HOME())`"" : '') --no-daemon)
                [string]$tempReturn = $null -eq $tempReturn ? 'ERROR CHECKING VERSION' : [System.String]::Join("`r`n",$tempReturn)
                if ($tempReturn -imatch '(?:^|\r?\n)(full|build|mod_|project|projectBase)[vV]ersion: (?''version''.*)(?:\r?\n|\z|$)') { $return = $Matches['version'] }
                #elseif ($tempReturn -imatch '(?:^|\r?\n)fullVersion: (?''version''.*)(?:\r?\n|\z|$)') { $return = $Matches['version'] }
                #elseif ($tempReturn -imatch '(?:^|\r?\n)mod_version: (?''version''.*)(?:\r?\n|\z|$)') { $return = $Matches['version'] }
                #elseif ($tempReturn -imatch '(?:^|\r?\n)projectVersion: (?''version''.*)(?:\r?\n|\z|$)') { $return = $Matches['version'] }
                #elseif ($tempReturn -imatch '(?:^|\r?\n)projectBaseVersion: (?''version''.*)(?:\r?\n|\z|$)') { $return = $Matches['version'] }
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
	BuildTypeMaven([string]$Output) : base('install',$null,$null,$null,$null,$Output,$true,$null) {}
	BuildTypeMaven([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild,$JAVA_HOME) {}
    BuildTypeMaven([Hashtable]$Value) : base ($value) {
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
            $this.Origin = "$($script:myGIT_URL)/$Name" }
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
	GitRepo([string]$Origin)																				{ $this.init($null, $Origin, 'master', $true, [GitRepo[]]@()) }
	GitRepo([string]$Name, [string]$Origin)																	{ $this.init($Name, $Origin, 'master', $true, [GitRepo[]]@()) }
    GitRepo([string]$Name, [string]$Origin, [string]$Branch, [System.Boolean]$Pull, [GitRepo[]]$SubModules)	{ $this.Init($Name, $Origin, $Branch,  $Pull, $SubModules)    }
    GitRepo([Hashtable]$Value) {
        $tmpName        = $Value.Contains('Name')       ? [string]$Value.Name          : $null
        $tmpOrigin      = $Value.Contains('Origin')     ? [string]$Value.Origin        : $null
        $tmpBranch      = $Value.Contains('Branch')     ? [string]$Value.Branch        : 'master'
        $tmpPull        = $Value.Contains('Pull')       ? [System.Boolean]$Value.Pull  : $true
        $tmpSubModules  = $Value.Contains('SubModules') ? [GitRepo[]]$Value.SubModules : [GitRepo[]]@()
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
	GITRepoForked([string]$Name, [string]$Upstream) : base($Name, "$myGIT_URL/$Name")																										{ $this.Upstream = $Upstream }
	GITRepoForked([string]$Name, [System.Boolean]$Pull, [string]$Upstream) : base($Name, "$myGIT_URL/$Name", $Pull)																			{ $this.Upstream = $Upstream }
	GITRepoForked([string]$Name, [string]$Upstream, [GitRepo[]]$SubModules) : base($Name, "$myGIT_URL/$Name", $SubModules)																	{ $this.Upstream = $Upstream }
	GITRepoForked([string]$Name, [System.Boolean]$Pull, [string]$Upstream, [GitRepo[]]$SubModules) : base($Name, "$myGIT_URL/$Name", $Pull, $SubModules)									{ $this.Upstream = $Upstream }
	GITRepoForked([string]$Name, [string]$Branch, [string]$Upstream) : base($Name, "$myGIT_URL/$Name", $Branch)																				{ $this.Upstream = $Upstream }
	GITRepoForked([string]$Name, [string]$Branch, [System.Boolean]$Pull, [string]$Upstream) : base($Name, "$myGIT_URL/$Name", $Branch, $Pull)												{ $this.Upstream = $Upstream }
	GITRepoForked([string]$Name, [string]$Branch, [string]$Upstream, [GitRepo[]]$SubModules) : base($Name, "$myGIT_URL/$Name", $Branch, $SubModules)										{ $this.Upstream = $Upstream }
	GITRepoForked([string]$Name, [string]$Branch, [System.Boolean]$Pull, [string]$Upstream, [GitRepo[]]$SubModules) : base($Name, "$myGIT_URL/$Name", $Branch, $Pull, $SubModules)			{ $this.Upstream = $Upstream }
	GITRepoForked([string]$Name, [string]$Origin, [string]$Branch, [string]$Upstream, [GitRepo[]]$SubModules) : base($Name, $Origin, $Branch, $SubModules)									{ $this.Upstream = $Upstream }
	GITRepoForked([string]$Name, [string]$Origin, [string]$Branch, [System.Boolean]$Pull, [string]$Upstream, [GitRepo[]]$SubModules) : base($Name, $Origin, $Branch, $Pull, $SubModules)	{ $this.Upstream = $Upstream }
}
class SourceSubModule {
	[string]$Name
	[SubModuleType]$SubModuleType
	[GitRepo]$Repo
	[BuildType]$Build
	[string]$FinalName
	SourceSubModule([string]$Name, [SubModuleType]$SubModuleType, [GitRepo]$Repo, [BuildType]$Build) {
		$this.Name = $Name
		$this.SubModuleType = $SubModuleType
		$this.Repo = $Repo
		$this.Build = $Build
		$this.FinalName = $null
	}
	SourceSubModule ([string]$Name, [SubModuleType]$SubModuleType, [GitRepo]$Repo, [BuildType]$Build, [string]$FinalName) {
		$this.Name = $Name
		$this.SubModuleType = $SubModuleType
		$this.Repo = $Repo
		$this.Build = $Build
		$this.FinalName = $FinalName
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
            else { Invoke-Expression -Command $this.Build.GetInitCommand() }
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
            [string]$copyToExistingFilter = [System.Text.RegularExpressions.Regex]::Escape($copyToFileName) + '(\.disabled|\.backup)*'
            $copyToExistingFiles = Get-ChildItem -File -Path $copyToFilePath | Where-Object { $_.Name -match $copyToExistingFilter }

            if ($this.SubModuleType -eq [SubModuleType]::Script) { 
                [string]$copyFromFileName = Join-Path -Path $dirCurrentSource -ChildPath ($this.Build.GetOutput())
                if ($this.SafeCopy($copyFromFileName,$copyToFileFullName,$WhatIF,$true)) { $updatedFile = $copyToFileFullName }
            }
            elseif ($copyToExistingFiles.Count -eq 0) {
                if ($this.Build.HasPreCommand()) { 
                    if ($WhatIF) { Write-Host "WhatIF: $($this.Build.GetPreCommand())"}
                    else { Invoke-Expression -Command $this.Build.GetPreCommand() }
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
                        else { Invoke-Expression -Command $this.Build.GetPostCommand() }
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

## URL for forked GIT Repositories
$myGIT_URL = 'https://github.com/DrakoTrogdor'

## JAVA_HOME alternatives
$Java8 = 'C:\Program Files\AdoptOpenJDK\jdk-8.0.265.01-hotspot'
$Java11 = 'C:\Program Files\AdoptOpenJDK\jdk-11.0.7.10-hotspot'
$Java14 = 'C:\Program Files\AdoptOpenJDK\jdk-14.0.2.12-hotspot'

## Debugging Variables
[boolean]$script:ShowDebugInfo = $false

## Begin Declare all submodule sources
[SourceSubModule[]] $sources = @(
<#
        [BuildTypeMaven]::new(@{
            Command = 'install'
            PreCommand = ''
            PostCommand = ''
            VersionCommand = 'project.version'
            Output = 'target\*.jar'
            PerformBuild = $true
            JAVA_HOME = ''
        })
        [BuildTypeGradle]::new(@{
            Command = 'build'
            PreCommand = ''
            PostCommand = ''
            VersionCommand = 'properties'
            Output = 'build\libs\*.jar'
            PerformBuild = $true
            JAVA_HOME = ''
        })
#>
	[SourceSubModule]::new(
		'AppleSkin',							# Submodule name
        [SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/squeek502/AppleSkin'
            Branch          = '1.16-fabric'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\appleskin-*.jar'
            JAVA_HOME       = $Java8
        })
	),
	[SourceSubModule]::new(
		'BoundingBoxOutlineReloaded',			# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/irtimaled/BoundingBoxOutlineReloaded'
            Branch          = '1.16.2-fabric'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\BBOutlineReloaded-*-fabric.jar'
            JAVA_HOME       = $Java8
        }),
        'BBOutlineReloaded'                                      # Final Name
	),
	[SourceSubModule]::new(
		'canvas',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/grondag/canvas'
            Branch          = 'one'
            Pull            = $false
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\canvas-*.jar'
            PerformBuild    = $false
            JAVA_HOME       = $Java8
        })
	),
	[SourceSubModule]::new(
		'cloth-config',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          ='https://github.com/shedaniel/cloth-config'
            Branch          ='v4'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\config-2-*.jar'
            JAVA_HOME       = $Java8
        }),
        'ClothConfig'
	),
	[SourceSubModule]::new(
		'connected-block-textures',				# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/Nuclearfarts/connected-block-textures'
            Branch          = '1.16'
            Pull            = $false
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\connected-block-textures-*.jar'
            PerformBuild    = $false
        }),
        'ConnectedBlockTextures'
	),
	[SourceSubModule]::new(
		'CraftPresence',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://gitlab.com/CDAGaming/CraftPresence.git'
            Branch          = '1.16.x-Fabric'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\CraftPresence-Fabric-*.jar'
            JAVA_HOME       = $Java8
        })
	),
	[SourceSubModule]::new(
		'Euclid',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/bermudalocket/Euclid'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\euclid-*.jar'
        })
	),
	[SourceSubModule]::new(
		'fabric',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/FabricMC/fabric'
            Branch          = '1.16'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\fabric-api-*.jar'
            JAVA_HOME       = $Java8
        }),
        'FabricAPI'
	),
	[SourceSubModule]::new(
		'Fabric-Autoswitch',					# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/dexman545/Fabric-Autoswitch'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\autoswitch-*.jar'
            InitCommand      =
@'
[string]$file = '.\build\loom-cache\ModUpdater-1.1.11+1.16.2.jar'
if (-not (Test-Path -Path $file)) {
    [string]$leaf = Split-Path -Path $file -Leaf
    Write-Host "Copying $leaf dependancy from mods folder..."
    $source = (Get-ChildItem -Path ..\..\.minecraft\mods\ModUpdater*1.1.11*.jar* | Select -First 1)
    Copy-Item -Path $source -Destination $file -Force 
    Write-Host "$leaf dependancy copied."
    
    Write-Host "Adjusting MopUpdater dependancy..."
    $file = '.\gradle.properties'
    $content = (Get-Content -Path $file -Raw)
    $content = $content -replace 'modupdater_version = 1\.1\.9\+1\.16\.1','modupdater_version = 1.1.11+1.16.2'
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Adjusted ModUpdater dependancy."
}
'@
            JAVA_HOME       = $Java14
        }),
        'Autoswitch'                                      # Final Name
	),
	[SourceSubModule]::new(
		'fabric-carpet',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/gnembon/fabric-carpet'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\*.jar'
            JAVA_HOME       = $Java8
        }),
        'Carpet'                                      # Final Name
	),
	[SourceSubModule]::new(
		'Grid',									# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/gbl/Grid'
            Branch          = 'fabric_1_16'}),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\grid-*-fabric*.jar'
        })
	),
	[SourceSubModule]::new(
		'HWYLA',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/TehNut/HWYLA'
            Branch          = '1.16_fabric'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\Hwyla-fabric-*.jar'
            JAVA_HOME       = $Java8
        })
	),
	[SourceSubModule]::new(
		'Inventory-Sorter',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/kyrptonaught/Inventory-Sorter'
            Branch          = '1.16'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\InventorySorter-*.jar'
            JAVA_HOME       = $Java8
        }),
        'InventorySorter'                                      # Final Name
	),
	[SourceSubModule]::new(
		'itemscroller',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/maruohon/itemscroller'
            Branch          = 'fabric_1.16_snapshots_temp'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\itemscroller-fabric-*.jar'
        }),
        'ItemScroller'                                      # Final Name
	),
	[SourceSubModule]::new(
		'LambDynamicLights',					# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/LambdAurora/LambDynamicLights'
            Branch          = 'mc1.16'
            Pull            = $false
        }),
        [BuildTypeGradle]::new(@{
            Command         = 'ShadowRemapJar'
            Output          = 'build\libs\lambdynamiclights-fabric-*.jar'
            PerformBuild    = $false
        })
	),
	[SourceSubModule]::new(
		'litematica',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/maruohon/litematica'
            Branch          = 'fabric_1.16_snapshots_temp'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\litematica-fabric-*.jar'
        }),
        'Litematica'                                      # Final Name
	),
	[SourceSubModule]::new(
		'lithium-fabric',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/jellysquid3/lithium-fabric'
            Branch          = '1.16.x/dev'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\lithium-fabric-*.jar'
        }),
        'Lithium'                                      # Final Name
	),
	[SourceSubModule]::new(
		'malilib',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/maruohon/malilib'
            Branch          = 'fabric_1.16_snapshots_temp'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\malilib-fabric-*.jar'
            JAVA_HOME       = $Java8
        }),
        'MaliLib'                                      # Final Name
	),
	[SourceSubModule]::new(
		'minihud',										# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/maruohon/minihud'
            Branch          = 'fabric_1.16_snapshots_temp'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\minihud-fabric-*.jar'
            # Minihud as it stands will not compile unless either:
            #    Download:
            #        https://masa.dy.fi/mcmods/malilib/malilib-fabric-1.16-snap-20w21a-0.10.0-dev.21%2Bbeta.1.jar
            #        malilib-fabric-1.16-snap-20w21a-0.10.0-dev.21+beta.1.jar => malilib-fabric-1.16-snap-20w21a.jar
            #    Change build.properties and fix issues (why doesn't this just get updated):
            #        minecraft_version_out = 1.16-snap-20w21a => 1.16.2
            #        minecraft_version     = 20w21a           => 1.16.2
            #        mappings_version      = 20w21a+build.7   => 1.16.2+build.1
            #        fabric_loader_version = 0.8.4+build.198  => 0.9.1+build.205
            #        mod_menu_version      = 1.11.5+build.10  => 1.14.6+build.31
            PreCommand      =
@'
[string]$file = '.\build\loom-cache\malilib-fabric-1.16-snap-20w21a.jar'
if (-not (Test-Path -Path $file)) {
    [string]$leaf = Split-Path -Path $file -Leaf
    Write-Host "Downloading $leaf dependancy..."
	$url = 'https://masa.dy.fi/mcmods/malilib/malilib-fabric-1.16-snap-20w21a-0.10.0-dev.21%2Bbeta.1.jar'
	Invoke-WebRequest -Uri $url -OutFile $file
	Write-Host "$leaf dependancy downloaded."
}
'@
            PerformBuild    = $false
            JAVA_HOME       = $Java8
        }),
        'MiniHUD'                                      # Final Name
	),
	[SourceSubModule]::new(
		'ModMenu',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/Prospector/ModMenu'
            Branch          = '1.16'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\modmenu-*.jar'
            JAVA_HOME       = $Java8
        })
	),
	[SourceSubModule]::new(
		'ModUpdater',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://gitea.thebrokenrail.com/TheBrokenRail/ModUpdater.git'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\modupdater-*.jar'
            JAVA_HOME       = $Java8
        })
	),
	[SourceSubModule]::new(
		'OptiFabric',										# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin = 'https://github.com/Chocohead/OptiFabric'
            Branch = 'llama'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\optifabric*.jar'
        })
	),
	[SourceSubModule]::new(
		'phosphor-fabric',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/jellysquid3/phosphor-fabric'
            Branch          = '1.16.x/dev'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\phosphor-fabric-*.jar'
            JAVA_HOME       = $Java8
        }),
        'Phosphor'                                      # Final Name
	),
	[SourceSubModule]::new(
		'ShulkerBoxTooltip',										# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/MisterPeModder/ShulkerBoxTooltip'
            Branch          = '1.16'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\shulkerboxtooltip-*.jar'
        })
	),
	[SourceSubModule]::new(
		'Skin-Swapper',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/cobrasrock/Skin-Swapper'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\Skin_Swapper_*.jar'
            JAVA_HOME       = $Java8
        }),
        'SkinSwapper'                                      # Final Name
	),
	[SourceSubModule]::new(
		'soaring-clouds',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin = 'https://github.com/Draylar/soaring-clouds'
            Branch          = '1.16'
            Pull = $false
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\soaring-clouds-*.jar'
            PerformBuild    = $false
            JAVA_HOME       = $Java8
        }),
        'SoaringClouds'                                      # Final Name
	),
	[SourceSubModule]::new(
		'sodium-fabric',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/jellysquid3/sodium-fabric'
            Branch          = '1.16.x/dev'
            Pull            = $false
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\sodium-fabric-*.jar'
            PerformBuild    = $false
        }),
        'Sodium'                                      # Final Name
	),
	[SourceSubModule]::new(
		'tweakeroo',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/maruohon/tweakeroo'
            Branch          = 'fabric_1.16_snapshots_temp'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\tweakeroo-fabric-*.jar'
            JAVA_HOME       = $Java8
        }),
        'Tweakeroo'                                      # Final Name
	),
	[SourceSubModule]::new(
		'WorldEdit',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/enginehub/WorldEdit'
        }),
        [BuildTypeGradle]::new(@{
            Command         = 'worldedit-fabric:build'
            VersionCommand  = 'worldedit-fabric:properties'
            Output          = 'worldedit-fabric\build\libs\worldedit-fabric-*.jar'
            JAVA_HOME       = $Java8
        })
	),
	[SourceSubModule]::new(
		'WorldEditCUI',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
        [GitRepo]::new(@{
            Origin          = 'https://github.com/mikroskeem/WorldEditCUI'
        }),
        [BuildTypeGradle]::new(@{
            Output          = 'build\libs\WorldEditCUI-*.jar'
            JAVA_HOME       = $Java8
        })
	)
)
## End Declare all submodule sources

do { # Main loop
    Clear-Host
    Show-WhatIfInfo
    Show-DirectoryInfo
	$choice = Show-Choices -Title 'Select an action' -List @('Build','Build One','Clean','Archive','Get Versions','Test','Toggle: WhatIF','Toggle: ForcePull') -NoSort -ExitPath $dirStartup
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
		'Test' { PressAnyKey; break; }
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