use v6.c;
unit class Lithograph::Write;

method run(@params) {
    # make file
    my $name = @params[0];
    my $today = Date.today;
    my $now = DateTime.now;
    my $filename = $today ~ '-' ~ $name ~ '.md';
    spurt "articles/" ~ $filename, self.template({ title => $name, date => $today, datetime => $now });
    
    my $editor = %*ENV<EDITOR>;
    run $editor, "articles/" ~ $filename if $editor;
    say "create new file $filename in articles"
}

method template(%params) {
    qq:to/END/;
title: %params<title>
date: %params<date>
datetime: %params<datetime>
---
END
}
