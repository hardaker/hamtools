package MyApp;

use Wx qw(:everything);
use Wx::Event qw(EVT_MENU);
use Wx::App;
our @ISA=qw(Wx::App);
use CQScanner;
use CQSpectrum;

our $type = 'blah';

sub OnInit {
   my $this = @_;
   my $frame;
   if ($type) {
       $frame = CQScanner->new("Scanner",  [-1,-1], [-1,-1]);
   } else {
       $frame = CQSpectrum->new( "Spectrum Plot", [-1,-1], [-1,-1]);
   }
   #my $this->{FRAME}=$frame;
   unless ($frame) {
       print "unable to create frame -- exiting."; 
       return undef;
   }
   $frame->Show( 1 );
   1;
}

