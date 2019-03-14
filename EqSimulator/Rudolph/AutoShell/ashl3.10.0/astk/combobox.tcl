
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: combobox.tcl,v 1.2 1999/01/05 22:32:30 jasonm Exp $
# $Log: combobox.tcl,v $
# Revision 1.2  1999/01/05 22:32:30  jasonm
# the behavior of destroy changed from tk4.2 to tk8.0. this caused us to
# use a different method of determining whether the popup listbox already
# existed
#
# Revision 1.1  1996/08/27  16:11:11  karl
# Initial revision
#
#
# combobox.tcl
#
set combobox_usage_notes {

Usage:  
    combobox win -list list [-width n] [-editable bool] [-textvariable var]

  - list is the list that will be in the listbox that drops down.

  - width is the width of the entry.

  - editable: if 1 then the widget that displays the current value will
    be an entry that can be edited. If 0, it will be an entry that is
    disabled.

  - textvariable is the global variable that will be used by the
    entry.  This is not usually necessary, since the set and get
    commands will do the same thing.


When first created, the name of the widget is returned. A new command
is created with the name of the widget that takes the following
arguments.

  - win set val
        sets the current value of the combobox to val

  - win get 
        returns the current value of the combobox

  - win setlist list
        sets the items in the listbox to list

}


# Bitmaps and related stuff to dropdown listbox
image create bitmap up -foreground black \
	-data {
		#define up_width 16
		#define up_height 16
		static char up_bits[] = {
			0x00, 0x00, 0x00, 0x00, 0xf0, 0x0f, 0xf0, 0x0f, 0x00, 0x00,
			0x80, 0x01, 0xc0, 0x03, 0xe0, 0x07, 0xf0, 0x0f, 0xc0, 0x03,
			0xc0, 0x03, 0xc0, 0x03, 0xc0, 0x03, 0xc0, 0x03, 0x00, 0x00,
			0x00, 0x00
		};
	}


image create bitmap down -foreground black \
	-data {
		#define down_width 16
		#define down_height 16
		static char down_bits[] = {
			0x00, 0x00, 0x00, 0x00, 0xc0, 0x03, 0xc0, 0x03, 0xc0, 0x03, 
			0xc0, 0x03, 0xc0, 0x03, 0xf0, 0x0f, 0xe0, 0x07, 0xc0, 0x03, 
			0x80, 0x01, 0x00, 0x00, 0xf0, 0x0f, 0xf0, 0x0f, 0x00, 0x00, 
			0x00, 0x00
		};
	}

proc combobox { wn args } {
	global ddi
	
	set editable 0
	set width 20
	set argc [llength $args]
	for { set n 0 } { $n < $argc } { incr n } {
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
			"-textvariable" {
				incr n
				set textvariable [lindex $args $n]
				global $textvariable
			}
		}
	}
	
	# Check to see if 'list' parameter was specified
	if { ![info exists list] } {
		return -code error "list must be specified"
	}
	# Check to see if 'textvariable' parameter was specified
	if { ![info exists textvariable] }  {
		set textvariable "ddi($wn,val)"
		#return -code error "textvariable must be specified"
	}
	
	frame $wn
	bind $wn <Destroy> "
  global ddi
  rename $wn {}
  # renmae ${wn}old {}
  unset ddi($wn,list)
 "
	
	if { ! [info exists $textvariable] }  {
		set $textvariable [lindex $list 0]
	}
	set ddi($wn,list) $list
	entry $wn.lab -textvariable $textvariable -width $width \
		-relief sunken 
	if { !$editable }  {
		$wn.lab configure -state disabled
	}
	
	# Button definition
	button $wn.button -image down -command \
		"popupLb $wn.lab $wn.button $textvariable"
	
	# Display entry and button
	pack $wn.lab -side left -fill x -expand 1
	pack $wn.button -side left
	
	rename $wn ${wn}old
	# Define command to get the current selection
	proc $wn {args} "
  global ddi

  lb-handler $wn $textvariable \$args 
  "
	
	return $wn
}

proc lb-handler {wn textvariable args} {
	global ddi
	# global $textvariable  Contains () so tcl 8.5 can't handle it.
	
	set args [lindex $args 0]
	if { [set s [lsearch -exact $args set]]  > -1}  {
		set $textvariable [lindex $args [incr s]] 
	} elseif { [set s [lsearch -exact $args get]]  > -1}  {
		return [set $textvariable]
	} elseif  { [set s [lsearch -exact $args setlist]] > -1} {
		set ddi($wn,list) [lindex $args [incr s]] 
	}
}


proc popupLb { lbentry lbbutton textvariable } {
	global ddi
	# global $textvariable  Contains () so tcl 8.5 can't handle it.
	
	# Figure out where its gotta be
	set xpos [winfo rootx $lbentry]
	set ypos [winfo rooty $lbentry]
	set geom [split [winfo geometry $lbentry] x+]
	set ypos [expr $ypos+[lindex $geom 1]]
	
	# If toplevel of lisbox & scrollbar already visible, get rid of it
	if { [winfo exists $lbentry-lb] }  {
       $lbbutton configure -image down
       destroy $lbentry-lb
       return
    }
	
	# Have to set cursor because it will be an override shell.
	toplevel $lbentry-lb -cursor right_ptr
	wm overrideredirect $lbentry-lb true
	
	# Scrollbar definition
	frame $lbentry-lb.frame -borderwidth 2 -relief raised
	scrollbar $lbentry-lb.scbar -command "$lbentry-lb.listbox yview" 
	
	# Set height for listbox
	regexp {(.+)(\.lab$)} $lbentry a b c
	if { 10 < [set height [llength $ddi($b,list)]] } {
		set height 10
	}
	
	# Listbox definition
	listbox $lbentry-lb.listbox -yscroll "$lbentry-lb.scbar set" -relief sunken \
		-width [$lbentry cget -width] -height $height
	
	# Insert list of elements into listbox
	foreach choice $ddi($b,list) { $lbentry-lb.listbox insert end $choice }
	$lbentry-lb.listbox selection clear 0 end
	set index [lsearch -exact $ddi($b,list) [set $textvariable]]
	$lbentry-lb.listbox selection set $index
	$lbentry-lb.listbox see $index
	
	# Case when a click is not inside the drop down list box - destroy it
	bind $lbentry-lb <ButtonRelease-1> "
  set lst {}
  set lst \[linsert \$lst 0 \[winfo containing \[winfo pointerx $lbentry-lb\] \
   \[winfo pointery $lbentry-lb\] \] \]
  set searchval \[lsearch -glob \$lst $lbentry-lb.*\]
  if { \$searchval == -1 } {
   $lbbutton configure -image down
   destroy $lbentry-lb
  }"
	
	bind $lbentry-lb.listbox <ButtonRelease-1> "
  $lbbutton configure -image down
  set command \[$lbentry-lb.listbox get \[$lbentry-lb.listbox curselection\]\]
  regexp {(.+)(\.lab$)} $lbentry a b c
  set $textvariable \$command
  destroy $lbentry-lb
  break"
	
	# Make the drop down listbox visible
	pack $lbentry-lb.scbar -side right -in $lbentry-lb.frame -expand true -fill y
	pack $lbentry-lb.listbox -side right  -in $lbentry-lb.frame -expand true -fill both
	pack $lbentry-lb.frame -fill x
	
	# Initial view of combobox
	$lbbutton configure -image up
	wm geom $lbentry-lb +$xpos+$ypos
	tkwait visibility $lbentry-lb
	grab -global $lbentry-lb
}
