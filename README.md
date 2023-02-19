# SFRpoke
assemble with Waterbear https://github.com/wtetzner/waterbear

controls when on SFR/test mode:
- Down / Up: select the MSB of the SFR you want to test
- Left / Right: select the LSB of the SFR you want to test
- A: test/write/read/quit
- B: enter bitmask edit mode
- Sleep: cycle between POKE, WRITE, READ and QUIT modes

controls when on bitmask edit mode: (the cursor should appear)
- Down / Up: select the bit you want
- A: flip the bit
- B: go back to SFR/TEST mode

you can only cycle between POKE, WRITE, READ and QUIT when on SFR/test mode

rows on POKE mode - leftmost: 0-write result, rightmost: 1-write result
