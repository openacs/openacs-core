ad_library {
    Documentation for procedures defined before the OpenACS documentation API.

    Register these entries during acs-tcl loading, after ad_proc and the
    database-specific bootstrap checks have been defined. Documentation-only
    declarations preserve the original implementations and caller scope.
}

ad_proc -private acs_bootstrap_fatal_error {message {throw_error_p 1}} {
    Record and log a fatal bootstrap error and install filters that display
    a service-unavailable response in place of the request processor.
    @param message Error message to record.
    @param throw_error_p Whether to raise a bootstrap_fatal_error Tcl error
    after installing the failure filters.
} -

ad_proc -private apm_bootstrap_load_queries {package_key} {
    Load a package's query files for the configured database during bootstrap,
    including query files shared by all database types. Does not require
    package metadata to be available in the database.
    @param package_key Package whose query files should be loaded.
} -

ad_proc -private ad_parse_documentation_string {doc_string elements_var} {
    Parse an OpenACS documentation string into an array in the caller's scope.
    Replace any existing array and collect the main text and tagged elements
    as lists of values, preserving formatting within each element.
    @param doc_string Documentation text to parse.
    @param elements_var Name of the caller's array to populate.
} -

# Database checks may be unavailable when bootstrap stops before DB selection.
if {[namespace which -command ::db_bootstrap_checks] ne ""} {
    ad_proc -private db_bootstrap_checks {errors error_p} {
        Perform bootstrap checks for the configured database implementation.
        Update the caller's error text and error flag as needed.
        @param errors Name of the caller's variable for diagnostic messages.
        @param error_p Name of the caller's variable indicating an error.
    } -
}
