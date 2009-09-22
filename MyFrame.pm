package MyFrame;
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


sub new {
   my $class = shift;
   my $this = $class->SUPER::new( undef, -1, $_[0], $_[1], $_[2] );
   #
   #   replace the filename with something appropriate.
   #
   my $file = IO::File->new( "/tmp/cq.png", "r" );
   unless ($file) {print "Can't load saved png.";return undef};
   binmode $file;
   my $handler = Wx::PNGHandler->new();
   my $image = Wx::Image->new();
   my $bmp;    # used to hold the bitmap.
   $handler->LoadFile( $image, $file );
   $bmp = Wx::Bitmap->new($image); 

   if( $bmp->Ok() ) {
      #  create a static bitmap called ImageViewer that displays the
      #  selected image.
      $this->{ImageViewer}= Wx::StaticBitmap->new($this, -1, $bmp);
   }
   $this->{ScaleImage}=0;

   $this->SetAutoLayout( 1 );  # allow wxperl to manage control sizing & placement
   # Layout constraints provide the guides
   # for wxperl's autolayout.
   my $b1 = Wx::LayoutConstraints->new();
   my $b2 = Wx::LayoutConstraints->new();

   # These constrainst define the placement and
   # dimensions of the controls they're bound to,
   # and can be either absolute, or relative to
   # other controls
   $b1->left->Absolute(0);
   $b1->top->Absolute(0);
   $b1->width->PercentOf( $this, wxWidth,50);
   $b1->height->PercentOf( $this, wxHeight, 100);
   $this->{ImageViewer}->SetConstraints($b1);

   #
   # Set up the menu bar.
   #
   my $file_menu = Wx::Menu->new();
   my ($OPEN_NEW_DIR, $REMOVE_DIR, $SCALE_IMAGE, $APP_QUIT)=(1..100);
   $file_menu->Append( $OPEN_NEW_DIR, "&Open A Directory\tCtrl-O");
   $file_menu->AppendSeparator();
   $file_menu->Append($SCALE_IMAGE,"&Scale Images To Window\tCtrl-S","",1);
   $file_menu->AppendSeparator();
   $file_menu->Append ($APP_QUIT, "E&xit\tCtrl-x","Exit Application");
   #
   # Note that even though there are 6 options, only
   # 4 of them are active as they're the only ones
   # bound to event handlers.
   #
#   EVT_MENU($this, $OPEN_NEW_DIR, \&OnDirDialog);
#   EVT_MENU($this, $SCALE_IMAGE,  \&Set_Scale);
   EVT_MENU($this, $APP_QUIT,     sub {$_[0]->Close( 1 )});

   my $menubar= Wx::MenuBar->new();
   $menubar->Append ($file_menu, "&File");
   $this->SetMenuBar($menubar);

   $this;  # return the frame object to the calling application.
}


