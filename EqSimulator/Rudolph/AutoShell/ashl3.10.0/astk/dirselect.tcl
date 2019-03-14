
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: dirselect.tcl,v 1.2 2000/07/07 21:19:28 karl Exp $
# $Log: dirselect.tcl,v $
# Revision 1.2  2000/07/07 21:19:28  karl
# Added a grab and a cd to the selected dir.
#
# Revision 1.1  2000/04/05  19:42:13  karl
# Initial revision
#

image create photo folderup -file $env(ASTK_DIR)/images/folderup.gif
image create photo folderexp -file $env(ASTK_DIR)/images/folderexp.gif
proc dirselect {args} {
	set w .ds
	toplevel $w
	global ds_vars
	set ds_vars(pwd) [pwd]
	set ds_vars(origdir) [pwd]
	set ds_vars(preservecwd) 0
	set ds_vars(shortcut) ""
	set ds_vars(shortcutabort) ""
	for {set n 0} {$n<[llength $args]} {incr n} {
		set arg [lindex $args $n]
		if {[string index $arg 0]=="-"} {
			set option [string range $args 1 end]
			switch $option {
			  "preservecwd" {
				incr n
				set ds_vars(preservecwd) [lindex $args $n]
			  }
			}
		} else {
		}
	}

	set t $w.top
	frame $t
	pack $t -in $w -side top -expand 1
	label $t.dl -text Dir: 
	entry $t.dt -width 40 -textvariable ds_vars(result)
	bind $t.dt <Return> "$w.ok invoke"
	button $t.du -image folderup -command "ds_changedir $w .."
	button $t.de -image folderexp -command "ds_directory_expand $w" \
		-state disabled
	pack $t.dl $t.dt $t.du $t.de -side left -expand 1 -fill x 
	#menu $t.dm.dirs
	#ds_update_pulldown $w

	set l $w.list
	frame $l
	pack $l -in $w -side top -expand 1 -fill both
	listbox $l.lb -yscrollcommand "$l.sb set" -takefocus 1
	bind $l.lb <Button-1> "[bind Listbox <Button-1>]; ds_select_item $w; set ds_vars(shortcut) {}; break"
	bind $l.lb <Double-Button-1> "$t.de invoke"
	bind $l.lb <Return> "$t.de invoke; break"
	bind $l.lb <BackSpace> "$t.du invoke; break"
	bind $l.lb <KeyPress> "ds_keypress $w %A"
	scrollbar $l.sb -command "$l.lb yview"
	pack $l.lb -side left -expand 1 -fill both
	pack $l.sb -side left -fill y

	button $w.ok -text OK -command "
		destroy $w
	"

	button $w.cancel -text Cancel -command "
		global ds_vars
		set ds_vars(result) {}
		destroy $w
	"
	pack $w.ok $w.cancel -side left -expand 1 -pady 2
	set ds_vars(result) [pwd]
	ds_populate $w
	#focus $w.list.lb
	grab $w
	tkwait window $w
	if {$ds_vars(preservecwd)} {
		cd $ds_vars(origdir)
	} else {
		cd $ds_vars(result)
	}
	return $ds_vars(result)	
}

proc ds_keypress {wn key} {
	global ds_vars
	if {$key!=""} {
		#puts "key=$key"
		append ds_vars(shortcut) $key
		if {$ds_vars(shortcutabort)!=""} {
			after cancel $ds_vars(shortcutabort)
			set ds_vars(shortcutabort) ""
		}
		set ds_vars(shortcutabort) [after 5000 {
			global ds_vars
			set ds_vars(shortcut) ""
		}]
		set items [$wn.list.lb get 0 end]
		set pos [lsearch $items "$ds_vars(shortcut)*"]
		#puts "pos=$pos"
		if {$pos>=0} {
			$wn.list.lb see $pos
			$wn.list.lb selection clear 0 end
			$wn.list.lb selection set $pos $pos
			ds_select_item $wn
		}
	}
}

proc ds_select_item {wn} {
	global ds_vars
	$wn.top.de configure -state normal
	set dirname [selection get]
	set ds_vars(result) [string trimright [pwd] /]/$dirname
	focus $wn.list.lb
}

proc ds_update_pulldown {wn} {
	$wn.top.dm.dirs delete 0 end
	set path [pwd]
	$wn.top.dm.dirs add command -label $path	
	while {[string compare [file dirname $path] "/"]!=0} {
		set path [file dirname $path]	
		$wn.top.dm.dirs add command -label $path \
			-command "ds_changedir $wn $path"
	}
}


proc ds_directory_expand {wn} {
	global ds_vars
	set dirname [selection get]
	if {![catch {cd $dirname}]} {
		set ds_vars(result) [pwd]
		ds_populate $wn
	}
}

proc ds_changedir {wn newdir} {
	global ds_vars
	if {![catch {cd $newdir}]} {
		set ds_vars(result) [pwd]
		ds_populate $wn
	}
}

proc ds_populate {wn} {
	global ds_vars
	$wn.list.lb delete 0 end	
	set files ""
	catch {set files [glob *]}
	set files [lsort $files]
	set founddir 0
	$wn.list.lb insert end ..
	foreach file $files {
		if [file isdirectory $file] {
			$wn.list.lb insert end $file
		}
	}
	$wn.top.de configure -state disabled
	set ds_vars(shortcut) ""
	if {$ds_vars(shortcutabort)!=""} {
		after cancel $ds_vars(shortcutabort)
		set ds_vars(shortcutabort) ""
	}
	#ds_update_pulldown $wn
}
#cd /home/karl
#wm withdraw .
#puts "results=[dirselect -keepdir]"
#exit
