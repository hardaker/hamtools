package MyApp;

use Wx qw(:everything);
use Wx::Event qw(EVT_MENU);
use Wx::App;
our @ISA=qw(Wx::App);
use MyFrame;
use MyScanner;

our $type = 'blah';

sub OnInit {
   my $this = @_;
   my $frame;
   print "here: $type\n";
   if ($type) {
       $frame = MyScanner->new("Scanner",  [-1,-1], [-1,-1]);
   } else {
       $frame = MyFrame->new( "Spectrum Plot", [-1,-1], [-1,-1]);
   }
   #my $this->{FRAME}=$frame;
   unless ($frame) {
       print "unable to create frame -- exiting."; 
       return undef;
   }
   $frame->Show( 1 );
   1;
}

