<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>

<p>
Please choose adp templates to extract message keys from.
</p>

<p>
<formtemplate id="adp_list_form"></formtemplate>
</p>

<p>
Note: Submitting this form will alter any adp files you selected that contain message key tags. However those adp files will first be backed up to files with the the ending .orig if such files do not already exist. You may want to remove those files once you have reassured yourself that the message key extraction worked properly. The keys to be extracted should be embedded in the templates with the following syntax: 
</p>

<p>
<center>
<#package_key.message_key Text in en_US locale#>.
</center>
</p>

<p>
Entries for the extracted messages will be added to the en_US catalog file only if they do not already exist in that file.
If the messages don't contain the package key prefix this prefix will be added before insertion into the message catalog.
</p>

<p>
The message tags are processed from the adp:s in the order that they appear. If the key of a message tag is already in the catalog
file then the message texts will be compared. If the message texts in the tag and in the catalog file are identical then no 
insertion is done to the catalog file. If they differ it is assumed that the new message should be inserted into the 
catalog file but with a different key. In this case a warning is issued in the log file and an integer is appended to the message key to make it unique before insertion into the catalog file is done.
</p>