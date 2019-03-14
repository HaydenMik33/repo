
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: parm2arr.tcl,v 1.1 1996/08/27 16:16:32 karl Exp $
# $Log: parm2arr.tcl,v $
# Revision 1.1  1996/08/27 16:16:32  karl
# Initial revision
#
proc parms_to_array {list arrayname} {
	#log "placing '$list' into $arrayname"
	upvar #0 $arrayname array
	#catch {unset array}
	foreach el $list {
		set tag [lindex $el 0]
		set val [lindex $el 1]
		if {$val!=""} {
			set array($tag) [string trim $val]
		} else {
			set array($tag) Y
		}
	}	
}

proc array_to_parms {arrayname} {
	upvar #0 $arrayname array
	set list {}
	foreach el [array names array] {
		if {$array($el)!=""} {
			set sublist {}
			lappend sublist $el
			lappend sublist [string trim $array($el)]
			#lappend list "$el {[string trim $array($el)]}"
			lappend list $sublist
		}
	}
	return [lsort $list]
}
#puts "Calling parms_to_array"
#parms_to_array {{command test} {comment blah} {clear Y}} testarray
#foreach el [array names testarray] {
#	puts "$el : $testarray($el)"
#}
#puts "Calling array_to_parms"
#puts "[array_to_parms testarray]"
