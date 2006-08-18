FILES = *.adp *.tcl blank.html

SOURCE = /usr/local/openacs-4/packages/acs-templating/www/resources/xinha-nightly/plugins/OacsFs/popups/

unlink:
	rm -f ${FILES}
	cp -p ${SOURCE}/*.html .
	cp -p ${SOURCE}/*.adp .
	cp -p ${SOURCE}/*.tcl .

link:
	ln -sf ${SOURCE}/*.html .
	ln -sf ${SOURCE}/*.adp .
	ln -sf ${SOURCE}/*.tcl .
