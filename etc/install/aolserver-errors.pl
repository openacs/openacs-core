#!/usr/bin/perl -i

# aolserver-errors.pl
#
# prints out the errors from an AOLserver error log
#
# dvr@arsdigita.com, 11/27/99
#
# USAGE:
#
#  aolserver-errors -<num_bytes>b <log_file_location>
#
#     print all errors found in the last <num_bytes> of 
#     the error log.
#
#  aolserver-errors -<num_minutes>m <log_file_location>
#     
#     print all errors logged in the last <num_minutes> 
#     minutes
#
# 
# If called with no options, it will default to
#
#    aolserver-errors -200000b <log_file_location>
#
#
#############################################################
#
# Modification History:
#
# 1/1/2000 -- Removed reliance on the POSIX module and got the 
# <num_minutes> parameter working correctly.
#
# 1/15/2000 -- replaced all calls to 'tail` with seek() calls
# to improve portability. This also allows us to compile this script
# with perlcc to create a single binary that should work under
# a chroot'ed server.
#
# 2/01/2000 -- fixed a bug that caused trouble the first of every 
# month. (Now the problem happens only on the first of each year)
#
# 5/12/2000 -- mbryzek@arsdigita.com
#   Added exit at end of script to kill the thread

$num_args = scalar @ARGV;

# the number of bytes to read from the end of the file when
# we're trying to find all errors in the last N minutes.
$bite_size = 200000; 

# The default size for the -<num_bytes>b parameter
$default_num_bytes = 200000;

%month_num = ('Jan', '00',
              'Feb', '01',
              'Mar', '02',
              'Apr', '03',
              'May', '04',
              'Jun', '05',
              'Jul', '06',
              'Aug', '07',
              'Sep', '08',
              'Oct', '09',
              'Nov', '10',
              'Dec', '11');

foreach $arg_num (0 .. ($num_args - 2)) {
    $arg = $ARGV[$arg_num];

    if ($arg =~ /\-([0-9]+)([A-Za-z])/) {
        ($number, $type) = ($1, lc($2));

        if ($type eq 'b') {
            $num_bytes = $number;
        } elsif ($type eq 'm') {
            $num_minutes = $number;
        } else {
            die "Bad option: $arg\n";
        }            
    } else {
        die "Bad option: $arg\n";
    }
}

$log_file = $ARGV[-1];

open LOG, "< $log_file";

if ($num_minutes) {
    $start_time = sprintf "%02d%02d%02d%02d", (localtime(time - (60*$num_minutes)))[4,3,2,1];

    seek LOG, -$bite_size, 2;

    while (1) {
        while (<LOG>) {
            if (/^\[([0-9]+)\/([A-Za-z]+)\/([0-9]+):([0-9]+):([0-9]+)/) {
                my($day, $month_name, $year, $hour, $minute) = ($1, $2, $3, $4, $5);
                
                $log_time = $month_num{$month_name} . $day . $hour . $minute;
    
                if ($log_time lt $start_time) {

                    # We've gone too far back. Advance until we find
                    # an error that's on or past $start_time

                    $last_position = tell LOG;

                    while (<LOG>) {
                        if (/^\[([0-9]+)\/([A-Za-z]+)\/([0-9]+):([0-9]+):([0-9]+)/) {
                            my($day, $month_name, $year, $hour, $minute) = ($1, $2, $3, $4, $5);

                            $log_time = $month_num{$month_name} . $day . $hour . $minute;

                            if ($start_time le $log_time) {
                                $starting_point = $last_position;
                                last;
                            }
                        }
                        $last_position = tell LOG;
                    }
                    # Either we've found the line we want or have reached
                    # the end of the file. If it's the second case, we 
                    # need to set the starting point to the end of the file.
                    $starting_point = $last_position unless $starting_point;
                }
                # We only need to get one time stamp
                last;
            }
        }

        last if defined $starting_point;

        seek LOG, -$bite_size, 1;

        $position = tell LOG;

        if ($position < $bite_size) {
            # then we need to read the entire file
            $starting_point = 0;
            last;
        }
    }
}

if (defined $starting_point) {
    seek LOG, $starting_point, 0;
} else {    
    $num_bytes = $default_num_bytes unless $num_bytes;
    seek LOG, -$num_bytes, 2;
}

$in_error = 0;
$in_following_notice = 0;

while (<LOG>) {
    if (/^\[(.*?)\]\[(.*?)\][^ ]? (.*)/) {
        ($time, undef, $message) = ($1, $2, $3);

        unless ($first_log_time) {
            ($first_log_time) = ($time =~ /^([^ ]+)/);
            print "Errors since $first_log_time\n";
        }

        if ($message =~ /^Error/) {          
            print "\n[$time]\n    $message\n";
            $in_error = 1;
            $in_following_notice = 0;
        } elsif ($message =~ /^Notice/) {
            if ($in_error == 1) {
                $in_following_notice = 1;
            } else {
                $in_following_notice = 0;
            }
            $in_error = 0;
            print "    $message\n" if $in_following_notice;
        } else {
            $in_error = 0;
            $in_following_notice = 0;
        }            
    } else {
        print "    $_" if ($in_error or $in_following_notice);
    }
}
close LOG;

exit(0);
