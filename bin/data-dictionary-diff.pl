#!/usr/local/bin/perl

# by Jin Choi <jsc@arsdigita.com>, 2000-03-20

# Utility script to check differences between two Oracle data dictionaries.
# Can be run in one of three modes.
# "Connect" is given two connect strings and does the diff then and there.
# "Write" is given a connect string and a file, and writes the results
# out to the file. You can do this twice on different data dictionaries,
# then use "Read" mode to compare the two.

# $Id$

use strict;
use DBI;


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

# Get information from the database or files; handle write case.
my ($table1_info, $table2_info);
if ($operation eq "-connect") {
  $table1_info = get_table_info($connstr1);
  $table2_info = get_table_info($connstr2);
} elsif ($operation eq "-read") {
  $table1_info = get_table_info_from_file($file1);
  $table2_info = get_table_info_from_file($file2);
} elsif ($operation eq "-write") {
  write_table_info_to_file(get_table_info($connstr1), $outfile);
  exit 0;
}

# Figure out which tables were added and deleted. Report,
# and remove from our data structures so we don't get a lot of
# reports about added and deleted columns.

my %tablename_hash1;
my %tablename_hash2;

foreach my $table_name (keys %$table1_info) {
  $tablename_hash1{$table_name}++;
}
foreach my $table_name (keys %$table2_info) {
  $tablename_hash2{$table_name}++;
}

my %union = union_hashes(\%tablename_hash1, \%tablename_hash2);

my @new_tables;
my @deleted_tables;

foreach my $table_name (sort keys %union) {
  if (!defined($tablename_hash1{$table_name})) {
    push @new_tables, $table_name;
    delete $table2_info->{$table_name};
  } elsif (!defined($tablename_hash2{$table_name})) {
    push @deleted_tables, $table_name;
    delete $table1_info->{$table_name};
  }
}

print "New tables:\n", join("\n", @new_tables), "\n\n";
print "Deleted tables:\n", join("\n", @deleted_tables), "\n\n";


# Figure out which columns in the remaining tables have been added or deleted.
my %column_hash1;
my %column_hash2;

foreach my $table (keys %$table1_info) {
  foreach my $column (keys %{$table1_info->{$table}}) {
    $column_hash1{"$table:$column"} = $table1_info->{$table}{$column};
  }
}

foreach my $table (keys %$table2_info) {
  foreach my $column (keys %{$table2_info->{$table}}) {
    $column_hash2{"$table:$column"} = $table2_info->{$table}{$column};
  }
}

%union = union_hashes(\%column_hash1, \%column_hash2);

my @new_columns;
my @deleted_columns;

foreach my $key (sort keys %union) {
  if (!defined($column_hash1{$key})) {
    push @new_columns, $key;
    delete $column_hash2{$key};
  } elsif (!defined($column_hash2{$key})) {
    push @deleted_columns, $key;
    delete $column_hash1{$key};
  }
}

print "New columns:\n", join("\n", @new_columns), "\n\n";
print "Deleted columns:\n", join("\n", @deleted_columns), "\n\n";


# Report columns which are different. column_hashes 1 and 2 should
# both contain the same columns now.
print "Modified columns:\n";
foreach my $key (sort keys %column_hash1) {
  if ($column_hash1{$key} ne $column_hash2{$key}) {
    print "$key\n   $column_hash1{$key}\n   $column_hash2{$key}\n";
  }
}



exit;


# Get information on tables. Returns a multi-dimensional hashref where
# the keys are the table name and the column name, and the value is
# the type and constraint information.

