ad_page_contract {

    Delete an unmounted package instance.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Mon Oct 23 14:58:57 2000
    @cvs-id $Id$
} {
    package_id:naturalnum
} -validate {
    package_not_mounted_ck {
	if {[db_string package_mounted_p {
	    select decode(count(*),0, 0, 1) 
	    from apm_packages p, site_nodes s
	    where package_id = :package_id
	    and p.package_id = s.object_id
	} -default 0]} {
	    ad_complain
	}
    }
} -errors {
    package_not_mounted_ck {The package you are trying to delete must be unmounted first.}
}

db_transaction {
    db_exec_plsql package_instance_delete {
	begin
	apm_package.delete(package_id => :package_id);
	end;
    }
} on_error {
    if {[db_string instance_delete_doubleclick_ck {
	select decode(count(*), 0, 0, 1) from apm_packages
	where package_id = :package_id
    } -default 0]} {
	ad_return_error "Error Deleting Instance" "The following error was returned:
	<blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
    }
}
	
ad_returnredirect unmounted
	
