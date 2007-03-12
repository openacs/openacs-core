ad_page_contract {
  This is the top level master template.  It allows the basic parts of an XHTML 
  document to be set through convenient data structures without introducing 
  anything site specific.

  You MUST supply the following variables:

  @property doc(title)        The document title, ie. <title /> tag.
  @property doc(title_lang)   The language of the document title, if different
                              from the document language.

  The document output can be customised by supplying the following variables:

  @property doc(type)         The declared xml DOCTYPE.
  @property doc(charset)      The document character set.
  @property body(id)          The id attribute of the body tag.
  @property body(class)       The class of the body tag.
  @property meta:multirow     A multirow of <meta /> tags to render.
  @property link:multirow     A multirow of <link /> tags to render.
  @property script:multirow   A multirow of <script /> tags to render.

  ad_conn -set language       Must be used to override the document language
                              if necessary.

  The following event handlers can be customised by supplying the appropriate 
  variable.  Each variable is a list of valid javascript code fragments to be
  executed in order.

  @property body(onload)
  @property body(onunload)
  @property body(onclick)
  @property body(ondblclick)
  @property body(onmousedown)
  @property body(onmouseup)
  @property body(onmouseover)
  @property body(onmousemove)
  @property body(onmouseout)
  @property body(onkeypress)
  @property body(onkeydown)
  @property body(onkeyup)

  @author Kevin Scaldeferri (kevin@arsdigita.com)
          Lee Denison (lee@xarg.co.uk)
  @creation-date 14 Sept 2000

  $Id$
}

if {[template::util::is_nil doc(type)]} { 
    set doc(type) {<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">}
}

if {[template::util::is_nil doc(charset)]} {
    set doc(charset) [ad_conn charset]
}

# The document language is always set from [ad_conn lang] which by default 
# returns the language setting for the current user.  This is probably
# not a bad guess, but the rest of OpenACS must override this setting when
# appropriate and set the lang attribute of tags which differ from the language
# of the page.  Otherwise we are lying to the browser.
set doc(lang) [ad_conn language]

# AG: Markup in <title> tags doesn't render well.
set doc(title) [ns_striphtml $doc(title)]

if {![template::multirow exists meta]} {
    template::multirow create meta name content http_equiv scheme lang
}

if {![template::multirow exists link]} {
    template::multirow create link rel type href title lang media
}

if {![template::multirow exists script]} {
    template::multirow create script type src charset defer content
}

# Concatenate the javascript event handlers for the body tag
if {[array exists body]} {
    foreach name [array names body -glob "on*"] {
        append event_handlers " ${name}=\""

        foreach javascript $body($name) {
            append event_handlers "[string trimright $javascript "; "]; "
        }

        append event_handlers "\""
    }
}
