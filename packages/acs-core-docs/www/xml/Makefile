# A very simple Makefile to generate the HTML docs
# @author Vinod Kurup (vinod@kurup.com)
# 2002-08-10
#
# This simply copys all the 'files' and 'images'
#   to the appropriate directory in www so that they are accessible
#
# It then moves into the www directory and runs the XSLT generation
#
# I'm a Makefile newbie, so feel free to comment/slash/change.

all:
	cp -u files/*.{txt,html} ../files/
	cp -u images/*.{pdf,png,gif,jpg} ../images/
	cp -u openacs.css ..
	cd .. ; \
	xsltproc xml/openacs.xsl xml/index.xml
