#!/usr/local/bin/perl

# by Jin Choi <jsc@arsdigita.com>, 2000-03-26

# Utility script for comparing definitions triggers in different data
# dictionaries.
# Can be run in one of three modes.
# "Connect" is given two connect strings and does the diff then and there.
# "Write" is given a connect string and a file, and writes the results
# out to the file. You can do this twice on different data dictionaries,
# then use "Read" mode to compare the two.

# $Id$

use strict;
use DBI;
use Data::Dumper;

my $usage_string = <<EOF;
Usage:
$0 -connect connect-string-1 connect-string-2
  or
$0 -write connect-string output-file
  or
$0 -read input-file-1 input-file-2
EOF

# Get the arguments.
my ($operation, $connstr1, $connstr2, $outfile, $file1, $file2);
if (scalar(@ARGV) == 3) {
  $operation = shift @ARGV;
  if ($operation eq "-connect") {
    ($connstr1, $connstr2) = @ARGV;
  } elsif ($operation eq "-write") {
    ($connstr1, $outfile) = @ARGV;
  } elsif ($operation eq "-read") {
    ($file1, $file2) = @ARGV;
  } else {
    die $usage_string;
  }
} else {
  die $usage_string;
}

my ($db1, $db2);
if ($connstr1) {
  $db1 = get_dbhandle($connstr1);
}

if ($connstr2) {
  $db2 = get_dbhandle($connstr2);
}

# Get information from the database or files; handle write case.
my ($trigger1_info, $trigger2_info);
if ($operation eq "-connect") {
  $trigger1_info = get_trigger_info($db1);
  $trigger2_info = get_trigger_info($db2);
} elsif ($operation eq "-read") {
  $trigger1_info = get_trigger_info_from_file($file1);
  $trigger2_info = get_trigger_info_from_file($file2);
} elsif ($operation eq "-write") {
  write_trigger_info_to_file(get_trigger_info($db1), $outfile);
  exit 0;
}


# Figure out which triggers were added and deleted. Report,
# and remove from our data structures so we don't get a lot of
# reports about modified triggers.

my %union = union_hashes($trigger1_info, $trigger2_info);

my @new_triggers;
my @deleted_triggers;

foreach my $key (sort keys %union) {
  if (!defined($trigger1_info->{$key})) {
    push @new_triggers, $key;
    delete $trigger2_info->{$key};
  } elsif (!defined($trigger2_info->{$key})) {
    push @deleted_triggers, $key;
    delete $trigger1_info->{$key};
  }
}

print "New triggers:\n", join("\n", @new_triggers), "\n\n";
print "Deleted triggers:\n", join("\n", @deleted_triggers), "\n\n";


# Report triggers which are different. trigger_infoes 1 and 2 should
# both contain the same triggers now.
print "Modified triggers:\n";
foreach my $key (sort keys %$trigger1_info) {
  if ($trigger1_info->{$key} ne $trigger2_info->{$key}) {
    print "$trigger1_info->{$key}\n--\n$trigger2_info->{$key}\n\n";
  }
}

exit;




sub get_trigger_info {
  my $db = shift;
  my $trigger_info = {};
  
  my $sth = $db->prepare("select trigger_name, description, trigger_body
from user_triggers");
  
  $sth->execute;
  
  while (my $rowref = $sth->fetchrow_arrayref) {
    my ($name, $description, $body) = @$rowref;
    chop $body; # Get rid of extraneous NULL.
    $trigger_info->{$name} .= "$description $body";
  }

  $sth->finish;
  $db->disconnect;
  return $trigger_info;
}

sub get_dbhandle {
  my $connstr = shift;
  print "Opening database connection for $connstr.\n";
  my $db = DBI->connect("dbi:Oracle:", $connstr) || die $!;
  $db->{AutoCommit} = 0;
  $db->{RaiseError} = 1;
  $db->{LongReadLen} = 2048;
  $db->{LongTruncOk} = 1;
  return $db;
}

# Returns a union of the keys of the two argument hashes.
# The values are unimportant.
sub union_hashes {
  my %union;
  my $h1_ref = shift;
  my $h2_ref = shift;

  foreach my $key (keys(%$h1_ref), keys(%$h2_ref)) {
    $union{$key} = 1;
  }
  return %union;
}

sub write_trigger_info_to_file {
  my ($trigger_info, $outfile) = @_;
  open(F, ">$outfile") || die $!;

  print "Outputting data to file $outfile.\n";

  print F Dumper($trigger_info);
  close F;
}


sub get_trigger_info_from_file {
  my $filename = shift;
  
  return do $filename;
}
