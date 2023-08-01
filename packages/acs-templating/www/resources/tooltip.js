const intersectionObserver = new IntersectionObserver((entries) => {
    //
    // Observe the visibility of the tooltip on the page and make so
    // that this falls back to the bottom orientation when the tooltip
    // would not be completely visible.
    //
    // The root for the observer is the document body, because we do
    // not care if the element is visible right now, only if it is
    // completely visible on the page.
    //
    // The assumption is that the bottom orientation is safe, as one
    // can always scroll further.
    //
    for (const entry of entries) {
        const tooltip = entry.target.parentElement;
        if (entry.intersectionRatio !== 1) {
            //
            // Entry is not fully visible, switch to the default
            // tooltip orientation.
            //
            tooltip.classList.remove('top', 'left', 'right', 'bottom');
            intersectionObserver.unobserve(tooltip);
        }
    }
}, {
    root: document.querySelector('body')
}
);
function acsTooltip(selector) {
    for (const e of document.querySelectorAll(selector)) {
        //
        // If the user did not provide the tooltip text as an own
        // element, we create one using the content of the 'title'
        // attribute.
        //
        let t = e.querySelector('.acs-tooltip-text');
        if (!t) {
            t = document.createElement('span');
            t.setAttribute('class', 'acs-tooltip-text');
            t.innerHTML = e.getAttribute('title');
            e.removeAttribute('title');
            e.appendChild(t);
        }
        //
        // Observe the visibility of the tooltip element.
        //
        intersectionObserver.observe(t);
    }
}

//
// When one does not create new tooltip elements dynamically, this
// load handler is all we need.
//
window.addEventListener('load', function (e) {
    acsTooltip('.acs-tooltip');
});
