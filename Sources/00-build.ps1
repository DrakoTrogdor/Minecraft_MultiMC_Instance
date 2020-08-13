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
$basedir = (Get-Location).Path
$modsdir = Join-Path -Path ((Get-Item $basedir).Parent) -ChildPath .minecraft -AdditionalChildPath mods
Get-ChildItem -Directory | ForEach-Object {
	$currentmod = $_.Name
	$currentdir = Join-Path -Path $basedir -ChildPath $currentmod
	Write-Host "$('=' * 120)`r`n$currentmod`r`n$currentdir`r`n$('=' * 120)" -ForegroundColor red
	Set-Location -Path $currentdir
	$gradlew = Join-Path -Path $currentdir -ChildPath "gradlew.bat"
	$gradlew_buildfile = Join-Path -Path $currentdir -ChildPath "build.gradle"
	if (!(Test-Path -Path $gradlew_buildfile)) { $gradlew_buildfile += '.kts' }
	if (!(Test-Path -Path $gradlew) -or !(Test-Path -Path $gradlew_buildfile)) {
		Write-Host "$currentmod does not have required gradle files"
	}
	else {
		switch ($currentmod) {
			'WorldEdit' {
				$gradleProperties = (Invoke-BatchFile -commandPath $gradlew -commandArguments "worldedit-fabric:properties --no-daemon").StandardOutput
				$gradleBuild = 'worldedit-fabric:build'
				$gitPull = $true
				$jardir = Join-Path -Path $currentdir -ChildPath worldedit-fabric -AdditionalChildPath build,libs
				break
			}
			'LambDynamicLights' {
				$gradleProperties = (Invoke-BatchFile -commandPath $gradlew -commandArguments "properties --no-daemon").StandardOutput
				$gradleBuild = 'ShadowRemapJar'
				$gitPull = $true
				$jardir = Join-Path -Path $currentdir -ChildPath build -AdditionalChildPath libs
				break
			}
			'Fabric-Autoswitch' {
				$gradleProperties = (Invoke-BatchFile -commandPath $gradlew -commandArguments "properties --no-daemon").StandardOutput
				$gradleBuild = 'build'
				$gitPull = $false
				$jardir = Join-Path -Path $currentdir -ChildPath build -AdditionalChildPath libs
				break
			}
			default {
				$gradleProperties = (Invoke-BatchFile -commandPath $gradlew -commandArguments "properties --no-daemon").StandardOutput
				$gradleBuild = 'build'
				$gitPull = $true
				$jardir = Join-Path -Path $currentdir -ChildPath build -AdditionalChildPath libs
			}
		}
		if ( $gitPull ) { Start-Process "git" -ArgumentList @('pull')  -NoNewWindow -Wait }
		$commit = (git rev-parse --short=7 HEAD)
		$archivesBaseName = ($gradleProperties | Select-String -Pattern "(?:archivesBaseName:\s)([^`r`n]*)").Matches[0].Groups[1].Value
		if ((Get-ChildItem -File -Path $modsdir | Where-Object {$_.Name -like "$archivesBaseName*+$commit.jar"}).Count -ne 0) {
			Write-Host "Jar file in mods folder is already up to date."
		}
		else {
			$currentProcess = Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c `"$gradlew`" -q $gradleBuild --no-daemon" -NoNewWindow -PassThru #-Wait
			$currentProcess.WaitForExit()
			$lastHour = (Get-Date).AddHours(-1)
			$jarfile = Get-ChildItem -Path $(Join-Path -Path $jardir -ChildPath "$archivesBaseName*.jar") -File -Exclude @('*-dev.jar','*-sources.jar') | Where-Object {$_.CreationTime -ge $lastHour} | Sort-Object -Descending CreationTime | Select-Object -First 1
			if ( $null -ne $jarfile ) {
				$copyToFileName = Join-Path -Path $modsdir -ChildPath ("$(($jarfile).BaseName)+$commit.jar")
				Copy-Item -Path $jarfile.FullName -Destination $copyToFileName -Force -EA:0
			}
			else {
				Write-Host "No jar file `"$jarfile`" found."
			}
		}
	}
}
Set-Location -Path $basedir