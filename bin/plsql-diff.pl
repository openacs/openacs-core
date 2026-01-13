#!/usr/local/bin/perl

# by Jin Choi <jsc@arsdigita.com>, 2000-03-21

# Utility script for comparing definitions of functions and procedures
# in different data dictionaries.
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
my ($object1_info, $object2_info);
if ($operation eq "-connect") {
  $object1_info = get_object_info($db1);
  $object2_info = get_object_info($db2);
} elsif ($operation eq "-read") {
  $object1_info = get_object_info_from_file($file1);
  $object2_info = get_object_info_from_file($file2);
} elsif ($operation eq "-write") {
  write_object_info_to_file(get_object_info($db1), $outfile);
  exit 0;
}


# Figure out which objects were added and deleted. Report,
# and remove from our data structures so we don't get a lot of
# reports about modified objects.

my %object_hash1;
my %object_hash2;

foreach my $type (keys %$object1_info) {
  foreach my $object (keys %{$object1_info->{$type}}) {
    $object_hash1{"$type:$object"} = $object1_info->{$type}{$object};
  }
}

foreach my $type (keys %$object2_info) {
  foreach my $object (keys %{$object2_info->{$type}}) {
    $object_hash2{"$type:$object"} = $object2_info->{$type}{$object};
  }
}

my %union = union_hashes(\%object_hash1, \%object_hash2);

my @new_objects;
my @deleted_objects;

foreach my $key (sort keys %union) {
  if (!defined($object_hash1{$key})) {
    push @new_objects, $key;
    delete $object_hash2{$key};
  } elsif (!defined($object_hash2{$key})) {
    push @deleted_objects, $key;
    delete $object_hash1{$key};
  }
}

print "New objects:\n", join("\n", @new_objects), "\n\n";
print "Deleted objects:\n", join("\n", @deleted_objects), "\n\n";


# Report objects which are different. object_hashes 1 and 2 should
# both contain the same objects now.
print "Modified objects:\n";
foreach my $key (sort keys %object_hash1) {
  if ($object_hash1{$key} ne $object_hash2{$key}) {
    print "$object_hash1{$key}\n--\n$object_hash2{$key}\n\n";
  }
}

exit;




sub get_object_info {
  my $db = shift;
  my $object_info = {};
  
  my $sth = $db->prepare("select object_type, s.name, s.text
from user_source s, user_objects o
where (object_type = 'FUNCTION' or object_type = 'PROCEDURE')
  and (s.name = o.object_name)
order by o.object_name, s.line");
  
  $sth->execute;
  
  while (my $rowref = $sth->fetchrow_arrayref) {
    my ($type, $name, $text) = @$rowref;
    $object_info->{$type}{$name} .= $text;
  }

  $sth->finish;
  $db->disconnect;
  return $object_info;
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

sub write_object_info_to_file {
  my ($object_info, $outfile) = @_;
  open(F, ">$outfile") || die $!;

  print "Outputting data to file $outfile.\n";

  print F Dumper($object_info);
  close F;
}


sub get_object_info_from_file {
  my $filename = shift;
  
  return do $filename;
}
