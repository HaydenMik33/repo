
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: elist.tcl,v 1.4 1998/07/09 22:57:04 jasonm Exp $
# $Log: elist.tcl,v $
# Revision 1.4  1998/07/09 22:57:04  jasonm
# added -mousedrag option to allow the user to position items in the
# list by dragging them with the mouse
#
# Revision 1.3  1997/12/23  21:22:30  jasonm
# - added new argument to keep lists sorted (-sort). passes value
#   directly to lsort
#
# Revision 1.2  1997/01/06  17:00:47  jasonm
# - added the -nowhitespace option which makes it so the user can't
#   type spaces into the entry widget
#
# Revision 1.1  1996/08/27  16:24:47  karl
# Initial revision
#
###
### elist.tcl
###

set elist  {
	
	Usage:
        elist pathName ?options?

	Options: 
    -unique value
	    if 0, then there can be multiples with the same name in the list.
	    if non-zero, then there can only be uniquely named items. 
	    defaults to 1.

	-nodelete
        does not allow the user to delete items from the listbox

	-nowhitespace 
        does not allow the user to input whitespace in the entry	

    -width value
	    sets the width of the entry widget. The rest of the widget expands
	    to conform to this size.

    -height value
	    sets the height of the listbox.

    -list list
	    sets the list which will initially be displayed in the listbox.

    -command command (not implemented yet)
	    the command that will be executed when the user double clicks
	    on an item in the listbox. The pathName of the widget will be
	    appended to the arguments.

	-sort type
	    items in the listbox will be kept sorted. type can be either
	    none, ascii, integer, or real. the type will be passed directly
	    to lsort. default is none.

	-mousedrag
	    allows the user to rearrange items in the list by dragging them
	    with the mouse

	Widget Command:
        A new command is created whose name is pathName. It takes one of the 
        following arguments.

    getlist
	    returns a list with the items currently in the listbox
	
    setlist list
	    sets the items in the listbox to list

    getsel
	    returns the currently selected item
}

###
### elist is the main proc. It creates the widget and sets up bindings,
### callbacks, etc.
###
proc elist { w args }  {
	
	frame $w -takefocus 0
	
	global elistinfo
	set elistinfo($w,unique) 1
	set width     ""
	set height    ""
	set list      ""
	set frameargs ""
	set command ""
	set nodelete 0
	set nowhitespace 0
	set mousedrag 0
	set elistinfo($w,sort) none
	bind $w <Destroy> { unset elistinfo(%W,unique) }
	
	set argc [llength $args]
	for {set i 0} {$i < $argc} {incr i}  {
		set arg [lindex $args $i]
		
		switch -exact -- $arg  {
			-unique {
				incr i
				set uniqueval [lindex $args $i]
				if {[regexp {[^0-9]} $uniqueval]}  {
					tkerror "invalid value for unique: must be 0 or 1"
				}
				set elistinfo($w,unique) $uniqueval
			}
			-sort {
				incr i
				set elistinfo($w,sort) [lindex $args $i]
			}
			-width {
				incr i
				set width [lindex $args $i]
			}
			-height {
				incr i
				set height [lindex $args $i]
			}
			-list {
				incr i
				set list [lindex $args $i]
			}
			-nodelete {
				set nodelete 1
			}
			-nowhitespace {
				set nowhitespace 1
			}
			-command {
				incr i
				set command [lindex $args $i]
			}
			-mousedrag {
				set mousedrag 1
			}
			default {
				lappend frameargs $arg
			}
		}
	}

	if {$frameargs != ""}  {
		eval $w configure $frameargs
	}

	set e [frame $w.edit]
	
	set elist_e [entry $e.entry] 
	if {$width != ""}  {
		$elist_e configure -width $width
	}
	if {$nowhitespace}  {
		bind $elist_e <space> { ; break }
	}

	set l [frame $e.list]
	set elist_l [listbox $l.list -yscrollcommand "$l.scroll set" \
					 -highlightthickness 0 -takefocus 0 -exportselection 0]
	if {$height != ""}  {
		$elist_l configure -height $height
	}
	scrollbar $l.scroll -command "$l.list yview" -highlightthickness 0 \
		-takefocus 0
	pack $l.list -side left -fill both -expand yes
	pack $l.scroll -side right -fill y

	pack $e.entry -side top -fill x
	pack $l -side top -fill both -expand yes

	set b [frame $w.butts]
	set f [frame $b.b]

	bind $elist_e <Return> "elist_add_entry $w $elist_e $elist_l"

	if {$mousedrag}  {
		bind $elist_l <B1-Motion> "elist_mouse_drag $elist_l %y; break"
		bind $elist_l <B1-Leave> "break"
	}

	button $f.add -text "Add" -width 5 -command \
		"elist_add_entry $w $elist_e $elist_l"
	button $f.delete -text "Delete" -width 5 -command \
		"elist_delete_entry $elist_l"
	pack $f.add -side left -padx 5 -pady 5
	if {!$nodelete} {
		pack $f.delete -side left -padx 5 -pady 5
	}
	pack $f -side top

	pack $e -side top -fill both -expand yes
	pack $b -side top -fill both
	focus $elist_e

	rename $w $w.old

	proc $w { args }  " elist-handler $w $elist_e $elist_l \$args "

	$w setlist $list

	return $w
}

