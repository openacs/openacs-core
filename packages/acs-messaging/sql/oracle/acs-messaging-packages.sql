--
-- packages/acs-messaging/sql/acs-messaging-packages.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @author Phong Nguyen <phong@arsdigita.com>
-- @creation-date 2000-08-27
-- @cvs-id $Id$
--

create or replace package acs_message
as

    function new (
        message_id    in acs_messages.message_id%TYPE   default null,
        reply_to      in acs_messages.reply_to%TYPE     default null,
        sent_date     in acs_messages.sent_date%TYPE    default sysdate,
        sender        in acs_messages.sender%TYPE       default null,
        rfc822_id     in acs_messages.rfc822_id%TYPE    default null,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        text          in varchar2                       default null,
        data          in cr_revisions.content%TYPE      default null,
        parent_id     in cr_items.parent_id%TYPE        default -4,
        context_id    in acs_objects.context_id%TYPE,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        object_type   in acs_objects.object_type%TYPE   default 'acs_message',
        is_live       in char                           default 't',
        package_id    in acs_objects.package_id%TYPE    default null
    ) return acs_objects.object_id%TYPE;

    function edit (
        message_id    in acs_messages.message_id%TYPE,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        text          in varchar2                       default null,
        data          in cr_revisions.content%TYPE      default null,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        is_live       in char                           default 't'
    ) return acs_objects.object_id%TYPE;

    procedure del (
        message_id    in acs_messages.message_id%TYPE
    );

    function message_p (
        message_id    in acs_messages.message_id%TYPE
    ) return char;

    procedure send (
        message_id    in acs_messages.message_id%TYPE,
        recipient_id  in parties.party_id%TYPE,
        grouping_id   in integer                        default null,
        wait_until    in date                           default sysdate
    );

    procedure send (
        message_id    in acs_messages.message_id%TYPE,
        to_address    in varchar2,
        grouping_id   in integer                        default null,
        wait_until    in date                           default sysdate
    );

    function first_ancestor (
        message_id    in acs_messages.message_id%TYPE
    ) return acs_messages.message_id%TYPE;

    -- ACHTUNG!  WARNING!  ACHTUNG!  WARNING!  ACHTUNG!  WARNING! --

    -- Developers: Please don't depend on the following functionality
    -- to remain in the same place.  Chances are very good these
    -- functions will migrate to another PL/SQL package or be replaced
    -- by direct calls to CR code in the near future.

    function new_file (
        message_id    in acs_messages.message_id%TYPE,
        file_id       in cr_items.item_id%TYPE          default null,
        file_name     in cr_items.name%TYPE,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        content       in cr_revisions.content%TYPE      default null,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        is_live       in char                           default 't',
        storage_type  in cr_items.storage_type%TYPE	default 'file',
        package_id    in acs_objects.package_id%TYPE    default null
    ) return acs_objects.object_id%TYPE;

    function edit_file (
        file_id       in cr_items.item_id%TYPE,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        content       in cr_revisions.content%TYPE      default null,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        is_live       in char                           default 't'
    ) return acs_objects.object_id%TYPE;

    procedure delete_file (
        file_id       in cr_items.item_id%TYPE
    );

    function new_image (
        message_id    in acs_messages.message_id%TYPE,
        image_id      in cr_items.item_id%TYPE          default null,
        file_name     in cr_items.name%TYPE,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE	default 'text/plain',
        content       in cr_revisions.content%TYPE      default null,
        width         in images.width%TYPE              default null,
        height        in images.height%TYPE             default null,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        is_live       in char                           default 't',
        storage_type  in cr_items.storage_type%TYPE	default 'file',
        package_id    in acs_objects.package_id%TYPE    default null
    ) return acs_objects.object_id%TYPE;

    function edit_image (
        image_id      in cr_items.item_id%TYPE,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE	default 'text/plain',
        content       in cr_revisions.content%TYPE      default null,
        width         in images.width%TYPE              default null,
        height        in images.height%TYPE             default null,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        is_live       in char                           default 't'
    ) return acs_objects.object_id%TYPE;

    procedure delete_image (
        image_id      in cr_items.item_id%TYPE
    );

    function new_extlink (
        name          in cr_items.name%TYPE		default null,
        extlink_id    in cr_extlinks.extlink_id%TYPE    default null,
        url           in cr_extlinks.url%TYPE,
        label         in cr_extlinks.label%TYPE         default null,
        description   in cr_extlinks.description%TYPE   default null,
        parent_id     in acs_objects.context_id%TYPE,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        package_id    in acs_objects.package_id%TYPE    default null
    ) return cr_extlinks.extlink_id%TYPE;

    function edit_extlink (
        extlink_id    in cr_extlinks.extlink_id%TYPE,
        url           in cr_extlinks.url%TYPE,
        label         in cr_extlinks.label%TYPE         default null,
        description   in cr_extlinks.description%TYPE   default null
    ) return cr_extlinks.extlink_id%TYPE;

    procedure delete_extlink (
        extlink_id    in cr_extlinks.extlink_id%TYPE
    );

    function name (
        message_id    in acs_objects.object_id%TYPE
    ) return varchar2;

