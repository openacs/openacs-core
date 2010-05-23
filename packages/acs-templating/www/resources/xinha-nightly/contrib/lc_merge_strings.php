<?php

// Author: Niels Baggesen, <nba@users.sourceforge.net>, 2009-08-16

// Distributed under the same terms as Xinha itself.
// This notice MUST stay intact for use (see license.txt).

// merge-strings.php - merge translation strings from master into
// individual language files.


function usage()
{
    print "merge-strings.php - merge translation strings\n";
    print "Options:\n";
    print "  -l xx     Process language xx. Required option\n";
    print "  -m master Master file. Defaults to 'de.js'\n";
    print "  -m base   Base directory. Defaults to '..'\n";
    print "  -v        Verbose\n";
    print "  -c        Tell about files that must be created\n";
    print "  -d        Debug. Very noisy\n";
    exit(1);
}

// This function taken from the php.net manual page for glob

function rglob($pattern='*', $flags = 0, $path='')
{
    $paths=glob($path.'*', GLOB_MARK|GLOB_ONLYDIR|GLOB_NOSORT);
    $files=glob($path.$pattern, $flags);
    foreach ($paths as $path)
    {
	$files=array_merge($files,rglob($pattern, $flags, $path));
    }
    return $files;
}

error_reporting(E_ALL);

$opts = getopt('l:b:m:cvd');

if ($opts === false) usage;
// here we should check extra options, but php lacks that functionality

$lang = 'xx';            // The language we process
$create = 0;             // Tell about missing files?
$verbose = 0;            // Log the details to stdout?
$debug = 0;              // ?
$basedir = '..';         // Base directory to process
$mastername = 'de.js';   // The best bet on a complete translation file

if (isset($opts['l'])) $lang = $opts['l'];
else die("Missing -l option\n");
if (isset($opts['c'])) $create = 1;
if (isset($opts['v'])) $verbose = 1;
if (isset($opts['d'])) $debug = 1;
if (isset($opts['b'])) $basedir = $opts['b'];
if (isset($opts['m'])) $mastername = $opts['m'];

if (!preg_match('#/$#', $basedir)) $basedir .= '/';

// So, find all the master files

$files = rglob($mastername, 0, $basedir);
if (count($files) == 0)
{
    print "No master files found. Check your -b and -m options!\n";
    exit(1);
}

// and process them

$filenum = 0;
foreach ($files as $masterjs)
{
    $langjs = preg_replace("/$mastername/", "$lang.js", $masterjs);
    $langnew = $langjs.'.new';

    if (!file_exists($langjs))
    {
	if ($create) print "Missing file: $langjs\n";
	continue;
    }

    // Populate $trans with the strings that must be translated

    $filenum++;
    $min = fopen($masterjs, "r");
    $trans = array();
    $strings = 0;
    while ($str = fgets($min))
    {
	$str = trim($str);
	if (preg_match('#^ *"([^"]*)" *: *"([^"]*)"(,)? *(//.*)?$#', $str, $m))
	{
	    if (isset($trans[$m[1]]))
	    {
		print "Duplicate string in $masterjs: $m[1]\n";
		continue;
	    }
	    if ($debug) print "Translate: $m[1]\n";
	    $trans[$m[1]] = 1;
	    $strings++;
	}
    }
    fclose($min);

    // Now copy from $lin to $lout while verifying that the strings
    // are still current.
    // Break out when we hit the last string in the master (no ','
    // after the translation.

    $lin = fopen($langjs, "r");
    $lout = fopen($langnew, "w");
    $obsolete = 0;
    $new = 0;
    $kept = 0;
    while ($fstr = fgets($lin))
    {
	$str = trim($fstr);
	if (preg_match('#^ *"([^"]*)" *: *"([^"]*)"(,)? *(//.*)?$#', $str, $m))
	{
	    if (!isset($trans[$m[1]]))
	    {
		if ($verbose) print "Obsolete: $m[1]\n";
		$obsolete++;
		fprintf($lout, "  // \"%s\": \"%s\" // OBSOLETE\n", $m[1], $m[2]);
	    }
	    else
	    {
		if ($debug) print "Keep: $m[1]\n";
		unset($trans[$m[1]]);
		$strings--;
		$kept++;
		fprintf($lout, "  \"%s\": \"%s\"%s\n", $m[1], $m[2], $strings ? ',' : '');
	    }
	    if (!isset($m[3]) || $m[3] != ',')
		break;
	}
	else
	    fprintf($lout, "%s", $fstr);
    }

    // Add the strings that are missing

    foreach ($trans as $tr => $v)
    {
	if ($verbose) print("New: $tr\n");
	$new++;
	$strings--;
	fprintf($lout, "  \"%s\": \"%s\"%s // NEW\n", $tr, $tr, $strings ? ',' : '');
    }

    // And then the final part of $lin

    while ($str = fgets($lin))
	fprintf($lout, "%s", $str);

    // Clean up, and tell user what happened

    fclose($lin);
    fclose($lout);
    
    if ($obsolete == 0 && $new == 0)
    {
	if ($verbose) print "$langjs: Unchanged\n";
	unlink($langnew);
    }
    else
    {
	print "$langnew: $new new, $obsolete obsoleted, $kept unchanged entries.\n";
	// rename($langnew, $langjs);
    }
}

print "$filenum files processed.\n";

?>
