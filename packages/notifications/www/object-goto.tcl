ad_page_contract {
    go to an object

    @author Tracy Adams (teadams@alum.mit.edu)
    @creation-date 22 July 2002
    @cvs-id $Id$
} {
    object_id:notnull
} 


# At the time of writing, the only supported
# notification types were on the object types
# forum_forums and forum_messages.  get_url
# will handle both these types.  If there are
# more type of notifications added, this file
# has to be changed to handle them.  Perhaps
# it could be handles in a generic way, using 
# meta-data about the object_type to auto-generate
# the url.

ad_returnredirect [forum::notification::get_url $object_id]

