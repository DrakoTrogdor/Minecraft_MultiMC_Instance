Function PressAnyKey {
	Write-Console "Press any key to continue ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
Function YesOrNo {
	Param (
		[Parameter(Mandatory=$false)][string]$Prompt = "Is the above information correct? [y|n]"
	)
	[string]$response = ""
	while ($response -notmatch "[y|n]"){
		$response = Read-Host $Prompt
	}
	If ($response -match "y") { Return $true }
	Else { Return $false}
}
$commondir = 'D:\Games\Minecraft'
$instancedir = Split-Path ($MyInvocation.MyCommand.Path)
if (YesOrNo -Prompt "Link files in `"$commondir`" to the folder `"$instancedir`"?") {
    Remove-Item "$instancedir\resourcepacks" -ErrorAction Ignore -Force
    New-Item -ItemType SymbolicLink -Path "$instancedir\resourcepacks" -Target "$commondir\_Resource_Packs\Current\"

    Remove-Item "$instancedir\saves" -ErrorAction Ignore -Force
    New-Item -ItemType SymbolicLink -Path "$instancedir\saves" -Target "$commondir\Saves\"

    Remove-Item "$instancedir\screenshots" -ErrorAction Ignore -Force
    New-Item -ItemType SymbolicLink -Path "$instancedir\screenshots" -Target "$commondir\Screenshots\"

    Remove-Item "$instancedir\schematics" -ErrorAction Ignore -Force
    New-Item -ItemType SymbolicLink -Path "$instancedir\schematics" -Target "$commondir\Schematics\"

    Remove-Item "$instancedir\shaderpacks" -ErrorAction Ignore -Force
    New-Item -ItemType SymbolicLink -Path "$instancedir\shaderpacks" -Target "$commondir\Shaders\"

    Remove-Item "$instancedir\skins" -ErrorAction Ignore -Force
    New-Item -ItemType SymbolicLink -Path "$instancedir\skins" -Target "$commondir\Skins\"
}