use v6.c;
use Lithograph::Setup;

unit class Lithograph::CLI;

method run(Str $command) {
    given $command {
        when "create" {
            Lithograph::Setup.run();
        }
        when "write" {
            Lithograph::Write.run();
        }
        when "build" {
            Lithograph::Build.run();
        }
        default {
            say "The command is not correct. See usage by executing lithograph with no option.";
        }
    }
}