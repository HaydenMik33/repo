
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: getstring.tcl,v 1.3 2000/06/14 22:58:57 karl Exp $
# $Log: getstring.tcl,v $
# Revision 1.3  2000/06/14 22:58:57  karl
# Added cancelval option to getstring.
#
# Revision 1.2  1997/05/13  17:12:48  karl
# Added an "update idletasks" and added some padding.
#
# Revision 1.1  1996/08/27  16:13:54  karl
# Initial revision
#
# Pops up a window for the user to enter a string in an entry widget
# The proc returns the text entered in the entry widget 
proc get_string { sstring stringval {cancelval {}}} {
# sstring -> string displayed as a label above the entry widget 
# stringval -> Contains the initial value to be placed in the entry widget

    global gs_strval gs_cancelval

	set gs_cancelval $cancelval
    set tmp $stringval
    set gs_strval ""
    toplevel .stringbox

 	wm geometry .stringbox "+[expr [winfo pointerx .] - 200]+[expr [winfo pointery .] - 15]"

    update idletasks
    grab .stringbox
    wm title .stringbox " "
    label .stringbox.label -text $sstring 
    pack .stringbox.label -side top 
    entry .stringbox.entry -relief sunken -width 30 
    pack .stringbox.entry -side top -padx 5 -pady 5

    # Entry widget operations
    .stringbox.entry delete 0 end 
    .stringbox.entry insert 1 $stringval

    button .stringbox.ok -text Ok -command {
     global gs_strval
     set gs_strval [.stringbox.entry get]
     destroy .stringbox 
     }
    button .stringbox.cancel -text Cancel -command {
	 global gs_strval
	 set gs_strval $gs_cancelval
     destroy .stringbox }
    pack .stringbox.ok .stringbox.cancel -side left -expand 1 

    bind .stringbox.entry <Return> { 
     global gs_strval
     set gs_strval [.stringbox.entry get]
     destroy .stringbox
    }

    bind .stringbox <Escape> {
     destroy .stringbox
     set gs_strval "" }
	focus .stringbox.entry

    tkwait window .stringbox
    return $gs_strval
}
