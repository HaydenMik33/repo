
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

#
# procedure to fix a bug in Tk4.x
# the default binding inserts the selected text at the mouse position,
# not the insertion point as stated in the man pages
#
proc fix_text_button2_release {{t Text}} {

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateCommand tkTextSelectTo
		tk::unsupported::ExposePrivateVariable tkPriv
	}

	bind $t <ButtonRelease-2> {
		if !$tkPriv(mouseMoved) {
			catch {
				%W insert insert [selection get -displayof %W]
			}
		}
		break
	}

	bind $t <1> {
		global ftb2_flag
		tkTextButton1 %W %x %y
		set ftb2_flag 1
		break
	}

	bind $t <B1-Motion> {
		global ftb2_flag
		if {[info exists ftb2_flag] && $ftb2_flag} {
			%W tag remove sel 0.0 end
			set ftb2_flag 0
		}
		set tkPriv(x) %x
		set tkPriv(y) %y
		tkTextSelectTo %W %x %y
		break
	}
}

# $Id: fix_text_b2.tcl,v 1.3 1996/11/06 16:16:25 jasonm Exp $
# $Log: fix_text_b2.tcl,v $
# Revision 1.3  1996/11/06 16:16:25  jasonm
# make previous change backward compatible, now if you don't pass an
# argument, it's affects all Text widgets.
#
# Revision 1.2  1996/11/01  21:04:41  jasonm
# changed so that you must specify a widget. also, added a break so
# the system binding doesn't fire also
#
# Revision 1.1  1996/08/27  16:14:16  karl
# Initial revision
