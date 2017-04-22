ad_library {
    Procs for the list builder.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-05-16
    @cvs-id $Id$
}

namespace eval template {}
namespace eval template::list {}
namespace eval template::list::element {}
namespace eval template::list::filter {}
namespace eval template::list::format {}
namespace eval template::list::orderby {}


#####
#
# template::list namespace
#
#####

ad_proc -public template::list::create {
    {-name:required}
    {-multirow ""}
    {-key ""}
    {-pass_properties ""}
    {-actions ""}
    {-bulk_actions ""}
    {-bulk_action_method "get"}
    {-bulk_action_export_vars ""}
    {-selected_format ""}
    {-has_checkboxes:boolean}
    {-checkbox_name "checkbox"}
    {-orderby_name "orderby"}
    {-row_pretty_plural "#acs-templating.data#"}
    {-no_data ""}
    {-main_class "list-table"}
    {-sub_class ""}
    {-class ""}
    {-html ""}
    {-caption ""}
    {-page_size ""}
    {-page_size_variable_p 0}
    {-page_groupsize 10}
    {-page_query ""}
    {-page_query_name ""}
    {-page_flush_p 0}
    {-ulevel 1}
    {-elements:required}
    {-filters ""}
    {-groupby ""}
    {-orderby ""}
    {-formats ""}
    {-filter_form 0}
    {-bulk_action_click_function "acs_ListBulkActionClick"}
} {
    Defines a list to be diplayed in a template. The list works in conjunction with a multirow, which contains the data for the list.
    The list is output using the &lt;listtemplate&gt; and &lt;listfilters&gt; templating tags, with the help of &lt;listelement&gt; and &lt;listrow&gt;.

    <p>

    Here's an example of a fairly simple standard list.

    <pre>
    template::list::create \
        -name order_lines \
        -multirow order_lines \
        -key item_id \
        -actions [list "Add item" [export_vars -base item-add {order_id}] "Add item to this order"] \
        -bulk_actions {
            "Remove" "item-remove" "Remove checked items"
            "Copy" "item-copy" "Copy checked items to clipboard"
        } \
        -bulk_action_method post \
        -bulk_action_export_vars {
            order_id
        } \
        -row_pretty_plural "order items" \
        -elements {
            quantity {
                label "Quantity"
            }
            item_id {
                label "Item"
                display_col item_name
                link_url_col item_url
                link_html { title "View this item" }
            }
            item_price {
                label "Price"
                display_eval {[lc_sepfmt $item_price]}
            }
            extended_price {
                label "Extended Price"
                display_eval {[lc_sepfmt [expr {$quantity $item_price}]]}
            }
        }

    db_multirow -extend { item_url } order_lines select_order_lines {
        select l.item_id,
        l.quantity,
        i.name as item_name,
        i.price as item_price
        from   order_lines l,
        items i
        where  l.order_id = :order_id
        and    i.item_id = l.item_id
    } {
        set item_url [export_vars -base "item" { item_id }]
    }
    </pre>

    And the ADP template would include this:

    <pre>
    &lt;listtemplate name="order_lines"&gt;&lt;/listtemplate&gt;
    </pre>


    @param  name           The name of the list you want to build.

    @param  multirow       The name of the multirow which you want to loop over. Defaults to name of the list.

    @param  key            The name of the column holding the primary key/unique identifier for each row.
    Must be a single column, which must be present in the multirow.
    This switch is required to have bulk actions.

    @param  pass_properties
    A list of variables in the caller's namespace, which should be available to the display_template
    of elements.

    @param  actions        A list of action buttons to display at the top of
    the list in the form (label1 url1 title1 label2 url2 title2 ...).
    The action button will be a simple link to the url.

    @param  bulk_actions   A list of bulk action buttons, operating on the checked rows,
    to display at the bottom of
    the list. The format is (label1 url1 title1 label2 url2 title2 ...).
    A form will be submitted to the url, containing a list of the key values of the checked rows.
    For example, if 'key' is 'message_id', and rows with message_id 2 4 and 9 are chcked, the
    page will get variables message_id=2&message_id=4&message_id=9. The receiving page
    should declare message_id:naturalnum,multiple in its ad_page_contract. Note that the 'message_id'
    local variable will the be a Tcl list.

    @param  bulk_action_method should a bulk action be a "get" or "post"

    @param  bulk_action_export_vars
    A list of additional variables to pass to the receiving page, along with the other variables for
    the selected keys. This is typically useful if the rows in this list are all hanging off of
    one row in a parent table. For example, if this list contains the order lines of one particular
    order, and the primary key of the order lines table is 'order_id, item_id', the key would be
    'item_id', and bulk_action_export_vars would be 'order_id', so together they constitute the
    primary key.

    @param  selected_format
    The currently selected display format. See the 'formats' option.

    @param  has_checkboxes Set this flag if your table already includes the checkboxes for the bulk actions.
    If not, and your list has bulk actions, we will add a checkbox column for you as the first column.

    @param  checkbox_name  You can explicitly name the checkbox column here, so you can refer to it and place it where you
    want it when you specify display formats. Defaults to 'checkbox'. See the 'formats' option.

    @param  row_pretty_plural
    The pretty name of the rows in plural. For example 'items' or 'forum postings'. This is used to
    auto-generate the 'no_data' message to say "No (row_pretty_plural)." Defaults to 'data'. See 'no_data' below.

    @param  no_data        The message to display when the multirow has no rows. Defaults to 'No data.'.

    @param  main_class     The main CSS class to be used in the output. The CSS class is constructed by combining the
    main_class and the sub_class with a dash in between. E.g., main_class could be 'list', and
    sub_class could be 'narrow', in which case the resuling CSS class used would be 'list-narrow'.

    @param  sub_class      The sub-part of the CSS class to use. See 'main_class' option.

    @param  class          Alternatively, you can specify the CSS class directly. If specified, this overrides main_class/sub_class.

    @param  html           HTML attributes to be output for the table tag, e.g. { align right style "background-color: yellow;" }.
    Value should be a Tcl list with { name value name value }

    @param caption         Caption tag that appears right below the table tag. Required for AA. Added 2/27/2007

    @param  page_size      The number of rows to display on each page. If specified, the list will be paginated.

    @param  page_size_variable_p Displays a selectbox to let the user change the number of rows to display on each page. If specified, the list will be paginated.

    @param  page_groupsize The page group size for the paginator. See template::paginator::create for more details.


    @param  page_query     The query to get the row IDs and contexts for the entire result set. See template::paginator::create for details.

    @param  page_query_name
    Alternatively, you can specify a query name. See template::paginator::create for details.

    @param  ulevel         The number of levels to uplevel when doing subst on values for elements, filters, groupbys, orderbys
    and formats below. Defaults to one level up, which means the caller of template::list::create's scope.

    @param elements        The list elements (columns).
    The value should be an array-list of (element-name, spec) pairs, like in the example above. Each spec, in turn, is an array-list of
    property-name/value pairs, where the value is 'subst'ed in the caller's environment, except for the *_eval properties, which are
    'subst'ed in the multirow context.
    See <a href="/api-doc/proc-view?proc=template::list::element::create">template::list::element::create</a> for details.

    @param  filters        Filters for the list. Typically used to slice the data, for example to see only rows by a particular user.
    Array-list of (filter-name, spec) pairs, like elements. Each spec, in turn, is an array-list of property-name/value pairs,
    where the value is 'subst'ed in the caller's environment, except for the *_eval properties, which are 'subst'ed in the multirow context.
    In order for filters to work, you have to specify them in your page's ad_page_contract, typically as filter_name:optional.
    The list builder will find them from there,
    by grabbing them from your page's local variables.
    See <a href="/api-doc/proc-view?proc=template::list::filter::create">template::list::filter::create</a> for details.

    filters are also the mechanism to export state variables which need to be preserved.  If for example you needed user_id to be
    maintained for the filter and sorting links you would add -filters {user_id {}}

    @param  groupby        Things you can group by, e.g. day, week, user, etc. Automatically creates a filter called 'groupby'.
    Single array-list of property-name/value pairs, where the value is 'subst'ed in the caller's environment.
    Groupby is really just a filter with a fixed name, so see above for more details.
    See <a href="/api-doc/proc-view?proc=template::list::filter::create">template::list::filter::create</a> for details.

    @param  orderby        Things you can order by. You can also specify ordering directly in the elements. Automatically creates a filter called 'orderby'.
    Array-list of (orderby-name, spec) pairs, like elements. Each spec, in turn, is an array-list of property-name/value pairs,
    where the value is 'subst'ed in the caller's environment, except for the *_eval properties, which are 'subst'ed in the multirow context.
    If the name of your orderby is the same as the name of an element, that element's header will be made a link to sort by that column.
    See <a href="/api-doc/proc-view?proc=template::list::orderby::create">template::list::orderby::create</a> for details.

    @param  orderby_name   The page query variable name for the selected orderby is normally named 'orderby', but if you want to, you can
    override it here.

    @param  formats        If no formats are specified, a default format is created. Automatically creates a filter called 'format'.
    Array-list of (format-name, spec) pairs, like elements. Each spec, in turn, is an array-list of property-name/value pairs,
    where the value is 'subst'ed in the caller's environment.
    See <a href="/api-doc/proc-view?proc=template::list::format::create">template::list::format::create</a> for details.

    @param filter_form     Whether or not we create the form data structure for the listfilters-form tag to dynamically generate a form to specify filter criteria. Default 0 will not generate form. Set to 1 to generate form to use listfilters-form tag.
    @param bulk_action_click_functon Javascript function name to call when bulk action buttons are clicked.

    @see template::list::element::create
    @see template::list::filter::create
    @see template::list::orderby::create
    @see template::list::format::create
} {
    set level [template::adp_level]

    # Get an upvar'd reference to list_properties
    get_reference -create -name $name

    # Setup some list defaults
    array set list_properties {
        actions {}
        bulk_action_click_function {}
        bulk_action_export_vars {}
        bulk_actions {}
        caption {}
        class {}
        html {}
        key {}
        main_class {list}
        multirow {}
        orderby_name {orderby}
        page_flush_p {}
        page_groupsize {}
        page_query {}
        page_query_name {}
        page_size {}
        page_size_variable_p {}
        style {}
        sub_class {}
    }

    # These are defauls for internally maintained properties
    array set list_properties {
        aggregates_p 0
        bulk_action_export_chunk {}
        display_elements {}
        dynamic_cols_p 0
        element_refs {}
        element_select_clauses {}
        element_where_clauses {}
        elements {}
        filter_refs {}
        filter_select_clauses {}
        filter_where_clauses {}
        filters {}
        filters_export {}
        format_refs {}
        from_clauses {}
        groupby {}
        groupby_label {}
        orderby_refs {}
        orderby_selected_direction {}
        orderby_selected_name {}
        output {}
        page_size_export_chunk {}
        row_template {}
        ulevel {}
        url {}
    }

    # Set default for no_data
    set row_pretty_plural [lang::util::localize $row_pretty_plural]
    set no_data [ad_decode $no_data "" [_ acs-templating.No_row_pretty_plural] $no_data]
    # Set ulevel to the level of the page, so we can access it later
    set list_properties(ulevel) "\#[expr {[info level] - $ulevel}]"

    # Set properties from the parameters passed
    foreach elm {
        actions
        bulk_action_click_function
        bulk_action_export_vars
        bulk_action_method
        bulk_actions
        caption
        class
        html
        key
        main_class
        multirow
        name
        no_data
        orderby_name
        page_flush_p
        page_groupsize
        page_query
        page_query_name
        page_size
        page_size_variable_p
        pass_properties
        row_pretty_plural
        sub_class
    } {
        set list_properties($elm) [set $elm]
    }

    # Default 'class' to 'main_class'
    if { $list_properties(class) eq "" } {
        set list_properties(class) $list_properties(main_class)
    }

    # Default 'multirow' to list name
    if { $list_properties(multirow) eq "" } {
        set list_properties(multirow) $name
    }

    # Set up automatic 'checkbox' element as the first element
    if { !$has_checkboxes_p && [llength $bulk_actions] > 0 } {
        if { $key eq "" } {
            error "You cannot have bulk_actions without providing a key for list '$name'"
        }
        # Create the checkbox element
        set label [subst {
            <input type="checkbox" name="_dummy" id="$name-bulkaction-control" title="[_ acs-templating.lt_Checkuncheck_all_rows]">
        }]
        template::add_event_listener \
            -id $name-bulkaction-control \
            -preventdefault=false \
            -script [subst {acs_ListCheckAll('[ns_quotehtml $name]', this.checked);}]
        template::add_event_listener \
            -id $name-bulkaction-control \
            -event keypress \
            -preventdefault=false \
            -script [subst {acs_ListCheckAll('[ns_quotehtml $name]', this.checked);}]

        if {[info exists ::__csrf_token]} {
            append label [subst {<input type="hidden" name="__csrf_token" value="$::__csrf_token">}]
        }
        
        # We only ulevel 1 here, because we want the subst to be done in this namespace
        template::list::element::create \
            -list_name $name \
            -element_name $checkbox_name \
            -spec {
                label $label
                display_template {<input type="checkbox" name="$key" value="@$list_properties(multirow).$key@"
                    id="$name.@$list_properties(multirow).$key@" title="[_ acs-templating.lt_Checkuncheck_this_row]">}
                sub_class {narrow}
                html { align center }
            }
    }

    # Define the elements
    foreach { elm_name elm_spec } $elements {
        # Create the element
        # Need to uplevel 2 the subst command to get to our caller's namespace

        template::list::element::create \
            -list_name $name \
            -element_name $elm_name \
            -spec $elm_spec \
            -ulevel 2
    }
    set reserved_filter_names { groupby orderby format page }

    # Handle filters
    foreach { dim_name dim_spec } $filters {
        if { [lsearch $reserved_filter_names $dim_name] != -1 } {
            error "The name '$dim_name' is a reserved filter name, list '$name'. Reserved names are [join $reserved_filter_names ", "]."
        }
        template::list::filter::create \
            -list_name $name \
            -filter_name $dim_name \
            -spec $dim_spec \
            -ulevel 2
    }

    # Groupby (this is also a filter, but a special one)
    if { [llength $groupby] > 0 } {
        template::list::filter::create \
            -list_name $name \
            -filter_name "groupby" \
            -spec $groupby \
            -ulevel 2
    }

    # Orderby
    if { [llength $orderby] > 0 } {

        set filter_default {}

        foreach { orderby_name orderby_spec } $orderby {
            if {$orderby_name eq "default_value"} {
                set filter_default $orderby_spec
            } else {
                template::list::orderby::create \
                    -list_name $name \
                    -orderby_name $orderby_name \
                    -spec $orderby_spec \
                    -ulevel 2
            }
        }

        template::list::filter::set_property \
            -list_name $name \
            -filter_name $list_properties(orderby_name) \
            -property default_value \
            -value $filter_default \
            -ulevel 2
    }

    # Formats
    if { [llength $formats] > 0 } {
        set filter_values {}
        foreach { format_name format_spec } $formats {
            lappend filter_values [template::list::format::create \
                                       -list_name $name \
                                       -format_name $format_name \
                                       -selected_format $selected_format \
                                       -spec $format_spec \
                                       -ulevel 2]
        }
        set filter_spec [list label [_ acs-templating.Formats] values $filter_values has_default_p 1]

        template::list::filter::create \
            -list_name $name \
            -filter_name "format" \
            -spec $filter_spec \
            -ulevel 2
    }

    # Pagination
    if { $list_properties(page_size_variable_p) == 1 } {
        # Create a filter for the variable page size
        template::list::filter::create \
            -list_name $name \
            -filter_name "page_size" \
            -spec [list label "[_ acs-templating.Page_Size]" default_value 20 hide_p t]
    }

    if { ($list_properties(page_size) ne "" && $list_properties(page_size) != 0) || $list_properties(page_size_variable_p) == 1 } {
        # Check that we have either page_query or page_query_name
        if { $list_properties(page_query) eq "" && $list_properties(page_query_name) eq "" } {
            error "[_ acs-templating.lt_When_specifying_a_non]"
        }

        # We create the selected page as a filter, so we get the filter,page thing out
        template::list::filter::create \
            -list_name $name \
            -filter_name "page" \
            -spec [list label "[_ acs-templating.Page]" default_value 1 hide_p t]
    }

    # Done, prepare the list. This has to be done while we still have access to the caller's scope
    prepare \
        -name $name \
        -ulevel 2
}

