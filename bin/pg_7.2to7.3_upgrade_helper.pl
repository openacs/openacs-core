#!/usr/bin/perl

# usage: ./dump_parser.pl origdump newdump /your/oacs/dir
#
# this parses a postgres dump file coming from pg 7.2.x
# it then looks for function names that has 31 char length, which are
# likely truncated function names.  It then digs into the 
# OpenACS home dir to look for the untruncated function name
# and substitutes the value and makes a new dump file.
# the new dump file can be used to restore on pg 7.3.x
#
# requires: perl, grep and find
#
# slapped together by Jun Yamog
#
# THIS IS NOT 100%, BUT SHOULD HELP A LOT.

# I have also seen that this following views are also truncated
#
# ad_template_sample_users_sequence
# acs_privilege_descendant_map_view

# this are the create statements on a dump file, i have not checked if other
# object types are affected.  The script only goes through functions
#
#CREATE CONSTRAINT
#CREATE FUNCTION
#CREATE INDEX
#CREATE RULE
#CREATE SEQUENCE
#CREATE TABLE
#CREATE TRIGGER
#CREATE TRUSTED
#CREATE UNIQUE
#CREATE VIEW
#
# Take note that views that made use of truncated names, but be recreated 
# to use the untruncated names
#
# look at this thread for further info
#
# http://openacs.org/forums/message-view?message_id=109337

$input_dump = $ARGV[0];
$output_dump = $ARGV[1];
$oacs_home = $ARGV[2]; 

open(INPUT_DUMP, $input_dump);
open(OUTPUT_DUMP, ">$output_dump");

@output_dump = "";

while (<INPUT_DUMP>) {
    # check to see if line is a CREATE FUNCTION
    if ($_ =~ /^CREATE FUNCTION "(.*)"/) {
        #check to see if the function is at 31 char
        $function_name = $1;
        if (length($function_name)>=31) {
            print("==================================================================\n");
            print("looking for function $function_name in oacs\n");
            # lets grep on the oacs files to get the real name
            $grep_result = `find $oacs_home -name "*.sql" | xargs grep -ri "function $function_name"`;
            print("grep result: $grep_result \n");
            if ($grep_result =~ /function (${function_name}\w*)/i) {
                # if we get the real name lets substitute it
                $real_function_name = $1;
                print("replacing $function_name with $real_function_name \n\n\n");
                $_ =~ s/$function_name/$real_function_name/;
            } else {
                print("WARNING: unable to find the real function name of $function_name \n\n\n");
            }
        }
    }
    push(@output_dump, $_);
}

print OUTPUT_DUMP (@output_dump);

close(INPUT_DUMP);
close(OUTPUT_DUMP);

