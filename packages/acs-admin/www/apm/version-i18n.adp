<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>

<p align="center">
  @file_type_filter@
</p>

<p align="center">
  @pre_select_filter@ | @status_filter@ (<a href="#file-status">?</a>)
</p>

<formtemplate id="file_list_form"></formtemplate>

<h2>Instructions</h2>

<p>
  Here's the process for internationalizing a package:
</p>

<ol>
  <p>
    <li>
      <b>Replace text with tags in ADP files</b>: Run above process
      for ADP files with only the first action checked.
    </li>
  </p>
  <p>
    <li>
      <b>Manually check ADP files</b>: Go through the ADP files and
      check that the &lt;\#...\#&gt;'s are where they should be.
    </li>
  </p>
  <p>
    <li>
      <b>Manually check Tcl files</b>: Go through the Tcl files, and
      replace any localizable text with the &lt;\#...\#&gt; notation.
    </li>
  </p>
  <p>
    <li>
      <b>Replace tags with keys</b> and insert into catalog: Run this
      action for both ADP files and Tcl files, one after another.
    </li>
  </p>
</ol>

<h3>Actions to take on adp files</h3>

<p>
  The last two checkboxes in the form above let you choose which of
  the two available scripts to run on the selected adp files.  You
  have to choose at least one of these actions, by default both are
  selected and for almost all cases this is the setting that we
  recommend. When translating the dotlrn package we first ran through
  all adp files with both actions. For each adp file, we looked at the
  untouched texts on the result page and manually inserted <#key
  text#> tags in the adp where appropriate. When we were done with
  this run-through we then ran the action "Replace tags with keys and
  insert into catalog" to remove the temporary tags from the adp:s.
</p>

<p>
  To the best of our knowledge there is no harm in running those
  actions multiple times on files. Before an adp file is modified it
  will be backed up to a file with the name of the original file with
  the ending .orig appended to it (i.e.  www/a-file.adp is backed up
  to www/a-file.adp.orig). However if such an .orig file already
  exists no backup is done.
</p>

<p>
  If the adp status for a file shows 0 translatable texts, then the
  "Replace texts with tags" action will do nothing. Likewise, if the
  adp status shows 0 tags then "Replace tags with keys and insert into
  catalog" action will have no effect.
</p>

<h4>Replacing text with tags</h4>

<p>
  If you select "Replace text with tags" then for each adp file a
  script will attempt to replace translatable text with temporary
  <#message_key text#> tags. You will have the opportunity to edit the
  message keys to use. You will also be able to indicate when a piece
  of text should be left untouched (since it should not be subject to
  translation, for example Javascript code).
</p>

<p>
  Any pieces of text that our script finds that it could not
  automatically extract, for example pieces of text with embedded adp
  variables (i.e. \@var_name\@), will be listed on the result
  page. Make sure to take note of these texts and translate them
  manually. Suppose for example that our script tells you that it left
  the text "Forum \@forum_name\@" untouched. What you should do then
  is to edit the corresponding adp file and manually replace that text
  with something like "<#Forum Forum#> \@forum_name\@" (to save you
  from too much typing you may use the shorthand <#_ Forum#>, an
  underscore key will result in the script auto-generating a key for
  you based on the text). After you have made all such manual edits
  you can simply run the second action labeled "Replace tags with keys
  and insert into catalog".
</p>

<p>
  <b>Note:</b> running this action will not find translatable text
  within HTML or adp tags on adp pages (i.e. text in alt tags of
  images), nor will it find translatable text in tcl files. Such texts
  will have to be found manually.  If those texts are in adp files
  they are best replaced with the <#message_key text#> tags that can
  be extracted by the action described below. Here are some commands
  that we used on Linux to look for texts in adp pages not found by
  the script:
</p>

<pre>
# List image tags, look for alt attributes with literal text
find -iname '*.adp'|xargs egrep -i '&lt;img'
# List submit buttons, look for text in the value attribute 
find -iname '*.adp'|xargs egrep -i '&lt;input[^&gt;]*type="?submit'
</pre>

<h4>Replace tags with keys and insert into catalog</h4>

<p>
  If selected, this action will be executed after the "Replace text
  with tags" action. It will replace any occurence of the temporary
  <#message_key text#> tags with \#message_key\# lookups in the adp
  files and insert the corresponding keys and messages into the en_US
  catalog file for the package.
</p>

<p>
  Entries for the extracted messages will be added to the en_US
  catalog file only if they do not already exist in that file.  If the
  messages don't contain the package key prefix this prefix will be
  added before insertion into the message catalog.
</p>

<p>
  The message tags are processed from the adp:s in the order that they
  appear. If the key of a message tag is already in the catalog file
  then the message texts will be compared. If the message texts in the
  tag and in the catalog file are identical then no insertion is done
  to the catalog file. If they differ it is assumed that the new
  message should be inserted into the catalog file but with a
  different key. In this case a warning is issued in the log file and
  an integer is appended to the message key to make it unique before
  insertion into the catalog file is done.
</p>

<h3>Dealing with tcl files</h3>

