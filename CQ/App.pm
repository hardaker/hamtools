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
   my $this = @_;
   my $frame;
   if ($type) {
       $frame = CQ::Scanner->new("CQ: Scanner",  [-1,-1], [-1,-1]);
   } else {
       $frame = CQ::Spectrum->new( "CQ: Spectrum Plot", [-1,-1], [-1,-1]);
   }
   #my $this->{FRAME}=$frame;
   unless ($frame) {
       print "unable to create frame -- exiting."; 
       return undef;
   }
   $frame->Show( 1 );
   1;
}

