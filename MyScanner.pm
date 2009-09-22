use Wx qw(:everything);
use Wx::Event qw(EVT_MENU);

package MyScanner;

use vars qw(@ISA);
use strict;

#
#   All we load here are constants used
#   to keep the image stretched to the dimensions of the window.
#
use Wx qw(wxWidth wxHeight wxLeft wxTop wxDefaultPosition wxDefaultSize wxID_CANCEL wxCentreX wxCentreY);
use Wx::Event qw(:everything);
use Wx::Timer;

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

   my $panel = Wx::Panel->new($this, -1);
   my $grid = new Wx::GridSizer(2,3);

   my $button;
   $grid->Add($button = Wx::Button->new($panel, 1, 'Lock            '));
   $this->{'lockbutton'} = $button;
   EVT_BUTTON($this, 1, 
	      sub {
		  print STDERR "hi! $_[0] $_[1] $_[2]\n";
		  $main::locked = !$main::locked;
		  $_[0]->{'lockbutton'}->SetLabel(($main::locked ? "Unlock" : "Lock") . " $main::currentchannel");
		});
   $panel->SetSizer($grid);
#   Centre();

   my $timer = Wx::Timer->new($this, 1000);
   print "$timer\n";
   $timer->Start(1000);
   $this->EVT_TIMER($timer, \&on_timer);
#   $this->Connect(1000, -1, -1, \&on_timer);

   if (0) {
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
   }

   $this;  # return the frame object to the calling application.
}

sub on_timer {
#    print STDERR "Time! $_[0] $_[1] $_[2]\n";
    main::next_scan();
}


1;
