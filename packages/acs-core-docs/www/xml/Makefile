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
XSLTPROC=xsltproc
HTMLDOC=htmldoc

all: html 

XSL:
	if [ ! -d XSL -a ! -L XSL ]; then \
		echo -e "\n\nNo XSL directory here.  I am looking for one...\n"; \
		for d in \
	 		/sw/share/xml/xsl/docbook-xsl \
			/usr/share/sgml/docbook/xsl-stylesheets-* \
			/usr/share/sgml/docbook/xsl-stylesheets \
			/usr/share/sgml/docbook/stylesheet/xsl/nwalsh; \
		do \
			if [ -d $$d ]; then \
				echo "Found $$d"; \
				EXISTS=$$d; \
			fi; \
		done; \
		if [ "$$EXISTS" = "" ]; then \
			echo -e "\
\nNo xsl stylesheets found in /usr/share/sgml/docbook/\n\
You need to install them on your system or if they exist already,\n\
symlink them here so that XSL/html/chunk.xsl exists\n\
see http://sourceforge.net/projects/docbook/ for the docbook-xsl stylesheets\n"; \
			exit 1; \
		else \
			echo "I think $$EXISTS is the best one\n\n"; \
			ln -s $$EXISTS XSL; \
		fi; \
	fi;


prelim:
	cp images/*.{pdf,png,gif,jpg} ../images/

# put all non-regenerated html in a sub-dir so that we can delete html
# in the main directory and regenerate
	cp non-xml/*.html ../

	cp openacs.css ..

html: prelim XSL
# adding --nonet --novalid is much faster but generates a bunch of bogus error messages
	cd .. ; $(XSLTPROC) --nonet --novalid --xinclude xml/openacs.xsl xml/index.xml

# I got this to work with FOP 0.20.5 and docbook-xsl 1.62, and Jimi 1.0
# see README.fop for some notes.
pdf: XSL
	cd ..; $(XSLTPROC) --xinclude --output fop.fo xml/fo.xsl xml/index.xml
	cd ..; fop -fo fop.fo -pdf full.pdf

# Validate with xmllint. --postvalid is needed so validation takes place after xincludes.
# In emacs do M-x compile then make lint; then C-x ` to walk through the resulting errors.
#
lint: XSL
	xmllint --xinclude --noout -postvalid index.xml 2>&1 | grep -v 'No declaration for attribute base of element'
