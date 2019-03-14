
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: scrldialog.tcl,v 1.10 2000/09/14 23:06:50 karl Exp $
# $Log: scrldialog.tcl,v $
# Revision 1.10  2000/09/14 23:06:50  karl
# Moved visibility binding setup out to separate proc.
#
# Revision 1.9  2000/09/11  22:08:04  karl
# Replaced global grab with more reasonable Visibility binding.
#
# Revision 1.8  2000/08/16  17:50:11  karl
# Had to add a scrollbar . . . viedit provided one but text does not.
#
# Revision 1.7  2000/08/15  22:49:39  karl
# Changed to only do global grab if error bitmap used.
#
# Revision 1.6  2000/08/08  19:29:18  karl
# Added global grab.
# Change viedit to text widget and added padding around text.
#
# Revision 1.5  2000/07/07  21:52:11  karl
# Fixed to adjust width up to 160 characters.
#
# Revision 1.4  1998/12/11  21:12:04  karl
# Changed to automatically take widget width from widest input text line.
#
# Revision 1.3  1998/09/01  19:01:03  karl
# Changed to pass through config parms (i.e. -height 20 -bg white) to
# underlying text widget.
#
# Revision 1.2  1997/05/23  17:01:45  karl
# Added pop_info_show command and made the scrl_dialog window wider.
#
# Revision 1.1  1996/08/27  16:25:02  karl
# Initial revision
#
proc scrl_dialog {w title text bitmap default args} {
    global tkPriv 

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}

    # 1. Create the top-level window and divide it into top
    # and bottom parts.

    catch {destroy $w}

    toplevel $w -class Dialog
    wm title $w $title
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW { }
#does not work with tcl/tk83
   # wm transient $w [winfo toplevel [winfo parent $w]]
    frame $w.top -relief raised -bd 1
    pack $w.top -side top -fill both -expand 1
    frame $w.bot -relief raised -bd 1
    pack $w.bot -side bottom -fill both

    # 2. Fill the top part with bitmap and message.

    set textlen [llength [split $text "\n"]]
	button .dummy
	set regfont [lindex [.dummy configure -font] 3]
	destroy .dummy
    set textwidth 0
    foreach line [split $text "\n"] {
	set linelen [string length $line]
	if {$linelen>$textwidth && $linelen<160} {
		set textwidth $linelen
	}
    }

    text $w.msg -height 12 -width $textwidth -font $regfont -padx 5 -pady 5 \
		-yscrollcommand "$w.scrl set"
	scrollbar $w.scrl -command "$w.msg yview"
    $w.msg insert 1.0 $text
    $w.msg mark set insert 1.0
    $w.msg configure -state disabled
	pack $w.scrl -in $w.top -side right -expand 1 -fill y
    pack $w.msg -in $w.top -side right -expand 1 -fill both -padx 3m -pady 3m 
    if {$bitmap != ""} {
	label $w.bitmap -bitmap $bitmap
	pack $w.bitmap -in $w.top -side left -padx 3m -pady 3m
    }

    # 3. Create a row of buttons at the bottom of the dialog.

    set i 0
    for {set el 0} {$el<[llength $args]} {incr el} {
	set but [lindex $args $el]
	if {[string index $but 0]=="-"} {
		if {[string match "-width *" $but]} {
			eval $w.msg configure $but
		} else {
			$w.msg configure $but [lindex $args [expr $el + 1]]
			incr el
		}
	} else {
		button $w.button$i -text $but -command "set tkPriv(button) $i"
		if {$i == $default} {
		    pack $w.button$i -in $w.bot -side left -expand 1 \
			    -padx 3m -pady 2m
		    focus $w.button$i
		    bind $w <Return> "$w.button$i flash; set tkPriv(button) $i"
		} else {
		    pack $w.button$i -in $w.bot -side left -expand 1 \
			    -padx 3m -pady 2m
		}
		incr i
	}
    }

    # 4. Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it.

    wm withdraw $w
    update idletasks
    set x [expr [winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
	    - [winfo vrootx [winfo parent $w]]]
    set y [expr [winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
	    - [winfo vrooty [winfo parent $w]]]
    wm geom $w +$x+$y
    wm deiconify $w

    # 5. Set a grab and claim the focus too.

    set oldFocus [focus]
	if {$bitmap=="error"} {
    	catch {grab $w; an_keep_on_top $w}
	}
    tkwait visibility $w
    if {$default >= 0} {
	focus $w.button$default
    } else {
	focus $w
    }

    # 6. Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.

    tkwait variable tkPriv(button)
    catch {focus $oldFocus}
    destroy $w
    return $tkPriv(button)
}

proc pop_info_show {string} {
	if [winfo exists .poptmp] {
		return
	}
    	lassign [winfo pointerxy .] x y
        toplevel .poptmp -relief groove -bd 2
    	wm geometry .poptmp +[expr $x - 50]+[expr $y - 30]
        set sw [winfo screenwidth .]
        set sh [winfo screenheight .]
	text .dummy
	set fixedfont [.dummy cget -font]
	destroy .dummy
        label .poptmp.lab -text $string -font $fixedfont -bg lightyellow \
		-justify left -padx 10 -pady 5
        pack .poptmp.lab
        set w .poptmp
 
    #set x [expr [winfo screenwidth .]/2 - [winfo reqwidth .poptmp.lab]/2 \
    #        - [winfo vrootx [winfo parent .poptmp.lab]]]
    #set y [expr [winfo screenheight .]/2 - [winfo reqheight .poptmp.lab]/2 \
    #        - [winfo vrooty [winfo parent .poptmp.lab]]]
 
        wm minsize $w 1 1
    wm withdraw $w
    #wm geom $w +$x+$y
        wm overrideredirect $w 1
 
    update idletasks; wm deiconify $w
}

proc pop_info_hide {} {
	catch {destroy .poptmp}
}
