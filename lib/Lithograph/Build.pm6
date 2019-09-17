use v6.c;
use Text::Markdown::Discount;
use Template6;
use YAMLish;

unit class Lithograph::Build;

my $t6 = Template6.new;
$t6.add-path: 'templates';
my $config_file = 'config.yml'.IO;

method run(@args) {
    my $settings = self.get-settings();
    if $settings<option><ga_id>:exists && $settings<option><ga_id> ~~ /^^UA\-/ {
        $settings<ga> = True;
    }

    if @args.elems == 2 && @args[0] eq 'article' {
        my $name = @args[1];
        my $filename = "articles/" ~ $name;
        my $html = "docs/entry/" ~ $filename.IO.basename;
        my ($params, $markdown) = self.parse($filename.IO);
        my $text = self.htmlize-article($settings, $params, $markdown);
        spurt ($html.IO.extension: 'html'), $text;
        say "make " ~ $html.IO.extension: 'html';
        if $params<alias>:exists {
            my $alias = "docs/entry/" ~ $params<alias> ~ ".html";
            spurt ($alias.IO.extension: 'html'), self.htmlize-alias($settings, $params, $markdown, $filename.IO);
            say "make alias " ~ $alias.IO.extension: 'html';
        }
        return;
    } elsif @args.elems == 1 && @args[0] eq 'index' {
        my @articles;
        my $recent = 5;
        for dir("articles").sort.reverse -> $file {
            next if "md" ne $file.extension;
            my ($params, $markdown) = self.parse($file);
            @articles.push( {params => $params, markdown => $markdown} );
            $recent--;
            last if $recent <= 0;
        }
        my $index = "docs/index.html";
        spurt $index, self.htmlize-index($settings, @articles);
        say "make index.html";
        return;
    } elsif @args.elems == 1 && @args[0] eq 'list' {
        my @articles;
        for dir("articles").sort.reverse -> $file {
            next if "md" ne $file.extension;
            my $html = "docs/entry/" ~ $file.basename;
            my ($params, $markdown) = self.parse($file);
            @articles.push( {params => $params, markdown => $markdown} );
        }
        my $list = "docs/list.html";
        spurt $list, self.htmlize-list($settings, @articles);
        say "make list.html";
        return;
    } elsif @args.elems == 1 && @args[0] eq 'static' {
        self.copy-static-files();
        say "copy static files";
        return;
    }

    my @articles;
    my $recent = 5;
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
    my $contents = Text::Markdown::Discount.from-str($markdown, :AUTOLINK, :FENCEDCODE, :EXTRA_FOOTNOTE);
    $params<text> = $contents.to-html;
    my %ogp = (
        title => $params<title> ~ ' | ' ~ $settings<blog><title>,
        type => 'article',
        url => 'https://' ~ $settings<blog><domain> ~ '/entry/' ~ $params<name> ~ '.html',
        image => $settings<ogp><default_image>,
    );
    if $params<image>:exists {
        %ogp<image> = $params<image>;
    }
    $params<ogp> = %ogp;
    my %args = (
        :params(%$params),
        :settings(%$settings),
        :canonical(False),
    );
    if $settings<ga> {
        %args.push: (:ga(True));
    }
    else {
        %args.push: (:ga(False));
    }
    if $params<description>:exists {
        %args.push: (:exists_description(True));
    }
    else {
        %args.push: (:exists_description(False));
    }
    if $settings<ogp><fb_app_id>:exists {
        %args.push: (:exists_ogp_fb(True));
    }
    else {
        %args.push: (:exists_ogp_fb(False));
    }
    if $settings<ogp><twitter_id>:exists {
        %args.push: (:exists_ogp_tw(True));
    }
    else {
        %args.push: (:exists_ogp_tw(False));
    }
    return $t6.process('article', |%args);
}

method htmlize-index($settings, @articles) {
    for @articles -> $article {
        my $contents = Text::Markdown::Discount.from-str($article<markdown>, :AUTOLINK, :FENCEDCODE, :EXTRA_FOOTNOTE);
        $article<params><text> = $contents.to-html;
    }
    my %ogp = (
        title => $settings<blog><title>,
        type => 'website',
        url => 'https://' ~ $settings<blog><domain>,
        image => $settings<ogp><default_image>,
    );
    my %params = (
        ogp => %ogp,
    );
    my %args = (
        :articles(@articles),
        :settings(%$settings),
        :params(%params),
        :exists_description(False),
    );
    if $settings<ga> {
        %args.push: (:ga(True));
    }
    else {
        %args.push: (:ga(False));
    }
    if $settings<ogp><fb_app_id>:exists {
        %args.push: (:exists_ogp_fb(True));
    }
    else {
        %args.push: (:exists_ogp_fb(False));
    }
    if $settings<ogp><twitter_id>:exists {
        %args.push: (:exists_ogp_tw(True));
    }
    else {
        %args.push: (:exists_ogp_tw(False));
    }
    return $t6.process('index', |%args);
}

method htmlize-list($settings, @articles) {
    my %ogp = (
        title => 'archives | ' ~ $settings<blog><title>,
        type => 'article',
        url => 'https://' ~ $settings<blog><domain> ~ '/list.html',
        image => $settings<ogp><default_image>,
    );
    my %params = (
        ogp => %ogp,
    );
    my %args = (
        :articles(@articles),
        :settings(%$settings),
        :params(%params),
        :exists_description(False),
    );
    if $settings<ga> {
        %args.push: (:ga(True));
    }
    else {
        %args.push: (:ga(False));
    }
    if $settings<ogp><fb_app_id>:exists {
        %args.push: (:exists_ogp_fb(True));
    }
    else {
        %args.push: (:exists_ogp_fb(False));
    }
    if $settings<ogp><twitter_id>:exists {
        %args.push: (:exists_ogp_tw(True));
    }
    else {
        %args.push: (:exists_ogp_tw(False));
    }
    return $t6.process('list', |%args);
}

method htmlize-alias($settings, $params, $markdown, $filename) {
    my $contents = Text::Markdown::Discount.from-str($markdown, :AUTOLINK, :FENCEDCODE, :EXTRA_FOOTNOTE);
    $params<text> = $contents.to-html;
    $params<origin> = '/entry/' ~ $filename.basename.IO.extension: 'html';
    my %args = (
        :params(%$params),
        :settings(%$settings),
        :canonical(True),
    );
    if $settings<ga> {
        %args.push: (:ga(True));
    }
    else {
        %args.push: (:ga(False));
    }
    return $t6.process('article', |%args);
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
            $to.IO.child($file.basename).mkdir unless $to.IO.child($file.basename).e;
            self.recursive-mkdir($file, $to.IO.child($file.basename));
        }
    }
}

method recursive-copy($from, $to) {
    for $from.dir -> $file {
        if $file.d and not $file.l {
            self.recursive-copy($file, $to.IO.child($file.basename));
        } else {
            $file.copy($to.IO.child($file.basename));
        }
    }
}
