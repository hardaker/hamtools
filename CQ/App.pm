package CQ::App;

our $VERSION = "0.4";

use Wx qw(:everything);
use Wx::Event qw(EVT_MENU);
use Wx::App;
our @ISA=qw(Wx::App);
use CQ::Scanner;
use CQ::Spectrum;

our $type = 'blah';

sub OnInit {
   my ($this) = @_;
   my $frame;
   my $haveit = eval "require CQ::$type";
   if (!$haveit) {
       die "whoops...  Can't find a window of type $CQ::$type\n  $@\n";
   }
   $frame = eval "CQ::$type->new()";
   #my $this->{FRAME}=$frame;
   unless ($frame) {
       print "unable to create frame -- exiting."; 
       exit 1;
   }
   $frame->Show( 1 );
   1;
}

1;
