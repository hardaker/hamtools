package CQ::Recorder;

use Audio::PortAudio;

our $VERSION = "0.4";
our @recorddata;

my $api = Audio::PortAudio::default_host_api();
my $device = $api->default_input_device;
my $wdevice = $api->default_output_device;

$sample_rate = 22050;
$frames_per_buffer = 100;
$flags = 0;
$number_of_frames = 1600;

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
					$stream_flags
				      );
die "ack no stream" if (!$stream);

my $wstream = $wdevice->open_write_stream( {
					 channel_count => 2,
					 sample_format => 'float32'
					},
# 				      {
# 					 channel_count => 2,
# 					 sample_format => 'float32'
# 					},
					$sample_rate,
					$frames_per_buffer,
					$stream_flags
				      );


my $buffer = "";
my @buffers;
my $maxbuffers = 100;

sub record_it {
    while ($recording) {
	my $ok = $stream->read($buffer,$number_of_frames);
	if (!$ok || length($buffer) == 0) {
	    die "recording failed\n";
	}
	push @buffers, $buffer;
	if ($#buffers > $maxbuffers) {
	    shift @buffers;
	}
    }
}

sub play_everything {
    foreach my $out (@buffers) {
	$wstream->write($out);
    }
}
