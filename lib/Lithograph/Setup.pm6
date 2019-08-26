use v6.c;
unit class Lithograph::Setup;

method run() {
    say "call Setup";
    my @templates = [
        "index.tt",
        "list.tt",
        "article.tt"
    ];
    my @static = [
        "main.css"
    ];

    # setup directories
    say "make directories";
    IO::Path.new("articles").mkdir(0o755);
    IO::Path.new("templates").mkdir(0o755);
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
        spurt "docs/static".IO.child($file), slurp(%?RESOURCES{"static/" ~ $file}.IO);
    }
    say "copy .yml files";
    spurt ".".IO.child(".travis.yml"), slurp(%?RESOURCES{".travis.yml"}.IO);
    spurt ".".IO.child("config.yml"), slurp(%?RESOURCES{"config.yml"}.IO);
    say "Complete setup. Please edit config.yml ."
    
}
