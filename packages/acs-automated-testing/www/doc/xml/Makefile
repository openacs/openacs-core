# A very simple Makefile to generate the HTML docs
# @author Vinod Kurup (vinod@kurup.com)
# @author Modified by Roberto Mello (rmello@fslc.usu.edu)
# @author Joel Aufrecht 
#
# @creation-date 2002-08-10
# @modified-date 2002-09-21
# @modified-date 2003-10-08
#
# Simplified version of acs-core-docs makefile, intended for generating
# documentation from standard location /www/doc/xml in 
# OpenACS packages
#

# Paths
XSLTPROC=/usr/bin/xsltproc
HTMLDOC=/usr/bin/htmldoc

all:

	cd .. ; $(XSLTPROC) --nonet --novalid --xinclude ../../../acs-core-docs/www/xml/openacs.xsl xml/index.xml