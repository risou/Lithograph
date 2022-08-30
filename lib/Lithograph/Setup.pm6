use v6.c;
unit class Lithograph::Setup;

method run() {
    say "call Setup";
    my @templates = [
        "index.tt",
        "list.tt",
        "article.tt",
        "ogp.tt",
    ];
    my @static = [
        "main.css"
    ];

    # setup directories
    say "make directories";
    IO::Path.new("static").mkdir(0o755);
    IO::Path.new("articles").mkdir(0o755);
    IO::Path.new("templates").mkdir(0o755);
    IO::Path.new(".github/workflows").mkdir(0o755);
    IO::Path.new("docs").mkdir(0o755);
    IO::Path.new("docs/static").mkdir(0o755);
    IO::Path.new("docs/entry").mkdir(0o755);

    # deploy files
    say "copy templates";
    for @templates -> $template {
        spurt "templates".IO.child($template), slurp(%?RESOURCES{"templates/" ~ $template}.IO);
    }
    say "copy static files";
    for @static -> $file {
        spurt "static".IO.child($file), slurp(%?RESOURCES{"static/" ~ $file}.IO);
    }
    say "copy .yml files";
    spurt ".".IO.child(".travis.yml"), slurp(%?RESOURCES{".travis.yml"}.IO);
    spurt ".".IO.child("config.yml"), slurp(%?RESOURCES{"config.yml"}.IO);
    spurt ".github/workflows".IO.child("build.yml"), slurp(%?RESOURCES{"github-actions/build.yml"}.IO);
    spurt ".github/workflows".IO.child("write.yml"), slurp(%?RESOURCES{"github-actions/write.yml"}.IO);
    say "Complete setup. Please edit config.yml ."
    
}
