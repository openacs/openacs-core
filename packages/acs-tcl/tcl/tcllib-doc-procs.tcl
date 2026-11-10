ad_library {
    API-browser documentation for Tcllib commands used by OpenACS.

    Only already-provided packages and existing commands are documented.
    Documentation-only ad_proc declarations do not replace implementations.
    Declarations stay in this source file, not in interpreter-blueprint data.
}

namespace eval ::acs::tcllib {}

if {[namespace which ::acs::tcllib::register_documentation] eq ""} {
    ad_proc -private ::acs::tcllib::register_documentation {{proc_name ""}} {
        Refresh documentation for already-loaded Tcllib packages, optionally
        when metadata is requested for a command in uri, base64 or mime.
        This procedure never requires a package or evaluates its loader.
        @param proc_name Procedure name, or empty to refresh all declarations.
    } {
        if {$proc_name ne ""} {
            set name [string trimleft $proc_name :]
            set package [string trimleft [namespace qualifiers ::$name] :]
            if {$package ni {uri base64 mime}
                || [package provide $package] eq ""
                || [namespace which -command ::$name] eq ""
                || ([nsv_exists api_proc_doc $name]
                    && [dict exists [nsv_get api_proc_doc $name] main])} {
                return
            }
        }
        # Sourcing keeps ad_proc's source attribution on this file, even
        # when registration was requested by a test or the calling-info scan.
        source [file join [acs_package_root_dir acs-tcl] tcl tcllib-doc-procs.tcl]
    }
}

if {[namespace which ::acs::tcllib::document] eq ""} {
    ad_proc -private ::acs::tcllib::document {
        package proc_name arguments documentation {protection public}
    } {
        Register documentation for an existing command of an already-loaded
        Tcllib package, without replacing its implementation or existing docs.
        @param package Owning Tcllib package.
        @param proc_name Fully qualified command name.
        @param arguments Documented Tcl argument list.
        @param documentation API-browser documentation text.
        @param protection API-browser visibility, public or private.
    } {
        if {[package provide $package] eq ""
            || [namespace which -command $proc_name] eq ""} {return}
        set name [string trimleft $proc_name :]
        set previous {}
        if {[nsv_exists api_proc_doc $name]} {
            set previous [nsv_get api_proc_doc $name]
            if {[dict exists $previous main]} {return}
        }
        ad_proc -$protection $proc_name $arguments $documentation -
        # Complete any partial entry without losing testcase/caller links.
        nsv_set api_proc_doc $name [dict merge $previous [nsv_get api_proc_doc $name]]
        set script [dict get [nsv_get api_proc_doc $name] script]
        if {![nsv_exists api_proc_doc_scripts $script]
            || $name ni [nsv_get api_proc_doc_scripts $script]} {
            nsv_lappend api_proc_doc_scripts $script $name
        }
    }
}

::acs::tcllib::document uri ::uri::split {url {defaultscheme http}} {
    Split a URI into scheme-dependent component name/value pairs using
    Tcllib. The result is suitable for array set or dict operations.
    Parsing follows the package's configured URI quirk options.
    @param url URI to parse.
    @param defaultscheme Scheme used when the URI has no scheme; defaults to http.
    @return Component names and values, including the scheme.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/uri/uri.md
}

::acs::tcllib::document uri ::uri::join {args} {
    Construct a URI from Tcllib component name/value pairs. Accepted
    components and normalization depend on the selected scheme.
    @param args Alternating component names and values, including scheme.
    @return The constructed URI.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/uri/uri.md
}

::acs::tcllib::document base64 ::base64::encode {args} {
    Encode binary data as standard Base64 using Tcllib.
    @param args Optional -maxlen and -wrapchar values followed by the data.
                Defaults are 76 columns and a newline; -maxlen 0 disables wrapping.
    @return Base64-encoded text.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/base64/base64.md
}

::acs::tcllib::document base64 ::base64::decode {string} {
    Decode standard Base64 text using Tcllib. Acceptance of malformed
    input depends on the loaded package version and implementation.
    @param string Base64-encoded input.
    @return Decoded binary data.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/base64/base64.md
}

::acs::tcllib::document mime ::mime::initialize {args} {
    Create a Tcllib MIME token by parsing a message or constructing a part.
    @param args Options including -file, -string or -parts; construction
                can specify -canonical type/subtype, -param, -header and -encoding.
    @return A MIME token; release it with mime::finalize when finished.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::finalize {token args} {
    Release a Tcllib MIME token and its associated resources.
    @param token MIME token to release.
    @param args Optional -subordinates all, dynamic or none; default is dynamic.
    @return The empty string.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::getproperty {token {property {}}} {
    Read properties of a Tcllib MIME token, such as content, encoding,
    params, parts and size.
    @param token MIME token to inspect.
    @param property Property name, -names for property names, or empty for all properties.
    @return The property value, property names, or property name/value pairs.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::getheader {token {key {}}} {
    Read headers of a Tcllib MIME token. Repeated headers can have
    multiple values.
    @param token MIME token to inspect.
    @param key Header name, -names for header names, or empty for all headers.
    @return Matching header values, header names, or header name/value pairs.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::setheader {token key value args} {
    Change a header of a Tcllib MIME token, subject to its restrictions
    on MIME-managed headers.
    @param token MIME token to modify.
    @param key Header name.
    @param value Header value.
    @param args Optional -mode write, append or delete; default is write.
    @return Previous values associated with the header.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::getbody {token args} {
    Read the body of a Tcllib MIME token. The -decode option requests
    transfer decoding; -command enables callback-based delivery.
    @param token MIME token to read.
    @param args Optional -decode, -command callback and -blocksize octets.
    @return The body, or the final callback result when -command is used.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::parseaddress {string} {
    Parse an email address list using Tcllib's MIME address parser.
    @param string Address list to parse.
    @return A list of address records represented as name/value lists.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::parsedatetime {value property} {
    Extract a property from an email date-time value using Tcllib.
    @param value Email date-time string, or -now for the current time.
    @param property Requested property, such as clock, proper, year, mon or zone.
    @return The requested date-time property.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::uniqueID {} {
    Generate a MIME Content-ID using Tcllib's process ID, clock,
    hostname and counter. This is not a cryptographic random identifier.
    @return An identifier enclosed in angle brackets.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::buildmessage {token} {
    Serialize a Tcllib MIME token, including its headers and body.
    This command is documented by Tcllib even though some versions do
    not export it from the mime namespace.
    @param token MIME token to serialize.
    @return The complete MIME message.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::qp_encode {string {encoded_word 0} {no_softbreak 0}} {
    Encode quoted-printable content using a Tcllib MIME implementation
    helper. This non-exported helper is version-dependent.
    @param string Data to encode.
    @param encoded_word Use encoded-word processing when true.
    @param no_softbreak Suppress insertion of soft line breaks when true.
    @return Quoted-printable text.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
} private

::acs::tcllib::document mime ::mime::word_encode {charset method string args} {
    Encode an RFC 2047 header value using a Tcllib MIME implementation
    helper. This non-exported helper is version-dependent.
    @param charset MIME charset name.
    @param method base64 or quoted-printable.
    @param string Data to encode.
    @param args Optional -charset_encoded boolean and -maxlength length.
    @return Encoded header text.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
} private
