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
my @buffers :shared;
my $recording :shared;

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

    while ($recording) {
	print "reading: $recording\n";
	my $ok = $stream->read($buffer,$number_of_frames);
	print "after:\n";
	if (!$ok || length($buffer) == 0) {
	    print "here: failed!\n";
	    die "recording failed\n";
	}
	lock(@buffers);
	push @buffers, $buffer;
	if ($#buffers > $maxbuffers) {
	    shift @buffers;
	}
	print "recorded: $#buffers frames\n";
    }
}

sub play_everything {
    my $wstream = $wdevice->open_write_stream( {
						channel_count => 2,
						sample_format => 'float32'
					       },
					       $sample_rate,
					       $frames_per_buffer,
					       $stream_flags
					     );

    die "ack no writable stream" if (!$wstream);

    my $wstream;
    lock(@buffers);
    foreach my $out (@buffers) {
	$wstream->write($out);
    }
}

sub record_channel {
    my ($newchannel) = @_;
    if ($newchannel) {
	print "-- starting recording\n";
	$recording = 1;
	threads->create(\&record_it);
    } else {
	print "-- stopping recording\n";
	$recording = 0;
    }
}

sub new {
    main::register_hook('set_current_channel', \&record_channel);
}

1;
