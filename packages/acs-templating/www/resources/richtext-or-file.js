
/* Richtext Widget Support */

function acs_RichText_FormatStr (v) {
    if (!document.selection) return;
    var str = document.selection.createRange().text;
    if (!str) return;
    document.selection.createRange().text = '<' + v + '>' + str + '</' + v + '>';
}

function acs_RichText_InsertLink () {
    if (!document.selection) return;
    var str = document.selection.createRange().text;
    if (!str) return;
    var my_link = prompt('Enter URL:', 'http://');
    if (my_link != null)
        document.selection.createRange().text = '<a href="' + my_link + '">' + str + '</a>';
}

function acs_RichText_WriteButtons () {
    if (document.selection) {
        document.write('<table border="0" cellspacing="0" cellpadding="0" width="80">');
        document.write('<tr>');
        document.write('<td width="24"><a href="javascript:acs_RichText_FormatStr(\'b\')" tabIndex="-1"><img src="/resources/acs-subsite/bold-button.gif" alt="bold" width="24" height="18" border="0"></a></td>');
        document.write('<td width="24"><a href="javascript:acs_RichText_FormatStr(\'i\')" tabIndex="-1"><img src="/resources/acs-subsite/italic-button.gif" alt="italic" width="24" height="18" border="0"></a></td>');
        document.write('<td width="26"><a href="javascript:acs_RichText_InsertLink()" tabIndex="-1"><img src="/resources/acs-subsite/url-button.gif" alt="link" width="26" height="18" border="0"></a></td>');
        document.write('</tr>');
        document.write('</table>');
    }
}

function acs_RichText_Or_File_InputMethodChanged(form_name, richtext_name, radio_elm) {
    if (radio_elm == null) return;
    if (document.forms == null) return;
    if (document.forms[form_name] == null) return;

    if ( radio_elm.value == 'file' ) {
        document.forms[form_name].elements[richtext_name+".text"].disabled = true;
        document.forms[form_name].elements[richtext_name+".mime_type"].disabled = true;
        document.forms[form_name].elements[richtext_name+".file"].disabled = false;
    } else {
        document.forms[form_name].elements[richtext_name+".text"].disabled = false;
        document.forms[form_name].elements[richtext_name+".mime_type"].disabled = false;
        document.forms[form_name].elements[richtext_name+".file"].disabled = true;
    }
}
