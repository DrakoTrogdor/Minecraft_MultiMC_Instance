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
Function Write-Color
{
<#
  .SYNOPSIS
    Enables support to write multiple color text on a single line
  .DESCRIPTION
    Users color codes to enable support to write multiple color text on a single line
    ################################################
    # Write-Color Color Codes
    ################################################
    # ^f + Color Code = Foreground Color
    # ^b + Color Code = Background Color
    # ^f?^b? = Foreground and Background Color
    ################################################
    # Color Codes
    ################################################
    # k = Black
    # b = Blue
    # c = Cyan
    # e = Gray
    # g = Green
    # m = Magenta
    # r = Red
    # w = White
    # y = Yellow
    # B = DarkBlue
    # C = DarkCyan
    # E = DarkGray
    # G = DarkGreen
    # M = DarkMagenta
    # R = DarkRed
    # Y = DarkYellow [Unsupported in Powershell]
    # z = <Default Color>
    ################################################
  .PARAMETER Value
    Mandatory. Line of text to write
  .INPUTS
    [string]$Value
  .OUTPUTS
    None
  .PARAMETER NoNewLine
    Writes the text without any lines in between.
  .NOTES
    Version:          2.0
    Author:           Casey J Sullivan
    Update Date:      11/09/2020
    Original Author:  Brian Clark
    Original Date:    01/21/2017
    Initially found at:  https://www.reddit.com/r/PowerShell/comments/5pdepn/writecolor_multiple_colors_on_a_single_line/
  .EXAMPLE
    A normal usage example:
        Write-Color "Hey look ^crThis is red ^cgAnd this is green!"
    An example using a piped array:
        @('^fmMagenta text,^fB^bE Blue on Dark Gray ^fr Red','This is a^fM Test ^fzof ^fgGreen and ^fG^bYGreen on Dark Yellow')|Write-Color
#>
 
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][AllowEmptyString()][string]$Value,
        [Parameter(Mandatory=$false)][switch]$NoNewLine
    )
    Begin {
        $colors = New-Object System.Collections.Hashtable
        $colors.b = 'Blue'
        $colors.B = 'DarkBlue'
        $colors.c = 'Cyan'
        $colors.C = 'DarkCyan'
        $colors.e = 'Gray'
        $colors.E = 'DarkGray'
        $colors.g = 'Green'
        $colors.G = 'DarkGreen'
        $colors.k = 'Black'
        $colors.m = 'Magenta'
        $colors.M = 'DarkMagenta'
        $colors.r = 'Red'
        $colors.R = 'DarkRed'
        $colors.w = 'White'
        $colors.y = 'Yellow'
        $colors.Y = 'DarkYellow'
        $colors.z = ''
    }
    Process {
        $Value |
            Select-String -Pattern '(?ms)(((?''fg''^?\^f[bBcCeEgGkmMrRwyYz])(?''bg''^?\^b[bBcCeEgGkmMrRwyYz])|(?''bg''^?\^b[bBcCeEgGkmMrRwyYz])(?''fg''^?\^f[bBcCeEgGkmMrRwyYz])|(?''fg''^?\^f[bBcCeEgGkmMrRwyYz])|(?''bg''^?\^b[bBcCeEgGkmMrRwyYz])|^)(?''text''.*?))(?=\^[fb][bBcCeEgGkmMrRwyYz]|\Z)' -AllMatches | 
            ForEach-Object { $_.Matches } |
            ForEach-Object {
                $fg = ($_.Groups | Where-Object {$_.Name -eq 'fg'}).Value -replace '^\^f',''
                $bg = ($_.Groups | Where-Object {$_.Name -eq 'bg'}).Value -replace '^\^b',''
                $text = ($_.Groups | Where-Object {$_.Name -eq 'text'}).Value
                $fgColor = [string]::IsNullOrWhiteSpace($fg) -or $fg -eq 'z' ? $Host.UI.RawUI.ForegroundColor : $colors.$fg
                $bgColor = [string]::IsNullOrWhiteSpace($bg) -or $bg -eq 'z' ? $Host.UI.RawUI.BackgroundColor : $colors.$bg
                Write-Host -Object $text -ForegroundColor $fgColor -BackgroundColor $bgColor -NoNewline
            }
        if (-not $NoNewLine) { Write-Host }
    }
    End {
    }
}
function Convert-FromUnixTime($Value){ return [TimeZoneInfo]::ConvertTimeFromUTC(([DateTime]::UnixEpoch).AddSeconds($Value),(Get-TimeZone)) }
function Write-DateDiff([DateTime]$Date1,[DateTime]$Date2) {
    $timespan = $Date1 - $Date2
    [int]$days = [Math]::Floor([Math]::Abs($timespan.TotalDays))
    [int]$hours = [Math]::Abs($timespan.Hours)
    [int]$minutes = [Math]::Abs($timespan.Minutes)
    [int]$seconds = [Math]::Abs($timespan.Seconds)
    [string[]]$return = switch ($true) {
        ({$days -gt 0})                         { "$($days)d" }
        ({$days -le 1 -and $hours -gt 0})       { "$($hours)h"}
        ({$days -eq 0 -and $hours -lt 2 -and $minutes -gt 0})   { "$($minutes)m"}
        ({$days -eq 0 -and $hours -eq 0 -and $Minutes -lt 2 -and $seconds -gt 0}) { "$($seconds)s"}
    }
    return $return -join ' '
}
function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][AllowEmptyString()][string]$Value,
        [Parameter(Mandatory=$false)][string]$Title = 'Info',
        [Parameter(Mandatory=$false)][int]$Align = 12,
        [Parameter(Mandatory=$false)][int]$Indent = 1,
        [Parameter(Mandatory=$false)][switch]$NoNewLine
    )
    Begin {
        [string]$spaces = "$(' ' * (($Align) - $Title.Length -1))"
    }
    Process {
        Write-Color "$("`t" * $Indent)^fy$Title^fz:$spaces$Value"
    }
}
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
            {$_ -in 'GitRepo[]'} {
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
                                    }
                                    else {
										$return = ($List | Where-Object {$_ -eq $MenuItems[$choice]} | Select-Object -First 1)
									}
								}
								break
                            }
                            'SourceSubModule[]' {
                                $return = $List | Where-Object { $_.GetFinalName() -eq $MenuItems[$choice] } | Select-Object -First 1
								break
                            }
                            {$_ -in 'GitRepo[]'} {
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
    if ($null -ne $ConfigurationData) {
        ## URL for forked GIT Repositories
        [string]$script:myGit_URL = $ConfigurationData.myGit_URL

        ## JAVA_HOME alternatives
        $script:JAVA_HOME = $ConfigurationData.JAVA_HOME

        ## Show Debugging Information
        [boolean]$script:ShowDebugInfo = ($ConfigurationData.ShowDebugInfo)

        ## Clean and pull repositories before building
        [boolean]$script:CleanAndPullRepo = $ConfigurationData.Contains('CleanAndPullRepo') ? $ConfigurationData.CleanAndPullRepo : $true

        [string[]]$script:ArchiveExceptions = [string[]]@()
        if ($ConfigurationData.Contains('ArchiveExceptions')) {
            foreach ($item in $ConfigurationData.ArchiveExceptions) {
                $script:ArchiveExceptions += [string]$item
            }
        }

        [string[]]$script:ArchiveAdditions = [string[]]@()
        if ($ConfigurationData.Contains('ArchiveAdditions')) {
            foreach ($item in $ConfigurationData.ArchiveAdditions) {
                $script:ArchiveAdditions += [string]$item
            }
        }

        [string[]]$script:CleanExceptions = [string[]]@()
        if ($ConfigurationData.Contains('CleanExceptions')) {
            foreach ($item in $ConfigurationData.CleanExceptions) {
                $script:CleanExceptions += [string]$item
            }
        }

        [string[]]$script:CleanAdditions = [string[]]@()
        if ($ConfigurationData.Contains('CleanAdditions')) {
            foreach ($item in $ConfigurationData.CleanAdditions) {
                $script:CleanAdditions += [string]$item
            }
        }

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
            if (-not ($item.Contains('Ignore') -and $item.Ignore)) {
                # Set the JAVA_HOME property if it exists
                if ($item.Build.Contains('JAVA_HOME')){
                    [int]$version = $item.Build.JAVA_HOME
                    [string]$path = $script:JAVA_HOME.$version
                    $item.Build.JAVA_HOME = [string]::IsNullOrWhiteSpace($path) ? $null : $path
                }
                $ReturnSources += [SourceSubModule]::new($item)
            }
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
function BuildSpigot {
    param (
        [string]$Version,
        [string]$ToolPath,
        [string]$JDKPath
    )
    $file = Join-Path -Path "$ToolPath" -ChildPath "spigot-$Version.jar"
    if (($null -ne (mvn dependency:get -Dartifact="org.spigotmc:spigot:$Version-R0.1-SNAPSHOT" -o -q)) -or ($null -ne (mvn dependency:get -Dartifact="org.spigotmc:spigot-api:$Version-R0.1-SNAPSHOT" -o -q))) {
        if (-not (Test-Path -Path $file)) {
            Push-Location -Path "$ToolPath" -StackName 'SpigotBuild'
            $javaCommand = [BuildTypeJava]::PushEnvJava($JDKPath)
            Write-Host "Building Craftbukkit and Spigot versions $Version"
            $javaProcess = Start-Process -FilePath "$javaCommand" -ArgumentList "-jar $ToolPath\\BuildTools.jar --rev $Version --compile CRAFTBUKKIT,SPIGOT" -NoNewWindow -PassThru
            $javaProcess.WaitForExit()
            [BuildTypeJava]::PopEnvJava()
            Pop-Location -StackName 'SpigotBuild'
        }
        Write-Host "Installing spigot $Version-R0.1-SNAPSHOT to maven local repository"
        mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$file"
        Write-Host "Installing spigot-API $Version-R0.1-SNAPSHOT to maven local repository"
        mvn install:install-file -DgroupId='org.spigotmc' -DartifactId=spigot-api -Dversion="$Version-R0.1-SNAPSHOT" -Dpackaging=jar -Dfile="$file"
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
    [string]GetPostCommand()			{ [string]$return = ([string]::IsNullOrWhiteSpace($this.PostCommand)    ? $null : $this.PostCommand);                           return $return; }
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

    [System.Boolean]HasCommand()        { return -not [string]::IsNullOrWhiteSpace($this.Command)     }
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

    InvokeInitBuild(){ $this.InvokeInitBuild($false) }
    InvokePreBuild(){ $this.InvokePreBuild($false) }
    InvokeBuild(){ $this.InvokeBuild($false) }
    InvokePostBuild(){ $this.InvokePostBuild($false) }

    InvokeInitBuild([switch]$WhatIF){
        if ($this.HasInitCommand()) { 
            if ($WhatIF) { Write-Log "$($this.GetInitCommand())" -Title 'WhatIF' }
            else { Invoke-Expression $($this.GetInitCommand()) }
        }
    }
    InvokePreBuild([switch]$WhatIF){
        if ($this.HasPreCommand()) { 
            if ($WhatIF) { Write-Log "$($this.GetPreCommand())" -Title 'WhatIF'}
            else { Invoke-Expression $($this.GetPreCommand()) }
        }
    }
    InvokeBuild([switch]$WhatIF){
        if ($this.HasCommand()) { 
            if ($WhatIF) { Write-Log "$($this.GetCommand())" -Title 'WhatIF'}
            else {
                [string]$buildCommand = $this.GetCommand()
                Write-Log "`"$buildCommand`""  -Title 'Executing'
                $currentProcess = Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c $buildCommand" -NoNewWindow -PassThru
                $currentProcess.WaitForExit()
            }
        }
    }
    InvokePostBuild([switch]$WhatIF){
        if ($this.HasPostCommand()) { 
            if ($WhatIF) { Write-Log "$($this.GetPostCommand())" -Title 'WhatIF' }
            else { Invoke-Expression $($this.GetPostCommand()) }
        }
    }

    [string]CleanVersion([string]$Value) {
        if ([string]::IsNullOrWhiteSpace($Value)) { return '' }

        [string]$ver = "1\.16(?:\.[0-3])?"
        $return = ($Value -replace "[$(-join ([System.Io.Path]::GetInvalidPathChars()| ForEach-Object {"\x$([Convert]::ToString([byte]$_,16).PadLeft(2,'0'))"}))]", '').Trim()

        if ($return -match "^[1-9]\d*\.\d+.\d+$") { return $return }
        if ($return -match "^1\.16$")             { return '1.16.0' }

        [string]$sep = '[' + [System.Text.RegularExpressions.Regex]::Escape('-+') + ']'
        [string[]]$removables = @('custom','local','snapshot','(alpha|beta|dev|fabric|pre|rc|arne)(\.?\d+)*','\d{2}w\d{2}[a-z]',"v\d{6,}","$ver")
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

    [string] hidden static $origEnvJAVA_HOME
    [string] hidden static $origEnvPath
    [string] static PushEnvJava($Value){
        if ([string]::IsNullOrWhiteSpace([BuildTypeJava]::origEnvJAVA_HOME)) { [BuildTypeJava]::origEnvJAVA_HOME = $env:JAVA_HOME }
        if ([string]::IsNullOrWhiteSpace([BuildTypeJava]::origEnvPath))      { [BuildTypeJava]::origEnvPath      = $env:Path      }
        $env:JAVA_HOME = $Value
        [string]$javaBin = Join-Path -Path $Value -ChildPath 'bin'
        $env:Path      = $env:Path -replace '([A-Z]:\\[^\;]+\\jdk-\d+\.\d+\.\d+[\.\+]\d+(-hotspot)?\\bin;)+',"$($javaBin);"
        return Join-Path -Path $javaBin -ChildPath 'java.exe'
    }
    [string] static PopEnvJava(){
        if (-not [string]::IsNullOrWhiteSpace([BuildTypeJava]::origEnvJAVA_HOME)) { $env:JAVA_HOME = [BuildTypeJava]::origEnvJAVA_HOME; [BuildTypeJava]::origEnvJAVA_HOME = $null }
        if (-not [string]::IsNullOrWhiteSpace([BuildTypeJava]::origEnvPath))      { $env:Path      = [BuildTypeJava]::origEnvPath;      [BuildTypeJava]::origEnvPath      = $null }
        return Join-Path -Path $env:JAVA_HOME -ChildPath 'bin' -AdditionalChildPath 'java.exe'
    }
	[void]PushJAVA_HOME() { if ($this.UseNewJAVA_HOME) { [BuildTypeJava]::PushEnvJava($this.GetJAVA_HOME()) } }
    [void]PopJAVA_HOME()  { if ($this.UseNewJAVA_HOME) { [BuildTypeJava]::PopEnvJava()                      } }

    InvokeInitBuild()               { $this.InvokeInitBuild($false) }
    InvokePreBuild()                { $this.InvokePreBuild($false) }
    InvokeBuild()                   { $this.InvokeBuild($false) }
    InvokePostBuild()               { $this.InvokePostBuild($false) }
    InvokeInitBuild([switch]$WhatIF){
        $this.PushJAVA_HOME()
        ([BuildType]$this).InvokeInitBuild($WhatIF)
        $this.PopJAVA_HOME()
    }
    InvokePreBuild([switch]$WhatIF) {
        $this.PushJAVA_HOME()
        ([BuildType]$this).InvokePreBuild($WhatIF)
        $this.PopJAVA_HOME()
    }
    InvokeBuild([switch]$WhatIF)    {
        $this.PushJAVA_HOME()
        Write-Log "`"$($env:JAVA_HOME)`"" -Title 'JAVA_HOME'
        ([BuildType]$this).InvokeBuild($WhatIF)
        $this.PopJAVA_HOME()
    }
    InvokePostBuild([switch]$WhatIF){
        $this.PushJAVA_HOME()
        ([BuildType]$this).InvokePostBuild($WhatIF)
        $this.PopJAVA_HOME()
    }
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
		return ".\gradlew.bat $buildCommand $($this.UseNewJAVA_HOME ? "-``"Dorg.gradle.java.home``"=``"$($this.GetJAVA_HOME())``"" : '') --no-daemon --quiet --warning-mode=none --console=rich" #-`"Dorg.gradle.logging.level`"=`"quiet`" -`"Dorg.gradle.warning.mode`"=`"none`" -`"Dorg.gradle.console`"=`"rich`"
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

    InvokeInitBuild()               { $this.InvokeInitBuild($false) }
    InvokePreBuild()                { $this.InvokePreBuild($false) }
    InvokeBuild()                   { $this.InvokeBuild($false) }
    InvokePostBuild()               { $this.InvokePostBuild($false) }
    InvokeInitBuild([switch]$WhatIF){ ([BuildTypeJava]$this).InvokeInitBuild($WhatIF) }
    InvokePreBuild([switch]$WhatIF) { ([BuildTypeJava]$this).InvokePreBuild($WhatIF)  }
    InvokeBuild([switch]$WhatIF)    {
        $this.CheckGradleInstall()
        ([BuildTypeJava]$this).InvokeBuild($WhatIF)
    }
    InvokePostBuild([switch]$WhatIF){ ([BuildTypeJava]$this).InvokePostBuild($WhatIF) }

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
	BuildTypeMaven([string]$Command,[string]$InitCommand,[string]$PreCommand,[string]$PostCommand,[string]$VersionCommand,[string]$Output,[System.Boolean]$PerformBuild,[string]$JAVA_HOME) : base($Command,$InitCommand,$PreCommand,$PostCommand,$VersionCommand,$Output,$PerformBuild,$JAVA_HOME) {}
    BuildTypeMaven([Hashtable]$Value) : base ($Value) {
        if(-not $Value.Contains('Command')) { $this.Command = 'install' }
        if(-not $Value.Contains('VersionCommand')) { $this.VersionCommand = 'project.version' }
        if(-not $Value.Contains('Output')) { $this.Output = 'target\*.jar' }
    }
	[string]GetCommand() {
		[string]$buildCommand = [string]::IsNullOrWhiteSpace($this.Command) ? 'install' : $this.Command
		return "mvn $buildCommand -q -U"
	}
    [string]GetVersion(){ return $this.GetVersion($false) }
	[string]GetVersion([switch]$RawVersion) {
        if([string]::IsNullOrWhiteSpace($this.generatedRawVersion) -or $this.generatedRawVersion -eq 'ERROR CHECKING VERSION') {
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

    InvokeInitBuild()               { $this.InvokeInitBuild($false) }
    InvokePreBuild()                { $this.InvokePreBuild($false) }
    InvokeBuild()                   { $this.InvokeBuild($false) }
    InvokePostBuild()               { $this.InvokePostBuild($false) }
    InvokeInitBuild([switch]$WhatIF){ ([BuildTypeJava]$this).InvokeInitBuild($WhatIF) }
    InvokePreBuild([switch]$WhatIF) { ([BuildTypeJava]$this).InvokePreBuild($WhatIF)  }
    InvokeBuild([switch]$WhatIF)    { ([BuildTypeJava]$this).InvokeBuild($WhatIF)     }
    InvokePostBuild([switch]$WhatIF){ ([BuildTypeJava]$this).InvokePostBuild($WhatIF) }
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
    [string]$LockAtCommit
    [System.Boolean]$Pull
    [GitRepo[]]$SubModules
    [string[]]$BranchIgnore
    [string[]]$ArchiveAdditions
    [string[]]$CleanAdditions
    [string[]]$CleanExceptions
    [void] hidden Init (
        [string]$Name,
        [string]$Origin,
        [string]$Branch,
        [string]$LockAtCommit,
        [System.Boolean]$Pull,
        [string[]]$BranchIgnore,
        [GitRepo[]]$SubModules,
        [string[]]$ArchiveAdditions,
        [string[]]$CleanAdditions,
        [string[]]$CleanExceptions
    ){
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
        $this.Branch           = if ([string]::IsNullOrWhiteSpace($Branch))       { 'master' } else { $Branch       }
        $this.LockAtCommit     = if ([string]::IsNullOrWhiteSpace($LockAtCommit)) { $null    } else { $LockAtCommit }
        $this.Pull             = if ($null -eq $Pull)             { $true          } else { $Pull             }
        $this.SubModules       = if ($null -eq $SubModules)       { [GitRepo[]]@() } else { $SubModules       }
        $this.BranchIgnore     = if ($null -eq $BranchIgnore)     { [string[]]@()  } else { $BranchIgnore     }
        $this.ArchiveAdditions = if ($null -eq $ArchiveAdditions) { [string[]]@()  } else { $ArchiveAdditions }
        $this.CleanAdditions   = if ($null -eq $CleanAdditions)   { [string[]]@()  } else { $CleanAdditions   }
        $this.CleanExceptions  = if ($null -eq $CleanExceptions)  { [string[]]@()  } else { $CleanExceptions  }
    }
    GitRepo() { $this.init($null, $null,   'master', $true, [string[]]@(), [GitRepo[]]@()), [string[]]@(), [string[]]@(), [string[]]@() }
    GitRepo([Hashtable]$Value) {
        $tmpName        = $Value.Contains('Name')           ? [string]$Value.Name          : $null
        $tmpOrigin      = $Value.Contains('Origin')         ? [string]$Value.Origin        : $null
        $tmpBranch      = $Value.Contains('Branch')         ? [string]$Value.Branch        : 'master'
        $tmpPull        = $Value.Contains('Pull')           ? [System.Boolean]$Value.Pull  : $true
        $tmpLockAtCommit  = $Value.Contains('LockAtCommit') ? [string]$Value.LockAtCommit  : $null
        $tmpSubModules =  [GitRepo[]]@()
        $tmpBranchIgnore = [string[]]@()
        if ($Value.Contains('BranchIgnore')){
            foreach ($item in $Value.BranchIgnore){
                $tmpBranchIgnore += [string]$item
            }
            
        }
        if ($Value.Contains('SubModules')){
            foreach ($submodule in $Value.SubModules){
                $tmpSubModules += [GitRepo]::new([Hashtable]$submodule)
            }
            
        }
        $tmpArchiveAdditions = [string[]]@()
        if ($Value.Contains('ArchiveAdditions')){
            foreach ($item in $Value.ArchiveAdditions){
                $tmpArchiveAdditions += [string]$item
            }
            
        }
        $tmpCleanAdditions = [string[]]@()
        if ($Value.Contains('CleanAdditions')){
            foreach ($item in $Value.CleanAdditions){
                $tmpCleanAdditions += [string]$item
            }
            
        }
        $tmpCleanExceptions = [string[]]@()
        if ($Value.Contains('CleanExceptions')){
            foreach ($item in $Value.CleanExceptions){
                $tmpCleanExceptions += [string]$item
            }
            
        }
        $this.Init($tmpName, $tmpOrigin, $tmpBranch, $tmpLockAtCommit, $tmpPull, $tmpBranchIgnore, $tmpSubModules, $tmpArchiveAdditions, $tmpCleanAdditions, $tmpCleanExceptions)
    }
    [string]GetUpstream() {
        [string]$return = (git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}') 2>&1
        if ($return -like 'fatal: * does not point to a branch') { $return = 'DETATCHED' }
        return $return
    }
    [string]GetRemote() {
        [string]$return = $this.GetUpstream() -replace '/.*$',''
        return $return
    }
    [string]GetURL() {
        [string]$remote = $this.GetRemote()
        if ($remote -ne 'DETATCHED' -and [string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
            [string]$return = $this.GetURL($remote)
        }
        else {
            [string]$return = $this.Origin
        }
        return $return
    }
    [string]GetURL([string]$remote) {
        [string]$return = (git config --get remote.$remote.url)
        return $return
    }
    [string]GetBranch() {
        [string[]]$Value = (git branch)
        [string]$return = ( $Value | Select-String -Pattern '(^\* (?''match''.*)$)' | Select-Object -First 1 | ForEach-Object {
            $_.matches.groups | Where-Object {
                $_.Name -match 'match'
            }
        } | Select-Object -Expand Value )
        if ($return -match '\(.* detached at (?<commit>[a-f0-9]+)\)') { $return = "DETATCHED - $($Matches.commit)" }
        return $return
    }
    [string]GetCommit(){
        [string]$return = (git rev-parse --short=7 HEAD)
        return $return
    }
    [string]CheckConfigRemote([System.Boolean]$InColor){
        [string]$reportedRemote = $this.GetRemote()
        if ($reportedRemote -like 'origin') { $reportedRemote += " ($($InColor ? '^fgSame^fz' : 'Same'))" } else { $reportedRemote += " (" + ($InColor ? "^frChanged from `"origin`"^fz" : "Changed from `"origin`"") + ")" }
        return $reportedRemote
    }
    [string]CheckConfigRemote() { return CheckConfigURL($false) }
    [string]CheckConfigURL([System.Boolean]$InColor){
        [string]$reportedURL = $this.GetURL()
        if ($reportedURL -like $this.Origin) { $reportedURL += " ($($InColor ? '^fgSame^fz' : 'Same'))" } else { $reportedURL += " (" + ($InColor ? "^frChanged from `"" + $this.Origin + "`"^fz" : "Changed from `"" + $this.Origin + "`"") + ")" }
        return $reportedURL
    }
    [string]CheckConfigURL() { return CheckConfigURL($false) }

    [string]CheckConfigBranch([System.Boolean]$InColor){
        [string]$reportedBranch = $this.GetBranch()
        if ($reportedBranch -like $this.Branch) { $reportedBranch += " ($($InColor ? '^fgSame^fz' : 'Same'))" } else { $reportedBranch += " (" + ($InColor ? "^frChanged from `"" + $this.Branch + "`"^fz" : "Changed from `"" + $this.Branch + "`"") + ")" } #" (Same)" } else { $reportedBranch += " (Changed from `"$($this.Branch)`")" }
        return $reportedBranch
    }
    [string]CheckConfigBranch() { return CheckConfigBranch($false) }
    [void]CompareAheadBehind() {
        [string]$upstream = $this.GetUpstream()
        if ($upstream -ne 'DETATCHED' -and [string]::IsNullOrWhiteSpace($this.LockAtCommit)) { [string]$local = $this.GetBranch() }
        elseif($upstream -eq 'DETATCHED' -and -not [string]::IsNullOrWhiteSpace($this.LockAtCommit)) { [string]$local = $this.LockAtCommit }
        else { 
            $this.InvokeCheckout()
            [string]$local = $this.GetBranch()
        }
        [string[]]$remotes = (git remote)
        foreach ($remote in $remotes) {
            Write-Log "$($remote): $($this.GetURL($remote))" -Title 'Compare'
            git fetch "$($remote.Trim())"
        }
        [string]$branchIgnoreRegex = '(' + (($this.BranchIgnore.Where({$_ -notmatch '^\s*$'}).ForEach({$_.Trim()})) -join '|') +')'
        if ($branchIgnoreRegex -eq '()') {
            [string[]]$branches = @($local) + @((git branch -r) -notmatch '^\s*(?<remote>.*)/HEAD -> \k<remote>/.*$').trim()
        }
        else {
            [string[]]$branches = @($local) + @((git branch -r) -notmatch '^\s*(?<remote>.*)/HEAD -> \k<remote>/.*$' -notmatch ".*$branchIgnoreRegex.*").trim()
        }
        [System.Collections.Hashtable]$branchCommits = New-Object System.Collections.Hashtable
        [PSCustomObject[]]$compareAheadBehind = @()
        foreach ($branchA in $branches) {
            [string]$commitA = $branchA -eq $local ? "refs/heads/$branchA" : "refs/remotes/$branchA"
            if (((git rev-list "$commitA" -n 1 --date=unix --abbrev-commit --pretty=format:"%cd") `
            -join "`r`n") -match '(?ms)(?:^commit (?<commit>[a-f0-9]+)\s*(?:(?<time>\d+))$)' ) {
                [string]$tmpCommit = $Matches.commit.Trim()
                [DateTime]$tmpTime = Convert-FromUnixTime $($Matches.time.Trim())
                $branchCommits.$branchA = [PSCustomObject]@{ Commit = $tmpCommit; Time = $tmpTime }
            }
            else { $branchCommits.$branchA = [PSCustomObject]@{ Commit = ''; Time = '' } }
            foreach ($branchB in $branches) {
                if ($branchB -eq $branchA) { continue }
                if ($compareAheadBehind.Where({$_.Left -eq $branchB -and $_.Right -eq $branchA})) { continue }
                # Double quotes is required around the entire "A...B" in order to parse properly
                [string]$commitB = $branchB -eq $local ? "refs/heads/$branchB" : "refs/remotes/$branchB"
                if ((git rev-list --left-right --count "$($commitA)...$($commitB)") -match '^\s*(?<ahead>\d+)\s+(?<behind>\d+)\s*$') {
                    [string]$left = $branchA
                    [string]$right = $branchB
                    [string]$ahead = $Matches.ahead
                    [string]$behind = $Matches.behind
                    $compareAheadBehind += [PSCustomObject]@{
                        Left = $branchA
                        Right = $branchB
                        Ahead = $Matches.ahead
                        Behind = $Matches.behind
                        Arrow = $(switch ($true){
                            ({$Matches.behind -eq 0 -and $Matches.ahead -eq 0}){'^fe===^fz'}
                            ({$Matches.behind -eq 0 -and $Matches.ahead -gt 0}){'^fg==>^fz'}
                            ({$Matches.behind -gt 0 -and $Matches.ahead -eq 0}){'^fr<==^fz'}
                            default{'^fR<=>^fz'}
                        })
                    }
                }
            }
        }
        [int]$longest=0
        $branches.ForEach({if (([string]$_).Length -gt $longest) {$longest = ([string]$_).Length}})
        Write-Log " Bnd | Ahd  - $('Branch A'.PadLeft($longest,' ')) --- $('Branch B'.PadRight($longest,' '))`t LastCmt --- LastCmt" -Title 'Compare'
        [DateTime]$now = Get-Date
        [DateTime]$stale = (Get-Date).AddDays(-90)
        $compareAheadBehind |
        #Sort-Object Left,Right |
        ForEach-Object {
            [string]$left = $_.Left
            [string]$right = $_.Right

            [DateTime]$leftTime      = $branchCommits.$($left).Time
            [DateTime]$rightTime     = $branchCommits.$($right).Time

            if (($left -eq $local) -or ($leftTime -gt $stale -and $rightTime -gt $stale)) {

                [string]$fgl    = $(switch ($left) { $local {'^fM'} $upstream {'^fM'} default { '' }})
                [string]$fgr    = $(switch ($right) { $local {'^fM'} $upstream {'^fM'} default { '' }})

                [string]$ahead  = ([string]($_.Ahead)).PadRight(4,' ')
                [string]$behind = ([string]($_.Behind)).PadLeft(4,' ')

                [string]$arrow  = $_.Arrow

                [string]$leftString   = $fgl + $left.PadLeft($longest,' ') + '^fz'
                [string]$rightString  = $fgr + $right.PadRight($longest,' ') + '^fz'

                [string]$leftTimeString  = (Write-DateDiff $now $leftTime).PadLeft(7,' ')
                [string]$rightTimeString = (Write-DateDiff $now $rightTime).PadRight(7,' ')

                if ($leftTime -lt $rightTime)     {[string]$timearrow = '^fr<==^fz'}
                elseif ($leftTime -gt $rightTime) {[string]$timearrow = '^fg==>^fz'}
                else                              {[string]$timearrow = '^fe===^fz'}

                Write-Log "$behind | $ahead - $leftString $arrow $rightString^bz`t $leftTimeString $timearrow $rightTimeString" -Title 'Compare'
            }
        }
    }
    [void]Display(){
        #if ($ShowName) { Write-Color "^fM$($this.Name)^fz" }
        Write-Log "$($this.CheckConfigRemote($true))" -Title 'Remote'
        Write-Log "$($this.CheckConfigURL($true))" -Title 'URL'
        Write-Log "$($this.CheckConfigBranch($true))" -Title 'Branch'
        Write-Log "$($this.GetCommit())" -Title 'Commit'
    }
    [void]InvokeCheckout() {
        $this.Display()
        if ([string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
            [string]$reportedBranch = $this.GetBranch()
            [string]$returnBranch = if ($this.Branch -eq $reportedBranch){ $this.Branch }
            elseif (YesOrNo -Prompt "Do you want to swtich from branch `"$($reportedBranch)`" to `"$($this.Branch)`"") { $this.Branch }
            else { $reportedBranch }
            git checkout -B $($returnBranch) --force
            [string]$remote=$this.GetRemote()
            if ($remote -eq 'DETATCHED') { $remote = 'origin' }
            git branch --set-upstream-to=$remote/$returnBranch $returnBranch
            git fetch --force $remote
        }
        else { (git checkout "$($this.LockAtCommit)") }
    }
    [void]InvokeReset() {
        $this.Display()
        [string]$upstream = [string]::IsNullOrWhiteSpace($this.LockAtCommit) ? $this.GetUpstream() : $this.LockAtCommit
        if ($upstream -eq 'DETATCHED') { $upstream = 'origin' }
        if ($script:WhatIF) { Write-Log "git reset --hard $upstream --recurse-submodules" -Title 'WhatIF' }
        else { git reset --hard "$upstream" --recurse-submodules }
    }
    [void]InvokeClean([System.Boolean]$Quiet) {
        if ($Quiet) { Write-Log -Value "Cleaning..." -Title "Action" } else { $this.Display() }
        [string[]]$cleanArguments = @('clean')
        $cleanArguments += ($script:WhatIF ? '-nxfd' : '-xfd')
        foreach ($item in $this.CleanExceptions) {
            $cleanArguments += @('-e',$([string]$item))
        }
        git @cleanArguments
        foreach ($item in $this.CleanAdditions) {
            Remove-Item $item -Force -Recurse -WhatIf:$($script:WhatIF)
        }
    }
    [void]InvokeClean() { $this.InvokeClean($false) }
    [void]InvokePull([System.Boolean]$Quiet) {
        if ($this.Pull) {
            if ($Quiet) { Write-Log -Value "Pulling..." -Title "Action" } else { $this.Display() }
            if ($script:WhatIF -and -not $script:ForcePull) { Write-Log "git pull" -Title 'WhatIF' }
            else {
                if ([string]::IsNullOrWhiteSpace($this.LockAtCommit)) {
                    [string]$tmpBranch = $null
                    try { $tmpBranch = git symbolic-ref HEAD }
                    catch { Write-Log "^fr$($_.Exception.Message)^fz" -Title 'Error' }
                    if ([string]::IsNullOrWhiteSpace($tmpBranch)) {
                        $this.InvokeCheckout()
                    }
                    git pull
                }
                else { (git checkout "$($this.LockAtCommit)") }
            }
        }
    }
    [void]InvokePull() { $this.InvokePull($false) }
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
    [string] hidden RelativePath([string]$Parent,[string]$Child){
        if([string]::IsNullOrWhiteSpace($Parent) -or [string]::IsNullOrWhiteSpace($Child)) { return ''}
        else {
            [string]$return = '.' + ($Child -replace [RegEx]::Escape($Parent),'')
            return $return
        }
    }
    [System.Boolean] hidden SafeCopy([string]$Source,[string]$Destination,[string]$Root,[switch]$WhatIF,[switch]$Compare){
        if ([string]::IsNullOrWhiteSpace($Source)){
            Write-Log "Source file is empty."
            return $false
        }
        if ([string]::IsNullOrWhiteSpace($Destination)) {
            Write-Log "Destination file is empty."
            return $false
        }
        [string]$relativeSource = $this.RelativePath($Root, $Source)
        [string]$relativeDestination = $this.RelativePath($Root, $Destination)
        if ($Compare -and ($null -eq (Compare-Object -ReferenceObject (Get-Content -Path $Source) -DifferenceObject (Get-Content -Path $Destination)))) {
            Write-Log "`"^fG$relativeSource^fz`" and `"^fG$relativeDestination^fz`" are identical."
            return $false
        }
        else {
            Write-Log "`"$relativeSource`" to `"$relativeDestination`"..." -Title 'Copying'
            try {
                if ($WhatIF) { Write-Log "Copy-Item -Path $relativeSource -Destination $relativeDestination -Force" -Title 'WhatIF'}
                else { Copy-Item -Path $Source -Destination $Destination -Force }
                Write-Log "`"^fg$relativeSource^fz`" to `"^fg$relativeDestination^fz`"." -Title "Copied"
                return $true
            }
            catch {
                Write-Log "^frCopying file `"$relativeSource`" to `"$relativeDestination`".^fz" -Title 'Error'
                return $false
            }
        }
    }
    DisplayHeader(){
        Write-Host "$('=' * 120)`r`nName:      $($this.Name)`r`nDirectory: $($this.RelativePath($script:dirRoot,(Get-Location)))`r`n$('=' * 120)" -ForegroundColor red
    }
    InvokeClean(
        [string]$PathSource
    ){
        $dirCurrentSource = Join-Path -Path $PathSource -ChildPath $this.Name
        Write-Host "Cleaning $($this.GetFinalName())"
        Set-Location -Path $dirCurrentSource
        $this.Repo.InvokeClean()
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
            [switch]$PerformCleanAndPull,
            [switch]$WhatIF
    ){
        [string]$updatedFile = $null
        $dirCurrentSource = Join-Path -Path $PathSource -ChildPath $this.Name

        Set-Location -Path $dirCurrentSource
        $this.DisplayHeader()

        if ($PerformCleanAndPull) {
            $this.Repo.InvokeClean($true)
            $this.Repo.InvokePull($true)
        }

        $this.Build.InvokeInitBuild($WhatIF)

        $commit = ($this.Repo.GetCommit())
        $version = ($this.Build.GetVersion())

        # Determine the copy to output file directory
        [string]$copyToFilePath = ''
        switch ($this.SubModuleType) {
            Other           { $copyToFilePath = $dirCurrentSource;      break; }
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
        $this.Repo.Display()
        Write-Log "$version" -Title 'Version'
        Write-Log "`"$($this.RelativePath($PathServer, $(Join-Path -Path $dirCurrentSource -ChildPath $($this.Build.GetOutput()))))`"" -Title 'Copy From'
        Write-Log "`"$($this.RelativePath($PathServer, $copyToFileFullName))`"" -Title 'Copy To'

        if ($this.Build.PerformBuild) {
            [string]$copyToExistingFilter = '^' + [System.Text.RegularExpressions.Regex]::Escape($copyToFileName) + '(\.disabled|\.backup)*$'
            $copyToExistingFiles = Get-ChildItem -File -Path $copyToFilePath | Where-Object { $_.Name -match $copyToExistingFilter }

            switch ($this.SubModuleType) {
                Script {
                    [string]$copyFromFileName = Join-Path -Path $dirCurrentSource -ChildPath ($this.Build.GetOutput())
                    if ($this.SafeCopy($copyFromFileName,$copyToFileFullName,$PathServer,$WhatIF,$true)) { $updatedFile = $copyToFileFullName }
                    break
                }
                Other {
                    $this.Build.InvokePreBuild($WhatIF)
                    $this.Build.InvokeBuild($WhatIF)
                    $this.Build.InvokePostBuild($WhatIF)
                    break
                }
                Default {
                    if ($copyToExistingFiles.Count -eq 0) {
                        $this.Build.InvokePreBuild($WhatIF)
                        $this.Build.InvokeBuild($WhatIF)
                        $lastHour = (Get-Date).AddDays(-1)
                        $copyFromExistingFiles = Get-ChildItem -Path $(Join-Path -Path $dirCurrentSource -ChildPath $this.Build.GetOutput()) -File -Exclude @('*-dev.jar','*-sources.jar','*-fatjavadoc.jar','*-noshade.jar') -EA:0 | Where-Object {$_.CreationTime -ge $lastHour} | Sort-Object -Descending CreationTime | Select-Object -First 1
                        if ( $null -ne $copyFromExistingFiles -or $WhatIF ) {
                            $renameOldFileFilter = [System.Text.RegularExpressions.Regex]::Escape("$($this.GetFinalName())-") + '.*\-CUSTOM\+.*' + [System.Text.RegularExpressions.Regex]::Escape($this.Build.GetOutputExtension()) + '$'
                            $renameOldFiles = Get-ChildItem -File -Path $copyToFilePath | Where-Object { $_.Name -match $renameOldFileFilter }
                            foreach ($renameOldFile in $renameOldFiles) {
                                Write-Log "`"$($this.RelativePath($PathServer, $renameOldFile.FullName))`" to `"$($this.RelativePath($PathServer, $renameOldFile.FullName))^fE.disabled^fz`"" -Title 'Renaming'
                                if ($WhatIF) { Write-Log "Rename-Item -Path `"$($this.RelativePath($PathServer, $renameOldFile.FullName))`" -NewName `"$($this.RelativePath($PathServer, $renameOldFile.FullName)).disabled`" -Force -EA:0" -Title 'WhatIF'}
                                else { Rename-Item -Path "$($renameOldFile.FullName)" -NewName "$($renameOldFile.FullName).disabled" -Force -EA:0 }
                            }
                            [string]$copyFromFileFullName = ($WhatIF ? '<buildOutputFile>' : $copyFromExistingFiles.FullName)
                            if ($this.SafeCopy($copyFromFileFullName,$copyToFileFullName,$PathServer,$WhatIF,$false)) { $updatedFile = $copyToFileFullName }
                            $this.Build.InvokePostBuild($WhatIF)
                        }
                        else { Write-Log "^frNo build output file `"$copyFromExistingFiles`" found." -Title 'Error' }
                    }
                    else { Write-Log "`"^fG$($this.RelativePath($PathServer, ($copyToExistingFiles|Select-Object -First 1).FullName))^fz`" is already up to date." }
                }
            }
        }
        else { Write-Log "^fMBuilding of this submodule is currently disabled.^fz" }
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
    $menuItems =  @(
        'Build - Compile All',
        'Build - Compile One',
        'Build - Get Versions',
        'Repositories - Display Details',
        'Repositories - Archive Untracked',
        'Repositories - Checkout',
        'Repositories - Clean',
        'Repositories - Reset',
        'Repositories - Compare All',
        'Repositories - Compare One',
        'Configuration - Reload Generic',
        'Configuration - Reload Submodules',
        'Configuration - Toggle WhatIF',
        'Configuration - Toggle ForcePull'
    )
	$choice = Show-Choices -Title 'Select an action' -List $menuItems -NoSort -ExitPath $dirStartup
	switch ($choice) {
        'Repositories - Display Details'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            Write-Host "Displaying Repository Details"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader()
                $currentSource.Repo.Display()
            }
            PressAnyKey
            break
        }
		'Repositories - Archive Untracked'{
            Push-Location -Path $dirRoot -StackName 'MainLoop'
            $files = @()

            #Setup untracked exceptions to exclude from the archive
            [string[]]$exceptions = @()
            # Retrieve untracked exceptions that will be excluded from the archive for the base repo
            foreach ($item in $script:ArchiveExceptions) { $exceptions += @('-x',$([string]$item)) }
            # Retrieve untracked exceptions that will be excluded from the archive for each submodule
            foreach ($currentSource in $sources) {
                foreach ($item in $currentSource.Repo.ArchiveExceptions) { $exceptions += @('-x',$([string]$item)) }
            }

            #Setup untracked additions to add to the archive
            [string[]]$additions = @()
            # Retrieve untracked additions to add to the archive for the base repo
            foreach ($item in $script:ArchiveAdditions) { $additions += [string]$item }
            # Retrieve untracked additions to add to the archive for each submodule
            foreach ($currentSource in $sources) {
                foreach ($item in $currentSource.Repo.ArchiveAdditions) { $additions += Join-Path -Path $dirSources -ChildPath $currentSource.Name -AdditionalChildPath $item }
            }

            $filesRoot = (git ls-files . --other @exceptions)
            foreach ($file in $filesRoot) { $files += Resolve-Path -Path "$dirRoot\$file" }
            
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
		'Repositories - Clean'{
            Push-Location -Path $dirRoot -StackName 'MainLoop'
            Write-Host "Cleaning Root Folder"
            if ($script:WhatIF) { Write-Host 'WhatIF: git clean' }
            [string[]]$cleanArguments = @('clean')
            $cleanArguments += ($script:WhatIF ? '-nxfd' : '-xfd')
            $cleanArguments += @('-e','plugins/')
            $cleanArguments += @('-e','worlds/')
            $cleanArguments += @('-e','worlds/world/datapacks/')
            $cleanArguments += @('-e','.minecraft/mods/')
            $cleanArguments += @('-e','.minecraft/resourcepacks/')

            foreach ($item in $script:CleanExceptions) {
                $cleanArguments += @('-e',[string]$item)
            }
            git @cleanArguments
            foreach ($item in $this.CleanAdditions) {
                Remove-Item $item -Force -Recurse -WhatIf:$($script:WhatIF)
            }
            foreach ($currentSource in $sources) {
                $currentSource.InvokeClean($dirSources)
            }
            PressAnyKey
            break
        }
        'Repositories - Reset' {
            Push-Location -Path $dirSources -StackName 'MainLoop'
            Write-Host "Resetting Repositories"
            foreach ($currentSource in $sources) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                $currentSource.DisplayHeader()
                $currentSource.Repo.InvokeReset()
            }
            PressAnyKey
            break
        }
        'Repositories - Compare All'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            Write-Host "Comparing Branches on all Repositories"
            foreach ( $currentSource in $sources ) {
                Set-Location -Path $(Join-Path -Path $dirSources -ChildPath $($currentSource.Name))
                $currentSource.DisplayHeader()
                $currentSource.Repo.CompareAheadBehind()
            }
            PressAnyKey
            break
        }
        'Repositories - Compare One'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            $currentSource = Show-Choices -Title 'Select an action' -List $sources -ExitPath $dirStartup
            Set-Location -Path $(Join-Path -Path $dirSources -ChildPath $($currentSource.Name))
            $currentSource.DisplayHeader()
            $currentSource.Repo.CompareAheadBehind()
            PressAnyKey
            break
        }
		'Build - Compile All'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            [string[]]$updatedFiles = @()
            foreach ( $currentSource in $sources ) {
                [string]$buildReturn = $currentSource.InvokeBuild($dirSources,$dirServer,$dirServer,$dirPlugins,$dirModules,$dirDataPacks,$dirResourcePacks,'',$script:CleanAndPullRepo,$WhatIF)
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
        'Build - Compile One'{
            Push-Location -Path $dirSources -StackName 'MainLoop'
            $currentSource = Show-Choices -Title 'Select an action' -List $sources -ExitPath $dirStartup
            [string]$buildReturn = $currentSource.InvokeBuild($dirSources,$dirServer,$dirServer,$dirPlugins,$dirModules,$dirDataPacks,$dirResourcePacks,'',$script:CleanAndPullRepo,$WhatIF)
            if (-not [string]::IsNullOrWhiteSpace($buildReturn)) { Write-Host "Updated Files...`r`n$('=' * 120)`r`n`t$buildReturn" -ForegroundColor Green }
            PressAnyKey
            break
        }
        'Build - Get Versions'{
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
        'Repositories - Checkout' {
            Push-Location -Path $dirSources -StackName 'MainLoop'
            foreach ( $currentSource in $sources ) {
                $dirCurrent = Join-Path -Path $dirSources -ChildPath $currentSource.Name
                Set-Location -Path $dirCurrent
                Write-Host $currentSource.GetFinalName()
                $currentSource.Repo.InvokeCheckout()
            }
            PressAnyKey
            break
        }
        'Configuration - Reload Generic' {
            LoadManageJSON -JsonContentPath "$dirRoot\manage.json" -JsonSchemaPath "$dirRoot\manage.schema.json"
            LoadConfiguration -ConfigurationData $script:ManageJSON.configuration
            break
        }
        'Configuration - Reload Submodules' {
            LoadManageJSON -JsonContentPath "$dirRoot\manage.json" -JsonSchemaPath "$dirRoot\manage.schema.json"
            LoadSourceSubModules -SubmodulesData $script:ManageJSON.submodules -SourcesArray ([ref]$sources)
            break
        }
        'Configuration - Toggle WhatIF' { $WhatIF = -not $WhatIF; break; }
        'Configuration - Toggle ForcePull' { $ForcePull = -not $ForcePull; break; }
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