# packages/acs-content-repository/tcl/image-procs.tcl

ad_library {
    
    Procedures to handle image subtype
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2006-07-31
    @cvs-id $Id$
}

namespace eval image:: {}

ad_proc -public image::new {
    {-name ""}
    {-parent_id ""}
    {-item_id ""}
    {-locale ""}
    {-creation_date ""}
    {-creation_user ""}
    {-context_id ""}
    {-package_id ""}
    {-creation_ip ""}
    {-item_subtype "content_item"}
    {-content_type "content_revision"}
    {-title ""}
    {-description ""}
    {-mime_type ""}
    {-relation_tag ""}
    {-is_live ""}
    {-storage_type "file"}
    {-attributes ""}
    {-tmp_filename ""}
} {
     Create a new image object from a temporary file
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2006-07-31
    
    @param item_id Item id of the content item for this image. The
                   item_id will be generated from the acs_object_id
                   sequence if not specified.

    @param parent_id Parent object for this image. Context_id will be
                     set to parent_id

    @param name      Name of image item, must be unique per parent_id

    @param tmp_filename Filename in the filesystem, readable by
                        AOLserver user to create image from

    @return          Item_id
    
    @error 
} {

    return [content::item::new \
                -name $name \
                -parent_id $parent_id \
                -item_id $item_id \
                -locale $locale \
                -creation_date $creation_date \
                -creation_user $creation_user \
                -context_id $context_id \
                -package_id $package_id \
                -creation_ip $creation_ip \
                -item_subtype $item_subtype \
                -content_type "image" \
                -title $title \
                -description $description \
                -mime_type $mime_type \
                -relation_tag $relation_tag \
                -is_live $is_live \
                -storage_type "file" \
                -attributes $attributes \
                -tmp_filename $tmp_filename]
}




