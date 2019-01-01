use v6.c;
unit class Lithograph::Write;

method run(@params) {
    # make file
    my $name = @params[0];
    my $today = Date.today;
    my $filename = $today ~ '-' ~ $name ~ '.md';
    spurt "articles/" ~ $filename, self.template($today, $name);
    
    my $editor = %*ENV<EDITOR>;
    run $editor, "articles/" ~ $filename if $editor;
    say "create new file $filename in articles"
}

method template($date, $title) {
    qq:to/END/;
title: $title
date: $date
---
END
}