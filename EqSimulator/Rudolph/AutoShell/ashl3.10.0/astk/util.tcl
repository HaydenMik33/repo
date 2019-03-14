
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: util.tcl,v 1.2 1997/01/20 22:03:42 karl Exp $
# $Log: util.tcl,v $
# Revision 1.2  1997/01/20 22:03:42  karl
# Removed global bind on Entry widgets that was causing some stack traces.
#
# Revision 1.1  1996/08/27  16:21:08  karl
# Initial revision
#
##########
### scrollmult
###
### Purpose
###   - used to scroll multiple listboxes with one scrollbar
###   - should be used as the command of a scrollbar
###
### Parameters
###   - items is the list of listboxes to be scrolled
###   - args is automatically appended and contains info about
###     how the listboxes should be scrolled
##########

proc scrollmult { items args }  {
    foreach box $items {
		eval "$box yview $args"
    }
}



##########
### selectmult
###
### Purpose
###   - used to select elements in multiple listboxes by only 
###     clicking in one of them
###   - used when working with tabular lists
###
### Parameters
###   - items is the list of listboxes to be selected
###   - y is the y-coordinate of the mouse
##########

proc selectmult { items y }  {
    foreach listbox $items {
		$listbox selection clear 0 end 
		$listbox selection set [$listbox nearest $y]
    }
}



##########
### kill_list_binds
###
### Purpose
###   - get rid of extraneous bindings on listboxes that would
###     interfere with scrollmult and selectmult
###
### Parameters
###   - items is the list of listboxes to be changed
##########

proc kill_list_binds { items }  {
    foreach listbox $items {
		bind $listbox <Shift-1> { }
		bind $listbox <Shift-B1-Motion> { }
		bind $listbox <2> { }
		bind $listbox <B2-Motion> { }
    }
}



##########
### resize
###
### Purpose
###   - toggle the size of a text widget
###
### Parameters
###   - b: the button to invoke the toggling
###   - t: the text widget
###   - winid: ID of the toplevel window
###   - num: ?
###   - which: ?
###   - bh: big height
###   - sh: small height
###
### Notes
###   - this is not really usable by anything but suscr or cmdedit
##########

proc resize { b t winid num which bh sh }  {
    
    global winInfo
    
    if {$winInfo($winid,$num,big_small,$which)}  {
		$t configure -height $sh
		$b configure -text {Full Size}
		set winInfo($winid,$num,big_small,$which) 0
    } else {
		$t configure -height $bh
		$b configure -text {Default}
		set winInfo($winid,$num,big_small,$which) 1
    }
}



##########
### switch_list
###
### Purpose
###   - move an item up or down in a listbox
###
### Parameters
###   - listbox is of course the listbox.  The index of the item
###     to move is obtained at runtime
###   - dir is the direction to move the item, either up or down
##########

proc switch_list { listbox dir }  {

    if {$dir == "down"}  {set dir 1} else {set dir -1}

    set index [$listbox curselection]
    set newindex [expr $index + $dir]
    set const1 [$listbox get $index]
    set const2 [$listbox get $newindex]
    
    $listbox delete $index
    $listbox insert $index $const2
    $listbox delete $newindex
    $listbox insert $newindex $const1
    $listbox selection clear 0 end ; $listbox selection set $newindex

}
 


##########
### lchange
###
### I don't think anything uses this anymore
##########

proc lchange { var newval n indices }  {

    if {$n == 1}  {
	return [lreplace $var $indices $indices $newval]
    }
    
    set level0 [lindex $var [lindex $indices 0]]
    for {set i 1} {$i < [expr $n-1]} {incr i}  {
	set pos [lindex $indices $i]
	set level$i [lindex [set level[expr $i-1]] $pos]
    }

    set level[expr $n-1] $newval

    for {set i [expr $n-1]} {$i > 0} {incr i -1}  {
	set pos [lindex $indices $i ]
	set level[expr $i-1] [lreplace [set level[expr $i-1]] \
				   $pos $pos [set level$i]]
    }
    set pos [lindex $indices 1]
    set level0 [lreplace $level0 $pos $pos $level1]

    set pos [lindex $indices 0]
    return [lreplace $var $pos $pos $level0]
}


##########
###
### The following bindings set up the focus so that when the
### user presses return in an entry, the focus goes to the
### next entry.
###
### Also, using Tab and Shift-Tab works for buttons similarly
### to Microsoft Windows
###
##########

bind middleEntry <Return> {focus [tk_focusNext %W]}
bind firstEntry <Shift-Tab> {[tk_focusPrev %W] configure -state active}
bind lastEntry <Tab> {[tk_focusNext %W] configure -state active}
bind lastEntry <Shift-Tab> { }
bind lastEntry <Return> {[tk_focusNext %W] configure -state active}

bind firstButton <Tab> {
    %W configure -state normal 
    [tk_focusNext %W] configure -state active
}
bind firstButton <Shift-Tab> {%W configure -state normal}

bind midButton <Tab> {
    %W configure -state normal 
    [tk_focusNext %W] configure -state active
}
bind midButton <Shift-Tab> {
    %W configure -state normal 
    [tk_focusPrev %W] configure -state active
}

bind lastButton <Tab> {%W configure -state normal}
bind lastButton <Shift-Tab> {
    %W configure -state normal 
    [tk_focusPrev %W] configure -state active
}
