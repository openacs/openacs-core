<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>

<center>

<p>
@file_type_filter@
</p>

<p>
@pre_select_filter@ | @status_filter@
</p>

<p>
<formtemplate id="file_list_form"></formtemplate>
</p>

</center>

<h2>Important Instructions</h2>

<h3>The I18N status of adp files</h3>
<p>
Clicking on the "Show I18N status of files" link above will display three counts for each adp file - the number of potential
translatable text messages, the number of temporary tags (on the syntax <#message_key text#>), and the number of
message key lookups in the file (i.e. occurencies of \#message_key\#). 
</p>

<p>
A fully translated adp must have 0 tags, it typically
has 0 or only a few texts deemed translatable by our script and any number of message key lookups (the last count). Our script 
sometimes considers for example Javascript to be translatable, but don't worry - you will have the opportunity to tell 
it to leave such texts untouched.
</p>

<h3>Actions to take on adp files</h3>
<p>
The last two checkboxes in the form above let you choose which of the two available scripts to run on the selected adp files.
You have to choose at least one of these actions, by default both are selected and for almost all cases this is the setting
that we recommend. When translating the dotlrn package we first ran through all adp files with both actions. For each adp file, we looked at the untouched texts on the result page and manually inserted <#key text#> tags in the adp where appropriate. When we were done with this run-through we then ran the action "Replace tags with keys and insert into catalog" to remove the temporary tags from the adp:s. 
</p>

<p>
To the best of our knowledge there is no harm in running those
actions multiple times on files. Before an adp file is modified it will be backed up to
a file with the name of the original file with the ending .orig appended to it (i.e.
www/a-file.adp is backed up to www/a-file.adp.orig). However
if such an .orig file already exists no backup is done. 
</p>

<p>
If the adp status for a file shows 0 translatable texts, then the "Replace texts with tags" 
action will do nothing. Likewise, if the adp status shows 0 tags then "Replace tags with keys and insert into catalog"
action will have no effect.
</p>

<h4>Replacing text with tags</h4>
<p>
If you select "Replace text with tags"
then for each adp file a script will attempt to replace translatable text with temporary <#message_key text#> tags. You will
have the opportunity to edit the message keys to use. You will also be able to indicate when a piece of text should be left 
untouched (since it should not be subject to translation, for example Javascript code).
</p>

<p>
Any pieces of text that our script finds that it could not automatically extract, for example pieces of text with embedded adp variables (i.e. \@var_name\@), will be listed on the result page. Make sure to take note of these texts and translate them manually. Suppose for example
that our script tells you that it left the text "Forum \@forum_name\@" untouched. What you should do then is to edit the corresponding
adp file and manually replace that text with something like "<#Forum Forum#> \@forum_name\@" (to save you from too much typing you may use the shorthand <#_ Forum#>, an underscore key will result in the script auto-generating a key for you based on the text). After you have made all such manual edits
you can simply run the second action labeled "Replace tags with keys and insert into catalog".
</p>

<p>
<b>Note:</b> running this action will not find translatable text within HTML or adp tags on
adp pages (i.e. text in alt tags of images), nor will it find translatable text in tcl files. Such texts will have to be found manually.
If those texts are in adp files they are best replaced with the <#message_key text#> tags that
can be extracted by the action described below. Here are some commands that we used on Linux to look for texts in
adp pages not found by the script:

<pre>
# List image tags, look for alt attributes with literal text
find -iname '*.adp'|xargs egrep -i '&lt;img'
# List submit buttons, look for text in the value attribute 
find -iname '*.adp'|xargs egrep -i '&lt;input[^&gt;]*type="?submit'
</pre>
</p>

<h4>Replace tags with keys and insert into catalog</h4>
If selected, this action will be executed after the "Replace text with tags" action. It will replace any occurence of the
temporary <#message_key text#> tags with \#message_key\# lookups in the adp files and insert the corresponding
keys and messages into the en_US catalog file for the package. 

<p>
Entries for the extracted messages will be added to the en_US catalog file only if they do not already exist in that file.
If the messages don't contain the package key prefix this prefix will be added before insertion into the message catalog.
</p>

<p>
The message tags are processed from the adp:s in the order 
that they appear. If the key of a message tag is already in the catalog
file then the message texts will be compared. If the message texts in the tag and in the catalog file are identical then no 
insertion is done to the catalog file. If they differ it is assumed that the new message should be inserted into the 
catalog file but with a different key. In this case a warning is issued in the log file and an integer is appended to the 
message key to make it unique before insertion into the catalog file is done.
</p>

<h3>Dealing with tcl files</h3>
<p>
It seems translatable text in tcl files often appers in double quotes, so we used the following
somewhat crude regexp to highlight such texts for us:
</p>

<pre>
find -iname '*.tcl'|xargs egrep -i '"[a-z]'
</pre>

<p>
You may mark up translatable text in tcl library files and tcl pages with temporary tags 
(on the <#key text#> syntax mentioned previously) and then run the 
"Replace tags with keys and insert into catalog" action on these files.
</p>
