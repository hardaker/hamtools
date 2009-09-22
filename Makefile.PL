# Copyright (C) 2008 Wes Hardaker
# License: GNU GPLv2.  See the COPYING file for details.
#!/usr/bin/perl

use ExtUtils::MakeMaker;

%opts = (
	 'NAME'		=> 'cq',
	 'PREREQ_PM'    => { Hamlib => 0,
			     Wx => 0},
	 'EXE_FILES'    => [qw(cq)],
         'VERSION_FROM' => 'cq',         # finds $VERSION
	);

WriteMakefile(%opts);
