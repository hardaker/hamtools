package CQ::ShowImage;

our $VERSION = "0.4";

use POE;
use vars qw(@ISA);
use strict;
#
#   All we load here are constants used
#   to keep the image stretched to the dimensions of the window.
#
use Wx qw(wxWidth wxHeight wxLeft wxTop wxDefaultPosition wxDefaultSize wxID_CANCEL wxCentreX wxCentreY);
use Wx::Event qw(:everything);
#
#   Wx::Image loads the Image control and all of the Image handlers.
#
use IO::File;
use Wx::Event ;
our @ISA=qw(Wx::Frame);

my $updatetime = 5;

sub load_imgfile {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    return if ($heap->{'stop'});

    # run the function to update stuff
    $heap->{'updatefn'}->();

    # create the image from the imgfile
    print "here: $heap->{'imgfile'}\n";
    my $file = IO::File->new( $heap->{'imgfile'}, "r" );
    die "can't load $heap->{'imgfile'}\n"  if (!$file);
    binmode $file;
    my $handler = Wx::PNGHandler->new();
    $handler->LoadFile( $heap->{'image'}, $file );

    # XXX: don't create new bitmap below but update old?
    $heap->{'bitmap'} = Wx::Bitmap->new($heap->{'image'});
    $heap->{'staticbm'}->SetBitmap($heap->{'bitmap'});
    $heap->{'staticbm'}->Refresh();
#    $heap->{'bitmap'}->Refresh();
    $heap->{'this'}->Refresh();
    $kernel->delay(load_imgfile => $updatetime);
}

sub new {
   my $class = shift;
   my $imgfile = shift;
   my $updatefn = shift;
   my $this = $class->SUPER::new( undef, -1, $_[0], [-1,-1], [-1,-1] );
   #
   #   replace the filename with something appropriate.
   #
   my $file = IO::File->new( $imgfile, "r" );
   unless ($file) {print "Can't load saved png.";return undef};
   binmode $file;
   my $handler = Wx::PNGHandler->new();
   my $image = Wx::Image->new();
   my $bmp;    # used to hold the bitmap.
   $handler->LoadFile( $image, $file );
   $this->{'bitmap'} = $bmp = Wx::Bitmap->new($image); 
   $this->{'image'} = $image;
   main::Die("failed to load image file") if( !$bmp->Ok() );

   my $subpanel = Wx::Panel->new($this, -1);
   my $grid = new Wx::FlexGridSizer(1,1);
   my $widget = Wx::StaticBitmap->new($subpanel, -1, $bmp);
   $this->{'staticbm'} = $widget;
   $grid->Add($widget);
   $subpanel->SetSizerAndFit($grid);

   $grid->SetSizeHints($this);

#   $this->SetAutoLayout( 1 );  # allow wxperl to manage control sizing & placement
   # Layout constraints provide the guides
   # for wxperl's autolayout.
#    my $b1 = Wx::LayoutConstraints->new();
#    my $b2 = Wx::LayoutConstraints->new();

   # These constrainst define the placement and
   # dimensions of the controls they're bound to,
   # and can be either absolute, or relative to
   # other controls
#    $b1->left->Absolute(0);
#    $b1->top->Absolute(0);
#    $b1->width->PercentOf( $this, wxWidth,50);
#    $b1->height->PercentOf( $this, wxHeight, 100);
#    $this->{ImageViewer}->SetConstraints($b1);

   my $stopfn;
   if ($updatefn) {
       # repeatedly call the update function once every ...  err
       # hardcoded 5 secends.

       my $session =
       POE::Session->create(
			 inline_states =>
			 {
			  _start => sub {
					  $_[HEAP]{updatefn} = $updatefn;
					  $_[HEAP]{imgfile} = $imgfile;
					  $_[HEAP]{this} = $this;
					  $_[HEAP]{bitmap} = $this->{'bitmap'};
					  $_[HEAP]{widget} = $widget;
					  $_[HEAP]{staticbm} =
					    $this->{'staticbm'};
					  $_[HEAP]{'image'} = $this->{'image'};
					  $_[HEAP]{'grid'} = $grid;

					  $_[KERNEL]->yield('load_imgfile');
				      },
			  load_imgfile => \&load_imgfile,
			  stop => sub { $_[HEAP]{'stop'} = 1; print "stopping\n";},
			 }
			);
       $stopfn = $session->postback('stop');
   }

   $this->{'stopfn'} = $stopfn;
   EVT_CLOSE($this, \&closit);

   $this;  # return the frame object to the calling application.
}


sub update_pixmap {
    my $self = shift;
    $self->load_imgfile();
}

sub closit {
    $_[0]->{'stopfn'}->() if ($_[0]->{'stopfn'});
    $_[0]->Destroy();
    return 1;
}
