#!/usr/local/bin/perl
#
# Encode a file from stdin as base64
#
# hqm@ai.mit.edu
#
# This script does the following:
#

use MIME::Base64 ();

binmode(STDIN);
binmode(STDOUT);
# Make sure to read in multiples of 6 chars, to
# keep the encoded blocks contiguous.
while (read(STDIN, $_, 60*1024)) {
  print MIME::Base64::encode($_);
}


