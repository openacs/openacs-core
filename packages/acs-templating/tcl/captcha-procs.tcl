ad_library {
    A captcha implementation for the template system.

    @author Antonio Pisano
}

namespace eval captcha {}
namespace eval captcha::image {}

ad_proc -private captcha::image::generate__convert {
    -height:required
    -width:required
    -text
    {-background "#ffffff"}
    {-fill "#000000"}
    -path:required
} {
    Creates capcha image from a text. This is the implementation using
    the popular convert command via exec. It will render the letters,
    then perturbate them with a wave of random length and amplitude.

    @param height in pixels
    @param width in pixels
    @param text the text to use for the captcha. When unspecified, a
                random text will be used. The text can only contain
                alphanumeric characters and spaces.
    @param background the background color, as RGB 6 characters code.
    @param fill the font color, background the background color, as
                RGB 6 characters code.

    @see https://imagemagick.org/script/convert.php

    @return a dict of fields 'path' (path to the image), 'text' (the
            text the image represents) and chec ksum (a checksum for
            the image to use for matching).
} {
    set amplitude [expr {round($height * 0.25)}]
    set wavelength [expr {round($width * 0.75)}]
    set offset [expr {round($width * rand())}]

    exec [::util::which convert] \
        -size ${width}x${height} \
        -background $background \
        -fill $fill \
        label:$text \
        -splice ${offset}x0+0+0 \
        -wave ${amplitude}x${wavelength} \
        -chop   ${offset}x0+0+0 \
        $path

    if {![file exists $path]} {
        error "File '$destination' was not generated"
    }
}

ad_proc -private captcha::image::generate__tclgd {
    -height:required
    -width:required
    -text
    {-background "#ffffff"}
    {-fill "#000000"}
    -path:required
} {
    Creates a capcha image from a text. This is and implementation
    using the libgd Tcl wrapper tclgd. Every character in the text
    will be rotated by a random angle and sprinkled with some noise.

    @param height in pixels
    @param width in pixels
    @param text the text to use for the captcha. When unspecified, a
                random text will be used. The text can only contain
                alphanumeric characters and spaces.
    @param background the background color, as RGB 6 characters code.
    @param fill the font color, background the background color, as
                RGB 6 characters code.

    @see https://flightaware.github.io/tcl.gd/

    @return a dict of fields 'path' (path to the image), 'text' (the
            text the image represents) and chec ksum (a checksum for
            the image to use for matching).
} {
    # Convert the rgb colors
    for {set i 1} {$i <= 5} {incr i 2} {
        lappend bg_color [expr 0x[string range $background $i $i+1]]
        lappend fg_color [expr 0x[string range $fill $i $i+1]]
    }

    package require tclgd

    set n_chars [string length $text]

    # Make sure there is space for the letters to be rotated without
    # overlapping with the others.
    set width [expr {int(max($width, $n_chars * $height * pow(2, -2)))}]

    set font "[acs_root_dir]/packages/acs-templating/resources/fonts/LiberationSans-Regular.ttf"

    # Rule of thumb to calculate the font size
    set font_size [expr {($height / 500.0) * 300.0}]

    set tot_width [expr {$width * $n_chars}]
    GD create captcha $tot_width $height

    set dest_y [expr {$height / 2}]

    # Create the letters and copy them flipped on the captcha. Would
    # be nice to generate them in place, but rotation expressed in the
    # text subcommand is not applied to the center.
    for {set i 0} {$i < $n_chars} {incr i} {
        set l [string index $text $i]

        GD create letter $width $height
        set foreground [letter allocate_color {*}$fg_color]
        set background [letter allocate_color {*}$bg_color]
        letter fill 0 0 $background

        set bbox [letter text_bounds $foreground $font $font_size 0 0 0 $l]
        set font_x [expr {abs([lindex $bbox 4] - [lindex $bbox 0])}]
        set font_y [expr {abs([lindex $bbox 5] - [lindex $bbox 1])}]

        set x [expr {int(($width - $font_x) * 0.5)}]
        set y [expr {int(($height + $font_y) * 0.5)}]
        letter text $foreground $font $font_size 0 $x $y $l

        set angle [expr {int(rand() * 360)}]
        set dest_x [expr {$width * $i + $width / 2}]
        captcha copy_rotated letter $dest_x $dest_y 0 0 $width $height $angle
    }

    # Spray some noise on 2% of the image
    set grey [letter allocate_color 100 100 100 0]
    set noisy_pixels [expr {int($tot_width * $height * 0.02)}]
    for {set i 0} {$i < $noisy_pixels} {incr i} {
        set x [expr {int(rand() * $tot_width)}]
        set y [expr {int(rand() * $height)}]
        captcha pixel $x $y $grey
    }

    set wfd [open $path w]
    captcha write_png $wfd 1
    close $wfd
}

