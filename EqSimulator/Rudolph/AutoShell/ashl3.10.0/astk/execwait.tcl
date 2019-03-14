
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: execwait.tcl,v 1.1 2000/04/25 17:18:49 karl Exp $
# $Log: execwait.tcl,v $
# Revision 1.1  2000/04/25 17:18:49  karl
# Initial revision
#
# Executes an external command, and invokes a callback when the external
# command finishes.

proc exec_and_wait {cmd script} {
	global env
	set p [open "|$cmd" r+]
	fconfigure $p -blocking 0 -buffering none
	fileevent $p readable "eaw_done {$script} $p"

}

proc eaw_done {script p} {
	if {[eof $p]} {
		fileevent $p readable ""	
		close $p
		eval $script
	} else {
		# Ignore spurious state changes to readable - happens on Windows in 8.5
		gets $p inline
		if {[info exists inline] && $inline == "READY"} {
			fileevent $p readable ""	
			close $p
			eval $script
		}
		# Otherwise keep waiting
	}
}

#proc testit {} {
#	button .exit -text Exit -command "exit"
#	pack .exit
#	puts "Calling command"
#	exec_and_wait "/home/karl/sol2/bin/anp junk.tcl" ""
#	puts "Called command"
#}
#testit
