use v6.c;
use Lithograph::Setup;
use Lithograph::Write;

unit class Lithograph::CLI;

method run(Str $command, @params) {
    given $command {
        when "create" {
            say "`create` command must has no parameter" and succeed if @params.elems != 0;
            Lithograph::Setup.run();
        }
        when "write" {
            say "`write` command must has 1 parameter" and succeed if @params.elems != 1;
            Lithograph::Write.run(@params);
        }
        when "build" {
            Lithograph::Build.run();
        }
        default {
            say "The command is not correct. See usage by executing lithograph with no option.";
        }
    }
}