<p>
  When internationalizing the tcl files in the dotlrn package we
  noticed that translatable texts are often found in page titles,
  context bars, and form labels and options. Many times the texts are
  enclosed in double quotes. We used the following grep commands on
  Linux to highlight translatable text in tcl files for us:
</p>

<pre>
# Find text in double quotes
find -iname '*.tcl'|xargs egrep -i '"[a-z]'
# Find untranslated text in form labels, options and values
find -iname '*.tcl'|xargs egrep -i '\-(options|label|value)'|egrep -v '<#'|egrep -v '\-(value|label|options)[[:space:]]+\$[a-zA-Z_]+[[:space:]]*\\?[[:space:]]*$'
# Find text in page titles and context bars
find -iname '*.tcl'|xargs egrep -i 'set (title|page_title|context_bar) '|egrep -v '<#'
# Find text in error messages
find -iname '*.tcl'|xargs egrep -i '(ad_complain|ad_return_error)'|egrep -v '<#'
</pre>

<p>
  You may mark up translatable text in tcl library files and tcl pages
  with temporary tags (on the <#key text#> syntax mentioned
  previously). If you have a sentence or paragraph of text with
  variables in it you may choose to turn the whole text into one
  message in the catalog. If you choose this option you cannot use the
  message tag syntax but rather you must manually replace the text
  with an invocation of the message lookup procedure (the underscore
  procedure) as well as manually insert the message into the catalog
  file (you should check that your message key is unique when you do
  this). Here is an example from dotlrn:
</p>

<p>
  The code
</p>

<pre>
ad_return_complaint 1 "Error: A [parameter::get -parameter classes_pretty_name] 
             must have <em>no</em>[parameter::get -parameter class_instances_pretty_plural] to be deleted"
</pre>

<p>
  was replaced manually by:
</p>

<pre>
set msg_subst_list [list subject [parameter::get -localize -parameter classes_pretty_name] 
                         class_instances [parameter::get -localize -parameter class_instances_pretty_plural]]

ad_return_complaint 1 [_ dotlrn.class_may_not_be_deleted $msg_subst_list]
</pre>

<p>
  and the following line was added to the catalog file:
</p>

<pre>
_mr en_US dotlrn.class_may_not_be_deleted {Error: A %subject% must have <em>no</em> %class_instances% to be deleted}
</pre>

<p>
Alternatively, the variable values in the message can be fetched with upvar, so that in the tcl file in the example above,
we would have simply:
</p>

<pre>
set subject [parameter::get -localize -parameter classes_pretty_name] 
set class_instances [parameter::get -localize -parameter class_instances_pretty_plural]

ad_return_complaint 1 [_ dotlrn.class_may_not_be_deleted]
</pre>

<p>
This kind of interpolation also works in adp files where adp variable values will be inserted into the message.
</p>

<p>
  When we were done going through the tcl files we ran the following
  commands to check for mistakes:
</p>

<pre>
# Message tags should usually not be in curly braces since then the message lookup may not be
# executed then (you can usually replace curly braces with the list command). Find message tags 
# in curly braces (should return nothing, or possibly a few lines for inspection)
find -iname '*.tcl'|xargs egrep -i '\{.*<#'
# Check if you've forgotten space between default key and text in message tags (should return nothing)
find -iname '*.tcl'|xargs egrep -i '<#_[^ ]'
# Review the list of tcl files with no message lookups
for tcl_file in $(find -iname '*.tcl'); do egrep -L '(<#|\[_)' $tcl_file; done
</pre>

<p>
  When you feel ready you may run the action "Replace tags with keys
  and insert into catalog" on the tcl files that you've edited to
  replace the temporary tags with calls to the message lookup
  procedure.
</p>

<h3>Checking the Consistency of the Catalog File</h3>

<p>
  This section describes how we checked that the set of keys used in
  message lookups in tcl, adp, and info files and the set of keys in
  the catalog file are identical.  The scripts below assume that
  message lookups in adp and info files are on the format
  \#package_key.message_key\#, and that message lookups in tcl files
  are always done with the underscore procedure. The script assumes
  that you have perl installed and in your path.  Run the script like
  this:
</p>

<pre>
acs-lang/bin/check-catalog.sh package_key
</pre>

<p>
  where package_key is the key of the package that you want to
  test. If you don't provide the package_key argument then all
  packages with catalog files will be checked. 
  The script will run its checks on en_US xml catalog files.
</p>

<h2>Help</h2>

<a name="file-status"><h3>The I18N status of adp files</h3></a>

<p>
  Clicking on the "Show I18N status of files" link above will display
  three counts for each adp file - the number of potential
  translatable text messages, the number of temporary tags (on the
  syntax <#message_key text#>), and the number of message key lookups
  in the file (i.e. occurencies of \#message_key\#).
</p>

<p>
  A fully translated adp must have 0 tags, it typically has 0 or only
  a few texts deemed translatable by our script and any number of
  message key lookups (the last count). Our script sometimes considers
  for example Javascript to be translatable, but don't worry - you
  will have the opportunity to tell it to leave such texts untouched.
</p>

