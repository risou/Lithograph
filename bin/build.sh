#!/bin/sh

ls -A articles/*.md | sort -r | xargs basename | xargs -I {} perl6 ~/src/github.com/risou/Lithograph/bin/lithograph build article {}
perl6 ~/src/github.com/risou/Lithograph/bin/lithograph build index
perl6 ~/src/github.com/risou/Lithograph/bin/lithograph build list
perl6 ~/src/github.com/risou/Lithograph/bin/lithograph build static