end acs_message;
/
show errors

create or replace package body acs_message
as

    function new (
        message_id    in acs_messages.message_id%TYPE   default null,
        reply_to      in acs_messages.reply_to%TYPE     default null,
        sent_date     in acs_messages.sent_date%TYPE    default sysdate,
        sender        in acs_messages.sender%TYPE       default null,
        rfc822_id     in acs_messages.rfc822_id%TYPE    default null,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        text          in varchar2                       default null,
        data          in cr_revisions.content%TYPE      default null,
        parent_id     in cr_items.parent_id%TYPE        default -4,
        context_id    in acs_objects.context_id%TYPE,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        object_type   in acs_objects.object_type%TYPE   default 'acs_message',
        is_live       in char                           default 't',
        package_id    in acs_objects.package_id%TYPE    default null
    ) return acs_objects.object_id%TYPE
    is
        v_message_id   acs_messages.message_id%TYPE;
        v_rfc822_id    acs_messages.rfc822_id%TYPE;
        v_revision_id  cr_revisions.revision_id%TYPE;
    begin
    
        -- -- generate a message id now so we can get an rfc822 message-id
        -- if message_id is null then
        --     select acs_object_id_seq.nextval into v_message_id from dual;
        -- else
        --     v_message_id := message_id;
        -- end if;

        -- -- this needs to be fixed up, but Oracle doesn't give us a way
        -- -- to get the FQDN
        -- if rfc822_id is null then
        --     v_rfc822_id := sysdate || '.' || v_message_id || '@' ||
        --         utl_inaddr.get_host_name || '.hate';
        -- else
        --     v_rfc822_id := rfc822_id;
        -- end if;

	-- Antonio Pisano 2016-09-20
	-- rfc822_id MUST come from the tcl, no more
	-- sql tricks to retrieve one if missing.
	-- Motivations:
	-- 1) duplication. We have same logics in acs_mail_lite::generate_message_id
	-- 2) what if SystemURL is https?
	-- 3) empty SystemURL would break General Comments
        if rfc822_id is null then
	   RAISE SELF_IS_NULL;
        end if;

        v_message_id := content_item.new (
            name           => rfc822_id,
            parent_id      => parent_id,
            content_type   => 'acs_message_revision',
            item_id        => message_id,
            context_id     => context_id,
            creation_date  => creation_date,
            creation_user  => creation_user,
            creation_ip    => creation_ip,
            item_subtype   => object_type,
            package_id     => package_id
        );

        insert into acs_messages 
            (message_id, reply_to, sent_date, sender, rfc822_id)
        values 
            (v_message_id, reply_to, sent_date, sender, rfc822_id);

        -- create an initial revision for the new message
        v_revision_id := acs_message.edit (
            message_id     => v_message_id,
            title          => title,
            description    => description,
            mime_type      => mime_type,
            text           => text,
            data           => data,
            creation_date  => creation_date,
            creation_user  => creation_user,
            creation_ip    => creation_ip,
            is_live        => is_live
        );

        return v_message_id;
    end new;

    function edit (
        message_id    in acs_messages.message_id%TYPE,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        text          in varchar2                       default null,
        data          in cr_revisions.content%TYPE      default null,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        is_live       in char                           default 't'
    ) return acs_objects.object_id%TYPE
    is
        v_revision_id  cr_revisions.revision_id%TYPE;
    begin

        -- create a new revision using whichever call is appropriate
        if edit.data is not null then
            v_revision_id := content_revision.new (
                item_id        => message_id,
                title          => title,
                description    => description,
                data           => data,
                mime_type      => mime_type,
                creation_date  => creation_date,
                creation_user  => creation_user,
                creation_ip    => creation_ip
            );
        elsif title is not null or text is not null then
            v_revision_id := content_revision.new (
                item_id        => message_id,
                title          => title,
                description    => description,
                text           => text,
                mime_type      => mime_type,
                creation_date  => creation_date,
                creation_user  => creation_user,
                creation_ip    => creation_ip
            );      
        end if;

        -- test for auto approval of revision   
        if edit.is_live = 't' then 
            content_item.set_live_revision(v_revision_id);
        end if;

        return v_revision_id;

    end edit;   

    procedure del (
        message_id    in acs_messages.message_id%TYPE
    )
    is
    begin
        delete from acs_messages
            where message_id = acs_message.del.message_id;
        content_item.del(message_id);
    end del;

    function message_p (
        message_id    in acs_messages.message_id%TYPE
    ) return char
    is
        v_check_message_id  integer;
    begin
        select decode(count(message_id),0,0,1) into v_check_message_id
            from acs_messages
            where message_id = message_p.message_id;
        if v_check_message_id <> 0 then
            return 't';
        else
            return 'f';
        end if;
    end message_p;

    procedure send (
        message_id    in acs_messages.message_id%TYPE,
        to_address    in varchar2,
        grouping_id   in integer                        default null,
        wait_until    in date                           default sysdate
    )
    is
        v_wait_until date;
    begin
        v_wait_until := nvl(wait_until, sysdate);
        insert into acs_messages_outgoing
            (message_id, to_address, grouping_id, wait_until)
        values
            (message_id, to_address, grouping_id, v_wait_until);
    end send;

    procedure send (
        message_id    in acs_messages.message_id%TYPE,
        recipient_id  in parties.party_id%TYPE,
        grouping_id   in integer                        default null,
        wait_until    in date                           default sysdate
    )
    is
        v_wait_until date;
    begin
        v_wait_until := nvl(wait_until, sysdate);
        insert into acs_messages_outgoing
            (message_id, to_address, grouping_id, wait_until)
        select send.message_id, p.email, send.grouping_id, v_wait_until
            from parties p
            where p.party_id = send.recipient_id;
    end send;

    function first_ancestor (
        message_id in acs_messages.message_id%TYPE
    ) return acs_messages.message_id%TYPE
    is
        v_message_id acs_messages.message_id%TYPE;
    begin
        select message_id into v_message_id
            from (select message_id, reply_to
                   from acs_messages
                   connect by message_id = prior reply_to
                   start with message_id = first_ancestor.message_id) ancestors
            where reply_to is null;
        return v_message_id;
    end first_ancestor;

    -- ACHTUNG!  WARNING!  ACHTUNG!  WARNING!  ACHTUNG!  WARNING! --

    -- Developers: Please don't depend on the following functionality
    -- to remain in the same place.  Chances are very good these
    -- functions will migrate to another PL/SQL package or be replaced
    -- by direct calls to CR code in the near future.

    function new_file (
        message_id    in acs_messages.message_id%TYPE,
        file_id       in cr_items.item_id%TYPE          default null,
        file_name     in cr_items.name%TYPE,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        content       in cr_revisions.content%TYPE      default null,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        is_live       in char                           default 't',
        storage_type  in cr_items.storage_type%TYPE	default 'file',
        package_id    in acs_objects.package_id%TYPE    default null
    ) return acs_objects.object_id%TYPE
    is
        v_file_id      cr_items.item_id%TYPE;
        v_revision_id  cr_revisions.revision_id%TYPE;
    begin

        v_file_id := content_item.new (
            name           => file_name,
            parent_id      => message_id,
            item_id        => file_id,
            creation_date  => creation_date,
            creation_user  => creation_user,
            creation_ip    => creation_ip,
            storage_type   => storage_type,
            package_id     => package_id
        );

        -- create an initial revision for the new attachment
        v_revision_id := edit_file (
            file_id         => v_file_id,
            title           => title,
            description     => description,
            mime_type       => mime_type,
            content         => content,
            creation_date   => creation_date,
            creation_user   => creation_user,
            creation_ip     => creation_ip,
            is_live         => is_live
        );

        return v_file_id;
    end new_file;

    function edit_file (
        file_id       in cr_items.item_id%TYPE,
        title         in cr_revisions.title%TYPE        default null,
        description   in cr_revisions.description%TYPE  default null,
        mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
        content       in cr_revisions.content%TYPE      default null,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        is_live       in char                           default 't'
    ) return acs_objects.object_id%TYPE
    is
        v_revision_id  cr_revisions.revision_id%TYPE;
    begin

        v_revision_id := content_revision.new (
             title         => title,
             mime_type     => mime_type,
             data          => content,
             item_id       => file_id,
             creation_date => creation_date,
             creation_user => creation_user,
             creation_ip   => creation_ip
        );

        -- test for auto approval of revision
        if is_live = 't' then 
            content_item.set_live_revision(v_revision_id);
        end if;

        return v_revision_id;
    end edit_file;

    procedure delete_file (
        file_id  in cr_items.item_id%TYPE
    ) 
    is
    begin
        content_item.del(delete_file.file_id);       
    end delete_file;    

    function new_image (
        message_id     in acs_messages.message_id%TYPE,
        image_id       in cr_items.item_id%TYPE           default null,
        file_name      in cr_items.name%TYPE,
        title          in cr_revisions.title%TYPE         default null,
        description    in cr_revisions.description%TYPE   default null,
        mime_type      in cr_revisions.mime_type%TYPE     default 'text/plain',
        content        in cr_revisions.content%TYPE       default null,
        width          in images.width%TYPE               default null,
        height         in images.height%TYPE              default null,
        creation_date  in acs_objects.creation_date%TYPE  default sysdate,
        creation_user  in acs_objects.creation_user%TYPE  default null,
        creation_ip    in acs_objects.creation_ip%TYPE    default null,
        is_live        in char                            default 't',
        storage_type   in cr_items.storage_type%TYPE      default 'file',
        package_id    in acs_objects.package_id%TYPE      default null
    ) return acs_objects.object_id%TYPE
    is
        v_image_id     cr_items.item_id%TYPE;
        v_revision_id  cr_revisions.revision_id%TYPE;
    begin

        v_image_id := content_item.new (
            name           => file_name,
            parent_id      => message_id,
            item_id        => image_id,
            creation_date  => creation_date,
            creation_user  => creation_user,
            creation_ip    => creation_ip,
            storage_type   => storage_type,
            package_id     => package_id
        );

        -- create an initial revision for the new attachment
        v_revision_id := edit_image (
            image_id       => v_image_id,
            title          => title,
            description    => description,
            mime_type      => mime_type,
            content        => content,
            width          => width,
            height         => height,
            creation_date  => creation_date,
            creation_user  => creation_user,
            creation_ip    => creation_ip,
            is_live        => is_live
        );

        return v_image_id;
    end new_image;    

    function edit_image (
        image_id       in cr_items.item_id%TYPE,
        title          in cr_revisions.title%TYPE         default null,
        description    in cr_revisions.description%TYPE   default null,
        mime_type      in cr_revisions.mime_type%TYPE     default 'text/plain',
        content        in cr_revisions.content%TYPE       default null,
        width          in images.width%TYPE               default null,
        height         in images.height%TYPE              default null,
        creation_date  in acs_objects.creation_date%TYPE  default sysdate,
        creation_user  in acs_objects.creation_user%TYPE  default null,
        creation_ip    in acs_objects.creation_ip%TYPE    default null,
        is_live        in char                            default 't'
    ) return acs_objects.object_id%TYPE
    is
        v_revision_id  cr_revisions.revision_id%TYPE;
    begin

        v_revision_id := content_revision.new (
            title          => edit_image.title,
            mime_type      => edit_image.mime_type,
            data           => edit_image.content,
            item_id        => edit_image.image_id,
            creation_date  => edit_image.creation_date,
            creation_user  => edit_image.creation_user,
            creation_ip    => edit_image.creation_ip       
        );      

        -- insert new width and height values
        -- XXX fix after image.new exists
        insert into images
            (image_id, width, height)
        values
            (v_revision_id, width, height);

        -- test for auto approval of revision   
        if edit_image.is_live = 't' then 
            content_item.set_live_revision(v_revision_id);
        end if;

        return v_revision_id;
    end edit_image;

    procedure delete_image (
        image_id  in cr_items.item_id%TYPE
    )
    is
    begin
        -- XXX fix after image.delete exists
        delete from images
            where image_id = delete_image.image_id;
        content_item.del(image_id);
    end delete_image;

    -- XXX should just call content_extlink.new
    function new_extlink (
        name           in cr_items.name%TYPE              default null,
        extlink_id     in cr_extlinks.extlink_id%TYPE     default null,
        url            in cr_extlinks.url%TYPE,
        label          in cr_extlinks.label%TYPE          default null,
        description    in cr_extlinks.description%TYPE    default null,
        parent_id      in acs_objects.context_id%TYPE,
        creation_date  in acs_objects.creation_date%TYPE  default sysdate,
        creation_user  in acs_objects.creation_user%TYPE  default null,
        creation_ip    in acs_objects.creation_ip%TYPE    default null,
        package_id    in acs_objects.package_id%TYPE      default null
    ) return cr_extlinks.extlink_id%TYPE
    is
        v_extlink_id  cr_extlinks.extlink_id%TYPE;
    begin
        v_extlink_id := content_extlink.new (
            name           => new_extlink.name,
            url            => new_extlink.url,
            label          => new_extlink.label,
            description    => new_extlink.description,
            parent_id      => new_extlink.parent_id,
            extlink_id     => new_extlink.extlink_id,   
            creation_date  => new_extlink.creation_date,
            creation_user  => new_extlink.creation_user,
            creation_ip    => new_extlink.creation_ip,
            package_id     => new_extlink.package_id
        );
    end new_extlink;        
    
    -- XXX should just edit extlink
    function edit_extlink (
        extlink_id   in cr_extlinks.extlink_id%TYPE,
        url          in cr_extlinks.url%TYPE,
        label        in cr_extlinks.label%TYPE        default null,
        description  in cr_extlinks.description%TYPE  default null
    ) return cr_extlinks.extlink_id%TYPE
    is
      v_is_extlink  char;
    begin
        v_is_extlink := content_extlink.is_extlink(edit_extlink.extlink_id);
        if v_is_extlink = 't' then
            update cr_extlinks
            set url = edit_extlink.url,
                label = edit_extlink.label,
                description = edit_extlink.description
            where extlink_id = edit_extlink.extlink_id;
        end if;
        return v_is_extlink;
    end edit_extlink;

    procedure delete_extlink (
        extlink_id  in cr_extlinks.extlink_id%TYPE
    ) is
    begin
        content_extlink.del(extlink_id => delete_extlink.extlink_id);
    end delete_extlink;

    function name (
        message_id      in acs_objects.object_id%TYPE
    ) return varchar2
    is
        v_message_name   acs_messages_all.title%TYPE;
    begin
        select title into v_message_name
            from acs_messages_all
	    where message_id = name.message_id;
        return v_message_name;
    end name;

end acs_message;
/
show errors
