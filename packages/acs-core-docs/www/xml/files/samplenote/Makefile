# A very simple Makefile to generate the HTML docs and copy any graphics
# Assumes that html should be generated into the parent directory
# of the current directory, which is named xml

# Paths
XSLTPROC=/usr/bin/xsltproc
HTMLDOC=/usr/bin/htmldoc
XSL=../../acs-core-docs/www/xml/openacs.xsl
XMLFILE=xml/index.xml

all: html

prelim:
	cp -u *.png ..

html: prelim
	cd .. ; $(XSLTPROC) $(XSL) $(XMLFILE)

