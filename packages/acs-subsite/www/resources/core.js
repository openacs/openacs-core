/*

  This file contains javascript utilities that makes sense to include
  in every page.

  It is added to every page reply by /www/blank-master

*/

function acs_FormRefresh(form_name) {
    const refreshing = document?.forms[form_name]?.elements['__refreshing_p'];
    if (refreshing) {
        refreshing.value = 1;
        refreshing.form.submit();
    }
}

/* List Builder Support */

function acs_ListCheckAll(listName, checkP) {
  //
  // Normalize to a boolean
  //
  checkP = checkP ? true : false;

  //
  // List checkboxes belong to the list bulk-action form and are
  // prefixed with the list name.
  //
  const controls = document.querySelectorAll(`form[name='${listName}'] input[type=checkbox][id^='${listName}'][name]`);
  for (const control of controls) {
    control.checked = checkP;
  }
}

function acs_ListBulkActionClick(formName, url) {
    const form = document.querySelector(`form[name='${formName}']`);
    if (!form) {
        return;
    }

    //
    // Sometimes is convenient to have a single page serving the
    // purpose of multiple bulk-actions, for instance
    // "do-bulk-stuff?action=1" and "do-bulk-stuff?action=2".
    //
    // To do so, we parse the URL searching for query parameters. If
    // there are, we inject them into the bulk-actions form together
    // with the rest of the request.
    //
    // Note that the variables specified this way have total
    // precedence and will override those specified differently.
    //

    //
    // Parse the URL
    //
    const queryString = url.slice(url.indexOf('?') + 1);
    const searchParams = new window.URLSearchParams(queryString);

    //
    // Cleanup pre-existing variable conflicting with the URL ones
    //
    for (const [name, value] of searchParams) {
        for (const e of form.querySelectorAll(`[name='${name}']`)) {
            //
            // "e" may not be a direct child of the form
            //
            e.remove();
        }
    }

    //
    // Inject the variables in the form.
    //
    // Note that most browsers now support the "formdata" event, that
    // can be use to manipulate the FormData object directly on the
    // form before this is submitted. However, Safari only introduced
    // support for it in 2021, so we resort to this method.
    //
    // See https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/formdata_event
    //
    for (const [name, value] of searchParams) {
        const i = document.createElement('input');
        i.setAttribute('type', 'hidden');
        i.setAttribute('name', name);
        i.value = value;
        form.appendChild(i);
    }

    form.action = url;
    form.submit();
}

//
// The function acs_ListBulkActionMultiFormClick() is similar to
// acs_ListBulkActionClick() but it iterates over all forms with the
// same name and submits the input elements of all such forms.
//
function acs_ListBulkActionMultiFormClick(formName, url) {
    const relevantForms = document.querySelectorAll(`form[name='${formName}']`);
    if (relevantForms.length === 0) {
        console.log(`no form named ${formName} found`);
        return;
    }

    const formData = new FormData();
    for (const form of relevantForms) {
        const fd = new FormData(form);
        for (const pair of fd.entries()) {
            //console.log(pair[0] + ': ' + pair[1]);
            formData.append(pair[0], pair[1]);
        }
    }

    const xhr = new XMLHttpRequest();
    xhr.open('POST', url, true);
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.onload = function() {
        if (this.status === 200) {
            console.log('change href');
            // We need the following round-trip just to show the
            // updated page (e.g. clipboard count).
            window.location.replace(url);
        }
    };
    xhr.send(formData);
}

function acs_KeypressGoto(theUrl, event) {
    if (event && event.which == 13) {
        window.location.href = theUrl;
    }
}
