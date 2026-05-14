# ReadDataRead
bash script for reading binary data into an integer array. wrote as a back-up in the event more specialised tools aren't available (like `dd`)

notes:
- tested on debian, and termux (not really a linux distro but it works)
- as far as i'm aware, the whole script uses nothing but built-in commands for bash- so, if you're ever in a situation where all you have is bash (no `awk`, `grep`, `cat`, etc.), then you're not missing out on anything.
- data is stored in groups of 8 bytes / 64 bits into an integer array in little-endian (or big-endian if you make a small change, as documented in the script itself). this is to make it more compact than having each element store a single byte
- it is able to handle multi-byte characters, primarily utf-8, and is able to account for null bytes (notice the wording there)
- using this to write / copy data is possible in theory- though, i cant say with certainty

feel free to take it, change it, and do what towel

~half one~ have fun
