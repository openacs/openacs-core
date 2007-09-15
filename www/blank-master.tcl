ad_page_contract {
  This is the top level master template.  It allows the basic parts of an XHTML 
  document to be set through convenient data structures without introducing 
  anything site specific.

  You MUST supply the following variables:
  You should NEVER need to modify this file.  
  
  Most of the time your pages or master templates should not directly set this
  file in their <master> tag.  They should instead use site-master with 
  provides a set of standard OpenACS content.  Only pages which need to return
  raw HTML should use this template directly.

  When using this template directly you MUST supply the following variables:

  @property doc(title)        The document title, ie. <title /> tag.
  @property doc(title_lang)   The language of the document title, if different
                              from the document language.

  The document output can be customised by supplying the following variables:

  @property doc(type)         The declared xml DOCTYPE.
  @property doc(charset)      The document character set.
  @property body(id)          The id attribute of the body tag.
  @property body(class)       The class of the body tag.

  ad_conn -set language       Must be used to override the document language
                              if necessary.

  To add a CSS or Javascripts to the <head> section of the document you can 
  call the corresponding template::head::add_* functions within your page.

  @see template::head::add_css
  @see template::head::add_javascript

  More generally, meta, link and script tags can be added to the <head> section
  of the document by calling their template::head::add_* function within your
  page.

  @see template::head::add_meta
  @see template::head::add_link
  @see template::head::add_script

  Javascript event handlers, such as onload, an be added to the <body> tag by 
  calling template::add_body_handler within your page.

  @see template::add_body_handler

  Finally, for more advanced functionality see the documentation for 
  template::add_body_script, template::add_header and template::add_footer.

  @see template::add_body_script
  @see template::add_header
  @see template::add_footer
 
  @author Kevin Scaldeferri (kevin@arsdigita.com)
          Lee Denison (lee@xarg.co.uk)
  @creation-date 14 Sept 2000

  $Id$
}

if {[template::util::is_nil doc(type)]} { 
    set doc(type) {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">}
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

# Generate the <meta /> tag multirow
variable ::template::head::metas
template::multirow create meta name content http_equiv scheme lang
template::multirow append meta \
    "" \
    "text/html; charset=$doc(charset)" \
    "content-type"

if {[array exists metas]} {
    foreach name [array names metas] {
        foreach {http_equiv name scheme content lang} $metas($name) {
            template::multirow append meta \
                $name \
                $content \
                $http_equiv \
                $scheme \
                $lang
        }
    }
}

# Generate the <link /> tag multirow
variable ::template::head::links
template::multirow create link rel type href title lang media
if {[array exists links]} {
    foreach name [array names links] {
        foreach {rel href type media title lang} $links($name) {
            template::multirow append link \
                $rel \
                $type \
                $href \
                $title \
                $lang \
                $media
        }
    }
}

# Generate the head <script /> tag multirow
variable ::template::head::scripts
template::multirow create script type src charset defer content
if {[array exists scripts]} {
    foreach name [array names scripts] {
        foreach {type src charset script defer} $scripts($name) {
            template::multirow append script \
                $type \
                $src \
                $charset \
                $defer \
                $content
        }
    }
}

# Generate the body <script /> tag multirow
variable ::template::body_scripts
template::multirow create body_script type src charset defer content
if {[info exists body_scripts]} {
    foreach {type src charset script defer} $body_scripts {
        template::multirow append body_script \
            $type \
            $src \
            $charset \
            $defer \
            $content
    }
}

# Concatenate the javascript event handlers for the body tag
variable ::template::body_handlers
if {[array exists body_handlers]} {
    set names [array names body_handlers]

    foreach name $names {
        set event [lindex [split $name ","] 0]

        foreach javascript $body_handlers($name) {
            lappend body_handlers($event) "[string trimright $javascript "; "];"
        }

        unset body_handlers($name)
     }
}

# Now create the event handlers string
foreach {event script} [array get body_handlers] {
    append event_handlers " ${event}=\"$script\""
}
 
# Generate the body headers
variable ::template::headers
set header [list]
if {[info exists headers]} {
    foreach {type src params} $headers {
        if {$type eq "literal"} {
            lappend header $src
        } else {
            lappend header [template::adp_include $src $params]
        }
    }
}

# Generate the body footers
variable ::template::footers
set footer [list]
if {[info exists footers]} {
    foreach {type src params} $footers {
        if {$type eq "literal"} {
            lappend footer $src
        } else {
            lappend footer [template::adp_include $src $params]
        }
    }
}