
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: scrlform.tcl,v 1.2 2002/01/18 16:20:31 karl Exp $
# $Log: scrlform.tcl,v $
# Revision 1.2  2002/01/18 16:20:31  karl
# Added optional scrollbar config.
#
# Revision 1.1  1998/08/06 17:05:41  karl
# Initial revision
#
# ----------------------------------------------------------------------
#  EXAMPLE: use the canvas to build a scrollable form
# ----------------------------------------------------------------------
#  Effective Tcl/Tk Programming
#    Mark Harrison, DSC Communications Corp.
#    Michael McLennan, Bell Labs Innovations for Lucent Technologies
#    Addison-Wesley Professional Computing Series
# ======================================================================
#  Copyright (c) 1996-1997  Lucent Technologies Inc. and Mark Harrison
# ======================================================================

# ----------------------------------------------------------------------
#  USAGE:  scrollform_create <win>
#
#  Creates an empty scrollform assembly.  The interior frame for this
#  form can be found by calling "scrollform_interior".  Widgets packed
#  into the interior can be scrolled in the vertical direction.
# ----------------------------------------------------------------------
proc scrollform_create {win {scrollbars y} args} {

    eval frame $win -class Scrollform $args

    if {$scrollbars=="y" || $scrollbars=="both"} {
        scrollbar $win.sbar -command "$win.vport yview"
        pack $win.sbar -side right -fill y 
    }

    if {$scrollbars=="x" || $scrollbars=="both"} {
        scrollbar $win.sbarx -command "$win.vport xview" -orient horizontal
        pack $win.sbarx  -side bottom -fill x 
    }

    canvas $win.vport 
	#-width [winfo reqwidth $win] -height [winfo reqheight $win]
    if {$scrollbars=="y" || $scrollbars=="both"} {
        $win.vport configure -yscrollcommand "$win.sbar set" 
    }
    if {$scrollbars=="x" || $scrollbars=="both"} {
        $win.vport configure -xscrollcommand "$win.sbarx set" 
    }
    pack $win.vport -side left -fill both -expand true

    frame $win.vport.form
    $win.vport create window 0 0 -anchor nw -window $win.vport.form

    bind $win.vport.form <Configure> "scrollform_resize $win"

    return $win
}

# ----------------------------------------------------------------------
#  USAGE:  scrollform_resize <win>
#
#  Used internally to handle size changes in the form area within
#  a scrollform assembly.  Updates the canvas to recognize the new
#  scrolling area.
# ----------------------------------------------------------------------
proc scrollform_resize {win} {
    set bbox [$win.vport bbox all]
    set wid [winfo width $win.vport.form]
    #set ht [winfo height $win.vport.form]
    set ht 400
    $win.vport configure -width $wid -height $ht \
        -scrollregion $bbox -yscrollincrement 0.1i \
	-xscrollincrement 0.1i
}

# ----------------------------------------------------------------------
#  USAGE:  scrollform_interior <win>
#
#  Returns the name of the interior frame that represents the
#  body of the scrollform.  Widgets should be packed in this
#  frame to build the form.
# ----------------------------------------------------------------------
proc scrollform_interior {win} {
    return "$win.vport.form"
}
