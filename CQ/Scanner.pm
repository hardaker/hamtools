package CQ::Scanner;

our $VERSION = "0.4";

use Wx qw(:everything :font :textctrl);
use Wx::Event qw(EVT_MENU);
use Data::Dumper;

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
my $scanenabled = 1;

sub set_button_text {
    my ($channel, $format) = @_;
    $format = "%s" if (!$format);
    my $val = sprintf($format, $main::config{$channel}{'label'} || $channel);
    $main::config{$channel}{'button'}->SetLabel($val);
    $main::config{$channel}{'lastformat'} = $format;
}

sub generate_history_plot {
    Die("You need to install the GD module before you can create graphs")
      if (! eval { require GD; });
    use GD;

    my $count = $#main::toscan + 1;

    my $textheight = 40;
    my $height = 20 * $count + $textheight;
    my $width = 640;
    my $im = new GD::Image(640,$height);
    my $black = $im->colorAllocate(0,0,0);
    my $fill = $im->colorAllocate(0,0,255);
    my $white = $im->colorAllocate(255,255,255);
    my $grey = $im->colorAllocate(60,60,60);
    $im->fill(1,1,$white);
    my %colors =
      ('locked' => $im->colorAllocate(255,0,0),
       'found' => $im->colorAllocate(0,255,0),
      );

    my $now = time();
    my $textwidth = 100;
    my $startat = $now-($width-$textwidth);

    my @sorted =
      sort { $main::config{$b}{'priority'} <=> $main::config{$a}{'priority'} }
	@main::toscan;

    $im->string(gdSmallFont, $textwidth/2, $height-$textheight/2,
		"Minutes Ago:", $black);
    for (my $i = 0; $i < $now-$startat; $i += 60) {
	$im->string(gdSmallFont, $width - $i, $height-$textheight/2,
		    $i/60, $black);
	$im->line($width-$i, 0, $width-$i, $height-$textheight, $grey);
    }

    for (my $i = 0; $i < $count; $i++) {
	my $channel = $sorted[$i];
	my $starty = $i * 20 + 5;
	my $endy = ($i+1)*20 - 5;

	$im->string(gdSmallFont, 2, $starty,
		    sprintf("%5d %s", $main::config{$channel}{'priority'},
			    $channel),
		    $black);
	
	foreach my $slot (@{$main::config{$channel}{'history'}}) {
	    if ($slot->[1] >= $startat) {
		$im->filledRectangle($slot->[1]       - $startat + $textwidth,
				     $starty,
				     ($slot->[2] || $now) -$startat +$textwidth,
				     $endy,
				     ($colors{$slot->[0]} || $fill));
	    }
	}

    }

	#return $im;
    open(G,">/tmp/cqb.png");
    binmode G;
    print G $im->png;
    close(G);
}

sub OnScanPlot {
    generate_history_plot();
    use CQ::ShowImage;
    my ($channel) = @_;
    my $frame = CQ::ShowImage->new("/tmp/cqb.png", \&generate_history_plot,
				   "Scanner Timing",
				   [-1,-1], [-1,-1]);
    unless ($frame) {
	print "unable to create scanning frame -- exiting."; 
	exit(1);
    }
    $frame->Show( 1 );
    1;
}

sub OnTuner {
    use CQ::Tuner;
    my $frame = CQ::Tuner->new("Tuner",
			       [-1,-1], [-1,-1]);
    unless ($frame) {
	print "unable to create tuner frame -- exiting."; 
	exit(1);
    }
    $frame->Show( 1 );
    1;
}

sub OnInfo {
    use CQ::ChannelInfo;
    my ($channel) = @_;
    my $frame = CQ::ChannelInfo->new($channel, "Channel Info", [-1,-1], [-1,-1]);
    unless ($frame) {
	print "unable to create info frame -- exiting."; 
	exit(1);
    }
    $frame->Show( 1 );
    1;
}

