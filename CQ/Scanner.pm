package CQ::Scanner;

use Wx qw(:everything :font :textctrl);
use Wx::Event qw(EVT_MENU);

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

my $mainpanel;
my $subpanel;
my $grid;

sub load_buttons {
   my $channelid = 2000;
   foreach my $channel (@main::toscan) {
       $main::config{$channel}{'button'} =
	 Wx::Button->new($subpanel, $channelid, $channel);
       my $font = Wx::Font->new( 8, wxROMAN, wxNORMAL, wxNORMAL);
       $main::config{$channel}{'button'}->SetFont($font);
       $grid->Add($main::config{$channel}{'button'});
       $main::config{$channel}{'button'}{'channel'} = $channel;
       EVT_BUTTON($main::config{$channel}{'button'}, $channelid,
		  \&channel_button);
       $channelid++;
   }
}

sub channel_button {
    my ($channelb, $event) = @_;
    set_channel_button($main::currentchannel) if ($main::currentchannel);
    $main::config{$main::currentchannel}{'button'}
      ->SetLabel("$main::currentchannel")
	if ($main::currentchannel);
    if ($main::locked && $main::currentchannel eq $channelb->{'channel'}) {
	# unlock
	$main::locked = 0;
    } else {
	# lock to a channel
	main::set_channel($channelb->{'channel'});
	set_channel_button($channelb->{'channel'}, wxNORMAL, wxBOLD);
	$channelb->SetLabel("(L) $channelb->{'channel'}");
	$main::locked = 1;
    }

}

sub OnQuit {
    exit;
}

sub OnEnable {
    my ($channel) = $_[0];
    if ($main::config{$channel}{'enabled'} eq 'false') {
	$main::config{$channel}{'enabled'} = 'true';
	set_channel_button($channel);
	$main::config{$channel}{'button'}->SetLabel("$channel");
    } else {
	$main::config{$channel}{'enabled'} = 'false';
	set_channel_button($channel, wxSLANT);
	$main::config{$channel}{'button'}->SetLabel("(D) $channel");
    }
}

sub OnGroup {
    my ($group) = $_[0];
    main::load_group($group);
    $grid->Clear(1);
    load_buttons();
    $subpanel->SetSizerAndFit($grid);
    $main::currentchannel = '';
}

sub set_channel_button {
    my ($channel, $ifont, $bfont) = @_;
    $ifont = wxNORMAL if (!$ifont);
    $bfont = wxNORMAL if (!$bfont);
    my $font = Wx::Font->new( 8, wxROMAN, $ifont, $bfont);
    $main::config{$channel}{'button'}->SetFont($font);
}

sub new {
   my $class = shift;
   my $this = $class->SUPER::new( undef, -1, $_[0], $_[1], $_[2] );
   $mainpanel = $this;

   #
   #   replace the filename with something appropriate.
   #

   $subpanel = Wx::Panel->new($this, -1);
   $grid = new Wx::GridSizer(1,int(($#main::toscan + 3)/2));

   #
   # MENU setup
   #
   my($MENU_QUIT, $MENU_GRID) = (3000..3999);
   my($mfile) = Wx::Menu->new(undef, wxMENU_TEAROFF);
   $mfile->Append($MENU_QUIT, "&Quit\tCtrl-Q", "Quit this program");
#   $mfile->AppendSeparator();

   my($mbar) = Wx::MenuBar->new();
   $mbar->Append($mfile, "&Commands");
   $this->SetMenuBar($mbar);
   EVT_MENU($this, $MENU_QUIT, \&OnQuit);

   my $enableid = 4000;
   my($menable) = Wx::Menu->new(undef, wxMENU_TEAROFF);
   foreach my $channel (@main::toscan) {
       $menable->Append($enableid, "$channel", "");
       EVT_MENU($this, $enableid, sub {OnEnable($channel);});
       $enableid++;
   }
   $mbar->Append($menable, "&Enable/Disable");

   my $groupid = 4500;
   my($mgroup) = Wx::Menu->new(undef, wxMENU_TEAROFF);
   foreach my $group (sort keys(%main::groups)) {
       $mgroup->Append($groupid, "$group", "");
       EVT_MENU($this, $groupid, sub {OnGroup($group);});
       $groupid++;
   }
   $mbar->Append($mgroup, "&Group");

   load_buttons();

   $subpanel->SetSizerAndFit($grid);
#   Centre();

   my $timer = Wx::Timer->new($this, 1000);
   $timer->Start(1000, 1);
   $this->EVT_TIMER($timer, \&on_timer);
#   $this->Connect(1000, -1, -1, \&on_timer);

   $this;  # return the frame object to the calling application.
}

sub on_timer {
    my $oldchannel = $main::currentchannel;
    my $sleeptime = main::next_scan();
    if ($main::currentchannel ne $oldchannel) {
	if ($oldchannel) {
	    my $font = Wx::Font->new( 8, wxROMAN, wxNORMAL, wxNORMAL);
	    $main::config{$oldchannel}{'button'}->SetFont($font);
	}
	if ($main::currentchannel) {
	    my $font = Wx::Font->new( 8, wxROMAN, wxNORMAL, wxBOLD);
	    $main::config{$main::currentchannel}{'button'}->SetFont($font);
	}
    }
    my $timer = Wx::Timer->new($mainpanel, 1000);
    $timer->Start(($sleeptime > .01 ? $sleeptime : .01) * 1000, 1);
    $mainpanel->EVT_TIMER($timer, \&on_timer);
    $mainpanel->Update();
}


1;
