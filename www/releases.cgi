#!/usr/bin/perl

use strict;

print "Content-Type: text/html\n\n";

opendir(D,"/home/hardaker/hamtools.org/releases");
my $f;
my %stuff;
while ($f = readdir(D)) {
    next if ($f =~ /^\./);

    # hamtools-0.4.tar.gz
    # cq-0.4.linux
    my ($name, $ver, $type) = ($f =~ /(.+)-([\.\d]+)\.(.*)/);
    $stuff{$ver}{$name}{$type} = $f if ($type);
}

print "<html>
<head>
  <title>Hamtools Releases</title>
  <link rel=\"StyleSheet\" type=\"text/css\" href=\"/style.css\" />
</head>
<body>
<h1>Available Downloads</h1>
";

print "<table><th>When</th><th>What</th><th>Who</th></tr>\n";
foreach my $ver (reverse sort keys(%stuff)) {
    if (exists($stuff{$ver}{'hamtools'}{'tar.gz'})) {
	print "<tr><td>$ver</td><td><a href=\"$stuff{$ver}{'hamtools'}{'tar.gz'}\">$stuff{$ver}{'hamtools'}{'tar.gz'}</a></td><td>source</td>\n";
	delete $stuff{$ver}{'hamtools'}{'tar.gz'};
    }

    foreach my $name (sort keys(%{$stuff{$ver}})) {
	foreach my $type (sort keys(%{$stuff{$ver}{$name}})) {
	    print "<tr><td></td><td><a href=\"$stuff{$ver}{$name}{$type}\">$name</a></td><td>$type</td></tr>\n";
	}
    }
}