sub get_table_info {
  my $connstr = shift;
  my $table_info = {};

  print "Fetching data from Oracle data dictionary for $connstr.\n";

  my $db = DBI->connect("dbi:Oracle:", $connstr) || die $!;
  $db->{AutoCommit} = 0;
  $db->{RaiseError} = 1;
  $db->{LongReadLen} = 2048;
  $db->{LongTruncOk} = 1;

  print "Connected to Oracle.\n";  

  my $sth = $db->prepare("select lower(table_name), lower(column_name), lower(data_type), data_length, data_precision, data_scale, nullable
from user_tab_columns");

  $sth->execute;

  while (my $rowref = $sth->fetchrow_arrayref) {
    my ($table_name, $column_name, $data_type, $data_length, $data_precision, $data_scale, $nullable) = @$rowref;
    
    $table_info->{$table_name}{$column_name} = format_type_info($data_type, $data_length, $data_precision, $data_scale, $nullable);
  }

  # Figure out the constraints.
  $sth = $db->prepare("select uc.constraint_type, uc.search_condition, uc.r_constraint_name, lower(ucc.table_name), lower(ucc.column_name)
from user_constraints uc, user_cons_columns ucc
where uc.constraint_name = ucc.constraint_name
order by constraint_type");

  my $sth2 = $db->prepare("select lower(table_name), lower(column_name)
from user_cons_columns
where constraint_name = ?");

  my %cached_reference_columns;

  $sth->execute;
  while (my $rowref = $sth->fetchrow_arrayref) {
    my ($constraint_type, $search_condition, $r_constraint_name, $table_name, $column_name) = @$rowref;
    if ($constraint_type eq "P") {
      $table_info->{$table_name}{$column_name} .= " primary key"; 
    } elsif ($constraint_type eq "U") {
      $table_info->{$table_name}{$column_name} .= " unique";
    } elsif ($constraint_type eq "C") {
      if ($search_condition !~ /IS NOT NULL/) {
	$table_info->{$table_name}{$column_name} .= " check ($search_condition)";
      }
    } elsif ($constraint_type eq "R") {
      my $ref_clause;
      if ($cached_reference_columns{$r_constraint_name}) {
	$ref_clause = $cached_reference_columns{$r_constraint_name};
      } else {
	$sth2->execute($r_constraint_name);
	my ($ref_table_name, $ref_column_name) = $sth2->fetchrow_array;
	$ref_clause = " references $ref_table_name($ref_column_name)";
	$cached_reference_columns{$r_constraint_name} = $ref_clause;
      }
      $table_info->{$table_name}{$column_name} .= $ref_clause;
    }
  }
  $sth->finish;
  $sth2->finish;
  $db->disconnect;

  return $table_info;
}

sub format_type_info {
  my ($type, $length, $precision, $scale, $nullable) = @_;
  my $formatted_info;
  
  $formatted_info = $type;
  if ($type eq "char" || $type eq "varchar2") {
    $formatted_info .= "($length)";
  } elsif ($type eq "number") {
    if ($scale > 0) {
      $formatted_info .= "($precision,$scale)";
    } elsif ($precision) {
      $formatted_info .= "($precision)";
    } else {
      $formatted_info = "integer";
    }
  }

  if ($nullable eq "N") {
    $formatted_info .= " not null";
  }
  return $formatted_info;
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

# Reports keys in first hash argument which are not in the second.
sub report_difference {
  my $h1_ref = shift;
  my $h2_ref = shift;

  foreach my $key (sort keys %$h1_ref) {
    if (!defined($$h2_ref{$key})) {
      print "* $key\n";
    }
  }
}

sub write_table_info_to_file {
  my ($table_info, $outfile) = @_;
  open(F, ">$outfile") || die $!;

  print "Outputting data to file $outfile.\n";

  foreach my $table (keys %$table_info) {
    foreach my $column (keys %{$table_info->{$table}}) {
      print F "$table:$column:", $table_info->{$table}{$column}, "\n";
    }
  }
  close F;
}

sub get_table_info_from_file {
  my $filename = shift;
  my $table_info = {};
  
  open(F, "<$filename") || die $!;
  while (<F>) {
    chop;
    my ($table, $column, $info) = split /:/;
    $table_info->{$table}{$column} = $info;
  }
  close F;
  return $table_info;
}
