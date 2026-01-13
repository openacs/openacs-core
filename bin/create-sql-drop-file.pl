#!/usr/local/bin/perl -w

# @author: Jim Guggemoos		created it
# @author: Christian Brechbuehler	some maintenance

# From a -create.sql script, construct the matching -drop.sql script.
#
# Does not follow @ or @@; rather there should be a -drop for every -create,
# like, e.g., in /packags/acs-kernel/sql.


if ( @ARGV != 1 ) {
    die "usage: $0 x-create.sql [ > x-drop.sql ]\n"
}

open( INFILE, "$ARGV[0]" ) or die "could not open $ARGV[0] for read\n";

$commit = 0;

while ( <INFILE> )
{
    chop( $_ );
    $_ =~ s/--.*$//;
    $_ =~ s/\s+or\s+replace//i;
    $_ =~ s/replace\s+or\s+//i;
    $_ =~ s/^\s+$//;

    if ( $_ =~ /^create\s+([^\s]+\s+[^\s\(;]+)/ ) {
	$x = $1;
	$x =~ s/\s+$//;
	push( @obj_list, "$x" );
    } elsif ( $_ =~ /begin\s+create_group_type_fields\(\s*('[^']+'),/i ) {
        $group = $1;
	push( @obj_list, "GTF:$group" );
    } elsif ( $_ =~ /commit\s*;/i ) {
        $commit = 1;
    } elsif ( $_ =~ /alter\s+table\s+([^\s]+)\s+add\s+constraint\s+([^\s]+)/i ) {
    	push( @obj_list, "CONS:$1:$2" );
    } elsif ( $_ =~ /(@@?)\s*(\S+)-create(\.sql)?/i ) {
        push( @obj_list, "$1 $2")
    }
}

close( INFILE );

$tailname = $ARGV[0];
if ( $tailname =~ /\/([^\/]+$)/ ) {
    $tailname = $1;
}

$t = localtime(time());
print "-- Uninstall file for the data model created by '$tailname'\n";
print "-- (This file created automatically by create-sql-uninst.pl.)\n";
$uname=$ENV{"USER"};
print "--\n-- $uname ($t)\n--\n-- \$Id\$\n--\n\n";

foreach $x (reverse( @obj_list )) {
    if ( $x =~ /^GTF:(.+)$/ ) {
	print "BEGIN remove_group_type_fields( $1 );\nEND;\n/\n";
    } elsif ( $x =~ /^CONS:([^:]+):(.*)/ ) {
    	print "alter table $1 drop constraint $2;\n";
    } elsif ( $x =~ /^@/) {
        print "$x-drop\n";
    }
      else {
	print "drop $x;\n";
    }
}

if ( $commit ) {
    print "\nCOMMIT;\n";
}
