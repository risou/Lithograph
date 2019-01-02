use v6.c;
unit class Lithograph::Setup;

method run() {
    say "call Setup";

    # setup directories
    IO::Path.new("static").mkdir(0o755);
    IO::Path.new("articles").mkdir(0o755);
    IO::Path.new("templates").mkdir(0o755);
    IO::Path.new("html").mkdir(0o755);

    # deploy files
}