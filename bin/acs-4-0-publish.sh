#!/bin/sh
#
# Usage: acs-4-0-stable.sh [files]
#
# Write a special tag (acs-4-0-stable) into the CVS repository
# for a set of files to indicate that they are ready for integration
# into the acs-4-0 source tree.
#
# This script is exceedingly simple.  The operation is
# provided as a shell script so that programmers cannot mistakenly 
# type the wrong tag name.  To undo this script run
#
# cvs tag -D acs-4-0-stable [files] 
#
#
# bquinn@arsdigita.com, September 2000
#
# $Id$
# -----------------------------------------------------------------------------

cvs -q -d ls:/usr/local/cvsroot tag -F acs-4-0-stable $@