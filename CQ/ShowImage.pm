package CQ::ShowImage;
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

sub load_imgfile {
    my ($self) = @_;
    $self->{'updatefn'}->();
    my $file = IO::File->new( $self->{'imgfile'}, "r" );
    die "can't load $self->{'imgfile'}\n"  if (!$file);
    binmode $file;
    my $handler = Wx::PNGHandler->new();
    #my $image = Wx::Image->new();
    $handler->LoadFile( $self->{'image'}, $file );
    # XXX: don't create new bitmap below but update old?
    $self->{'bitmap'} = Wx::Bitmap->new($self->{'image'});
    $self->{'staticbm'}->SetBitmap($self->{'bitmap'});
}

sub new {
   my $class = shift;
   my $imgfile = shift;
   my $updatefn = shift;
   my $this = $class->SUPER::new( undef, -1, $_[0], $_[1], $_[2] );
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

   if ($updatefn) {
       # repeatedly call the update function once every ...  err
       # hardcoded 5 secends.

       my $timer = Wx::Timer->new($this, 1500);
       $timer->Start(5000);
       $this->EVT_TIMER($timer, \&load_imgfile);
       $this->{'updatefn'} = $updatefn;
       $this->{'imgfile'} = $imgfile;
       $this->{'timer'} = $timer;
   }

   EVT_CLOSE($this, \&closit);

   $this;  # return the frame object to the calling application.
}


sub update_pixmap {
    my $self = shift;
    $self->load_imgfile();
}

sub closit {
    $_[0]->Destroy();
    $_[0]->{'timer'}->Stop();
    return 1;
}
