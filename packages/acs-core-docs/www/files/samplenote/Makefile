# A very simple Makefile to generate the HTML docs

# Paths
XSLTPROC=/usr/bin/xsltproc
HTMLDOC=/usr/bin/htmldoc
XSL=../../../acs-core-docs/www/xml/openacs.xsl

all: html

prelim:
	cp -u *.png ..

html: prelim
	cd .. ; $(XSLTPROC) $(XSL) xml/index.xml

