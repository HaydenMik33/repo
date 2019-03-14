
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: editlist.tcl,v 1.2 2000/07/14 15:08:20 karl Exp $
# $Log: editlist.tcl,v $
# Revision 1.2  2000/07/14 15:08:20  karl
# Fixed to support multiple editlist windows at one time.
#
# Revision 1.1  1996/08/27  16:12:39  karl
# Initial revision
#
#source style.tcl
#source ../tktalk/selbind.tcl

proc el_return {eltop} {
		global el_result
		$eltop.list insert end $el_result($eltop)
		set el_result($eltop) ""
}

proc el_delete {eltop} {
	$eltop.list delete [lindex [$eltop.list curselection ] 0]
}

proc el_double_button {eltop} {
	global el_result el_list
	#%W select from [%W nearest %y]
	if {[catch {set el_result($eltop) [lindex [lindex [selection get] 0] 0]}]} {
	} else {
		set el_list {}
		for {set i 0} {$i<[$eltop.list size]} {incr i} {
			lappend el_list [$eltop.list get $i]
		}
		destroy $eltop
	}
}

proc el_button {eltop} {
		global el_result
		#%W select from [%W nearest %y]
		catch {set el_result($eltop) [lindex [lindex [selection get] 0] 0]}
}

proc el_add {eltop} {
	global el_result
	$eltop.list insert end $el_result($eltop)
}

proc el_cancel {eltop} {
		global el_result el_list el_oldlist
		set el_result($eltop) {}
		set el_list $el_oldlist
		destroy $eltop
}

proc el_delete {eltop} {
        $eltop.list delete [lindex [$eltop.list curselection ] 0]
}

proc el_select {eltop} {
		global el_list
		set el_list {}
		for {set i 0} {$i<[$eltop.list size]} {incr i} {
			lappend el_list [$eltop.list get $i]
		}
		destroy $eltop
}

proc el_ok {eltop} {
			global el_list el_result
			set el_list {}
			for {set i 0} {$i<[$eltop.list size]} {incr i} {
				lappend el_list [$eltop.list get $i]
			}
			destroy $eltop
			set el_result($eltop) "CHECK_DELETES"
}

global el_count
set el_count 0
proc edit_list {listname startitem title ok_text args} {
	global el_result 
	upvar $listname list
	if {![info exists list]} {
		set list {}
	}
	global el_list el_oldlist
	set el_oldlist $list
	set el_list {}
	global el_count
	set eltop .el$el_count
	incr el_count
	toplevel $eltop
	wm title $eltop $title
	
	if {$args == "-with_ok"}  {
		set with_ok 1
	} else {
		set with_ok 0
	}
	
	frame $eltop.left
	pack $eltop.left -side left

	entry $eltop.edit -width 20 -textvariable el_result($eltop)
	bind $eltop.edit <Return> "el_return $eltop"
	bind $eltop.edit <Delete> "el_delete $eltop"
	if {$startitem>=0} {
		set el_result($eltop) [lindex $list $startitem]
	}
	listbox $eltop.list -width 20 -height 7 -yscrollcommand "$eltop.scrl set"
	bindtags $eltop.list "Listbox $eltop.list . all"
	bind $eltop.list <Button-1>  "el_button $eltop" 
	bind $eltop.list <Double-Button-1>  "el_double_button $eltop"
	foreach el $list {
		$eltop.list insert end $el
	}
	scrollbar $eltop.scrl -command "$eltop.list yview"
	pack $eltop.edit -in $eltop.left -side top -fill x -padx 2 -pady 2
	pack $eltop.list $eltop.scrl -in $eltop.left -side left -fill y
	
	frame $eltop.right 
	pack $eltop.right -side left -fill y

	button  $eltop.add -text Add -command "el_add $eltop"
	button  $eltop.del -text Delete -command "el_delete $eltop"
	button  $eltop.sel -text $ok_text -command "el_select $eltop"
	if {$with_ok} {
		button $eltop.ok -text OK -command "el_ok $eltop"
	}
	button  $eltop.exit -text Cancel -command "el_cancel $eltop"
	if {$with_ok}  {
		pack $eltop.add $eltop.del $eltop.sel $eltop.ok $eltop.exit -in $eltop.right -side top \
			-padx 2 -pady 2
	} else {
		pack $eltop.add $eltop.del $eltop.sel $eltop.exit -in $eltop.right -side top \
			-padx 2 -pady 2
	}
	focus $eltop.edit
	tkwait window $eltop
	set list $el_list
	return $el_result($eltop)
	
	#wtree $eltop
}
#editlist "apple banana orange kumquat kiwi grapefruit pineapple" 0 FRUIT
