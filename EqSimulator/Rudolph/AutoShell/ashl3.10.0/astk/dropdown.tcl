
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: dropdown.tcl,v 1.1 1996/08/27 16:12:25 karl Exp $
# $Log: dropdown.tcl,v $
# Revision 1.1  1996/08/27 16:12:25  karl
# Initial revision
#
proc dropdown {wn args} {
    global ddi
    set editable 0
    set width 20
    set argc [llength $args]
    for {set n 0} {$n < $argc} {incr n} {
	set val [lindex $args $n]
	switch -- $val {
	    "-list" {
		incr n
		set list [lindex $args $n]
	    }
	    "-width" {
		incr n
		set width [lindex $args $n]
	    }
	    "-editable" {
		incr n
		set editable [lindex $args $n]
	    }
		"-value"  {
		incr n
		set ddi($wn,val) [lindex $args $n]
		}
	}	
    }
    if {![info exists list]} {
	return -code error "list must be specified"
    }
    frame $wn
    bind $wn <Destroy> "
		global ddi
		rename $wn {}
		catch {rename ${wn}old {}}
		unset ddi($wn,val)
		unset ddi($wn,list)
	"
	if {![info exists ddi($wn,val)]}  {
    	set ddi($wn,val) [lindex $list 0]
	}
    if {$editable} {
	set type entry
    } else {
	set type label
    }
    $type $wn.lab -textvariable ddi($wn,val) -width $width -relief sunken -bd 2
    if {$type == "label"}  "$wn.lab configure -anchor w"
    if {$editable} {
	bind $wn.lab <Return> "
	    global ddi
	    set ddi($wn,val) \[string trim \$ddi($wn,val)\]
	    lappend ddi($wn,list) \"\$ddi($wn,val)\"
	    $wn.butt.menu add command -label \$ddi($wn,val) \
		    -command {global ddi; set ddi($wn,val) {\$ddi($wn,val)}}
	    break
	    "
	bindtags $wn.lab "$wn.lab Entry all ."
    }
    menubutton $wn.butt -text "v" -menu $wn.butt.menu -relief raised
    menu $wn.butt.menu -tearoff 0
    foreach item $list {
	$wn.butt.menu add command -label $item \
	    -command "global ddi; set ddi($wn,val) {$item}"
    }
    set ddi($wn,list) $list
    pack $wn.lab $wn.butt -side left
    catch {rename $wn ${wn}old}
    proc $wn {cmd} "
		global ddi
		if {\$cmd=={get}} {
			return \$ddi($wn,val)
		}
	"
}

