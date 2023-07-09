# SFRpoke

## assembling
assemble with Waterbear https://github.com/wtetzner/waterbear using the following command on your command line of preference `waterbear assemble SFRpoke.s -o SFRpoke.vms`

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

## NOTICE
SFR.I is taken from https://github.com/jahan-addison/snake
