package CQ::Recorder;

use strict;
use threads;
use threads::shared;

use Audio::PortAudio;


our $VERSION = "0.4";
our @recorddata;

my $api = Audio::PortAudio::default_host_api();
my $device = $api->default_input_device;
my $wdevice = $api->default_output_device;

my $sample_rate = 22050;
my $frames_per_buffer = 100;
my $flags = 0;
my $number_of_frames = 1600;
my $stream_flags = '';

my $buffer = "";
my $maxbuffers = 1000;


#
# shared resources
#
our @buffers :shared;
our @recorddata :shared;
our $recording :shared;
our $enablerecording :shared;

$enablerecording = 1;

our $savedir = "/home/hardaker/tmp/h/cq"; # XXX
our $outfile;
our $newchannel :shared;
our $currentrecording :shared;

sub open_file {
    my ($channel) = @_;
    close_file() if ($outfile);
    $outfile = new IO::File;
    $outfile->open(">$savedir/" . time() . "-" . $channel);
    $currentrecording = $newchannel;
    $newchannel = undef;
}

sub close_file {
    $outfile->close();
    $outfile = undef;
    $currentrecording = undef;
}

sub record_it {
    print "starting up recording: $recording\n";

my $stream = $device->open_read_stream( {
					 channel_count => 2,
					 sample_format => 'float32'
					},
# 				      {
# 					 channel_count => 2,
# 					 sample_format => 'float32'
# 					},
					$sample_rate,
					$frames_per_buffer,
					$stream_flags,
				      );
    die "ack no stream" if (!$stream);

    while ($recording && $enablerecording) {
	print "reading: $recording -- $enablerecording\n";
	my $ok = $stream->read($buffer,$number_of_frames);

	print "after reading:\n";

	if (!$ok || length($buffer) == 0) {
	    print "here: failed!\n";
	    die "recording failed\n";
	}

	# push onto the interanl buffer stack
	lock(@buffers);
	push @buffers, $buffer;
	if ($#buffers > $maxbuffers) {
	    shift @buffers;
	}

	# record to file
	print "  newchannel: $newchannel\n";
	open_file($newchannel) if ($newchannel);
	print $outfile $buffer if ($outfile);

	print "  recorded: $#buffers frames\n";
    }
    $recording = 0;
}

sub play_everything {
    my $enablestatus = $enablerecording;
    $enablerecording = 0;
    sleep(1);
    my $wstream = $wdevice->open_write_stream( {
						channel_count => 2,
						sample_format => 'float32'
					       },
					       $sample_rate,
					       $frames_per_buffer,
					       $stream_flags
					     );

    die "ack no writable stream" if (!$wstream);

    print "here: $wstream\n";

    lock(@buffers);
    my $count;
    foreach my $out (@buffers) {
	$count++;
	my $bogus = length($out);  # gets around an odd threads::shared issue
#	print "here ($count / $#buffers): " . length($out) . " $$wstream\n";
	$wstream->write($out);
    }
    $enablerecording = $enablestatus;
    if ($enablerecording && !$recording) {
	# we fell out of recording so we need to restart it.
	$recording = 1;
	threads->create(\&record_it);
    }
}

sub record_channel {
    my ($incomingnewchannel) = @_;
    if ($incomingnewchannel && $enablerecording) {
	$newchannel = $incomingnewchannel
	  if ($currentrecording ne $incomingnewchannel);
	return if ($recording);
	print "-- starting recording of $newchannel\n";
	$recording = 1;
	threads->create(\&record_it);
    } else {
	print "-- stopping recording\n";
	$recording = 0;
    }
}

sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my $self = {};
    %$self = @_;
    bless($self, $class);

    main::register_hook('set_current_channel', \&record_channel);
    return $self;
}

1;
