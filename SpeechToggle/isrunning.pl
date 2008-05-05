#!/usr/bin/perl

# Copyright 2007 Chimoosoft, www.chimoosoft.com
# is it running?

my $line = `ps -cx | grep -i speakable`;
if ($line =~ /([0-9]+).*/) {
	exit 1;
} else {
	exit 0;
}

