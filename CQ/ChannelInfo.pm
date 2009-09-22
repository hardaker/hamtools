package CQ::ChannelInfo;

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

sub add_info {
    my ($label, $value) = @_;
    $grid->Add(Wx::StaticText->new($subpanel, -1, $label));
    $grid->Add(Wx::StaticText->new($subpanel, -1, $value));
}

sub new {
    my $class = shift;
    my $channel = shift;
    my $this = $class->SUPER::new( undef, -1, $_[0], $_[1], $_[2] );
    $mainpanel = $this;

    $subpanel = Wx::Panel->new($this, -1);
    $grid = new Wx::FlexGridSizer(0,2);
    #   $grid = new Wx::BoxSizer(wxHORIZONTAL);

    add_info("Channel:", $channel);
    add_info("Frequency:", $main::config{$channel}{'frequency'});

    foreach my $key (sort keys(%{$main::config{$channel}})) {
	next if (ref($main::config{$channel}{$key}) ne '');
	add_info($key, $main::config{$channel}{$key});
    }

    $subpanel->SetSizerAndFit($grid);

    $this;			# return the frame object to the calling application.
}

1;
