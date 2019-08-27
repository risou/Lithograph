#!/bin/sh

export PERL6LIB=Lithograph/lib
ls -A articles/*.md | sort -r | xargs -n1 basename | xargs -I {} perl6 Lithograph/bin/lithograph build article {}
perl6 Lithograph/bin/lithograph build index
perl6 Lithograph/bin/lithograph build list
perl6 Lithograph/bin/lithograph build static

