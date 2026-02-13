This module is just an adaptation of illwill for my own use, mostly to make easier to make changes wihout passing via my fork.

I will probably make big changes to the module since I dont like single file libraries, my brain context window is like 500 lines long xD

For now the only change is the fix of mouse capabilities on Unix systems (only tested on Linux and WSL by the way). Windows terminals are still broke mostly because windows defender is a PITA, but the WSL version works like a charm. I will try to fix the windows version in the future, but for now I recommend using WSL if you want to run this on Windows.
