
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: wtree.tcl,v 1.1 1996/08/27 16:23:27 karl Exp $
# $Log: wtree.tcl,v $
# Revision 1.1  1996/08/27 16:23:27  karl
# Initial revision
#
proc wtree {window} {
	set fid [open wt$window w]
	if {$fid!=""} {
		children_of $fid $window 0
	}
	close $fid
}

proc children_of {fid window level} {
	for {set t 0} {$t<$level} {incr t} {
		puts -nonewline $fid "  "
	}
	puts $fid $window
	set children [winfo children $window]
	foreach child $children {
		children_of $fid $child [expr $level+1]
	}
}
