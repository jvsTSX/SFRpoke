# SFRpoke
<br><p align="left"><img src="https://github.com/jvsTSX/SFRpoke/blob/main/assets/SFRpoke_example.png?" alt="SFRpoke example" width="850" height="555"/>

## assembling
use Waterbear assembler https://github.com/wtetzner/waterbear, and then making sure that `SFR.i`, `SFRpoke.s` and `SFRpoke_DCicon.gif`
are all in the same folder type the following on your command line app of preference `waterbear assemble SFRpoke.s -o SFRpoke.vms`

## controls
### per-mode controls, you can tell what mode you're on if you can see a little dot cursor showing up
> On SFR select mode (no cursor)
- Dpad right and left: adjust the indicated SFR's lower nibble
- Dpad up and down: adjust the indicated SFR's upper nibble
- SLEEP: go to Bit edit mode

> On Bit edit mode (cursor showing up)
- Dpad right and left: toggle bit
- Dpad up and down: select bit
- SLEEP: go to SFR select mode

### common controls - these do the same function regardless of whether you're selecting bits or selecting SFR
- A: Write 'W' column to the indicated SFR in the top right corner
- B: Read the indicated SFR in the top right corner and store the result into the 'R' column
- MODE: toggles between the app's own modes, see below

## app modes
- SFR: pokes hardware registers
- XRAM: pokes the whole screen memory at the first 2 banks of XBNK (0 and 1)
- ICON: pokes the last 2 banks of XBNK (2 and 3)
- EXIT: goes back to the BIOS when pressing A

## NOTICE
SFR.I is taken from https://github.com/jahan-addison/snake

## Version log
- 1.0 - initial version
- 1.1 - reworked UI and rewrote the entire code from the ground up, now supports XRAM and ICON pokes
- 1.2 - fixed a bug where poking PSW and C broke the program, changed fonts and added an animated icon visible on your dreamcast file manager or Elysian VMU file manager
- 1.3 - fixed player inputs in general, keys now no longer re-trigger if you are holding another one and there is no bouncing errors when setting the system to 1MHz or 500KHz clock rates
