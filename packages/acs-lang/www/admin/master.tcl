ad_page_contract {
    Master template for gp-lang admin pages.

    @ author Alex Sokoloff <alex_sokoloff@yahoo.com>
    @ creation-date 20020910
    @ cvs-id $Id$
} -properties {
    encoding_charset:onevalue
}

#set encoding_charset [gp_determine_charset]

# LARS:
set encoding_charset ""

ad_return_template
