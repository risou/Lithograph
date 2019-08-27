use v6.c;
use Text::Markdown::Discount;
use Template6;
use YAMLish;

unit class Lithograph::Build;

my $t6 = Template6.new;
$t6.add-path: 'templates';
my $config_file = 'config.yml'.IO;

method run() {
    my @articles;
    my $recent = 5;
    my $settings = self.get-settings();
    for dir("articles").sort.reverse -> $file {
        next if "md" ne $file.extension;
        my $html = "docs/entry/" ~ $file.basename;
        my ($params, $markdown) = self.parse($file);
        @articles.push( {params => $params, markdown => $markdown} );
        my $text = self.htmlize-article($settings, $params, $markdown);
        spurt ($html.IO.extension: 'html'), $text;
        say "make " ~ $html.IO.extension: 'html';
        if $params<alias>:exists {
            my $alias = "docs/entry/" ~ $params<alias> ~ ".html";
            spurt ($alias.IO.extension: 'html'), self.htmlize-alias($settings, $params, $markdown, $file);
            say "make alias " ~ $alias.IO.extension: 'html';
        }
    }
    $recent = @articles.elems if @articles.elems < $recent;

    my $index = "docs/index.html";
    spurt $index, self.htmlize-index($settings, @articles[0..($recent-1)]);
    say "make index.html";

    my $list = "docs/list.html";
    spurt $list, self.htmlize-list($settings, @articles);
    say "make list.html";

    self.copy-static-files();
    say "copy static files";
}

method htmlize-article($settings, $params, $markdown) {
    my $contents = markdown($markdown, :AUTOLINK, :FENCEDCODE);
    $params<text> = $contents;
    return $t6.process('article', :params(%$params), :settings(%$settings), :canonical(False));
}

method htmlize-index($settings, @articles) {
    for @articles -> $article {
        $article<params><text> = markdown($article<markdown>, :AUTOLINK, :FENCEDCODE);
    }
    return $t6.process('index', :articles(@articles), :settings(%$settings));
}

method htmlize-list($settings, @articles) {
    return $t6.process('list', :articles(@articles), :settings(%$settings));
}

method htmlize-alias($settings, $params, $markdown, $filename) {
    my $contents = markdown($markdown, :AUTOLINK, :FENCEDCODE);
    $params<text> = $contents;
    $params<origin> = '/entry/' ~ $filename.basename;
    return $t6.process('article', :params(%$params), :settings(%$settings), :canonical(True));
}

method parse($file) {
    my %params;
    my @text;
    my Bool $isText = False;

    my @params-lines;

    for $file.lines -> $line {
        if $isText {
            @text.push: $line;
        }
        if $line ~~ /^^\-\-\-/ {
            $isText = True;
            next;
        }
        unless $isText {
            @params-lines.push: $line;
        }
    }
    %params = load-yaml(@params-lines.join: "\n");
    %params<datetime> = %params<date>  unless %params<datetime>:exists;
    %params<name> = $file.basename.IO.extension: '';

    return $%params, @text.join: "\n";
}

method get-settings() {
    my %config = load-yaml slurp($config_file);
    return $%config;
}

method copy-static-files() {
    my $root-dir = "./static".IO;
    self.recursive-mkdir($root-dir, "./docs/static".IO);
    self.recursive-copy($root-dir, "./docs/static".IO);
}

method recursive-mkdir($from, $to) {
    for $from.dir -> $file {
        if $file.d and not $file.l {
            $to.IO.child($file).mkdir unless $to.IO.child($file).e;
            self.recursive-mkdir($file, $to.IO.child($file));
        }
    }
}

method recursive-copy($from, $to) {
    for $from.dir -> $file {
        if $file.d and not $file.l {
            self.recursive-copy($file, $to.IO.child($file));
        } else {
            $file.copy($to.IO.child($file));
        }
    }
}
