# A very simple Makefile to generate the HTML docs
# @author Vinod Kurup (vinod@kurup.com)
# @author Modified by Roberto Mello (rmello@fslc.usu.edu) to have PDF generation
#         plus refactored it a bit to have rules and dependencies.
#
# @creation-date 2002-08-10
# @modified-date 2002-09-21
#
# This simply copys all the 'files' and 'images'
#   to the appropriate directory in www so that they are accessible
#
# It then moves into the www directory and runs the XSLT generation
# and runs htmldoc to generate PDFs.
#
# I'm a Makefile newbie, so feel free to comment/slash/change.

# Paths
XSLTPROC=/usr/bin/xsltproc
HTMLDOC=/usr/bin/htmldoc

all: html

prelim:
	cp -u files/*.{txt,html} ../files/
	cp -u images/*.{pdf,png,gif,jpg} ../images/
	cp -u openacs.css ..

html: prelim
	cd .. ; $(XSLTPROC) xml/openacs.xsl xml/index.xml

pdf: html
	$(HTMLDOC) --batch ../for-everyone.book ../for-admins.book ../for-developers.book