ad_proc -public template::list::prepare {
    {-name:required}
    {-ulevel 1}
} {
    Prepare list for rendering
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    # Default the display_elements property to be all elements
    if { [llength $list_properties(display_elements)] == 0 } {
        set list_properties(display_elements) $list_properties(elements)
    }

    # Set the bulk_action_export_chunk
    if { $list_properties(bulk_action_export_vars) ne "" } {
        set list_properties(bulk_action_export_chunk) [uplevel $list_properties(ulevel) \
                                                           [list export_vars -form $list_properties(bulk_action_export_vars)]]
    }

    # This sets urls, selected_p, etc., for filters, plus sets the (filter,name) var in list_properties
    upvar filter_form filter_form
    if {$filter_form} {
        prepare_filter_form -name $name
    }

    prepare_filters \
        -name $name

    # Split the current ordering info into name and direction
    # name is the string before the comma, order (asc/desc) is what's after
    if { [info exists list_properties(filter,$list_properties(orderby_name))] } {
        foreach { orderby_name orderby_direction } \
            [lrange [split $list_properties(filter,$list_properties(orderby_name)) ","] 0 1] {}

        set list_properties(orderby_selected_name) $orderby_name

        if { $orderby_direction eq "" } {

            if {[catch {
                template::list::orderby::get_reference \
                    -list_name $name \
                    -orderby_name $orderby_name
            } errorMsg]} {
                ad_page_contract_handle_datasource_error $errorMsg
                ad_script_abort
            }

            set orderby_direction $orderby_properties(default_direction)
        }
        set list_properties(orderby_selected_direction) $orderby_direction
    }

    # This sets orderby, etc., for filters
    prepare_elements \
        -name $name \
        -ulevel [expr {$ulevel + 1}]

    # Make groupby information available to templates
    if { [exists_and_not_null list_properties(filter,groupby)] } {
        set list_properties(groupby) $list_properties(filter,groupby)
    }
    if { [exists_and_not_null list_properties(filter_label,groupby)] } {
        set list_properties(groupby_label) $list_properties(filter_label,groupby)
    }

    # Create the paginator
    if { $list_properties(page_size_variable_p) == 1 } {
        set list_properties(page_size) $list_properties(filter,page_size)
        set list_properties(url) [ad_conn url]
        set list_properties(page_size_export_chunk) [uplevel $list_properties(ulevel) [list export_vars -form -exclude {page_size page} $list_properties(filters_export)]]
    }

    if { $list_properties(page_size) ne "" && $list_properties(page_size) != 0 } {

        if {$list_properties(page_query) eq ""} {
            # We need to uplevel db_map it to get the query from the right context
            set list_properties(page_query_substed) \
                [uplevel $list_properties(ulevel) [list db_map $list_properties(page_query_name)]]
        } else {
            # We need to uplevel subst it so we get the filters evaluated
            set list_properties(page_query_substed) \
                [uplevel $list_properties(ulevel) \
                     [list subst -nobackslashes $list_properties(page_query)]]
        }

        # Use some short variable names to make the expr readable
        set page $list_properties(filter,page)
        set groupsize $list_properties(page_groupsize)
        set page_size $list_properties(page_size)
        set page_group [expr {($page - 1 - (($page - 1) % $groupsize)) / $groupsize + 1}]
        set first_row [expr {($page_group - 1) * $groupsize * $page_size + 1}]
        set last_row [expr {$first_row + ($groupsize + 1) * $page_size - 1}]
        set page_offset [expr {($page_group - 1) * $groupsize}]

        # Antonio Pisano 2015-11-17: From now on, the original query 
        # will be tampered with the limit information, so this is our 
        # last chance to save it and use it to get the full row count in
        # the paginator.
        set list_properties(page_query_original) $list_properties(page_query_substed)
        
        # Now wrap the provided query with the limit information
        set list_properties(page_query_substed) [db_map pagination_query]

        # Generate a paginator name which includes the page group we're in 
        # and all the filter values, so the paginator cahing works properly
        # Antonio Pisano 2015-11-17: it is important that the paginator_name starts with the list's 
        # name, because we count on this in template::paginator::create to retrieve the count_query
        set paginator_name $list_properties(name)

        foreach filter $list_properties(filters) {
            if { $filter ne "page" && [info exists list_properties(filter,$filter)] } {
                append paginator_name ",$filter=$list_properties(filter,$filter)"
            }
        }

        append paginator_name ",page_group=$page_group"
        set list_properties(paginator_name) $paginator_name

        set flush_p f
        if { [template::util::is_true $list_properties(page_flush_p)] } {
            set flush_p t
        }

        # We need this uplevel so that the bind variables in the query
        # will get bound at the caller's level
        # we pass in a dummy query name because the query text was
        # already retrieved previously with db_map so this call
        # always passes the full query text and not the query name
        # this was failing if the template::list call contained a
        # page_query with an empty page_query_name
        uplevel $ulevel [list template::paginator create \
                             --dummy--query--name-- \
                             $list_properties(paginator_name) \
                             $list_properties(page_query_substed) \
                             -pagesize $list_properties(page_size) \
                             -groupsize $list_properties(page_groupsize) \
                             -page_offset $page_offset \
                             -flush_p $flush_p \
                             -contextual]

        if { $list_properties(filter,page) > [template::paginator get_page_count $list_properties(paginator_name)] } {
            set list_properties(filter,page) [template::paginator get_page_count $list_properties(paginator_name)]
        }

    }
}

ad_proc -public template::list::get_refname {
    {-name:required}
} {
    Return a canonical name for the given list template.
} {
    return "$name:properties"
}

ad_proc -public template::list::get_reference {
    {-name:required}
    {-local_name "list_properties"}
    {-create:boolean}
} {
    Bind an upvar reference to a variable at the template parse level to a local
    variable, optionally giving an error message if it doesn't exist.

    @param name Name of the variable at the template parse level.
    @param local_name Name of the local variable to bind the reference to, default
    "list_properties".
    @param create Boolean which if true suppresses the "not found" error return, for
    instance when you're building the reference in order to create a new
    list.

} {
    if {$name eq ""} {
        error "Attempt to get reference to an empty name."
    }
    set refname [get_refname -name $name]

    if { !$create_p && ![uplevel \#[template::adp_level] [list info exists $refname]] } {
        error "List '$name' not found"
    }

    uplevel upvar #[template::adp_level] $refname $local_name
}

ad_proc -private template::list::get_url {
    {-name:required}
    {-override ""}
    {-exclude ""}
} {
    Build a URL for the current page with query variables set for the various filters
    active for the named list.

    @param name The name of the list
    @param override Values that export_vars should override
    @param exclude Values that export_vars should not put in the query string

    @return The current page's URL decorated with the computed query string
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    return [uplevel $list_properties(ulevel) \
                [list export_vars \
                     -base [ad_conn url] \
                     -exclude $exclude \
                     -override $override \
                     $list_properties(filters_export)]]
}


ad_proc -public template::list::filter_from_clauses {
    -name:required
    -comma:boolean
} {
    @param  and     Set this flag if you want the result to start with an ',' if the list of from clauses returned is non-empty.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { [llength $list_properties(filter_from_clauses)] == 0 } {
        return {}
    }

    set result {}
    if { $comma_p } {
        append result ", "
    }
    append result [join $list_properties(filter_from_clauses) "\n , "]

    return $result
}

ad_proc -public template::list::filter_select_clauses {
    -name:required
    -comma:boolean
} {
    @param  and     Set this flag if you want the result to start with a ',' if the list of select clauses returned is non-empty.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { [llength $list_properties(filter_select_clauses)] == 0 } {
        return {}
    }

    set result {}
    if { $comma_p } {
        append result ", "
    }
    append result [join $list_properties(filter_select_clauses) "\n , "]

    return $result
}

ad_proc -public template::list::from_clauses {
    -name:required
    -comma:boolean
} {
    @param  and     Set this flag if you want the result to start with an ',' if the list of from clauses returned is non-empty.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { [llength $list_properties(from_clauses)] == 0 } {
        return {}
    }
    set trimmed_from_clauses [list]

    set result {}

    if { [string trim "[lindex $list_properties(from_clauses) 0]"] ne "" && $comma_p && ![string match "left*" [string trim [lindex $list_properties(from_clauses) 0]]]} {
        append result ", "
    }
    set i 0
    foreach elm $list_properties(from_clauses) {

        if {([string trim $elm] ne "" && ![string match "left*" [string trim $elm]]) \
                && ($comma_p || $i > 0)} {
            append results ","
        }
        append result " $elm"
        incr i
    }
    #    append result [join $list_properties(from_clauses) "\n , "]

    return $result
}

ad_proc -public template::list::element_select_clauses {
    -name:required
    -comma:boolean
} {
    @param  and     Set this flag if you want the result to start with a ',' if the list of select clauses returned is non-empty.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { [llength $list_properties(element_select_clauses)] == 0 } {
        return {}
    }

    set result {}
    if { $comma_p } {
        append result ", "
    }
    append result [join $list_properties(element_select_clauses) "\n , "]

    return $result
}

ad_proc -public template::list::filter_where_clauses {
    -name:required
    -and:boolean
} {
    @param  and     Set this flag if you want the result to start with an 'and' if the list of where clauses returned is non-empty.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { [llength $list_properties(filter_where_clauses)] == 0 } {
        return {}
    }

    set result {}
    if { $and_p } {
        append result "and "
    }
    append result [join $list_properties(filter_where_clauses) "\n and "]
    return $result
}

ad_proc -public template::list::element_where_clauses {
    -name:required
    -and:boolean
} {
    @param  and     Set this flag if you want the result to start with an 'and' if the list of where clauses returned is non-empty.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { [llength $list_properties(element_where_clauses)] == 0 } {
        return {}
    }

    set result {}
    if { $and_p } {
        append result "and "
    }
    append result [join $list_properties(element_where_clauses) "\n and "]

    return $result
}

ad_proc -public template::list::page_where_clause {
    -name:required
    -and:boolean
    {-key}
} {
    @param  and     Set this flag if you want the result to start with an 'and' if the list of where clauses returned is non-empty.

    @param key      Specify the name of the primary key to be used in the query's where clause,
    if different from the list builder's key.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { $list_properties(page_size) eq "" || $list_properties(page_size) == 0 } {
        return {}
    }

    set result {}

    if { $and_p } {
        append result "and "
    }

    if { (![info exists key] || $key eq "") } {
        set key $list_properties(key)
    }

    append result "$key in ([page_get_ids -name $name])"

    return $result
}

