ad_library {
    API-browser documentation for external Tcl commands used by OpenACS.

    Only already-provided packages and existing commands are documented.
    Documentation-only ad_proc declarations do not replace implementations.
    Declarations stay in this source file, not in interpreter-blueprint data.
}

namespace eval ::acs::tcllib {}

if {[namespace which ::acs::tcllib::register_documentation] eq ""} {
    ad_proc -private ::acs::tcllib::register_documentation {{proc_name ""}} {
        Refresh documentation for existing Tcl core and extension commands,
        optionally when metadata is requested for a single command.
        This procedure never requires a package or evaluates its loader.
        @param proc_name Procedure name, or empty to refresh all declarations.
    } {
        if {$proc_name ne ""} {
            set name [string trimleft $proc_name :]
            set package [string trimleft [namespace qualifiers ::$name] :]
            switch -- $name {
                dom {set package tdom}
                transform {
                    set package Trf
                    if {[package provide Trf] eq ""} {
                        set package smtp
                    }
                }
                tcl::mathfunc::max {set package Tcl}
            }
            if {$package ni {uri base64 mime md5 tdom Trf Tcl smtp}
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
        Tcl package, without replacing its implementation or existing docs.
        @param package Owning Tcl package.
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

# Version-dependent implementation helpers remain private in the API browser.
::acs::tcllib::document base64 ::base64::ADD {x} {
    Append a character to the pure-Tcl Base64 encoder's caller-owned output
    state, inserting line breaks as needed. This version-dependent helper
    requires its encoder's local variables and is not a standalone API.
    @param x Character to append.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/base64/base64.md
} private

::acs::tcllib::document mime ::mime::base64 {modeOption action separator chunk} {
    Internal MIME adapter for Base64 encoding and decoding when Trf is absent.
    This helper is version-dependent and is not a standalone public API.
    @param modeOption Literal -mode argument.
    @param action encode or decode.
    @param separator Literal -- argument.
    @param chunk Data to process.
    @return The encoded or decoded chunk.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
} private

::acs::tcllib::document mime ::mime::quoted-printable {modeOption action separator chunk} {
    Internal MIME adapter for quoted-printable encoding and decoding when
    Trf is absent. This helper is version-dependent, not a public API.
    @param modeOption Literal -mode argument.
    @param action encode or decode.
    @param separator Literal -- argument.
    @param chunk Data to process.
    @return The encoded or decoded chunk.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
} private

::acs::tcllib::document mime ::mime::reversemapencoding {mimeType} {
    Map a MIME charset name to the corresponding Tcl encoding name using
    Tcllib's case-insensitive mapping table.
    @param mimeType MIME charset name.
    @return The Tcl encoding name, or the empty string if no mapping is known.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
}

::acs::tcllib::document mime ::mime::buildmessageaux {token} {
    Internal recursive MIME message serializer used by mime::buildmessage.
    This helper is version-dependent and operates on MIME token state.
    @param token MIME token to serialize.
    @return Serialized MIME message content.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
} private

::acs::tcllib::document mime ::mime::getsize {token} {
    Determine the size reported for a MIME token by mime::getproperty.
    This internal helper is version-dependent and is not a public API.
    @param token MIME token to inspect.
    @return The size reported for the MIME part.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
} private

::acs::tcllib::document mime ::mime::initializeaux {token args} {
    Configure an allocated MIME token's internal state on behalf of
    mime::initialize. This helper is version-dependent, not a public API.
    @param token Allocated MIME token to configure.
    @param args MIME initialization options passed by mime::initialize.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
} private

::acs::tcllib::document mime ::mime::parseaddressaux {token string} {
    Parse an address list using an internal MIME address-parser token.
    This helper is version-dependent and is not a public API.
    @param token Internal address-parser token.
    @param string Address list to parse.
    @return Parsed address records as name/value lists.
    @see https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/mime/mime.md
} private

::acs::tcllib::document mime ::mime::addr_next {token} {
    Advance an internal MIME address-parser token to the next address.
    This version-dependent helper updates parser state and is not a public API.
    @param token Internal address-parser token.
    @return 1 if another address was parsed, or 0 at the end of the list.
} private

::acs::tcllib::document mime ::mime::addr_x400 {mbox key} {
    Extract a keyed attribute from an X.400 mailbox representation for the
    internal MIME address parser. This helper is not a public API.
    @param mbox X.400 mailbox representation.
    @param key Attribute key to find, matched without case distinctions.
    @return Attribute value with surrounding quotes trimmed, or an empty string
    if the key is absent.
} private

::acs::tcllib::document mime ::mime::md5 {separator string} {
    Internal MIME adapter for computing a hexadecimal MD5 digest when Trf is
    absent. The ignored first positional parameter has a version-dependent
    name in Tcllib. This helper is not a public API.
    @param separator Literal -- argument, ignored by the adapter.
    @param string Data to hash.
    @return Hexadecimal MD5 digest.
} private

::acs::tcllib::document mime ::mime::addr_specification {token} {
    Parse the next address specification using the internal MIME parser state
    and lookahead. Invalid address syntax can raise an error.
    This version-dependent helper is not a public API.
    @param token Internal address-parser token.
    @return 1 if another address was parsed, or 0 at the end of the list.
} private

::acs::tcllib::document mime ::mime::parselexeme {token} {
    Consume the next lexeme from an internal MIME address-parser token,
    updating its input, buffer and last-lexeme state.
    This version-dependent helper is not a public API.
    @param token Internal address-parser token.
    @return Lexeme type recognized by the parser.
} private

::acs::tcllib::document mime ::mime::parsepart {token} {
    Parse a MIME part from its token's string or file input and populate
    the internal part state. Parsing errors are reported as Tcl errors.
    This version-dependent helper is not a public API.
    @param token MIME token containing the part to parse.
} private

if {[package provide md5] ne "" && [namespace which -command ::md5::md5] ne ""} {
    ::acs::tcllib::document md5 ::md5::md5 [info args ::md5::md5] {
        Compute an MD5 digest using the already-loaded Tcllib MD5 implementation.
        The default result is binary in MD5 2.x; -hex requests hexadecimal output.
        @param args Data and options supported by the loaded MD5 package,
        including -hex, -filename and -channel in MD5 2.x.
        @return MD5 digest in the requested representation.
    }
}

::acs::tcllib::document mime ::mime::parsetype {token string} {
    Parse a Content-Type value for an internal MIME token.
    @param token MIME parser token.
    @param string Content-Type value to parse.
    @return Content type and parameters as a two-element list.
} private

::acs::tcllib::document mime ::mime::addr_domain {token} {
    Parse a domain using internal MIME address-parser state.
    @param token Internal address-parser token.
} private

::acs::tcllib::document mime ::mime::addr_end {token} {
    Validate the end of an address using internal MIME parser state.
    Invalid trailing syntax raises an error.
    @param token Internal address-parser token.
} private

::acs::tcllib::document mime ::mime::addr_group {token} {
    Parse an address group using internal MIME parser state.
    @param token Internal address-parser token.
} private

::acs::tcllib::document mime ::mime::addr_phrase {token} {
    Parse an address phrase using internal MIME parser state.
    @param token Internal address-parser token.
} private

::acs::tcllib::document mime ::mime::addr_routeaddr {token {checkP 1}} {
    Parse a route address using internal MIME parser state.
    @param token Internal address-parser token.
    @param checkP Whether to require a closing angle bracket.
} private

::acs::tcllib::document tdom ::tdom::xmlReadFile {filename {encodingString {}}} {
    Read XML file content through tDOM's internal encoding-aware file helper.
    This implementation helper is not a public API.
    @param filename XML file to read.
    @param encodingString Optional name of a caller variable receiving encoding information.
    @return File content read by the helper.
} private


::acs::tcllib::document tdom ::dom {subcommand args} {
    Parse XML or create and manage DOM documents using tDOM.
    @param subcommand Operation such as parse or createDocument.
    @param args Arguments and options for the selected operation.
}

::acs::tcllib::document tdom ::tdom::IANAEncoding2TclEncoding {IANAName} {
    Map a recognized IANA character encoding name to Tcl's encoding name.
    Matching is case-insensitive. An unrecognized name raises an error.
    @param IANAName Character encoding name or alias.
    @return The corresponding Tcl encoding name.
}

::acs::tcllib::document tdom ::tdom::xmlOpenFileWorker {
    filename {encodingString {}} {forSimple 0} {forRead 0}
} {
    Open an XML file and configure the channel for tDOM's parser or file reader.
    @param filename XML file to open.
    @param encodingString Optional caller variable for encoding information.
    @param forSimple Select the simple parser's channel handling.
    @param forRead Select channel handling for reading the file as text.
    @return Open input channel.
} private

::acs::tcllib::document md5 ::md5::MD5Init {} {
    Initialize a Tcllib incremental MD5 digest.
    @return A token for MD5Update and MD5Final.
}

::acs::tcllib::document md5 ::md5::MD5Update {token data} {
    Feed a chunk of binary data into an incremental MD5 digest.
    @param token Token returned by MD5Init.
    @param data Chunk to hash.
}

::acs::tcllib::document md5 ::md5::MD5Final {token} {
    Finalize an incremental MD5 digest and release its state.
    @param token Token returned by MD5Init.
    @return The binary MD5 digest.
}

::acs::tcllib::document md5 ::md5::Hex {data} {
    Convert binary data to hexadecimal for Tcllib's MD5 implementation.
    @param data Bytes to encode.
    @return Hexadecimal text.
} private

::acs::tcllib::document md5 ::md5::Pop {varname {nth 0}} {
    Remove and return an element from a list in the caller's scope.
    @param varname Name of the caller's list variable.
    @param nth Index of the element to remove, defaulting to the first.
} private

::acs::tcllib::document mime ::mime::addr_local {token} {
    Parse the local part of a mailbox and store it in the MIME parser state.
    @param token Internal address-parser token.
} private

::acs::tcllib::document mime ::mime::addr_route {token} {
    Parse a source route and store it in the MIME parser state.
    @param token Internal address-parser token.
} private

::acs::tcllib::document mime ::mime::parsetypeaux {token string} {
    Parse the media type, subtype and parameters for the MIME Content-Type parser.
    @param token Internal MIME parser token.
    @param string Original Content-Type value.
} private

::acs::tcllib::document Tcl ::tcl::mathfunc::max {arg args} {
    Return the greatest of one or more numeric arguments.
    This command implements max() for Tcl expressions.
    @param arg First numeric argument.
    @param args Additional numeric arguments.
}

::acs::tcllib::document Trf ::transform {args} {
    Run a Tcl-defined data transformation or attach it to an I/O channel
    using the Trf extension.
    @param args Transformation options, including -command for the Tcl callback
                and -attach for channel mode, or data for immediate mode.
}


# Some Tcllib SMTP versions define this global shim when Trf is unavailable.
if {[package provide Trf] eq ""
    && [info exists ::smtp::trf] && !$::smtp::trf
    && [info procs ::transform] ne ""
    && [string match {*set mystate(size) 1*} [info body ::transform]]} {
    ::acs::tcllib::document smtp ::transform {args} {
        Internal compatibility shim installed by Tcllib SMTP when Trf is
        unavailable. Set the caller's SMTP size state to 1.
        @param args Compatibility arguments accepted and ignored by the shim.
    } private
}
