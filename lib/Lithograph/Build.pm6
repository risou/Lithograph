use v6.c;
use Text::Markdown::Discount;

unit class Lithograph::Build;

method run() {
    for dir("articles") -> $file {
        next if "md" ne $file.extension;
        say $file.basename;
        my $html = "html/" ~ $file.basename;
        my ($params, $text) = self.parse($file);
        spurt ($html.IO.extension: 'html'), $text;
    }
}

method parse($file) {
    my %params;
    my @text;
    my Bool $isText = False;

    for $file.lines -> $line {
        if $isText {
            @text.push: $line;
        }
        if "---" eq $line {
            $isText = True;
            next;
        }
        unless $isText {
            my @kv = split(":", $line, 2);
            %params{@kv[0]} = @kv[1];
        }
    }

    return $%params, markdown(@text.join: "\n");
}