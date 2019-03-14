
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: antkdialog.tcl,v 1.4 2000/12/14 22:44:42 karl Exp $
# $Log: antkdialog.tcl,v $
# Revision 1.4  2000/12/14 22:44:42  karl
# Added option to turn off feature that floats TK blocking dialogs
# to the surface when they get hidden by the window manager.  If
# the file ~/.astknofloat exists, the float feature will be disabled,
# meaning that users that get into clicking frenzies can end up
# with dialogs hidden behind other windows.  The float feature
# is only known to cause problems on Linux Gnome displays.
#
# Revision 1.3  2000/09/14 23:00:55  karl
# Changed Visibility binding to raise window if obscured at 1, 2, 4, 8,
# 16 ... second intervals, to make competing warning windows more
# manageable.
#
# Revision 1.2  2000/09/11  21:33:23  karl
# Replaced global grab with more workable Visibility binding.
#
# Revision 1.1  2000/08/09  21:03:37  karl
# Initial revision
#

source $env(TK_LIBRARY)/dialog.tcl

proc an_keep_on_top {w} {
	global akot_counts
	set akot_counts($w) 1
    bind $w <Visibility> "+after 3000 {an_bring_to_top $w}"
}

proc an_bring_to_top {w} {
	global akot_counts
	if {[winfo exists $w]} {
		if {$akot_counts($w)<4} {
			raise $w
			incr akot_counts($w)
			bind $w <Visibility> "+after [expr $akot_counts($w) * 3000] \
				{an_bring_to_top $w}"
		} else {
			bind $w <Visibility> {}
			set akot_counts($w) 0
		}
	}
}

# Set up all tk_dialog windows to float to surface, unless user
# turns it off by creating a .astknofloat file in their home dir.
if {![file exists ~/.astknofloat]} {
	rename tk_dialog old_tk_dialog
	set tmp [info body old_tk_dialog]
	regsub {grab \$w} $tmp {grab $w; an_keep_on_top $w} tmp
	proc tk_dialog {w title text bitmap default args} $tmp
}

option add *font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* 
option add *Entry.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*
option add *Text.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*

