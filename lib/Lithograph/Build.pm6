use v6.c;
use Text::Markdown::Discount;
use Template6;

unit class Lithograph::Build;

my $t6 = Template6.new;
$t6.add-path: 'templates';

method run() {
    for dir("articles") -> $file {
        next if "md" ne $file.extension;
        say $file.basename;
        my $html = "docs/" ~ $file.basename;
        my ($params, $markdown) = self.parse($file);
        my $text = self.htmlize($params, $markdown);
        spurt ($html.IO.extension: 'html'), $text;
    }
}

method htmlize($params, $markdown) {
    my $contents = markdown($markdown);
    $params{"text"} = $contents;
    return $t6.process('article', :params(%$params));
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

    return $%params, @text.join: "\n";
}
