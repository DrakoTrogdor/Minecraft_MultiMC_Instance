# Minecraft_MultiMC_Instance
MultiMC instance for Minecraft 1.17 with Fabric, Optifine and a light selection of mods.

## Mods
- AppleSkin
- Autofish
> https://www.curseforge.com/minecraft/mc-mods/autofish
- BoundingBox OutlineReloaded
- CraftPresence
- Fabric API
- Grid
- Inventory Sorter
- Item Scroller
- Litematica
- MaLiLib
- MiniHUD
- Mod Menu
- OptiFabric
- OptiFine
> Credit to sp614x [Donate](https://optifine.net/donate).
> 
> Downloads: https://optifine.net/downloads
- Replay Mod
- Shulker Box Tooltip
- Skin Swapper
- Simple Voice Chat
- Tweakeroo
- VoxelMap
> Credit to MamiyaOtaru [Patreon](https://www.patreon.com/MamiyaOtaru).
> 
> Downloads: https://www.curseforge.com/minecraft/mc-mods/voxelmap
- WorldEdit
- WorldEditCUI
- WTHIT
## Resource Packs
- Infested Blocks
- Shield Corrections
- Stridaph
> https://twitter.com/rubikowl/status/1249460449088659456?lang=en
- Villager Sounds
> Derp-tastic Villager Sounds as seen in Grian's videos
> The Element Animation Villager Sounds Resource Pack (T.E.A.V.S.R.P.)
> http://www.elementanimation.com
- Vanilla Tweaks
> Information below:
### Vanilla Tweaks
> Downloaded from https://vanillatweaks.net/picker/resource-packs/
#### Aesthetic
- EndlessEndRods
- NoteblockBanners
#### Variation
- VariatedBookshelves
#### Peace and Quiet
- QuieterCows
- QuieterDispensersDroppers
- QuieterEndermen
- QuieterFire
- QuieterGhasts
- QuieterMinecarts
- QuieterNetherPortals
- QuieterPistons
- QuieterShulkers
- QuieterVillagers
- QuieterWater
#### Utility
- DiminishingTools
#### Unobtrusive
- LowerFire
- LowerShield
- SmallerUtilities
- TransparentPumpkin
- UnobtrusiveScaffolding
#### HUD
- PingColorIndicator
#### GUI
- NumberedHotbar
#### Retro
- OldDamageSounds
#### Fixes
- BlazeFix
- DoubleSlabFix
- ItemHoldFix
- JappaObserver
- JappaSigns
- NicerFastLeaves

## Shader Packs
- Sidulrs Vibrand Shaders Extreme-VL
> https://sildurs-shaders.github.io/downloads/

See Changelog for list of mod versions.

## Cloning Repository
### ./.git/config
Add the following to the git config file in order to prevent personal information from being pushed online:
```
[core]
    autocrlf = false
[filter "gf-instance_cfg"]
    clean = sed -E -e 's/lastLaunchTime=[0-9]+/lastLaunchTime=0/' -e 's/totalTimePlayed=[0-9]+/totalTimePlayed=0/' -e 's/^JavaPath=.*$/JavaPath=/'
    smudge = sed -E -e 's/lastLaunchTime=[0-9]+/lastLaunchTime=0/' -e 's/totalTimePlayed=[0-9]+/totalTimePlayed=0/' -e 's/^JavaPath=.*$/JavaPath=/'
[filter "gf-craftpresence_properties"]
    clean = sed -E -e 's/(Sun|Mon|Tue|Wed|Thu|Fri|Sat) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [A-Z]{3} [0-9]{4}/Sun Jan 1 00:00:00 GMT 2020/' -e 's/^Client_ID=748976419190603806$/Client_ID=/'
    smudge = sed -E -e 's/(Sun|Mon|Tue|Wed|Thu|Fri|Sat) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [A-Z]{3} [0-9]{4}/Sun Jan 1 00:00:00 GMT 2020/' -e 's/^Client_ID=$/Client_ID=748976419190603806/'
[filter "gf-minihud_json"]
    clean = sed   -E 's/    "infoLightLevel": true,/    "infoLightLevel": false,/'
    smudge = sed   -E 's/    "infoLightLevel": true,/    "infoLightLevel": false,/'
[filter "gf-properties"]
    clean = sed -E 's/(Sun|Mon|Tue|Wed|Thu|Fri|Sat) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [A-Z]{3} [0-9]{4}/Sun Jan 1 00:00:00 GMT 2020/'
    smudge = sed -E 's/(Sun|Mon|Tue|Wed|Thu|Fri|Sat) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [A-Z]{3} [0-9]{4}/Sun Jan 1 00:00:00 GMT 2020/'
```