sub popup_channel_menu {
    my ($channelb, $event) = @_;
    my $menu = new Wx::Menu;
    my $frame = new Wx::Frame;
    my $channel = $channelb->{'channel'};
    my $item;
    my $menuid = 2100;

    $item = $menu->AppendCheckItem($menuid, "Enabled");
    if ($main::config{$channel}{'enabled'} ne 'false') {
	$item->Check(1);
    }
    EVT_MENU($menu, $menuid, sub { OnEnable($channel) });

    $item = $menu->Append(++$menuid, "Skip This Conversation");
    EVT_MENU($menu, $menuid, sub { 
		 $main::config{$channel}{'skipconversation'} =
		   $main::opts{'skip-count'};
		 if ($channel eq $main::currentchannel) {
		     main::close_channel();
		 }
	     });

    $item = $menu->Append(++$menuid, "Disable all channels above this one");
    EVT_MENU($menu, $menuid, sub { OnDisableAbove($channel) });

    $item = $menu->Append(++$menuid,
			  "Enable this and all channels above this one");
    EVT_MENU($menu, $menuid, sub { OnEnableAbove($channel) });

    $menu->AppendSeparator();

    $item = $menu->Append(++$menuid, "Channel Details");
    EVT_MENU($menu, $menuid, sub { OnInfo($channel) });

    $item = $menu->Append(++$menuid, "Rename");
    EVT_MENU($menu, $menuid, sub { 
		 my ($self) = @_;
		 my $box = Wx::TextEntryDialog->new($mainpanel, "Rename To:",
						    "Rename the $channel button");
		 $box->SetValue($channel);
		 if ($box->ShowModal() == wxID_OK) {
		     $main::config{$channel}{'label'} = $box->GetValue();
		     set_button_text($channel,
				     $main::config{$channel}{'lastformat'});
		 }
	     });

    $item = $menu->Append(++$menuid, "Change frequency to radio setting");
    EVT_MENU($menu, $menuid, sub { $main::config{$channel}{'frequency'} = 
				     main::get_frequency() });

    $menu->AppendSeparator();

    my($lockmenu) = Wx::Menu->new(undef, wxMENU_TEAROFF);
    foreach my $locktime (qw(.5 1 2 3 4 5 10 20 30 60)) {
	$lockmenu->Append(++$menuid, "$locktime", "");
	EVT_MENU($lockmenu, $menuid, sub {
		     lock_channel($channel, 60*$locktime)
		 });
    }
    $menu->AppendSubMenu($lockmenu, "&Lock for N minutes ...");

#     $menu->Append(2101, "Test Item 2");
#     EVT_MENU($menu, 2101, sub { got_something("2", $channelb->{'channel'})});
#     $menu->AppendCheckItem(2102, "Check1 on");
#     EVT_MENU($menu, 2102, sub { got_something("3", $channelb->{'channel'})});
#     my $item = $menu->AppendCheckItem(2102, "Check1 off");
#     EVT_MENU($menu, 2101, sub { got_something("4", $channelb->{'channel'})});
#     $item->Check(1);
    $subpanel->PopupMenu($menu,$channelb->GetPosition());
}

sub load_buttons {
   my $channelid = 2000;

   foreach my $channel (sort { $main::config{$a}{'priority'} <=> 
				 $main::config{$b}{'priority'} }
			@main::toscan) {

       my $bar = new Wx::BoxSizer(wxHORIZONTAL);

       $main::config{$channel}{'button'} =
	 Wx::Button->new($subpanel, $channelid,
			 $main::config{$channel}{'label'} || $channel);
       my $font = Wx::Font->new( 8, wxROMAN, wxNORMAL, wxNORMAL);
       $main::config{$channel}{'button'}->SetFont($font);
       $bar->Add($main::config{$channel}{'button'},0,wxEXPAND | wxALL,0);
       $main::config{$channel}{'button'}{'channel'} = $channel;
       EVT_BUTTON($main::config{$channel}{'button'}, $channelid,
		  \&channel_button);
#       $main::config{$channel}{'button'}->SetWindowStyle(wxBU_EXACTFIT);
       $channelid++;

       $main::config{$channel}{'popbutton'} =
	 Wx::Button->new($subpanel, $channelid, "^");
       my $font = Wx::Font->new( 8, wxROMAN, wxNORMAL, wxNORMAL);
       $main::config{$channel}{'popbutton'}->SetFont($font);
       $bar->Add($main::config{$channel}{'popbutton'},0,0,0);
       $main::config{$channel}{'popbutton'}{'channel'} = $channel;
       EVT_BUTTON($main::config{$channel}{'popbutton'}, $channelid,
		  \&popup_channel_menu);
       $channelid++;
       $main::config{$channel}{'popbutton'}->SetWindowStyle(wxBU_EXACTFIT);

       $grid->Add($bar);
       $bar->SetSizeHints($subpanel);
   }
   $grid->SetSizeHints($mainpanel);
}

