//
// When the user clicks anywhere outside of the modal, close it.
//
window.addEventListener('click', function (event) {
    //
    // Quick check to see if this event is relevant to us.
    //
    if (!event.target.classList.contains('acs-modal')) {
        return;
    }
    //
    // Note that we query every time so that the behavior applies also
    // to elements added to the page later.
    //
    for (const modal of document.querySelectorAll('.acs-modal')) {
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    }
});

//
// Attach to every element addressed by the selector the behavior of
// opening their target modal on click.
//
function acsModal(selector) {
    for (const ui of document.querySelectorAll(selector)) {
        //
        // One can either specify a target, or the modal to be opened
        // will be the first one found on the page. Convenient when
        // the modal is the only one on the page, or if it is reused.
        //
        let modalSelector = ui.getAttribute('data-target');
        if (!modalSelector) {
            modalSelector = '.acs-modal';
        }
        const modal = document.querySelector(modalSelector);
        if (!modal) {
            console.warn('Modal not found by selector:', modalSelector);
            return;
        }

        ui.addEventListener('click', function (e) {
            modal.style.display = 'block';
        });

        //
        // See if the modal provides a close button and attach the
        // closing behavior in case.
        //
        for (const close of modal.querySelectorAll('.acs-modal-close')) {
            close.addEventListener('click', function (e) {
                modal.style.display = 'none';
            });
        }
    }
}

window.addEventListener('load', function (e) {
    //
    // Attach the modal UI behavior to all elements of class
    // "acs-modal-open"
    //
    acsModal('.acs-modal-open');
});
