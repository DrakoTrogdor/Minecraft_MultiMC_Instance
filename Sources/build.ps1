#git submodule update --remote
Function Invoke-BatchFile ($commandPath, $commandArguments, $workingDirectory, $timeout)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $env:ComSpec
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    if ($null -eq $workingDirectory) { $pinfo.WorkingDirectory = (Get-Location).Path }
    else { $pinfo.WorkingDirectory = $workingDirectory }
    $pinfo.Arguments = "/c `"$commandPath`" $commandArguments"
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    if ($null -eq $timeout) { $timeout = 5 }
    Wait-Process $p.Id -Timeout $timeout -EA:0
    [pscustomobject]@{
        StandardOutput = $p.StandardOutput.ReadToEnd()
        StandardError = $p.StandardError.ReadToEnd()
        ExitCode = $p.ExitCode
    }
}
enum SubModuleType {
	Plugin = 0
	Module = 1
	Datapack = 2
	Resourcepack = 3
	Server = 4
	Script = 5
}
enum BuildType {
	Gradle = 0
	Maven = 1
	Java = 2
	Other = 3
}
class SourceSubModule {
	[string]$Name
	[SubModuleType]$SubModuleType
	[boolean]$GitPull
	[boolean]$Build
	[BuildType]$BuildType
	[string]$BuildCommand
	[string]$BuildOutput
	[string]$PreCommand
	[string]$PostCommand
	SourceSubModule(){}
	SourceSubModule (
			[string]$Name,
			[SubModuleType]$SubModuleType,
			[boolean]$GitPull,
			[boolean]$Build,
			[BuildType]$BuildType,
			[string]$BuildCommand,
			[string]$BuildOutput,
			[string]$PreCommand,
			[string]$PostCommand
		){
		$this.Name = $Name
		$this.SubModuleType = $SubModuleType
		$this.GitPull = $GitPull
		$this.Build = $Build
		$this.BuildType = $BuildType
		$this.BuildCommand = $BuildCommand
		$this.BuildOutput = $BuildOutput
		$this.PreCommand = $PreCommand
		$this.PostCommand = $PostCommand
	
	}
	[string]GetBuildOutputFileName() {
		return Split-Path -Path $this.BuildOutput -Leaf
	}
	[string]GetBuildOutputFileBase() {
		return Split-Path -Path $this.BuildOutput -LeafBase
	}
	[string]GetBuildOutputExtension() {
		return Split-Path -Path $this.BuildOutput -Extension
	}
	[string]GetBuildCommand() {
		[string]$return = ''
		switch ($this.BuildType) {
			Gradle {
				$return = "`".\gradlew.bat`" -q $($this.BuildCommand) --no-daemon"
				break
			}
			Maven {
				$return = "mvn $($this.BuildCommand) -q"
				break
			}
			Other {
				$return = $this.BuildCommand
			}
		}
		return $return
	}
}
$sourcesdir = Split-Path ($MyInvocation.MyCommand.Path)
Push-Location $sourcesdir
$instancedir = (Get-Item $sourcesdir).Parent
$clientdir = Join-Path -Path $instancedir -ChildPath .minecraft
$serverdir = Join-Path -Path $clientdir -ChildPath saves
$modsdir = Join-Path -Path $clientdir -ChildPath mods
#$pluginsdir = Join-Path -Path $clientdir -ChildPath plugins
$resourcepacksdir = Join-Path -Path $clientdir -ChildPath resourcepacks
$worldsdir = Join-Path -Path $serverdir -ChildPath 'New World'
$datapacksdir = Join-Path -Path $worldsdir -ChildPath datapacks
Write-Host "$('=' * 120)`r`nInstance:       $instancedir`r`nClient:         $clientdir`r`nServer:         $serverdir`r`nSources:        $sourcesdir`r`nMods:           $modsdir`r`nResource Packs: $resourcepacksdir`r`nData Packs:     $datapacksdir`r`n$('=' * 120)" -ForegroundColor Green
[SourceSubModule[]] $sources = @(
	[SourceSubModule]::new(
		'AppleSkin',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\appleskin-*.jar',			# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'BoundingBoxOutlineReloaded',			# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\BBOutlineReloaded-*.jar',	# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'canvas',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\canvas-*.jar',				# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'cloth-config',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\config-2-*.jar',			# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'connected-block-textures',				# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\connected-block-textures-*.jar',	# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'CraftPresence',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\CraftPresence-Fabric-*.jar',	# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'fabric',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\fabric-api-*.jar',			# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'Fabric-Autoswitch',					# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\autoswitch-*.jar',			# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'fabric-carpet',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\fabric-carpet-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'Grid',									# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\grid-*-fabric*.jar',		# Build output
		# Pre-compile command
@'
if (-not (Test-Path -Path '.\gradlew.bat')) {
	$url = 'https://services.gradle.org/distributions/gradle-4.10.2-bin.zip'
	$file = Split-Path -Path "$url" -Leaf
	Invoke-WebRequest -Uri $url -OutFile $file
	Expand-Archive -Path $file -DestinationPath .
	.\gradle-4.10.2\bin\gradle.bat wrapper --no-daemon
}
'@,
				$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'HWYLA',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\Hwyla-fabric-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'Inventory-Sorter',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\InventorySorter-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'itemscroller',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\itemscroller-fabric-*.jar',	# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'LambDynamicLights',					# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'ShadowRemapJar',						# Build command
		'build\libs\lambdynamiclights-fabric-*.jar',	# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'litematica',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\litematica-fabric-*.jar',	# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'lithium-fabric',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\lithium-fabric-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'malilib',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\malilib-fabric-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'minihud',										# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$false,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\minihud-fabric-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'ModMenu',								# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\modmenu-*.jar',				# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'OptiFabric',										# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\optifabric-*.jar',			# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'phosphor-fabric',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\phosphor-fabric-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'ShulkerBoxTooltip',										# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\shulkerboxtooltip-*.jar',	# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'Skin-Swapper',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\Skin_Swapper_*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'soaring-clouds',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\soaring-clouds-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'sodium-fabric',						# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\sodium-fabric-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'tweakeroo',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\tweakeroo-fabric-*.jar',	# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'WorldEdit',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'worldedit-fabric:build',				# Build command
		'worldedit-fabric\build\libs\worldedit-fabric-*.jar',	# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	),
	[SourceSubModule]::new(
		'WorldEditCUI',							# Submodule name
		[SubModuleType]::Module,				# Submodule type (Server/Plugin/Module/Data-pack/Resource-pack)
		$true,									# Git pull (True/False)
		$true,									# Build submodule (True/False)
		[BuildType]::Gradle,					# Build type (Maven/Gradle/Java/Other)
		'build',								# Build command
		'build\libs\WorldEditCUI-*.jar',		# Build output
		$null,									# Pre-compile command
		$null									# Post-compile command
	)
)

foreach ( $currentSource in $sources ) {
	$currentDir = Join-Path -Path $sourcesdir -ChildPath $currentSource.Name
	Write-Host "$('=' * 120)`r`nName:      $($currentSource.Name)`r`nDirectory: $currentDir`r`n$('=' * 120)" -ForegroundColor red
	Set-Location -Path $currentDir
	if ( $currentSource.GitPull ) { Start-Process "git" -ArgumentList @('pull') -NoNewWindow -Wait }
	$giturl = (git config --get remote.origin.url)
	$gitbranch = (git branch --show-current)
	$commit = (git rev-parse --short=7 HEAD)
	Write-Host "URL:       $giturl`r`nBranch:    $gitbranch`r`nCommit:    $commit`r`nOutput:    $($currentSource.BuildOutput)" -ForegroundColor Yellow
	if ( $currentSource.Build ) {
		[string]$finalOutputDir = ''
		switch ($currentSource.SubModuleType) {
			Server {
				$finalOutputDir = $serverdir
				break
			}
			Plugin {
				$finalOutputDir = $pluginsdir
				break
			}
			Module {
				$finalOutputDir = $modsdir
				break
			}
			Datapack {
				$finalOutputDir = $datapacksdir
				break
			}
			Resourcepack {
				$finalOutputDir = $resourcepacksdir
				break
			}
		}
		$finalOutputFilter = $currentSource.GetBuildOutputFileBase().Replace('.', '\.').Replace('?', '.').Replace('*', '.*')
		$finalOutputFilter += "[+-]?$commit"
		$finalOutputFilter += $currentSource.GetBuildOutputExtension()
		$finalOutputFilter += '(\.disabled)?'
		$files = (Get-ChildItem -File -Path $finalOutputDir | Where-Object { $_.Name -match $finalOutputFilter })
		if ($files.Count -ne 0) {
			Write-Host "`"$(($files|Select-Object -First 1).FullName)`" is already up to date." -ForegroundColor Green
		}
		else {
			Start-Process "git" -ArgumentList @('clean', '-xfd') -NoNewWindow -Wait
			if (-not [string]::IsNullOrEmpty($currentSource.PreCommand)) { Invoke-Expression -Command $currentSource.PreCommand }
			$currentArguments = $currentSource.GetBuildCommand()
			$currentProcess = Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c $currentArguments" -NoNewWindow -PassThru
			$currentProcess.WaitForExit()
			$lastHour = (Get-Date).AddHours(-1)
			$buildOutputFile = Get-ChildItem -Path $(Join-Path -Path $currentdir -ChildPath $currentSource.BuildOutput) -File -Exclude @('*-dev.jar', '*-sources.jar', '*-fatjavadoc.jar', '*-noshade.jar') -EA:0 | Where-Object { $_.CreationTime -ge $lastHour } | Sort-Object -Descending CreationTime | Select-Object -First 1
			if ( $null -ne $buildOutputFile ) {
				[string]$copyFromFileFullName = $buildOutputFile.FullName
				[string]$copyFromFileBaseName = $buildOutputFile.BaseName -replace "[+-]$commit", ''
				[string]$copyFromFileExtention = $buildOutputFile.Extension
				[string]$copyToFileBaseName = "$copyFromFileBaseName+$commit"
				[string]$copyToFileFullName = Join-Path -Path $finalOutputDir -ChildPath ("$copyToFileBaseName$copyFromFileExtention")
				Write-Host "Copying `"$copyFromFileFullName`" to `"$copyToFileFullName`"..."
				try {
					Copy-Item -Path $copyFromFileFullName -Destination $copyToFileFullName -Force -ErrorAction:Stop
					Write-Host "Copied `"$copyFromFileFullName`" to `"$copyToFileFullName`"." -ForegroundColor Green
				}
				catch {
					Write-Host "Error copying file `"$copyFromFileFullName`" to `"$copyToFileFullName`"." -ForegroundColor Red
				}
				if (-not [string]::IsNullOrEmpty($currentSource.PostCommand)) { Invoke-Expression -Command $currentSource.PostCommand }
			}
			else {
				Write-Host "No build output file `"$buildOutputFile`" found." -ForegroundColor Red
			}
		}
	}
	else {
		Write-Host "Building of this submodule is currently disabled." -ForegroundColor Magenta
	}
}
Pop-Location