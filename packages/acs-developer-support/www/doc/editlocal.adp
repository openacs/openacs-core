<master>
<property name="doc(title)">Edit and code links</property>
<property name="context">editlocal</property>
<p>
The <u>e</u> and <u>c</u> links in the bottom profiling pane display when ds is enabled 
and the profiling is running for page renders.  The <u>c</u> link sends the body of the cached compiled code 
and the <u>e</u> link sends the filename with a mimetype of application/x-editlocal which you can 
have run a script which will start an editor session on a local copy of that file 
(or potentially a <a href="http://www.fifi.org/doc/tramp/tramp-emacs.html">tramp</a> or Ange-FTP session in 
emacs).
<p>
<p>
An example <a href="editlocal.sh.txt">editlocal.sh</a> script would look something 
like:
<pre>
#!/bin/sh
# an example editlocal script.  To use tell your browser to use
# it to open files with mimetype application/x-editlocal
#
SERVERROOT=/web/head
for a in `cat $1`
do
    if [ -f "$a" ] 
    then 
        emacsclient -n "$a"
    elif [ -f "$SERVERROOT/$a" ]
    then 
         emacsclient -n "$SERVERROOT/$a"
    fi
done
</pre>