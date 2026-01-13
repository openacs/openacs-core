#!/usr/bin/perl

# Written by Richard Hamilton 02/05/04
# Based on an original script written by Jun Yamog
#
# usage: ./dump_parser.pl origdump newdump /your/oacs/dir
#
# This script examines the OpenACS file system and extracts 
# all function and view names that have length greater
# than 32 chars and are therefore likely to have been
# truncated by PostgreSQL version 7.2.x and earlier.
#
# It then parses a PostgreSQL v 7.2.x dumpfile and
# substitutes the full function or view names for the
# truncated ones, placing the output into a new dump file.
# The new dump file can be used to restore on pg 7.3.x and 7.4.x
#
# requires: perl, grep and find
#
# These are the create statements on a dump file. I have 
# checked my own installations and only FUNCTION and VIEW
# definitions have been affected. It is possible that in
# some installations other object types are affected. 
# For this reason the script only goes through functions
# and views, but may be easily modified to include other
# types.
#
# CREATE CONSTRAINT
# CREATE FUNCTION
# CREATE INDEX
# CREATE RULE
# CREATE SEQUENCE
# CREATE TABLE
# CREATE TRIGGER
# CREATE TRUSTED
# CREATE UNIQUE
# CREATE VIEW
#
#
# look at this thread for further info
#
# http://openacs.org/forums/message-view?message_id=109337
#
#
# 2004-08-14 Gilbert Wong: 
#    - modified s/ / /   line to include ' (the apostrophe) 
#      which is used in triggers and the gi option to catch multiple
#      instances of the key and all cases..
#    - added command line argument checking
#    - added $types variable so that adding types can be done easily
#    - added the "copy" command to the list of commands to check


### do argument checking and sanity checks
if ($#ARGV!=2) {
    # print error message
    print "\nThis script examines the OpenACS file system and extracts
all function and view names that have length greater
than 32 chars and are therefore likely to have been
truncated by PostgreSQL version 7.2.x and earlier.

It then parses a PostgreSQL v 7.2.x dumpfile and
substitutes the full function or view names for the
truncated ones, placing the output into a new dump file.
The new dump file can be used to restore on pg 7.3.x and 7.4.x

requires: perl, grep and find

USAGE:
------
    rhdmppsr2.pl origdump newdump /your/oacs/dir
       origdump: original PostgreSQL dump file
       newdump:  cleaned up PostgreSQL dump file
       /your/oacs/dir: path to your OpenACS directory (e.g. /web/openacs-4)\n\n";
    exit;
}

### added by Gilbert Wong:
### edit these lines to add more types
$types = "(function|view|table|sequence|trigger|constraint)";

### get command line args
$input_dump = $ARGV[0];
$output_dump = $ARGV[1];
$oacs_home = $ARGV[2];

### added by Gilbert Wong:
### check existence of files and directories
$errstr = "";
$errcnt = 0;
if (!(-e $input_dump)) {
    $errstr .= "\nERROR: $input_dump does not exist";
    $errcnt++;
}
if (!(-d $oacs_home)) {
    $errstr .= "\nERROR: $oacs_home does not exist";
    $errcnt++;
}
if ($errcnt > 0) {
    print "$errstr\n\n";
    exit;
}

# Grab object names from file system, split on newlines, and put in list called @object_names
print("\nLooking up definitions in OpenACS *.sql files");
### edited by Gilbert Wong: $types added below.  $types is defined above
#@object_names = (split /\n/, `find $oacs_home -name "*.sql" | xargs egrep -riI '(create|create or replace|drop) $types [^ ]* '`);
@object_names = (split /\n/, `find $oacs_home -name "*.sql" | xargs egrep -riI '(create|create or replace|drop) $types \w*'`);
print(" : DONE\n");
foreach $name (@object_names) {
    # Grab the name from each line and process it if it is longer than 32 characters
    ### edited by Gilbert Wong: $types added below.  $types is defined above
    if (($name =~ /(create|create or replace|drop) $types (\w*)/i) && (length($3) > 31)) {
        # Each set of parentheses specifies a regexp memory. Our name is memory 3 ($3)
        $real_function_name = $3;
        print("Found declaration for: $real_function_name\n");
        # Store full names in a hash called $full_name with the truncated name as key
        $full_name{substr($real_function_name, 0, 31)}=$real_function_name;
        }
}

print("\nPreparing to processing dump file: $input_dump\n\n");
# Now go through the dump file
open(INPUT_DUMP, $input_dump);
open(OUTPUT_DUMP, ">$output_dump");

while (my $line = <INPUT_DUMP>) {
    # For all lines beginning with 'CREATE', 'DROP' or '--NAME: "'
    ### added by Gilbert Wong: copy
    if ($line =~ /^(create|drop|copy|-- Name: ")/i) {
        # Loop through the hash of names for each line in the file
        foreach $key (keys %full_name) {
            # If it exists, substitute the truncated name in $key for the full name in the hash
	    # The truncated name will be followed by an optional space and either a '"' or a '(' or a ''' (apostrophe for triggers). 
            # Store whichever it is
	    # in the $1 regexp memory and use it at the end of the substitution
            $original_line = $line;
            if ($line =~ s/$key( ?("|\(|'))/$full_name{$key}$1/ig) {printf("Original line: %sAmmended Line: %s\n", $original_line, $line);};
        }
    }
    print OUTPUT_DUMP ($line);
}

close(INPUT_DUMP);
close(OUTPUT_DUMP);

print("==========================================================================\nWrote new dump file as $output_dump");
print(" : DONE\n");

print("Process Completed\n");

