package CQ::Tuner;

our $VERSION = "0.4";

use vars qw(@ISA);
use strict;
#
#   All we load here are constants used
#   to keep the image stretched to the dimensions of the window.
#
use Wx qw(wxWidth wxHeight wxLeft wxTop wxDefaultPosition wxDefaultSize wxID_CANCEL wxCentreX wxCentreY wxROMAN wxNORMAL wxBOLD);
use Wx::Event qw(:everything);
#
#   Wx::Image loads the Image control and all of the Image handlers.
#
use IO::File;
use Wx::Event ;
our @ISA=qw(Wx::Frame);

my ($button, $freq, $signal);

sub update_freq {
    my ($self) = @_;
    # XXX: don't create new bitmap below but update old?
    my $freq = $main::rig->get_freq();
    $button->SetLabel(sprintf("%0.6f",$freq/1000000));
}

sub change_tuner_label {
    my ($self, $channel, $format) = @_;

    my $newfreq   = "000.000.00";
    my $newsignal = "-54";
    my $newchannel = "Scanning...";

    if ($channel) {
	$newchannel = $main::config{$channel}{'label'} || $channel;
	$newsignal = $main::config{$channel}{'lastgoodsignal'};
	$newfreq = $main::config{$channel}{'frequency'};
    }

    $format = "%s" if (!$format);
    my $val = sprintf($format, $newchannel);
    $button->SetLabel($val);

    $freq->SetLabel($newfreq);
    $signal->SetLabel($newsignal);
}

sub lock_tuner_channel {
    if ($main::locked) {
	my $font = Wx::Font->new( 8, wxROMAN, wxNORMAL, wxNORMAL);
	$button->SetFont($font);
	$main::locked = 0;
	main::Verbose("tuner unlocking\n");
    } elsif ($main::currentchannel) {
	my $font = Wx::Font->new( 8, wxROMAN, wxNORMAL, wxBOLD);
	$button->SetFont($font);
	main::set_channel($main::currentchannel,0,'locked');
	$main::locked = 1;
	main::Verbose("tuner locking to $main::currentchannel\n");
    }
}

sub new {
   my $class = shift;
   my $this = $class->SUPER::new( undef, -1, $_[0], $_[1], $_[2] );

   my $subpanel = Wx::Panel->new($this, -1);
   my $grid = new Wx::FlexGridSizer(1,1);

   $button =
     Wx::Button->new($subpanel, 3900,
		     ($main::currentchannel) ?
		     ($main::config{$main::currentchannel}{'label'} || 
		      $main::currentchannel) : "");
   EVT_BUTTON($button, 3900, \&lock_tuner_channel);

   $grid->Add($button);


   my $textbox = new Wx::FlexGridSizer(0,2);

   my $label = Wx::StaticText->new($subpanel, -1, "Frequency:  ");
   $textbox->Add($label);

   $freq = Wx::StaticText->new($subpanel, -1, "000.000.00");
   $textbox->Add($freq);

   $label = Wx::StaticText->new($subpanel, -1, "Signal:  ");
   $textbox->Add($label);

   $signal = Wx::StaticText->new($subpanel, -1, "-54");
   $textbox->Add($signal);

   $grid->Add($textbox);

   if (0) {
       my $timer = Wx::Timer->new($this, 1501);
       $timer->Start(100);
       $this->EVT_TIMER($timer, \&update_freq);
       $this->{'timer'} = $timer;
   }



   main::register_hook('set_current_channel', \&change_tuner_label, $this);

   $subpanel->SetSizerAndFit($grid);
   $grid->SetSizeHints($this);

   EVT_CLOSE($this, \&closit);

   $this;  # return the frame object to the calling application.
}

sub closit {
    $_[0]->Destroy();
    $_[0]->{'timer'}->Stop();
    return 1;
}

1;
