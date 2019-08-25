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
    IO::Path.new("articles").mkdir(0o755);
    IO::Path.new("templates").mkdir(0o755);
    IO::Path.new("docs").mkdir(0o755);
    IO::Path.new("docs/static").mkdir(0o755);
    IO::Path.new("docs/entry").mkdir(0o755);

    # deploy files
    for @templates -> $template {
        spurt "templates".IO.child($template), slurp(%?RESOURCES{"templates/" ~ $template}.IO);
    }
    for @static -> $file {
        spurt "docs/static".IO.child($file), slurp(%?RESOURCES{"static/" ~ $file}.IO);
    }
    spurt ".".IO.child(".travis.yml"), slurp(%?RESOURCES{".travis.yml"}.IO);
}
