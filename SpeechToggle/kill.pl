#!/usr/bin/perl

# Copyright 2007 Chimoosoft, www.chimoosoft.com
# ps and grep for pid, then kill it.

my $line = `ps -cx | grep -i speakable`;
if ($line =~ /([0-9]+).*/) {
	my $pid = $1;
	`kill $pid`;
}