sub lock_channel {
    my ($channel, $timer) = @_;
    # lock to a channel
    main::set_channel($channel,0,'locked');
    set_channel_button($channel, wxNORMAL, wxBOLD);
    set_button_text($channel, "(L) %s");
    $main::locked = 1;
    if ($timer) {
	$main::config{$channel}{'locktimer'} = time() + $timer;
    }
    main::Verbose("locking to $channel\n");
}


sub channel_button {
    my ($channelb, $event) = @_;
    set_channel_button($main::currentchannel) if ($main::currentchannel);
    set_button_text($main::currentchannel) if ($main::currentchannel);
    if ($main::locked && $main::currentchannel eq $channelb->{'channel'}) {
	# unlock
	$main::locked = 0;
    } else {
	lock_channel($channelb->{'channel'});
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
	set_button_text($channel);
    } else {
	$main::config{$channel}{'enabled'} = 'false';
	set_channel_button($channel, wxSLANT);
	set_button_text($channel, "(D) %s");
	if ($channel eq $main::currentchannel) {
	    main::close_channel();
	}
    }
}

sub OnDisableAbove {
    my ($channel) = $_[0];
    my $priority = $main::config{$channel}{'priority'};
    foreach my $todo (@main::toscan) {
	if ($main::config{$todo}{'priority'} > $priority) {
	    $main::config{$todo}{'enabled'} = 'false';
	    set_channel_button($todo, wxSLANT);
	    set_button_text($todo, "(D) %s");
	}
    }
}

sub OnEnableAbove {
    my ($channel) = $_[0];
    my $priority = $main::config{$channel}{'priority'};
    foreach my $todo (@main::toscan) {
	if ($main::config{$todo}{'priority'} >= $priority) {
	    $main::config{$todo}{'enabled'} = 'true';
	    set_channel_button($todo);
	    set_button_text($todo);
	}
    }
}