ad_proc -private captcha::image::generate {
    {-size 150x50}
    -text
    {-background "#ffffff"}
    {-fill "#000000"}
} {
    Creates a distorted capcha image from a text.

    @param size the size expressed as \{width\}x\{height\} in pixel
    @param text the text to use for the captcha. When unspecified, a
                random text will be used. The text can only contain
                alphanumeric characters and spaces.
    @param background the background color, as RGB 6 characters code.
    @param fill the font color, background the background color, as
                RGB 6 characters code.

    @return a dict of fields 'path' (path to the image), 'text' (the
            text the image represents) and chec ksum (a checksum for
            the image to use for matching).
} {
    try {
        package require tclgd
    } on error {errmsg} {
        set convert [::util::which convert]
        if {$convert eq ""} {
            error {'tclgd' or 'convert' command not available.}
        }
        set backend convert
    } on ok {d} {
        set backend tclgd
    }

    if {![regexp -nocase {^(\d+)x(\d+)$} $size m width height]} {
        error {Invalid size}
    }
    if {![regexp -nocase {^(\#([0-9]|[a-f]){6}){2}$} ${background}${fill}]} {
        error {Invalid color}
    }
    if {[info exists text]} {
        if {![regexp {^(\w| )*$} $text]} {
            error {'text' can only contain alphanumerics and spaces}
        }
    } else {
        set text [ad_generate_random_string 5]
    }

    set path [ad_tmpnam].png

    captcha::image::generate__$backend \
        -height $height \
        -width $width \
        -text $text \
        -background $background \
        -fill $fill \
        -path $path

    set checksum [ns_md file -digest sha1 $path]

    return [list \
                text $text \
                path $path \
                checksum $checksum]
}

namespace eval template {}
namespace eval template::widget {}

ad_proc -public template::widget::captcha {
    element_reference
    tag_attributes
} {
    Generate a captcha text widget. This widget will display a captcha
    image containing a text. On validation, the value supplied by the
    user must match the value in the captcha.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {
    if {![ns_conn isconnected]} {
        return
    }

    upvar $element_reference element

    if {[info exists element(background)]} {
        set background $element(background)
    } else {
        set background #ffffff
    }
    if {[info exists element(fill)]} {
        set fill $element(fill)
    } else {
        set fill #000000
    }
    if {[info exists element(size)]} {
        set size $element(size)
    } else {
        set size 150x50
    }

    set captcha [captcha::image::generate \
                     -background $background \
                     -fill $fill \
                     -size $size]

    set checksum [dict get $captcha checksum]
    set text [dict get $captcha text]

    # The capcha image we are injecting directly into the page as
    # base64 to not clutter the filesystem and mess around with
    # request processor.
    set captcha_path [dict get $captcha path]
    set rfd [open $captcha_path r]
    fconfigure $rfd -translation binary
    set base64image [ns_base64encode -- [read $rfd]]
    ::file delete -- $captcha_path
    close $rfd

    if {[info exists element(expire)]} {
        set expiration $element(expire)
    } else {
        set expiration 3600
    }
    # Store the checksum in the database together with the text we
    # expect. While we do this, we also take care of cleaning up
    # expired captchas.
    db_dml store_captcha {
        with
        cleanup as (
            delete from template_widget_captchas
            where image_checksum = :checksum
               or expiration < current_timestamp
        )
        insert into template_widget_captchas
        (image_checksum, text, expiration)
        values
        (:checksum,
         :text,
         current_timestamp + cast(:expiration || ' seconds' as interval)
         )
    }

    set captcha_checksum_id $element(form_id):$element(name):image_checksum
    return [subst {
        <input type="hidden"
               id="$captcha_checksum_id"
               name="$captcha_checksum_id"
               value="$checksum">
        <div><img src="data:image/png;base64,$base64image"></div>
        <div>[input text element $tag_attributes]</div>
    }]
}

namespace eval template::data {}
namespace eval template::data::validate {}

ad_proc -public template::data::validate::captcha {
    value_ref
    message_ref
} {
    Validate the captcha widget by matching the image checksum against
    the text that was supplied by the user.

    @param value_ref Reference variable to the submitted value.
    @param message_ref Reference variable for returning an error
                       message.

    @return True (1) if valid, false (0) if not.
} {
    if {![ns_conn isconnected]} {
        return 1
    }

    upvar 2 \
        $message_ref message \
        $value_ref value \
        element element

    set checksum [ns_queryget $element(form_id):$element(name):image_checksum]
    if {$checksum ne ""} {
        # While we check for this particular captcha, we also sloppily
        # cleanup the ones that have already expired.
        set valid_p [db_0or1row check_captcha {
            with
            lookup as (
               select text, image_checksum
                 from template_widget_captchas
                where image_checksum = :checksum
            ),
            cleanup as (
                delete from template_widget_captchas
                where image_checksum = (select image_checksum from lookup)
                   or expiration < current_timestamp
            )
            select 1 from lookup where text = :value
        }]
    } else {
        set valid_p 0
    }

    if {!$valid_p} {
        set message [_ acs-templating.Your_captcha_is_invalid]
    }

    return $valid_p
}

