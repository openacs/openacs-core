# A very simple Makefile to generate the HTML docs
# @author Vinod Kurup (vinod@kurup.com)
# @creation-date 2002-08-10
#
# @author Modified by Roberto Mello (rmello@fslc.usu.edu) to have PDF generation
# @modified-date 2002-09-21
#         plus refactored it a bit to have rules and dependencies.

#
# @author Joel Aufrecht (joel@aufrecht.org)
# @modified-date 2002-09-21
# Removed the xml/files directory as redundant.
#
# This copies the 'images'
#   to the appropriate directory in www so that they are accessible
#
# It then moves into the www directory and runs the XSLT generation
# and runs htmldoc to generate PDFs.
#

# Paths
XSLTPROC=/usr/bin/xsltproc
HTMLDOC=/usr/bin/htmldoc

all: html

prelim:
	cp -u images/*.{pdf,png,gif,jpg} ../images/
	cp -u openacs.css ..

html: prelim
	cd .. ; $(XSLTPROC) xml/openacs.xsl xml/index.xml

pdf: html
	$(HTMLDOC) --batch ../for-everyone.book ../for-admins.book ../for-developers.book
