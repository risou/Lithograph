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
    my $settings = self.get_settings();
    for dir("articles").sort.reverse -> $file {
        next if "md" ne $file.extension;
        my $html = "docs/entry/" ~ $file.basename;
        my ($params, $markdown) = self.parse($file);
        @articles.push( {params => $params, markdown => $markdown} );
        my $text = self.htmlize-article($settings, $params, $markdown);
        spurt ($html.IO.extension: 'html'), $text;
    }
    $recent = @articles.elems if @articles.elems < $recent;

    my $index = "docs/index.html";
    spurt $index, self.htmlize-index($settings, @articles[0..($recent-1)]);

    my $list = "docs/list.html";
    spurt $list, self.htmlize-list($settings, @articles);
}

method htmlize-article($settings, $params, $markdown) {
    my $contents = markdown($markdown, :AUTOLINK, :FENCEDCODE);
    $params<text> = $contents;
    return $t6.process('article', :params(%$params), :settings(%$settings));
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

method parse($file) {
    my %params;
    my @text;
    my Bool $isText = False;

    %params<name> = $file.basename.IO.extension: '';

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
            %params{@kv[0]} = trim(@kv[1]);
        }
    }

    return $%params, @text.join: "\n";
}

method get_settings() {
    my %config = load-yaml slurp($config_file);
    return $%config;
}