sub OnGrid {
    my $count = shift;
    $grid->Clear(1);
    $grid = new Wx::FlexGridSizer(1,int(($#main::toscan)/$count + 1));
    load_buttons();
    $subpanel->SetSizerAndFit($grid);
}

sub OnGroup {
    my ($group, $append) = @_;
    $group = $main::currentgroupconfig . "," . $group if ($append);
    main::load_group($group);
    $grid->Clear(1);
    load_buttons();
    $subpanel->SetSizerAndFit($grid);
    main::set_current_channel();
}

sub set_channel_button {
    my ($channel, $ifont, $bfont) = @_;
    $ifont = wxNORMAL if (!$ifont);
    $bfont = wxNORMAL if (!$bfont);
    my $font = Wx::Font->new( 8, wxROMAN, $ifont, $bfont);
    $main::config{$channel}{'button'}->SetFont($font);
}

sub OnMaxcount {
    my ($maxcount) = @_;
    $main::maxscancount = $maxcount;
}

sub OnChangeChannel {
    my $channel = shift;
    if ($channel) {
	$mainpanel->SetTitle("CQ: " . $channel);
    } else {
	$mainpanel->SetTitle("CQ: Scanning");
    }
}

sub new {
   my $class = shift;
   my $this = $class->SUPER::new( undef, -1, $_[0], $_[1], $_[2] );
   $mainpanel = $this;

   main::register_hook('set_current_channel', \&OnChangeChannel);

   #
   #   replace the filename with something appropriate.
   #

   $subpanel = Wx::Panel->new($this, -1);
   $grid = new Wx::FlexGridSizer(1,int(($#main::toscan)/2 + 1));
#   $grid = new Wx::BoxSizer(wxHORIZONTAL);

   #
   # MENU setup
   #
   my($MENU_QUIT, $MENU_GRID, $MENU_USAGE, $MENU_TUNER) = (3000..3999);
   my($mfile) = Wx::Menu->new(undef, wxMENU_TEAROFF);
   $mfile->Append($MENU_QUIT, "&Quit\tCtrl-Q", "Quit this program");
#   $mfile->AppendSeparator();

   my($mbar) = Wx::MenuBar->new();
   $mbar->Append($mfile, "&Commands");
   $this->SetMenuBar($mbar);
   EVT_MENU($this, $MENU_QUIT, \&OnQuit);
   EVT_MENU($this, $MENU_USAGE, \&OnScanPlot);
   EVT_MENU($this, $MENU_TUNER, \&OnTuner);

   my $scannermenu = Wx::Menu->new(undef, wxMENU_TEAROFF);
   $mbar->Append($scannermenu, "&Scanner");
   $scannermenu->Append($MENU_USAGE, "&Graph Usage\tCtrl-G", "Graph the usage of the scanner");
   $scannermenu->AppendSeparator;

   $scannermenu->Append($MENU_TUNER, "&Show Tuner Window\tCtrl-T",
			"Show the tuner window");
   $scannermenu->AppendSeparator;

   my $configmenu = Wx::Menu->new(undef, wxMENU_TEAROFF);
   $mbar->Append($configmenu, "&Config");

   my $groupid = 3500;
   my($mgroup) = Wx::Menu->new(undef, wxMENU_TEAROFF);
   my($maddgroup) = Wx::Menu->new(undef, wxMENU_TEAROFF);
   foreach my $group (sort keys(%main::groups)) {
       $mgroup->Append($groupid, "$group", "");
       EVT_MENU($this, $groupid, sub {OnGroup($group);});
       $groupid++;

       $maddgroup->Append($groupid, "$group", "");
       EVT_MENU($this, $groupid, sub {OnGroup($group, 1);});
       $groupid++;
   }
   $scannermenu->AppendSubMenu($mgroup, "&Switch to Group");
   $scannermenu->AppendSubMenu($maddgroup, "&Add in Group");
   $scannermenu->AppendSeparator;

   my $gridid = 4200;
   my ($mgrid) = Wx::Menu->new(undef, wxMENU_TEAROFF);
   foreach my $rowcount (1..15) {
       $mgrid->Append($gridid, "$rowcount", "");
       EVT_MENU($this, $gridid, sub {OnGrid("$rowcount");});
       $gridid++;
   }
   $configmenu->AppendSubMenu($mgrid, "&No. Button Rows");

   my $maxcountid = 4300;
   my ($mmaxcount) = Wx::Menu->new(undef, wxMENU_TEAROFF);
   my ($sleeptime) = Wx::Menu->new(undef, wxMENU_TEAROFF);
   foreach my $maxcount (1..15, 10000) {

       my $item = $mmaxcount->AppendCheckItem($maxcountid, $maxcount);
       if ($main::maxscancount eq $maxcount) {
	   $item->Check(1);
       }
       EVT_MENU($this, $maxcountid, sub { OnMaxcount($maxcount) });

       $maxcountid++;

       $item = $sleeptime->AppendCheckItem($maxcountid, $maxcount);
       if ($main::opts{'sleep'} eq $maxcount) {
	   $item->Check(1);
       }
       EVT_MENU($this, $maxcountid, sub { $main::opts{'sleep'} = $maxcount } );

       $maxcountid++;
   }
   $scannermenu->AppendSubMenu($mmaxcount, "&Scan Count Maximum");
   $scannermenu->AppendSubMenu($sleeptime, "&Scan Sleep Value");

   load_buttons();

   $subpanel->SetSizerAndFit($grid);
#   Centre();

   my $timer = Wx::Timer->new($this, 1000);
   $timer->Start(1000, 1);
   $this->EVT_TIMER($timer, \&on_timer);
#   $this->Connect(1000, -1, -1, \&on_timer);

   $this;  # return the frame object to the calling application.
}

sub OnEnableScanner {
    $scanenabled = !$scanenabled;
    start_timer(.1) if ($scanenabled);
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
    start_timer($sleeptime);
    $mainpanel->Update();
}

sub start_timer {
    my ($sleeptime) = @_;
    return if (!$scanenabled);

    my $timer = Wx::Timer->new($mainpanel, 1000);
    $timer->Start(($sleeptime > .01 ? $sleeptime : .01) * 1000, 1);
    $mainpanel->EVT_TIMER($timer, \&on_timer);
    $mainpanel->Update();
}

1;
