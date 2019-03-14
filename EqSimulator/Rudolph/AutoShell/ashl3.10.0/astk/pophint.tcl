
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: pophint.tcl,v 1.1 1996/08/27 16:25:19 karl Exp $
# $Log: pophint.tcl,v $
# Revision 1.1  1996/08/27 16:25:19  karl
# Initial revision
#
# This procedure can be called to provide a hint for a button or other widget
# if the cursor lingers on the widget for more than 2 seconds.  
# For each widget that you want a popup hint for, insert the following line
# in your code:
# 
# 	bind .my.widget <Enter> {ready_hint .my.widget "This is a hint."}

proc ready_hint {window hint} {
	set id [after 1500 "
		toplevel .tmp
		wm geometry .tmp \
			+\[winfo pointerx .\]+\[expr \[winfo pointery .\]+20\]
		wm overrideredirect .tmp 1
		frame .tmp.frm -background black
		pack .tmp.frm
		label .tmp.tmp2 -text \"$hint\" \
			-background yellow -foreground black
		pack .tmp.tmp2 -in .tmp.frm -padx 2 -pady 2
	"]
	bind $window <Leave> "catch {destroy .tmp}; after cancel $id"
}
