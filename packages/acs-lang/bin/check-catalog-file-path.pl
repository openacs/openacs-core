#!/usr/bin/perl -w
#
# Check that a catalog file has a consistent path and that package_key, locale, and
# charset info in the xml is consistent with info embedded in the filename.
#
# @author Peter Marklund

my $usage = "catalog-file-name.pl catalog_file_path";

use strict;

# Get arguments
my $file_path = shift or die "usage: $usage";

# Parse information from the file path
$file_path =~ m#(?i)([a-z-]+)/catalog/\1\.([a-z]{2,3}_[a-z]{2})\.(.*)\.xml$# 
    or die "catalog file path $file_path is not on format package_key/catalog/package_key.locale.charset.xml";
my ($file_package, $file_locale, $file_charset) = ($1, $2, $3, $4);

# Get the same info from the xml of the catalog file
open(FILE_INPUT, "< $file_path");
# Undefine the record separator to read the whole file in one go
undef $/;
my $file_contents = <FILE_INPUT>;
$file_contents =~ m#<message_catalog\s+package_key="(.+?)".+locale="(.+?)"\s+charset="(.+?)">#
    or die "catalog file $file_path does not have a root xml node on parsable format";
my ($xml_package, $xml_locale, $xml_charset) = ($1, $2, $3);

# Assert that info in filename and xml be the same
if ( $file_package ne $xml_package || 
     $file_locale ne $xml_locale ||
     $file_charset ne $xml_charset) {

    die "FAILURE: $file_path does not pass check since info in file path ($file_package, $file_locale, $file_charset) does not match info in xml ($xml_package, $xml_locale, $xml_charset)\n";
}