ad_proc -public template::list::write_output {
    -name:required
} {
    Writes the output to the connection if output isn't set to template.
    Will automatically issue an ad_script_abort, if the output has been written
    directly to the connection instead of through the templating system.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    switch $list_properties(output) {
        csv {
            write_csv -name $name
            ad_script_abort
        }
    }
}

ad_proc -public template::list::csv_quote {
    string
} {
    Quote a string for inclusion as a csv element
} {
    regsub -all {\"} $string {""} result
    return $result
}

ad_proc -public template::list::write_csv {
    -name:required
} {
    Writes a CSV to the connection
} {
    # Creates the '_eval' columns and aggregates
    template::list::prepare_for_rendering -name $name

    get_reference -name $name

    set __list_name $name
    set __output {}
    set __groupby $list_properties(groupby)

    # Output header row
    set __cols [list]
    set __csv_cols [list]
    set __csv_labels [list]

    foreach __element_name $list_properties(elements) {
        template::list::element::get_reference -list_name $name -element_name $__element_name
        if {!$element_properties(hide_p)} {
            lappend __csv_cols $__element_name
            lappend __csv_labels [csv_quote $element_properties(label)]
        }
    }
    append __output "\"[join $__csv_labels "\",\""]\"\n"

    set __rowcount [template::multirow size $list_properties(multirow)]
    set __rownum 0
    # Output rows
    template::multirow foreach $list_properties(multirow) {
        set group_lastnum_p 0
        if {$__groupby ne ""} {
            if {$__rownum < $__rowcount} {
                # check if the next row's group column is the same as this one
                set next_group [template::multirow get $list_properties(multirow) [expr {$__rownum + 1}] $__groupby]
                if {[set $__groupby] ne $next_group} {
                    set group_lastnum_p 1
                }
            } else {
                set group_lastnum_p 1
            }
            incr __rownum
        }

        if {$__groupby eq "" \
                || $group_lastnum_p} {
            set __cols [list]

            foreach __element_name $__csv_cols {
                if {![string match "*___*_group" $__element_name]} {
                    template::list::element::get_reference \
                        -list_name $__list_name \
                        -element_name $__element_name \
                        -local_name __element_properties
                    if { [info exists $__element_properties(csv_col)] } {
                        lappend __cols [csv_quote [set $__element_properties(csv_col)]]
                    } else {
                        lappend __cols [csv_quote [set $__element_name]]
                    }
                } {
                    lappend __cols [csv_quote [set $__element_name]]
                }
            }
            append __output "\"[join $__cols "\",\""]\"\n"
        }
    }
    set oh [ns_conn outputheaders]
    ns_set put $oh Content-Disposition "attachment; filename=${__list_name}.csv"
    ns_return 200 text/csv $__output
}


ad_proc -public template::list::page_get_ids {
    -name:required
    -tcl_list:boolean
} {
    @param  name     Name of the list builder list for which you want the IDs of the current page.
    @param  tcl_list Set this option if you want the IDs as a Tcl list. Otherwise, they'll be returned as a
    quoted SQL list, ready to be included in an "where foo_id in (...)" expression.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { $list_properties(page_size) eq "" || $list_properties(page_size) == 0 } {
        return {}
    }

    set ids [template::paginator get_row_ids $list_properties(paginator_name) $list_properties(filter,page)]

    if { $tcl_list_p } {
        return $ids
    } else {
        if { [llength $ids] == 0 } {
            return NULL
        }
        set quoted_ids [list]
        foreach one_id $ids {
            lappend quoted_ids "'[DoubleApos $one_id]'"
        }
        return [join $quoted_ids ","]
    }
}

ad_proc -public template::list::page_get_rowcount {
    -name:required
} {
    Gets the number of rows across all pages in a paginated result set.

    @param  name     Name of the list builder list for which you want the number of rows in the result set.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { $list_properties(page_size) eq "" || $list_properties(page_size) == 0 } {
        return {}
    }

    return [template::paginator get_row_count $list_properties(paginator_name)]
}

ad_proc -public template::list::get_rowcount {
    -name:required
} {
    Gets the full number of rows retrieved from this template::list. This number can
    exceed number_of_pages * rows_per_page. If list is not paginated, size of the
    multirow will be returned. Multirow must exist for count to succeed on a not
    paginated list.

    @param  name     Name of the list builder list for which you want the full number of rows.
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { $list_properties(page_size) eq "" || $list_properties(page_size) == 0 } {
        if {![template::multirow exists {*}$list_properties(multirow)]} {
            return {}
        }
        return [template::multirow size {*}$list_properties(multirow)]
    }

    return [template::paginator get_full_row_count $list_properties(paginator_name)]
}


ad_proc -public template::list::orderby_clause {
    -name:required
    -orderby:boolean
} {
    Get the order by clause for use in your DB query, or returns the empty string if not sorting in the DB.

    @param name List name

    @param  orderby     If this is specified, this proc will also spit out the "order by" part, so it can be used directly
    in the query without saying 'order by' yourself.

} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { $list_properties(orderby_selected_name) eq "" } {
        return {}
    }

    set result {}
    template::list::orderby::get_reference -list_name $name -orderby_name $list_properties(orderby_selected_name)

    if {![info exists orderby_properties(orderby_$list_properties(orderby_selected_direction))]} {
        ad_page_contract_handle_datasource_error "invalid value for orderby: $list_properties(orderby_selected_direction)"
        ad_script_abort
    }
    set result $orderby_properties(orderby_$list_properties(orderby_selected_direction))

    if { $orderby_p && $result ne "" } {
        set result "order by $result"
    }

    return $result
}

ad_proc -public template::list::multirow_cols {
    -name:required
} {
    Get the list of columns to order by, if ordering in web server. Otherwise returns empty string.

    @param name List name
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if { $list_properties(orderby_selected_name) eq "" } {
        return {}
    }

    template::list::orderby::get_reference -list_name $name -orderby_name $list_properties(orderby_selected_name)

    set result [list]
    if {$list_properties(orderby_selected_direction) eq "desc"} {
        lappend result "-decreasing"
    }

    set result [concat $result $orderby_properties(multirow_cols)]

    return $result
}

ad_proc -private template::list::template {
    {-name:required}
    {-style ""}
} {
    Process a list template with the special hacks into becoming a
    'real' ADP template, as if it was included directly in the page.
    Will provide that template with a multirow named 'elements'.
} {
    set level [template::adp_level]

    # Get an upvar'd reference to list_properties
    get_reference -name $name

    #
    # Create 'actions' and 'bulk_actions' multirows
    #

    # Manually construct a multirow by setting the relevant variables
    foreach type { actions bulk_actions } {
        set ${type}:rowcount 0

        foreach { label url title } $list_properties(${type}) {
            incr ${type}:rowcount
            set "${type}:[set "${type}:rowcount"](label)" $label
            set "${type}:[set "${type}:rowcount"](url)" $url
            set "${type}:[set "${type}:rowcount"](title)" $title
            set "${type}:[set "${type}:rowcount"](rownum)" [set "${type}:rowcount"]
        }
    }

    #
    # Create 'elements' multirow
    #

    # Manually construct a multirow by upvar'ing each of the element refs
    set elements:rowcount 0

    foreach element_name $list_properties(display_elements) {
        set element_ref [template::list::element::get_refname \
                             -list_name $name \
                             -element_name $element_name]
        upvar #$level $element_ref element_properties

        if { ![template::util::is_true $element_properties(hide_p)] } {
            incr elements:rowcount

            # get a reference by index for the multirow data source
            upvar #$level $element_ref elements:${elements:rowcount}

            # Also set the rownum pseudocolumn
            set "elements:${elements:rowcount}(rownum)" ${elements:rowcount}
        }
    }

    # Table tag HTML attributes
    set list_properties(table_attributes) [template::list::util_html_to_attributes_string $list_properties(html) 1]

    #
    # Find the list template
    #

    if {$style eq {}} {
        set style $list_properties(style)
    }

    if {$style eq {}} {
        set style [parameter::get \
                       -package_id [ad_conn subsite_id] \
                       -parameter DefaultListStyle \
                       -default [parameter::get \
                                     -package_id [apm_package_id_from_key "acs-templating"] \
                                     -parameter DefaultListStyle \
                                     -default "table"]]
    }

    set file_stub [template::resource_path -type lists -style $style]

    # ensure that the style template has been compiled and is up-to-date
    template::adp_init adp $file_stub

    # get result of template output procedure into __adp_output
    # the only data source on which this template depends is the "elements"
    # multirow data source.  The output of this procedure will be
    # placed in __adp_output in this stack frame.

    template::code::adp::$file_stub

    return $__adp_output
}

ad_proc -private template::list::prepare_for_rendering {
    {-name:required}
} {
    Build all the variable references that are required when rendering a list
    template.

    @param name The name of the list template we hope to be able to render eventually.
} {
    set __level [template::adp_level]

    # Provide a reference to the list properties for use by the list template
    # This one is named __list_properties to avoid getting scrambled by below multirow
    get_reference -name $name -local_name __list_properties

    # Sort in webserver layer, if requested to do so
    set __multirow_cols [template::list::multirow_cols -name $__list_properties(name)]
    if { $__multirow_cols ne "" } {
        template::multirow sort {*}$__list_properties(multirow) {*}$__multirow_cols
    }

    # Upvar other variables passed in through the pass_properties property
    foreach var $__list_properties(pass_properties) {
        upvar #$__level $var $var
    }

    #
    # Dynamic columns: display_eval, link_url_eval, aggregate
    #

    # TODO: If we want to be able to sort by display_eval'd element values,
    # we'll have to do those in a separate run from doing the aggregates.

    if { $__list_properties(dynamic_cols_p) || $__list_properties(aggregates_p) } {
        foreach __element_ref $__list_properties(element_refs) {
            # We don't need to prefix it with __ to become __element_properties here
            # because we're not doing the multirow foreach loop yet.
            upvar #$__level $__element_ref element_properties

            # display_eval, link_url_eval
            foreach __eval_property { display link_url } {
                if { [exists_and_not_null element_properties(${__eval_property}_eval)] } {

                    # Set the display col to the name of the new, dynamic column
                    set element_properties(${__eval_property}_col) "$element_properties(name)___$__eval_property"

                    # And add that column to the multirow
                    template::multirow extend $__list_properties(multirow) $element_properties(${__eval_property}_col)
                }
            }

            # aggregate
            if { ([info exists element_properties(aggregate)] && $element_properties(aggregate) ne "") } {
                # Set the aggregate_col to the name of the new, dynamic column
                set element_properties(aggregate_col) "$element_properties(name)___$element_properties(aggregate)"
                set element_properties(aggregate_group_col) "$element_properties(name)___$element_properties(aggregate)_group"

                # Add that column to the multirow
                template::multirow extend $__list_properties(multirow) $element_properties(aggregate_col)
                template::multirow extend $__list_properties(multirow) $element_properties(aggregate_group_col)

                # Initialize our counters to 0
                set __agg_counter($element_properties(name)) 0
                set __agg_sum($element_properties(name)) 0

                # Just in case, we also initialize our group counters to 0
                set __agg_group_counter($element_properties(name)) 0
                set __agg_group_sum($element_properties(name)) 0
            }
        }
        set __have_groupby [expr { [info exists $__list_properties(groupby)] && [set $__list_properties(groupby)] ne "" }]


        # This keeps track of the value of the group-by column for sub-totals
        set __last_group_val {}

        template::multirow foreach $__list_properties(multirow) {

            foreach __element_ref $__list_properties(element_refs) {
                # We do need to prefix it with __ to become __element_properties here
                # because we are inside the multirow foreach loop yet.
                # LARS: That means we should probably also __-prefix element_ref, eval_property, and others.
                upvar #$__level $__element_ref __element_properties

                # display_eval, link_url_eval
                foreach __eval_property { display link_url } {
                    if { [exists_and_not_null __element_properties(${__eval_property}_eval)] } {
                        set $__element_properties(${__eval_property}_col) [subst $__element_properties(${__eval_property}_eval)]
                    }
                }

                # aggregate
                if { ([info exists __element_properties(aggregate)] && $__element_properties(aggregate) ne "") } {
                    # Update totals
                    incr __agg_counter($__element_properties(name))
                    if {$__element_properties(aggregate) eq "sum" } {
                        set __agg_sum($__element_properties(name)) \
                            [expr {$__agg_sum($__element_properties(name)) +
                                   ([set $__element_properties(name)] ne "" ? [set $__element_properties(name)] : 0)} ]
                    }

                    # Check if the value of the groupby column has changed
                    if { $__have_groupby } {
                        if { $__last_group_val ne [set $__list_properties(groupby)] } {
                            # Initialize our group counters to 0
                            set __agg_group_counter($__element_properties(name)) 0
                            set __agg_group_sum($__element_properties(name)) 0
                        }
                        # Update subtotals
                        incr __agg_group_counter($__element_properties(name))
                        set __agg_group_sum($__element_properties(name)) \
                            [expr {$__agg_group_sum($__element_properties(name)) +
                                   ([string is double [set $__element_properties(name)]] ? [set $__element_properties(name)] : 0)}]
                    }

                    switch $__element_properties(aggregate) {
                        sum {
                            set $__element_properties(aggregate_col) $__agg_sum($__element_properties(name))
                            if { $__have_groupby } {
                                set $__element_properties(aggregate_group_col) $__agg_group_sum($__element_properties(name))
                            }
                        }
                        average {
                            set $__element_properties(aggregate_col) \
                                [expr {$__agg_sum($__element_properties(name)) / $__agg_counter($__element_properties(name))}]
                            if { $__have_groupby } {
                                set $__element_properties(aggregate_group_col) \
                                    [expr {$__agg_sum($__element_properties(name)) / $__agg_group_counter($__element_properties(name))}]
                            }
                        }
                        count {
                            set $__element_properties(aggregate_col) [expr {$__agg_counter($__element_properties(name))}]
                            if { $__have_groupby } {
                                set $__element_properties(aggregate_group_col) \
                                    [expr {$__agg_group_counter($__element_properties(name))}]
                            }
                        }
                        default {
                            error "Unknown aggregate function '$__element_properties(aggregate)'"
                        }
                    }

                    set $__element_properties(aggregate_group_col) [lc_numeric [set $__element_properties(aggregate_group_col)]]
                    set $__element_properties(aggregate_col) [lc_numeric [set $__element_properties(aggregate_col)]]
                }
            }

            # Remember this value of the groupby column
            if { $__have_groupby } {
                set __last_group_val [set $__list_properties(groupby)]
            }
        }
    }
}