###
### elist-handler is called when the widget command is invoked. It
### accepts either setlist list, getlist, or getsel
###
proc elist-handler { w entry listbox args }  {
	
	global elistinfo

	set args [lindex $args 0]
	set length [llength $args]
	
	set is_error 0
	set setlist 0
	set getlist 0
	set getsel 0
	set getentry 0
	
	if {$length == 2}  {
		set arg [lindex $args 0]
		if {$arg != "setlist"}  {
			set is_error 1
		} else {
			set newlist [lindex $args 1]
			set setlist 1
		}
	} elseif {$args == "getlist"}  {
		set getlist 1
	} elseif {$args == "getsel"}  {
		set getsel 1
	} elseif {$args == "getentry"}  {
		set getentry 1
	} else {
		set is_error 1
	}
	
	if {$is_error}  {
		return
	}

	if {$getlist}  {
		return [$listbox get 0 end]
	}

	if {$getsel}  {
		if {[set index [$listbox curselection]] == ""} { return }
		return [$listbox get $index]
	}

	if {$getentry}  {
		return [$entry get]
	}

	if {$setlist}  {
		if {![ string length [set index [$listbox curselection]]]}  {
			set index 0
		}
		$listbox delete 0 end
		if {[string compare $elistinfo($w,sort) "none"]}  {
			set newlist [lsort -$elistinfo($w,sort) $newlist]
		}
		eval "$listbox insert end $newlist"
		$listbox selection set $index
		return
	}
}

###
### elist_add_entry adds the text in the entry widget to the listbox.
### If the widget was created with unique set to non-zero, only unique
### entries are added to the listbox.
###
proc elist_add_entry { w entry listbox }  {

	if {[set value [string trim [$entry get]]] == ""}  {
		return
	}

	global elistinfo

	if {$elistinfo($w,unique)}  {
		if {[lsearch -exact [$w getlist] $value] > -1}  {
			return
		}
	}

	if {[set index [$listbox curselection]] == ""}  {
		set index 0
	}
	
	if {[string compare $elistinfo($w,sort) "none"]}  {
		set newlist [$w getlist]
		lappend newlist $value 
		$w setlist $newlist
	} else {
		$listbox insert end $value
	}

	$listbox selection clear 0 end
	$listbox selection set end
	$listbox see end
	$entry selection range 0 end
}

###
### elist_delete_entry deletes the entry that is currently highlighted
### in the listbox
###
proc elist_delete_entry { listbox }  {

	if {[set index [$listbox curselection]] == ""}  {
		return
	}
	
	$listbox delete $index
	$listbox selection clear 0 end
	$listbox selection set $index
}


###
### elist_mouse_drag allows the user to drag items and reposition them
### in the list. it is called if the -mousedrag option is passed in
###
proc elist_mouse_drag { listbox y }  {
	
	if {![string length [set cursel [$listbox curselection]]]}  {
		return
	}

	set curpos [$listbox nearest $y]
	if {$cursel != $curpos}  {
		set moving [$listbox get $cursel]
		set top [lindex [$listbox yview] 0]
		if {$top != 0}  {
			set top [expr round([$listbox size]*$top)]
		}
		$listbox delete $cursel
		$listbox insert $curpos $moving
		$listbox yview $top
		$listbox selection clear 0 end
		$listbox selection set [$listbox nearest $y]
	}
}
