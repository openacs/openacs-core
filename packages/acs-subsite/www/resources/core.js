function acs_Focus(form_name, element_name) {
    if (document.forms == null) return;
    if (document.forms[form_name] == null) return;
    if (document.forms[form_name].elements[element_name] == null) return;
    if (document.forms[form_name].elements[element_name].type == 'hidden') return;

    document.forms[form_name].elements[element_name].focus();
}

function acs_FormRefresh(form_name) {
    if (document.forms == null) return;
    if (document.forms[form_name] == null) return;
    if (document.forms[form_name].elements["__refreshing_p"] == null) return;

    document.forms[form_name].elements["__refreshing_p"].value = 1;
    document.forms[form_name].submit();
}

function acs_CopyText(text) {
    if (document.all) {
        holdtext.innerText = text;
        Copied = holdtext.createTextRange();
        Copied.execCommand("Copy");
    } else if (window.netscape) {
        netscape.security.PrivilegeManager.enablePrivilege('UniversalXPConnect');

        var clip = Components.classes['@mozilla.org/widget/clipboard;1'].createInstance(Components.interfaces.nsIClipboard);
        if (!clip) return;

        var trans = Components.classes['@mozilla.org/widget/transferable;1'].createInstance(Components.interfaces.nsITransferable);
        if (!trans) return;

        trans.addDataFlavor('text/unicode');

        var str = new Object();
        var len = new Object();

        var str = Components.classes["@mozilla.org/supports-string;1"].createInstance(Components.interfaces.nsISupportsString);

        var copytext = text;

        str.data = copytext;

        trans.setTransferData("text/unicode", str, copytext. length*2);

        var clipid = Components.interfaces.nsIClipboard;
        if (!clipid) return false;

        clip.setData(trans, null, clipid. kGlobalClipboard);
    }
}