ad_proc -private template::list::render {
    {-name:required}
    {-style ""}
} {
    Simple procedure to render HTML from a list template

    (That's a lame joke, Don)

    @param name The name of the list template.
    @param style Style template used to render this list template.

    @return HTML suitable for display by your favorite browser.
} {
    set level [template::adp_level]

    # Creates the '_eval' columns and aggregates
    template::list::prepare_for_rendering -name $name

    # Get an upvar'd reference to list_properties
    get_reference -name $name

    # This gets and actually compiles the dynamic template into the template to use for the output
    # Thus, we need to do the dynamic columns above before this step
    set __adp_output [template -name $name -style $style]

    # set __adp_stub so includes work. Only fully qualified includes will work with this
    set __list_code {
        set __adp_stub ""
    }

    # compile the template (this is the second compilation, if we're using a dynamic template -- I think)
    append __list_code [template::adp_compile -string $__adp_output]

    # Paginator
    if { $list_properties(page_size_variable_p) == 1 } {
        template::util::list_to_multirow page_sizes {{name 10 value 10} {name 20 value 20} {name 50 value 50} {name 100 value 100}}
    }

    if { $list_properties(page_size) ne "" && $list_properties(page_size) != 0 } {

        set current_page $list_properties(filter,page)

        template::paginator get_display_info $list_properties(paginator_name) paginator $current_page

        # Set the URLs which the next/prev page/group links should point to
        foreach elm { next_page previous_page next_group previous_group } {
            if { ([info exists paginator($elm)] && $paginator($elm) ne "") } {
                set paginator(${elm}_url) [get_url \
                                               -name $list_properties(name) \
                                               -override [list [list page $paginator($elm)]]]
            }
        }

        # LARS HACK:
        # Use this if you want to display the pages around the currently selected page,
        # with num_pages pages before and num_pages after the currently selected page.
        # This is an alternative to 'groups' of pages, and should eventually be built
        # into paginator, should we decide that this is a nicer way to do things
        # (I stole the idea from Google).
        # However, for now, it's just commented out with an if 0 ... block.
        if 0 {
            set num_pages 11
            set pages [list]
            for { set i [expr {$current_page - $num_pages}] } { $i < $current_page + $num_pages } { incr i } {
                if { $i > 0 && $i <= $paginator(page_count) } {
                    lappend pages $i
                }
            }
        }

        set pages [template::paginator get_pages \
                       $list_properties(paginator_name) \
                       $paginator(current_group)]

        template::paginator get_context \
            $list_properties(paginator_name) \
            paginator_pages \
            $pages

        # Add URL to the pages
        template::multirow -local extend paginator_pages url

        template::multirow -local foreach paginator_pages {
            set url [get_url -name $list_properties(name) -override [list [list page $page]]]
        }

        # LARS HACK:
        # This gets info for all the groups, in case you want to display all the groups available
        # We don't currently do this, so I've commented it out with an if 0 ... block
        if 0 {
            template::paginator get_context \
                $list_properties(paginator_name) \
                paginator_groups \
                [template::paginator get_groups activities $paginator(current_group) $list_properties(page_groupsize)]
        }
    }

    # Get the multirow upvar'd to this namespace
    template::multirow upvar $list_properties(multirow)

    # Upvar other variables passed in through the pass_properties property
    foreach var $list_properties(pass_properties) {
        upvar #$level $var $var
    }

    # evaluate the code and return the rendered HTML for the list
    set __output [template::adp_eval __list_code]

    return $__output
}

ad_proc -private template::list::render_row {
    {-name:required}
} {
    Render one row of a list template.
} {
    set level [template::adp_level]

    # Get an upvar'd reference to list_properties
    get_reference -name $name

    set __adp_output $list_properties(row_template)

    # compile the template (this is the second compilation, if we're using a dynamic template -- I think)
    set __list_code [template::adp_compile -string $__adp_output]

    # Get the multirow upvar'd to this namespace
    template::multirow upvar $list_properties(multirow)

    # Upvar other variables passed in through the pass_properties property
    foreach var $list_properties(pass_properties) {
        upvar #$level $var $var
    }

    # Get the list definition upvar'd to this namespace
    upvar #$level [get_refname -name $name] [get_refname -name $name]
    foreach element_ref $list_properties(element_refs) {
        upvar #$level $element_ref $element_ref
    }

    # evaluate the code and return the rendered HTML for the list
    set output [template::adp_eval __list_code]

    return $output
}



ad_proc -private template::list::prepare_elements {
    {-name:required}
    {-ulevel 1}
    {-elements}
} {
    Builds urls, selected_p, etc., for filters
} {
    # Get an upvar'd reference to list_properties
    get_reference -name $name
    if {![info exists elements]} {
        set elements $list_properties(elements)
    }
    foreach element_name $elements {
        template::list::element::get_reference -list_name $name -element_name $element_name

        if { $element_properties(default_direction) ne "" } {

            if {$list_properties(orderby_selected_name) eq $element_name} {
                # We're currently ordering on this column
                set direction [ad_decode $list_properties(orderby_selected_direction) "asc" "desc" "asc"]
                set element_properties(orderby_url) [get_url \
                                                         -name $name \
                                                         -override [list [list $list_properties(orderby_name) "${element_name},$direction"]]]
                set element_properties(orderby_html_title) [_ acs-templating.reverse_sort_order_of_label [list label $element_properties(label)]]
                set element_properties(ordering_p) "t"
                set element_properties(orderby_direction) $list_properties(orderby_selected_direction)

            } else {
                # We're not currently ordering on this column
                set element_properties(orderby_url) [get_url \
                                                         -name $name \
                                                         -override [list [list $list_properties(orderby_name) "${element_name},$element_properties(default_direction)"]]]
                set element_properties(orderby_html_title) [_ acs-templating.sort_the_list_by_label [list label $element_properties(label)]]
            }
        }

        # support dynamic coluumns
        if {!$element_properties(hide_p)} {
            if {$element_properties(from_clause_eval) ne ""} {
                set evaluated_from_clause [uplevel $list_properties(ulevel) $element_properties($property)]
                if {[lsearch $list_properties(from_clauses) $evaluated_from_clause] < 0} {
                    lappend list_properties(from_clauses) $evaluated_from_clause
                }
            } elseif {$element_properties(from_clause) ne "" \
                          && [lsearch $list_properties(from_clauses) $element_properties(from_clause)] < 0} {
                lappend list_properties(from_clauses) $element_properties(from_clause)
            }
            # get the select clause
            if {$element_properties(select_clause_eval) ne "" \
                    && [lsearch $list_properties(element_select_clauses) [string trim  [uplevel $list_properties(ulevel) $element_properties(select_clause_eval)]]] < 0} {
                lappend list_properties(element_select_clauses) [uplevel $list_properties(ulevel) $element_properties(select_clause_eval)]
            } elseif {$element_properties(select_clause) ne "" \
                          && [lsearch $list_properties(element_select_clauses) [string trim $element_properties(select_clause)]] < 0} {
                lappend list_properties(element_select_clauses) $element_properties(select_clause)
            }
            # get the where clause
            if {$element_properties(where_clause_eval) ne "" \
                    && [lsearch $list_properties(element_where_clauses) [string trim [uplevel $list_properties(ulevel) $element_properties(where_clause_eval)]]] < 0} {
                lappend list_properties(element_where_clauses) [uplevel $list_properties(ulevel) $element_properties(where_clause_eval)]
            } elseif {$element_properties(where_clause) ne "" \
                          && [lsearch $list_properties(element_where_clauses) [string trim $element_properties(where_clause)]] < 0} {
                lappend list_properties(element_where_clauses) $element_properties(where_clause)
            }
        }
    }
}


ad_proc -private template::list::prepare_filters {
    {-name:required}
    {-filter_names}
} {
    Builds urls, selected_p, etc., for filters
} {
    set level [template::adp_level]

    # Get an upvar'd reference to list_properties
    get_reference -name $name

    if {[info exists filter_names]} {
        set filter_refs [list]
        foreach filter_name $filter_names {
            lappend filter_refs ${name}:filter:${filter_name}:properties
        }

    } else {
        set filter_refs $list_properties(filter_refs)
    }
    # Construct URLs for the filters now, while we still have access to the caller's namespace
    foreach filter_ref $list_properties(filter_refs) {
        upvar #$level $filter_ref filter_properties

        upvar $list_properties(ulevel) $filter_properties(name) current_filter_value

        # Set to default value if undefined
        if { (![info exists current_filter_value] || $current_filter_value eq "") && $filter_properties(default_value) ne "" } {
            set current_filter_value $filter_properties(default_value)
        }

        # Does the filter have a current value?
        if { [info exists current_filter_value] } {

            # Get the where clause
            if { $current_filter_value eq "" } {
                set search_order { null_where_clause_eval null_where_clause where_clause_eval where_clause }
            } else {
                set search_order { where_clause_eval where_clause }
            }

            foreach property $search_order {
                if { $filter_properties($property) ne "" } {
                    # We've found a where_clause to include

                    if { [string match "*_eval" $property] } {
                        # It's an _eval, subst it now
                        lappend list_properties(filter_where_clauses) \
                            [uplevel $list_properties(ulevel) $filter_properties($property)]
                    } else {
                        # Not an eval, just add it straight
                        lappend list_properties(filter_where_clauses) $filter_properties($property)
                    }
                    break
                }
            }
            # Get the clear_url
            if { ![template::util::is_true $filter_properties(has_default_p)] }\
                {
                    set filter_properties(clear_url) [get_url \
                                                          -name $name \
                                                          -exclude [list $filter_properties(name)]]
                }
            # Remember the filter value
            set list_properties(filter,$filter_properties(name)) $current_filter_value
            # get the from clause
            # check if there is a dynamic column
            # see if we have an element with the same name
            if {[lsearch $list_properties(elements) $filter_properties(name)] > -1} {
                template::list::element::get_reference -list_name $name -element_name $filter_properties(name)

                if {[info exists element_properties(from_clause_eval)] && $element_properties(from_clause_eval) ne "" && [lsearch $list_properties [string trim [uplevel $list_properties(ulevel) $filter_properties($property)]]] < 0} {
                    lappend list_properties(from_clauses) [uplevel $list_properties(ulevel) $filter_properties($property)]
                } elseif {[info exists element_properties(from_clause)] && $element_properties(from_clause) ne "" && [lsearch $list_properties(from_clauses) [string trim $element_properties(from_clause)]] < 0} {
                    lappend list_properties(from_clauses) [string trim $filter_properties(from_clause)]
                }
            }
            # get the select clause
            if {$filter_properties(select_clause_eval) ne "" \
                    && [lsearch $list_properties(element_select_clauses) $filter_properties(select_clause_eval)] < 0} {
                lappend list_properties(filter_select_clauses) [uplevel $list_properties(ulevel) $filter_properties(select_clause_eval)]
            } elseif {$filter_properties(select_clause) ne "" \
                          && [lsearch $list_properties(element_select_clauses) $filter_properties(select_clause)] < 0} {
                lappend list_properties(filter_select_clauses) $filter_properties(select_clause)
            }
        }

        # If none were found, we may need to provide an 'other' entry below
        set found_selected_p 0

        # Now generate selected_p, urls, add_urls
        foreach elm $filter_properties(values) {

            # Set label and value from the list element
            # We do an lrange here, otherwise values would be set wrong
            # in case someone accidentally supplies a list with too many elements,
            # because then the foreach loop would run more than once
            foreach { label value count } [lrange $elm 0 2] {}

            if { [string trim $label] eq "" } {
                set label $filter_properties(null_label)
            }
            switch $filter_properties(type) {
                singleval {
                    set selected_p [exists_and_equal current_filter_value $value]
                }
                multival {
                    if { (![info exists current_filter_value] || $current_filter_value eq "") } {
                        set selected_p 0
                    } else {
                        # Since here we have multiple values
                        # we set as selected_p the value that match any
                        # of the values present in the list
                        set selected_p 0
                        foreach val $current_filter_value {
                            if { [util_sets_equal_p $val $value] } {
                                set selected_p 1
                                break
                            }
                        }
                    }
                }
                multivar {
                    # Value is a list of { key value } lists
                    # We only check the value whose key matches the filter name
                    set selected_p 0
                    foreach elm $value {
                        foreach { elm_key elm_value } [lrange $elm 0 1] {}
                        if {$elm_key eq $filter_properties(name)} {
                            set selected_p [exists_and_equal current_filter_value $elm_value]
                        }
                    }
                }
            }
            # DAVEB Make multivar actually DO someting
            # set the other vars according to the settings
            if {$selected_p && $filter_properties(type) eq "multivar"} {
                foreach elm $value {
                    foreach { elm_key elm_value } [lrange $elm 0 1] {}
                    if {$elm_key ne $filter_properties(name)} {
                        set list_properties(filter,$elm_key) $elm_value
                    }
                }
            }

            lappend filter_properties(selected_p) $selected_p
            set found_selected_p [expr {$found_selected_p || $selected_p}]

            if { $selected_p } {
                # Remember the filter label
                set list_properties(filter_label,$filter_properties(name)) $label
            }

            # Generate url and add to filter(urls)
            switch $filter_properties(type) {
                singleval - multival {
                    lappend filter_properties(urls) [get_url \
                                                         -name $name \
                                                         -override [list [list $filter_properties(var_spec) $value]]]
                }
                multivar {
                    # We just use the value-list directly
                    lappend filter_properties(urls) [get_url \
                                                         -name $name \
                                                         -override $value]
                }
            }

            # Generate add_url, and add to filter(add_urls)
            if { ([info exists filter_properties(add_url_eval)] && $filter_properties(add_url_eval) ne "") } {
                upvar $list_properties(ulevel) __filter_value __filter_value
                set __filter_value $value
                lappend filter_properties(add_urls) [uplevel $list_properties(ulevel) subst $filter_properties(add_url_eval)]
            }


            # Handle 'other_label'
            if { [info exists current_filter_value] && $current_filter_value ne ""
                 && !$found_selected_p
                 && $filter_properties(other_label) ne ""
             } {
                # Add filter entry with the 'other_label'.
                lappend filter_properties(values) [list $filter_properties(other_label) {}]
                lappend filter_properties(urls) {}
                lappend filter_properties(selected_p) 1
            }
        }
    }
}

ad_proc -private template::list::render_filters {
    {-name:required}
    {-style ""}
} {
    set level [template::adp_level]

    # Provide a reference to the list properties for use by the list template
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    #
    # Create 'filters' multirow
    #

    # Manually construct a multirow by setting the relevant variables
    set filters:rowcount 0
    template::multirow -local create filters \
        filter_name \
        filter_label \
        filter_clear_url \
        label \
        key_value \
        url \
        url_html_title \
        count \
        add_url \
        selected_p \
        type

    foreach filter_ref $list_properties(filter_refs) {

        upvar #$level $filter_ref filter_properties

        if { ![template::util::is_true $filter_properties(hide_p)] } {

            # Loop over 'values' and 'url' simultaneously
            foreach elm $filter_properties(values) url $filter_properties(urls) selected_p $filter_properties(selected_p) add_url $filter_properties(add_urls) {


                # 'label' is the first element, 'value' the second
                # We do an lrange here, otherwise values would be set wrong
                # in case someone accidentally supplies a list with too many elements,
                # because then the foreach loop would run more than once
                foreach { label value count } [lrange $elm 0 2] {}

                if { [string trim $label] eq "" } {
                    set label $filter_properties(null_label)
                }

                if {$filter_properties(type) eq "multival"} {
                    # We need to ns_urlencode the name to work
                    set filter_properties_name [ns_urlencode $filter_properties(name)]
                } else {
                    set filter_properties_name $filter_properties(name)
                }

                template::multirow -local append filters \
                    $filter_properties_name \
                    $filter_properties(label) \
                    $filter_properties(clear_url) \
                    [string_truncate -len 25 -- $label] \
                    $value \
                    $url \
                    $label \
                    $count \
                    $add_url \
                    $selected_p \
                    $filter_properties(type)
            }
        }
    }

    if {$style eq {}} {
        set style [parameter::get \
                       -package_id [apm_package_id_from_key "acs-templating"] \
                       -parameter DefaultListFilterStyle \
                       -default "filters"]
    }
    
    set file_stub [template::resource_path -type lists -style $style]

    # ensure that the style template has been compiled and is up-to-date
    template::adp_init adp $file_stub

    # get result of template output procedure into __adp_output
    # the only data source on which this template depends is the "elements"
    # multirow data source.  The output of this procedure will be
    # placed in __adp_output in this stack frame.

    template::code::adp::$file_stub

    return $__adp_output
}

ad_proc -public template::list::util_html_to_attributes_string {
    html
    {default_summary_p "0"}
} {
    Takes a list in array get format and builds HTML attributes from them.

    @param html A misnomer?  The input isn't HTML, the output is HTML.
    @param default_summary_p Include a default summary if one does not exist

    @return HTML attributes built from the list in array get format

    2/28/2007 - Project Zen - Modifying to handle a default value for summary if default_summary_p = 1
} {
    set output {}
    set summary_exists_p 0
    foreach { key value } $html {
        if { $key eq "summary" } {
            if { $value ne "" } {
                set summary_exists_p 1
                append output " summary=\"[ns_quotehtml $value]\""
            }
        } else {
            if { $value ne "" } {
                append output " [ns_quotehtml $key]=\"[ns_quotehtml $value]\""
            } else {
                append output " [ns_quotehtml $key]"
            }
        }
    }

    if {$default_summary_p && !$summary_exists_p} {
        append output " summary=\"[_ acs-templating.DefaultSummary [list list_name \@list_properties.name\@]]\""
    }

    return $output
}




#####
#
# template::list::element namespace
#
#####

ad_proc -public template::list::element::create {
    {-list_name:required}
    {-element_name:required}
    {-spec:required}
    {-ulevel 1}
} {
    Adds an element to a list builder list.

    <p>

    This proc shouldn't be called directly, only through <a href="/api-doc/proc-view?proc=template::list::create">template::list::create</a>.

    <p>

    These are the available properties in the spec:

    <p>

    <ul>
    <li>
    <b>label</b>: The label to use in the header.
    </li>
    <li>
    <b>hide_p</b>: 1 to hide the element from the default display, 0 (default) to show it.
    </li>
    <li>
    <b>aggregate</b>: Aggregate function to use on this column. Can be 'sum', 'average', or 'count'.
    The aggregate will be displayed at the bottom of the table. If groupby is used, aggregates for each
    group will also be displayed.
    </li>
    <li>
    <b>aggregate_label</b>: The label to use for the aggregate, e.g. "Total".
    </li>
    <li>
    <b>aggregate_group_label</b>: The label to use for the group aggregate, e.g. "Subtotal".
    </li>
    <li>
    <b>html</b>: HTML attributes to be output for the table element, e.g. { align right style "background-color: yellow;" }.
    Value should be a Tcl list with { name value name value }
    </li>
    <li>
    <b>display_col</b>: The column to display for this element, if not the column with the same name as the element.
    </li>
    <li>
    <b>display_template</b>: An ADP chunk used to display the element. This overrides all other display options.
    You can use @multirow_name.column_name@ to get values of the multirow, and you can directly use the variables
    specified in the 'pass_properties' argument to the template::list::create.
    </li>
    <li>
    <b>display_template_name</b>: theme-able template. If a
    display_template_name is specified, and a file with this name is
    available from the ressource directory in the display_templates
    section, then take its countent as display_template. The resouce
    directory is taken from the ResourceDir of the theme (parameter of
    acs-sub-site) or from the "resources" directory in acs-templating.
    The display_template_name acts similar to the query names in
    the database interface: When display_template_name is specified
    and the file is available, it overrules display_template, which
    acts as a default.
    </li>
    <li>
    <b>link_url_col</b>: Name of column in the multirow which contains the URL to which the cell contents should point.
    If either link_url_col or link_url_eval is specified, the cell's contents will be made a link to the specified URL, if that
    URL is non-empty.
    </li>
    <li>
    <b>link_url_eval</b>: A chunk of Tcl code which will be evaluated in the context of a template::multirow foreach looping over the
    dataset multirow, to return the URL to link this cell to. This means that it will have all the columns of the multirow available
    as local variables. Example: link_url_eval {[acs_community_member_url -user_id $creation_user]}.
    </li>
    <li>
    <b>link_html</b>: Attributes to be set on the &lt;a&gt; tag of the link generated as a result of link_url_col or link_url_eval.
    For example link_html { title "View this user" style "background-color: yellow;" }.
    Value should be a Tcl list with { name value name value }
    </li>
    <li>
    <b>csv_col</b>: The column to return in CSV output.
    </li>
    <li>
    <b>sub_class</b>: The second half of the CSS class name. Will be combined with the list's 'main_class' property to form
    the full CSS class name with a dash in-between, as in 'main-sub'.
    </li>
    <li>
    <b>class</b>: Alternatively, you can specify full class here, in which case this will override the sub_class property.
    </li>
    <li>
    <b>orderby</b>: The column to use in the order by clause of the query, when sorting by this column. Specifying either this,
    or 'orderby_asc' and 'orderby_desc' will cause the table's header to become a hyperlink to sort by that column.
    </li>
    <li>
    <b>orderby_asc</b>: If you want to be able to sort by this column, but sorting ascending and descending is not just a matter of
    appending 'asc' or 'desc', you can specify the asc and desc orderby clauses directly. This is useful when you're actually sorting
    by two database columns.
    </li>
    <li>
    <b>orderby_desc</b>: The reverse ordering from 'orderby_asc'.
    </li>
    <li>
    <b>default_direction</b>: The default order direction when ordering by this column, 'asc' or 'desc'.
    </li>
    </ul>

    @param list_name     Name of list.

    @param element_name  Name of the element.

    @param spec          The spec for this filter. This is an array list of property/value pairs, where the right hand side
    is 'subst'ed in the caller's namespace, except for *_eval properties, which are 'subst'ed inside the multirow.

    @param ulevel        Where we should uplevel to when doing the subst's. Defaults to '1', meaning the caller's scope.
} {
    # Get an upvar'd reference to list_properties
    template::list::get_reference -name $list_name

    # Get the list properties
    lappend list_properties(elements) $element_name

    # We store the full element ref name, so its easy to find later
    lappend list_properties(element_refs) [get_refname -list_name $list_name -element_name $element_name]

    # Create the element properties array
    get_reference -create -list_name $list_name -element_name $element_name

    # Setup element defaults
    array set element_properties {
        label {}
        hide_p 0
        aggregate {}
        aggregate_label {}
        aggregate_group_label {}
        html {}
        display_col {}
        display_template {}
        display_template_name {}
        link_url_col {}
        link_url_eval {}
        link_html {}
        csv_col {}
        sub_class {}
        class {}
        orderby {}
        orderby_asc {}
        orderby_desc {}
        default_direction {}
        select_clause {}
        select_clause_eval {}
        from_clause {}
        from_clause_eval {}
        where_clause {}
        where_clause_eval {}
    }

    # These attributes are internal listbuilder attributes
    array set element_properties {
        subrownum 0
        aggregate_col {}
        aggregate_group_col {}
        cell_attributes {}
        orderby_asc {}
        orderby_desc {}
        default_direction {}
        orderby_url {}
        orderby_direction {}
        orderby_html_title {}
        ordering_p "f"
        class {}
    }

    # Let the element know its own name
    set element_properties(name) $element_name

    # Let the element know its owner's name
    set element_properties(list_name) $list_name

    incr ulevel

    set_properties \
        -list_name $list_name \
        -element_name $element_name \
        -spec $spec \
        -ulevel $ulevel

    # Default display_col to element name
    if { $element_properties(display_col) eq "" } {
        set element_properties(display_col) $element_properties(name)
    }

    # Default csv_col to display_col
    if { $element_properties(csv_col) eq "" } {
        set element_properties(csv_col) $element_properties(display_col)
    }

    # Default sub_class to list:sub_class
    if { $element_properties(sub_class) eq "" } {
        set element_properties(sub_class) $list_properties(sub_class)
    }

    # Default class to (list:main_class)-(element:sub_class)
    if { $element_properties(class) eq "" } {
        set element_properties(class) [join [concat $list_properties(main_class) $element_properties(sub_class)] "-"]
    }

    # Create the orderby filter, if specified
    if { $element_properties(orderby) ne "" || $element_properties(orderby_asc) ne "" || $element_properties(orderby_desc) ne "" } {
        set orderby_spec [list]
        foreach elm { orderby orderby_asc orderby_desc default_direction label } {
            if { $element_properties($elm) ne "" } {
                lappend orderby_spec $elm $element_properties($elm)
            }
        }

        template::list::orderby::create \
            -list_name $list_name \
            -orderby_name $element_properties(name) \
            -ulevel [expr {$ulevel + 1}] \
            -spec $orderby_spec
    }
}

ad_proc -public template::list::element::get_refname {
    {-list_name:required}
    {-element_name:required}
} {
    @return the name used for the list element properties array.
} {
    return "$list_name:element:$element_name:properties"
}

ad_proc -public template::list::element::get_reference {
    {-list_name:required}
    {-element_name:required}
    {-local_name "element_properties"}
    {-create:boolean}
} {
    upvar the list element to the callers scope as $local_name
} {
    # Check that the list exists
    template::list::get_reference -name $list_name

    set refname [get_refname -list_name $list_name -element_name $element_name]

    if { !$create_p && ![uplevel \#[template::adp_level] [list info exists $refname]] } {
        error "Element '$element_name' not found in list '$list_name'"
    }

    uplevel upvar #[template::adp_level] $refname $local_name
}


ad_proc -public template::list::element::get_property {
    {-list_name:required}
    {-element_name:required}
    {-property:required}
} {
    @return the element property in the named list.
} {
    get_reference \
        -list_name $list_name \
        -element_name $element_name

    return $element_properties($property)
}

ad_proc -public template::list::element::set_property {
    {-list_name:required}
    {-element_name:required}
    {-property:required}
    {-value:required}
    {-ulevel 1}
} {
    Set a property in the named list template.
} {
    # Get an upvar'd reference to list_properties
    template::list::get_reference -name $list_name

    get_reference \
        -list_name $list_name \
        -element_name $element_name

    switch $property {
        display_eval - link_url_eval {
            # This is a chunk of Tcl code, which should be executed later, not now
            set element_properties($property) $value

            # Remember that we'll have to do dynamic columns
            set list_properties(dynamic_cols_p) 1
        }
        aggregate {
            # Remember that we'll have to do aggregation
            set list_properties(aggregates_p) 1

            # do an uplevel subst on the value now
            set element_properties($property) [uplevel $ulevel [list subst $value]]
        }
        html {
            # All other vars, do an uplevel subst on the value now
            set element_properties($property) [uplevel $ulevel [list subst $value]]
            set element_properties(cell_attributes) [template::list::util_html_to_attributes_string $element_properties(html)]
        }
        default {
            # We require all properties to be initialized to the empty string in the array, otherwise they're illegal.
            if { ![info exists element_properties($property)] } {
                error "Unknown element property '$property' for element '$element_name' in list '$list_name'. Allowed properties are [join [array names element_properties] ", "]."
            }

            # All other vars, do an uplevel subst on the value now
            set element_properties($property) [uplevel $ulevel [list subst $value]]
        }
    }
}

ad_proc -public template::list::element::set_properties {
    {-list_name:required}
    {-element_name:required}
    {-spec:required}
    {-ulevel 1}
} {
    Set a list of properties in array get format for the given list template.
} {
    incr ulevel

    foreach { property value } $spec {
        set_property \
            -list_name $list_name \
            -element_name $element_name \
            -property $property \
            -value $value \
            -ulevel $ulevel
    }
}



ad_proc -private template::list::element::render {
    {-list_name:required}
    {-element_name:required}
} {
    Returns an ADP chunk, which must be evaluated
} {
    set level [template::adp_level]

    # Get an upvar'd reference to list_properties
    template::list::get_reference -name $list_name

    set multirow $list_properties(multirow)

    # Get the element properties
    # We ignore if the element doesn't exist, 'cause then we'll just hope it exists in the multirow and display the value directly
    get_reference -create -list_name $list_name -element_name $element_name

    if { [info exists element_properties(display_template_name)] && $element_properties(display_template_name) ne "" } {
        set stub [template::resource_path -type display_templates -style $element_properties(display_template_name)]
        if {[file readable $stub.adp]} {
            set output [template::util::read_file $stub.adp]
        }
    }
    if { ![info exists output] } {
        if { [info exists element_properties(display_template)] && $element_properties(display_template) ne "" } {
            set output $element_properties(display_template)
        } elseif { [info exists element_properties(display_col)] && $element_properties(display_col) ne "" } {
            set output "@$multirow.$element_properties(display_col)@"
        } else {
            set output "@$multirow.$element_name@"
        }
    }
    # We have support for making the cell contents a hyperlink right here, because it's so common
    set link_url {}
    set link_html {}

    if { [info exists element_properties(link_url_col)] && $element_properties(link_url_col) ne "" } {
        set link_url "@$multirow.$element_properties(link_url_col)@"
    } elseif { [info exists element_properties(link_url)] && $element_properties(link_url) ne "" } {
        set link_url $element_properties(link_url)
    }

    if { [info exists element_properties(link_html_col)] && $element_properties(link_html_col) ne "" } {
        set link_html "@$multirow.$element_properties(link_html_col)@"
    } elseif { [info exists element_properties(link_html)] && $element_properties(link_html) ne "" } {
        set link_html $element_properties(link_html)
    }

    if { $link_url ne "" } {
        set old_output $output

        set output [subst {<if "$link_url" not nil><a
            href="$link_url"[template::list::util_html_to_attributes_string $link_html]>$old_output</a></if><else>$old_output</else>}]
    }

    return $output
}





#####
#
# template::list::filter namespace
#
#####

ad_proc -public template::list::filter::create {
    {-list_name:required}
    {-filter_name:required}
    {-spec:required}
    {-ulevel 1}
} {
    Adds a filter to a list builder list.

    <p>

    This proc shouldn't be called directly, only through <a href="/api-doc/proc-view?proc=template::list::create">template::list::create</a>.

    <p>

    These are the available properties in the spec:

    <p>

    <ul>
    <li>
    <b>label</b>: The label of the filter.
    </li>
    <li>
    <b>hide_p</b>: Set to 1 to hide this filter from default rendering.
    </li>
    <li>
    <b>type</b>: The type of values this filter sets. Also see 'values' below. Valid options are: 'singleval', meaning that the
    value is a single value of a query variable with the name of the filter; 'multival', meaning the the value is really a Tcl list of values,
    sent to a :multiple page variable; and 'multivar', meaning that the value is a list of (key value) lists, as in { { var1 value1 } { var2 value 2 } }.
    'multival' is useful when you're filtering on, say, a date range, in which case you'd send two values, namely the start and end date.
    'multivar' is useful when you want the selection of one filter to change the value of another filter, for example when selecting groupby, you also
    want to order by the grouped by column, otherwise the groupby won't work properly (you'll get a new group each time the value changes, but it's not sorted
                                                                                       by that column, so you'll get more than one group per value over the entire list).
    </li>
    <li>
    <b>add_url_eval</b>: An expression which will be uplevel subst'ed with a magic
    variable __filter_value set to the value of the given filter.
    </li>
    <li>
    <b>values</b>: A list of lists of possible filter values, as in { { label1 value1 count1 } { label2 value2 count2 } ... }.
    The 'label' is what's displayed when showing the available filter values. 'value' is what changes filter values, and, depending on 'type' above,
    can either be a single value, a list of values, or a list of ( name value ) pairs. 'count' is optional, and is the number of rows that match the
    given filter value.
    </li>
    <li>
    <b>has_default_p</b>: If set to 1, it means that this filter has a default value, and thus cannot be cleared. If not set, the list builder will automatically
    provide a link to clear the currently selected value of this filter. You only need to set this if you specify a default value in your page's ad_page_contract,
    instead of through the 'default_value' property below.
    </li>
    <li>
    <b>default_value</b>: The default value to use when no value is selected for this filter. Automatically sets has_default_p to 1.
    </li>
    <li>
    <b>where_clause</b>: What should go in the where clause of your query when
    filtering on this filter. For example "l.project_id = :project_id".
    </li>
    <li>
    <b>where_clause_eval</b>: Same as where_clause, except this gets evaluated in the caller's context.
    </li>
    <li>
    <b>other_label</b>: If your values above do not carry all possible values, we can display a special
    'other' value when some other value is selected for this filter. You specify here what label should
    be used for that element.
    </li>
    <li>
    <b>form_element_properties</b>: If you are using filter form, additional properties to override the form element declaration. Any valid form properties can be passed using the same names are template::element::create. A list of name value pairs.
    </li>
    </ul>

    <p>

    In order for filters to work, you have to specify them in your page's ad_page_contract, typically as filter_name:optional. The list builder will find them from there,
    by grabbing them from your page's local variables.

    @param list_name     Name of list.

    @param filter_name  Name of the filter.

    @param spec          The spec for this filter. This is an array list of property/value pairs, where the right hand side
    is 'subst'ed in the caller's namespace, except for *_eval properties, which are 'subst'ed inside the multirow.

    @param  ulevel       Where we should uplevel to when doing the subst's. Defaults to '1', meaning the caller's scope.
} {
    set level [template::adp_level]

    # Get an upvar'd reference to list_properties
    template::list::get_reference -name $list_name

    # Remember the filters and their order
    lappend list_properties(filters) $filter_name

    # Properties are going to be stored in an array named 'list-name:filter:filter-name:properties'
    if {$filter_name eq ""} {
        error "Invalid filter name for list '$list_name', spec: $spec"
    }
    set filter_ref "$list_name:filter:$filter_name:properties"

    # We also store the full filter array name, so its easy to find <
    lappend list_properties(filter_refs) $filter_ref

    # Upvar the filter properties array
    upvar #$level $filter_ref filter_properties

    # Setup filter defaults
    array set filter_properties {
        label {}
        hide_p 0
        type singleval
        add_url_eval {}
        values {}
        has_default_p 0
        default_value {}
        where_clause {}
        where_clause_eval {}
        null_where_clause {}
        null_where_clause_eval {}
        from_clause {}
        from_clause_eval {}
        select_clause {}
        select_clause_eval {}
        other_label {}
        null_label {}
        form_element_properties {}
    }

    # Prepopulate some automatically generated values
    array set filter_properties {
        clear_url {}
        urls {}
        add_urls {}
        selected_p {}
    }

    # Let the filter know its own name
    set filter_properties(name) $filter_name

    # Let the filter know its owner's name
    set filter_properties(list_name) $list_name

    set_properties \
        -list_name $list_name \
        -filter_name $filter_name \
        -spec $spec \
        -ulevel [expr {$ulevel + 1}]

    # This is to be used by the export_vars function
    switch $filter_properties(type) {
        singleval - multivar {
            set filter_properties(var_spec) $filter_name
        }
        multival {
            set filter_properties(var_spec) "${filter_name}:multiple"
        }
    }
    lappend list_properties(filters_export) $filter_properties(var_spec)
}

ad_proc -public template::list::filter::get_refname {
    {-list_name:required}
    {-filter_name:required}
} {
    Build a canonical name from a list and filter name.

    @param list_name List name.
    @param filter_name Filter name.

    @return Canonical name built from list_name and filter_name.
} {
    return "$list_name:filter:$filter_name:properties"
}

ad_proc -public template::list::filter::get_reference {
    {-list_name:required}
    {-filter_name:required}
    {-local_name "filter_properties"}
    {-create:boolean}
} {
    Build a reference to the given filter for the given list template.
} {
    set refname [get_refname -list_name $list_name -filter_name $filter_name]

    if { !$create_p && ![uplevel \#[template::adp_level] [list info exists $refname]] } {
        error "Filter '$filter_name' not found"
    }

    uplevel upvar #[template::adp_level] $refname $local_name
}

ad_proc -public template::list::filter::set_property {
    {-list_name:required}
    {-filter_name:required}
    {-property:required}
    {-value:required}
    {-ulevel 1}
} {
    Set a property for the given list and filter.
} {
    # Get an upvar'd reference to list_properties
    template::list::get_reference -name $list_name

    get_reference \
        -list_name $list_name \
        -filter_name $filter_name

    switch $property {
        where_clause_eval - add_url_eval {
            # Eval's shouldn't be subst'ed here, will be later
            set filter_properties($property) $value
        }
        default_value {
            set value [uplevel $ulevel [list subst $value]]
            set filter_properties($property) $value
            if { $value ne "" } {
                set filter_properties(has_default_p) 1
            }
        }
        default {
            # We require all properties to be initialized to the empty string in the array, otherwise they're illegal.
            if { ![info exists filter_properties($property)] } {
                error "Unknown filter property '$property'  for filter '$filter_name' in list '$list_name'. Allowed properties are [join [array names filter_properties] ", "]."
            }

            # All other vars, do an uplevel subst on the value now
            set value [uplevel $ulevel [list subst $value]]
            set filter_properties($property) $value
        }
    }
}

ad_proc -public template::list::filter::set_properties {
    {-list_name:required}
    {-filter_name:required}
    {-spec:required}
    {-ulevel 1}
} {
    Set multiple properties for the given list and filter from a list in
    array get format.
} {
    incr ulevel

    foreach { property value } $spec {
        set_property \
            -list_name $list_name \
            -filter_name $filter_name \
            -property $property \
            -value $value \
            -ulevel $ulevel
    }
}


ad_proc -public template::list::filter::get_property {
    {-list_name:required}
    {-filter_name:required}
    {-property:required}
} {
    Return a property from a given list and filter.
} {
    get_reference \
        -list_name $list_name \
        -filter_name $filter_name

    return $filter_properties($property)
}

ad_proc -public template::list::filter::exists_p {
    {-list_name:required}
    {-filter_name:required}
} {
    Determine if a given filter exists for a given list template.

    @param list_name The name of the list template.
    @param filter_name The filter name.

    @return True (1) if the filter exists, false (0) if not.
} {
    set refname [get_refname -list_name $list_name -filter_name $filter_name]

    return [uplevel \#[template::adp_level] [list info exists $refname]]
}




#####
#
# template::list::format namespace
#
#####

ad_proc -public template::list::format::create {
    {-list_name:required}
    {-format_name:required}
    {-selected_format ""}
    {-spec:required}
    {-ulevel 1}
} {
    Adds a format to a list builder list.

    <p>

    This proc shouldn't be called directly, only through <a href="/api-doc/proc-view?proc=template::list::create">template::list::create</a>.

    <p>

    These are the available properties in the spec:

    <p>

    <ul>
    <li>
    <b>label</b>: The label.
    </li>
    <li>
    <b>layout</b>: The layout, can be 'table' or 'list'.
    </li>
    <li>
    <b>style</b>: The name of the template to used to render this format. Defaults to the name of the layout, and can be overridden in the ADP file.
    </li>
    <li>
    <b>output</b>: Output format, can be either 'template' or 'csv'. If 'csv'. then the output is streamed directly to the browser
    and not through the templating system, but you have to call
    <a href="/api-doc/proc-view?proc=template::list::write_output">template::list::write_output</a> from your page to make this work.
    </li>
    <li>
    <b>page_size</b>: The page size for this format. Leave blank to use the list's page size.
    </li>
    <li>
    <b>elements</b>: 'table' layout: An ordered list of elements to display in this format.
    </li>
    <li>
    <b>row</b>: 'table' layout: For more complex table layout, you can specify each row individually. The value is an array-list of ( element_name spec ) pairs.
    You can have more than one 'row' property, in which case your output table will have more than one HTML table row per row in the data set.
    In the 'spec' part of each element listed in the row, you can specify properties that override the properties defined in the -elements section
    of template::list::create, thus changing the label, link, display_col, etc.
    </li>
    <li>
    <b>template</b>: 'list' layout: An ADP chunk to be used for display of each row of the list. Use
    &lt;listelement name="<i>element_name</i>"&gt; to output a list element in your template.

    </li>
    </ul>


    @param list_name     Name of list.

    @param format_name   Name of the format.

    @param spec          The spec for this format. This is an array list of property/value pairs, where the right hand side
    is 'subst'ed in the caller's namespace, except for *_eval properties, which are 'subst'ed inside the multirow.

    @param  ulevel       Where we should uplevel to when doing the subst's. Defaults to '1', meaning the caller's scope.
} {
    set level [template::adp_level]

    # Get an upvar'd reference to list_properties
    template::list::get_reference -name $list_name

    # Remember the formats and their order
    lappend list_properties(formats) $format_name

    # Properties are going to be stored in an array named 'list-name:format:format-name:properties'
    set format_ref "$list_name:format:$format_name:properties"

    # We also store the full format array name, so its easy to find <
    lappend list_properties(format_refs) $format_ref

    # Upvar the format properties array
    upvar #$level $format_ref format_properties

    # Setup format defaults
    array set format_properties {
        label {}
        layout table
        style {}
        output template
        page_size {}
        elements {}
        row {}
        template {}
    }

    # Let the format know its own name
    set format_properties(name) $format_name

    # Let the format know its owner's name
    set format_properties(list_name) $list_name

    # Counting the row number within one row of the dataset
    set subrownum 0
    set elementnum 0

    foreach { key value } $spec {
        switch $key {
            row {
                # We only care about this for the currently selected format
                if {$format_name eq $selected_format} {

                    # This is the layout specification for table layouts
                    set value [uplevel $ulevel [list subst $value]]
                    incr subrownum

                    foreach { element_name spec } $value {
                        incr elementnum

                        template::list::element::get_reference \
                            -list_name $list_name \
                            -element_name $element_name

                        # Set elementnum and subrownum
                        set element_properties(elementnum) $elementnum
                        set element_properties(subrownum) $subrownum

                        # Set/override additional element properties from the spec
                        template::list::element::set_properties \
                            -list_name $list_name \
                            -element_name $element_name \
                            -spec $spec \
                            -ulevel [expr {$ulevel + 1}]

                        # Remember the display order
                        lappend list_properties(display_elements) $element_name
                    }
                }
            }
            template {
                # We only care about this for the currently selected format
                if {$format_name eq $selected_format} {
                    # All other vars, do an uplevel subst on the value now
                    set value [uplevel $ulevel [list subst $value]]
                    set format_properties($key) $value
                    set list_properties(row_template) $value
                }
            }
            default {
                # We require all properties to be initialized to the empty string in the array, otherwise they're illegal.
                if { ![info exists format_properties($key)] } {
                    error "Unknown format property '$key' for element '$format_name' in list '$list_name'. Allowed properties are [join [array names format_properties] ", "]."
                }

                # All other vars, do an uplevel subst on the value now
                set format_properties($key) [uplevel $ulevel [list subst $value]]
            }
        }
    }

    # For the currently selected format, copy some things over to the list properties
    if {$format_name eq $selected_format} {
        if { $format_properties(style) eq "" } {
            set format_properties(style) $format_properties(layout)
        }

        # Move style up to the list_properties
        if { $format_properties(style) ne "" } {
            set list_properties(style) $format_properties(style)
        }

        # Move output up to the list_properties
        if { $format_properties(output) ne "" } {
            set list_properties(output) $format_properties(output)
        }

        # Move page_size up to the list_properties
        if { $format_properties(page_size) ne "" } {
            set list_properties(page_size) $format_properties(page_size)
        }

        # Move elements up to the list_properties as display_elements
        if { $format_properties(elements) ne "" } {
            set list_properties(display_elements) $format_properties(elements)
        }

    }

    return [list $format_properties(label) $format_name]
}






#####
#
# template::list::orderby namespace
#
#####

ad_proc -public template::list::orderby::create {
    {-list_name:required}
    {-orderby_name:required}
    {-spec:required}
    {-ulevel 1}
} {
    Adds an orderby to a list builder list.

    <p>

    This proc shouldn't be called directly, only through <a href="/api-doc/proc-view?proc=template::list::create">template::list::create</a>.

    <p>

    These are the available properties in the spec:

    <p>

    <ul>
    <li>
    <b>label</b>: The label for the orderby.
    </li>
    <li>
    <b>orderby</b>: The column to use in the order by clause of the query. If it's not as simple as that, you can also specify
    'orderby_asc' and 'orderby_desc' separately.
    </li>
    <li>
    <b>orderby_asc</b>: The orderby clause when sorting ascending. This is useful when you're actually sorting
    by two database columns.
    </li>
    <li>
    <b>orderby_desc</b>: The reverse ordering from 'orderby_asc'.
    </li>
    <li>
    <b>orderby_name</b>: The name of a named query, same functionality as orderby property.
    </li>
    <li>
    <b>orderby_asc_name</b>: The name of a named query, same functionality as orderby_asc property.
    </li>
    <li>
    <b>orderby_desc_name</b>: The name of a named query, same functionality as orderby_desc property.
    </li>
    <li>
    <b>default_direction</b>: The default order direction, 'asc' or 'desc'. Defaults to 'asc'.
    </li>
    <li>
    <b>multirow_cols</b>: If specified, we will sort the multirow in the webserver layer by the given cols.
    </li>
    </ul>

    It is difficult, but you can <a href="http://openacs.org/forums/message-view?message_id=213344">sort hierarchical queries</a>.

    @param list_name     Name of list.

    @param orderby_name  Name of the orderby.

    @param spec          The spec for this orderby. This is an array list of property/value pairs, where the right hand side
    is 'subst'ed in the caller's namespace, except for *_eval properties, which are 'subst'ed inside the multirow.

    @param  ulevel       Where we should uplevel to when doing the subst's. Defaults to '1', meaning the caller's scope.

    @see template::list::orderby_clause
} {
    # Get an upvar'd reference to list_properties
    template::list::get_reference -name $list_name

    # Get the list properties
    lappend list_properties(orderbys) $orderby_name

    # We store the full element ref name, so its easy to find later
    lappend list_properties(orderby_refs) [get_refname -list_name $list_name -orderby_name $orderby_name]

    # Create the orderby properties array
    if {$orderby_name eq ""} {
        error "Invalid orderby field or spec for list '$list_name', spec: $spec"
    }
    get_reference -create -list_name $list_name -orderby_name $orderby_name

    # Setup element defaults
    array set orderby_properties {
        label {}
        orderby_desc {}
        orderby_asc {}
        multirow_cols {}
        orderby {}
        default_direction asc
    }

    # These attributes are internal listbuilder attributes
    array set orderby_properties {
    }

    # Let the orderby know its own name
    set orderby_properties(name) $orderby_name

    # Let the orderby know its owner's name
    set orderby_properties(list_name) $list_name

    incr ulevel

    set_properties \
        -list_name $list_name \
        -orderby_name $orderby_name \
        -spec $spec \
        -ulevel $ulevel

    # Set the orderby properties of the element with the same name, if any
    template::list::element::get_reference -create -list_name $list_name -element_name $orderby_name
    if { [info exists element_properties] } {
        set element_properties(orderby_asc) $orderby_properties(orderby_asc)
        set element_properties(orderby_desc) $orderby_properties(orderby_desc)
        set element_properties(multirow_cols) $orderby_properties(multirow_cols)
        set element_properties(default_direction) $orderby_properties(default_direction)
    }

    # Create the 'orderby' filter if it doesn't already exist
    if { ![template::list::filter::exists_p -list_name $list_name -filter_name $list_properties(orderby_name)] } {
        template::list::filter::create \
            -list_name $list_name \
            -filter_name $list_properties(orderby_name) \
            -spec [list label [_ acs-templating.Sort_order]] \
            -ulevel 2
    }

    template::list::filter::get_reference \
        -list_name $list_name \
        -filter_name $list_properties(orderby_name)

    lappend filter_properties(values) [list $orderby_properties(label) "${orderby_name},$orderby_properties(default_direction)"]

    # Return an element which can be put into the 'values' property of a filter
    return [list $orderby_properties(label) "${orderby_name},$orderby_properties(default_direction)"]
}

ad_proc -public template::list::orderby::get_refname {
    {-list_name:required}
    {-orderby_name:required}
} {
    Build a canonical name from a list and orderby filter.
} {
    return "$list_name:orderby:$orderby_name:properties"
}

ad_proc -public template::list::orderby::get_reference {
    {-list_name:required}
    {-orderby_name:required}
    {-local_name "orderby_properties"}
    {-create:boolean}
} {
    Build a local reference to an orderby filter for a named list template.
} {
    # Check that the list exists
    template::list::get_reference -name $list_name

    set refname [get_refname -list_name $list_name -orderby_name $orderby_name]

    if { !$create_p && ![uplevel #[template::adp_level] [list info exists $refname]] } {
        error "Orderby '$orderby_name' not found in list '$list_name'"
    }

    uplevel upvar #[template::adp_level] $refname $local_name
}

ad_proc -public template::list::orderby::get_property {
    {-list_name:required}
    {-orderby_name:required}
    {-property:required}
} {
    Get a property from an orderby filter for a list template.
} {
    get_reference \
        -list_name $list_name \
        -orderby_name $orderby_name

    return $orderby_properties($property)
}

ad_proc -public template::list::orderby::set_property {
    {-list_name:required}
    {-orderby_name:required}
    {-property:required}
    {-value:required}
    {-ulevel 1}
} {
    Set a property for an orderby filter in the given list template.
} {
    # Get an upvar'd reference to list_properties
    template::list::get_reference -name $list_name

    get_reference \
        -list_name $list_name \
        -orderby_name $orderby_name

    switch $property {
        orderby {
            set value [uplevel $ulevel [list subst $value]]
            set orderby_properties($property) $value
            set orderby_properties(orderby_asc) "$value asc"
            set orderby_properties(orderby_desc) "$value desc"
        }
        orderby_asc_name {
            set orderby_properties($property) $value
            set value [uplevel $ulevel [list db_map $value]]
            set orderby_properties(orderby_asc) $value
        }
        orderby_desc_name {
            set orderby_properties($property) $value
            set value [uplevel $ulevel [list db_map $value]]
            set orderby_properties(orderby_desc) $value
        }
        orderby_name {
            set orderby_properties($property) $value
            set value [uplevel $ulevel [list db_map $value]]
            set orderby_properties(orderby_asc) "$value asc"
            set orderby_properties(orderby_desc) "$value desc"
        }
        default {
            # We require all properties to be initialized to the empty string in the array, otherwise they're illegal.
            if { ![info exists orderby_properties($property)] } {
                error "Unknown orderby property '$property' for column '$orderby_name' in list '$list_name'. Allowed properties are [join [array names orderby_properties] ", "]."
            }

            # All other vars, do an uplevel subst on the value now
            set orderby_properties($property) [uplevel $ulevel [list subst $value]]
        }
    }
}

ad_proc -public template::list::orderby::set_properties {
    {-list_name:required}
    {-orderby_name:required}
    {-spec:required}
    {-ulevel 1}
} {
    Set multiple properties for the given orderby filter in the given list
    template from a list in array get format.
} {
    incr ulevel

    foreach { property value } $spec {
        set_property \
            -list_name $list_name \
            -orderby_name $orderby_name \
            -property $property \
            -value $value \
            -ulevel $ulevel
    }
}






#####
#
# Templating system ADP tags
#
#####



template_tag listtemplate { chunk params } {
    set level [template::adp_level]
    
    set list_name [template::get_attribute listtemplate $params name]
    set style [ns_set iget $params style]

    template::adp_append_code "set list_properties(name) [list $list_name]"
    template::adp_append_string \
        "\[template::list::render -name \"$list_name\" -style \"$style\"\]"
}

template_tag listelement { params } {

    set element_name [template::get_attribute listelement $params name]

    # list_properties will be available, because

    template::adp_append_string \
        "\[template::list::element::render -list_name \${list_properties(name)} -element_name $element_name\]"
}

template_tag listrow { params } {
    set level [template::adp_level]

    template::adp_append_string \
        "\[template::list::render_row -name \${list_properties(name)}\]"
}

template_tag listfilters { chunk params } {
    set level [template::adp_level]

    set list_name [template::get_attribute listfilters $params name]
    set style [ns_set iget $params style]

    template::adp_append_string \
        "\[template::list::render_filters -name \"$list_name\" -style \"$style\"\]"
}

template_tag listfilters-form { chunk params } {
    set level [template::adp_level]
    set list_name [template::get_attribute listfilters $params name]

    set style [ns_set iget $params style]

    template::adp_append_string \
        "\[template::list::render_form_filters -name \"$list_name\" -style \"$style\"\]"
}

ad_proc -private template::list::render_form_filters {
    {-name:required}
    {-style ""}
} {

    set level [template::adp_level]

    # Provide a reference to the list properties for use by the list template
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    #
    # Create 'filters' multirow
    #

    # Manually construct a multirow by setting the relevant variables
    set filters:rowcount 0
    template::multirow -local create filters \
        filter_name \
        filter_label \
        filter_clear_url \
        selected_p \
        clear_one_url \
        widget

    foreach filter_ref $list_properties(filter_refs) {
        upvar #$level $filter_ref filter_properties
        if { ![template::util::is_true $filter_properties(hide_p)] } {
            foreach elm $filter_properties(values) url $filter_properties(urls) selected_p $filter_properties(selected_p) add_url $filter_properties(add_urls) {
                if {![info exists filter_properties(clear_one_url)]} {
                    set filter_properties(clear_one_url) ""
                }
                if {[string is true $selected_p]} {
                    template::multirow -local append filters \
                        $filter_properties(name) \
                        $filter_properties(label) \
                        $filter_properties(clear_url) \
                        $selected_p \
                        $filter_properties(clear_one_url) \
                        [expr {[info exists filter_properties(widget)] ? $filter_properties(widget) : ""}]
                }
            }
        }
    }

    ############################################################
    ############################################################
    if {$style eq ""} {
        set style [parameter::get \
                       -package_id [apm_package_id_from_key "acs-templating"] \
                       -parameter DefaultListFilterStyle \
                       -default "filters"]
    }
    set file_stub [template::resource_path -type lists -style $style]

    # ensure that the style template has been compiled and is up-to-date
    template::adp_init adp $file_stub

    # get result of template output procedure into __adp_output
    # the only data source on which this template depends is the "elements"
    # multirow data source.  The output of this procedure will be
    # placed in __adp_output in this stack frame.

    template::code::adp::$file_stub

    return $__adp_output
}

ad_proc -private template::list::prepare_filter_form {
    -name
    {-filter_exclude_from_key_extra {}}
} {
    Documentation goes here
} {
    set level [template::adp_level]
    # Provide a reference to the list properties for use by the list template
    # Get an upvar'd reference to list_properties
    get_reference -name $name

    set filter_names_options_tmp [list]
    set filter_names_options [list]
    set filter_hidden_filters [list]
    set filter_key_filters [list]
    set filter_exclude_from_key [list orderby groupby format page __list_view]
    if {[llength $filter_exclude_from_key_extra]} {
        set filter_exclude_from_key [concat $filter_exclude_from_key $filter_exclude_from_key_extra]
    }
    set filter_hidden_filters_url_vars [list]
    # loop through all the filters in this list
    foreach filter_ref $list_properties(filter_refs) {
        upvar #$level $filter_ref filter_properties
        if {$filter_properties(label) ne "" && [lsearch $filter_exclude_from_key $filter_properties(name)] < 0} {
            # filters with a label will be added to the form for the user
            # to choose from
            lappend filter_names_options_tmp [list $filter_properties(label) $filter_properties(name)]
        }

        # filters without a label are added as hidden elements
        # to the form so that quer params for the list
        # and group by/order by are preserved when the filter
        # form is used

        # grab the current value of the filter out of the list if
        # it exists
        upvar $list_properties(ulevel) $filter_properties(name) current_filter_value
        if {[info exists current_filter_value] && $current_filter_value ne ""} {

            if {[lsearch $filter_exclude_from_key $filter_properties(name)] > -1} {
                lappend filter_hidden_filters $filter_properties(name)
            } else {
                lappend filter_key_filters $filter_properties(name) $current_filter_value
            }
        }
    }
    upvar #[template::adp_level] __list_filter_form_client_property_key list_filter_form_client_property_key
    # we only get 50 characters
    # to save our clienty property name, we can encode it into an
    # ns_sha1 hash to make it fit. we don't extract the data from the
    # property name so this should work fine
    #    set list_filter_form_client_property_key [ns_sha1 [list [ad_conn url] $name $filter_key_filters]]
    set list_filter_form_client_property_key [ns_sha1 [list [ad_conn url] $name]]
    upvar \#[template::adp_level] __client_property_filters client_property_filters
    set client_property_filters [ad_get_client_property acs-templating $list_filter_form_client_property_key]
    # take out filters we already applied...
    set i 0
    foreach option_list $filter_names_options_tmp {
        set option_label [lindex $option_list 0]
        set option_name [lindex $option_list 1]
        if {"${name}:filter:${option_name}:properties" ni $client_property_filters} {
            lappend filter_names_options [list $option_label $option_name]
        }
    }
    # build an ad_form form based on the chosen filters
    set filters_form_name list-filters-$name
    set add_filter_form_name list-filter-add-$name
    ad_form -name $add_filter_form_name -form {
        {choose_filter:text(select) {label "Add Filter"} {options {$filter_names_options}} }
        {name:text(hidden) {value $name}}
        {add_filter:text(submit) {label "Add"}}
        {clear_all:text(submit) {label "Clear All"}}
        {clear_one:text(hidden),optional}
    }
    foreach fhf $filter_hidden_filters {
        ad_form -extend -name $add_filter_form_name -form {
            {$fhf:text(hidden),optional}
        }
    }
    ad_form -extend -name $add_filter_form_name -on_request {
        # setup little Xs to click to clear one field
        # pass the name of the field in the clear_one variable

        set __form [ns_getform]
        set clear_one [ns_set get $__form clear_one]

        if {([info exists clear_one] && $clear_one ne "")} {
            # loop through the saved filters and remove
            # the filter from the client property if its
            # specified in clear_one
            set __old_client_property_filters [ad_get_client_property acs-templating $__list_filter_form_client_property_key]
            set __client_property_filters [list]

            foreach {__ref __value} $__old_client_property_filters {
                if {[set ${__ref}(name)] ne $clear_one} {
                    lappend __client_property_filters $__ref $__value
                }
            }
            # if we changed the list of filters, save it in the
            # client property, we read it later on to build the
            # form of selected filters
            set client_property_filters $__client_property_filters
            ad_set_client_property acs-templating $__list_filter_form_client_property_key $__client_property_filters
            # now reload the form. excluding var clear_one
            set pattern [ns_urlencode "clear_one"]=[ns_urlencode "$clear_one"]
            regsub "${pattern}&?" [ad_return_url] {} url
            ad_returnredirect $url
        }
    } -on_submit {

        if {([info exists clear_all] && $clear_all ne "")} {
            set __client_property_filters {}
            ad_set_client_property acs-templating $__list_filter_form_client_property_key $__client_property_filters
            break
        }
        template::list::get_reference -name $name
        foreach filter_ref $list_properties(filter_refs) {
            upvar \#[template::adp_level] $filter_ref filter_properties
            if {$filter_properties(name) eq $choose_filter} {
                lappend __client_property_filters $filter_ref ""
            }
        }
        ad_set_client_property acs-templating $__list_filter_form_client_property_key $__client_property_filters
    }

    # create the form the holds the actual filter values
    ad_form -name $filters_form_name -has_submit 1 -form {
        {name:text(hidden) {value $name}}
    }
    # we need to pass the hidden list filters in this form too
    # since we need to preserve the other variables if either
    # the add filter or the apply filter form is submitted
    foreach fhf $filter_hidden_filters {
        ad_form -extend -name $filters_form_name -form {
            {$fhf:text(hidden),optional}
        }
        upvar \#[template::adp_level] $name:filter:${fhf}:properties filter_properties
        set filter_properties(widget) hidden
        set filter_properties(selected_p) t
    }

    # we need to extract the values of the hidden filters out of the
    # form elements, there is some magic here where ad_form
    # grabs the elements out of the form/url vars and
    # sets them, we want to pull them out of the form instead of
    # setting local variables to prevent collisions
    foreach fhf $filter_hidden_filters {
        lappend filter_hidden_filters_url_vars [list $fhf [template::element::get_value $add_filter_form_name $fhf]]
    }
    set visible_filters_p 0
    # add a select box for filters with a list of valid values
    # otherwise add a regular text box
    foreach {f_ref f_value} $client_property_filters {
        upvar \#[template::adp_level] $f_ref filter_properties
        if {$filter_properties(label) ne "" \
                && $filter_properties(hide_p) eq 0 \
                && [lsearch $filter_exclude_from_key $filter_properties(name)] < 0} {
            incr visible_filters_p
        }
        if {![template::element::exists $filters_form_name $filter_properties(name)]} {
            # extract options
            set options [list]

            foreach elm $filter_properties(values) url $filter_properties(urls) selected_p $filter_properties(selected_p) add_url $filter_properties(add_urls) {
                # Loop over 'values' and 'url' simultaneously
                # 'label' is the first element, 'value' the second
                # We do an lrange here, otherwise values would be set wrong
                # in case someone accidentally supplies a list with too many elements,
                # because then the foreach loop would run more than once
                foreach { label value count } [lrange $elm 0 2] {}

                if { [string trim $label] eq "" } {
                    set label $filter_properties(null_label)
                }
                lappend  options [list $label $value]
            }
            set clear_url_vars [concat [list [list clear_one $filter_properties(name)]] $filter_hidden_filters_url_vars]
            set filter_properties(clear_one_url) [export_vars -base [ad_conn url] $clear_url_vars]

            set form_element(element_name) $filter_properties(name)
            set form_element(widget) text
            set form_element(datatype) text
            if {[llength $options]} {
                set form_element(widget) select
                set form_element(options) $options
            }
            set form_element(label) "$filter_properties(label)"
            if {[info exists filter_properties(form_element_properties)]} {
                foreach {var value} $filter_properties(form_element_properties) {
                    set form_element($var) $value
                }
            }
            set ad_form_element [list ${form_element(element_name)}:${form_element(datatype)}(${form_element(widget)}),optional]
            if {$filter_properties(type) eq "multival"} {
                set ad_form_element [list "[lindex $ad_form_element 0],multiple"]
            }
            foreach {var value} [array get form_element] {
                if {[lsearch {name widget datatype} $var] < 0} {
                    lappend ad_form_element [list $var $value]
                }
            }

            ad_form -extend -name $filters_form_name -form [list $ad_form_element]

            set filter_properties(widget) $form_element(widget)
            set filter_properties(selected_p) t
            array unset form_element
        }
    }

    ad_form -extend -name $filters_form_name -on_request {
        foreach {f_ref f_value} $__client_property_filters {
            upvar \#[template::adp_level] $f_ref filter_properties
            set $filter_properties(name) $f_value
        }
    } -on_submit {
        # set the values of the filters, the creator of the list
        # still has to process the values to generate a valid
        # where clause
        template::list::get_reference -name $name
        set templist [list]
        foreach {f_ref f_value} $__client_property_filters {
            upvar \#[template::adp_level] $f_ref filter_properties
            set filter_properties(value) [set $filter_properties(name)]
            lappend templist $f_ref $filter_properties(value)
            # hack in elements??
            if {[lsearch [template::multirow columns $list_properties(multirow)] $filter_properties(name)] > -1} {
                # FIXME Don't do this where, don't allow filters for
                # matching elmenet/filter names if element does not exist
                # check if its a dynamic element...(has select_clause)
                list::element::create -list_name $name -element_name $filter_properties(name) -spec [list label $filter_properties(label)]
            }
        }
        set __client_property_filters $templist
        ad_set_client_property acs-templating $__list_filter_form_client_property_key $__client_property_filters
    }
    # only show the submit button for the apply filters form if
    # there are filters selected by the user
    if {$visible_filters_p} {
        ad_form -extend -name $filters_form_name -form {
            {submit:text(submit) {label "Apply Filters"}}
        }
    } else {
        # hard to figure out how to conditionally handle this in the
        #
        ad_form -extend -name $filters_form_name -form {
            {submit:text(hidden),optional
            }
        }
    }
}

ad_proc template::list::set_elements_property {
    {-list_name:required}
    {-element_names:required}
    {-property:required}
    {-value:required}
} {
    Sets a property on multiple list elements

    @param list_name Name of the list
    @param element_names List of element names
    @param property Which property to set
    @param value Value to set, all elements in element_names get this value

} {
    foreach name $element_names {
        template::list::element::set_property \
            -list_name $list_name \
            -element_name $name \
            -property $property \
            -value $value
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
