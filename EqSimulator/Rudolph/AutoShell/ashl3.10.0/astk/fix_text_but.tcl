
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

#
# this procedure changes the behaviour of button-1 and button-2 to
# match that of and xterm.  In other words, the mouse can only be
# used to select text and insert it at the insertion cursor (as
# opposed to the mouse position).  The mouse can't be used to 
# move the insertion point around.
#
proc fix_text_button_behavior {t} {

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateCommand tkTextSelectTo
		tk::unsupported::ExposePrivateVariable tkPriv
	}

	bind $t <1> {
		set tkPriv(selectMode) char
		set tkPriv(mouseMoved) 0
		set tkPriv(pressX) %x
		%W mark set anchor @%x,%y
		if {[%W cget -state] == "normal"} {focus %W}
		%W tag remove sel 0.0 end
		break
	}

	bind $t <Double-1> {
		set tkPriv(selectMode) word
		tkTextSelectTo %W %x %y
		break
	}

	bind $t <Triple-1> {
		set tkPriv(selectMode) line
		tkTextSelectTo %W %x %y
		break
	}

}


# $Id: fix_text_but.tcl,v 1.1 1996/08/27 16:13:39 karl Exp $
# $Log: fix_text_but.tcl,v $
# Revision 1.1  1996/08/27 16:13:39  karl
# Initial revision
