
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: asstruct.tcl,v 1.2 2000/12/14 22:50:49 karl Exp $
# $Log: asstruct.tcl,v $
# Revision 1.2  2000/12/14 22:50:49  karl
# Fixed bug that was keeping files from being selectable and therefore
# editable/viewable.
#
# Revision 1.1  2000/04/25 17:21:04  karl
# Initial revision
#

proc as_struct_win {wn args} {
	#puts "creating tree"
	global as_struct_data
	set list ""
	set passthrough {}
	for {set n 0} {$n<[llength $args]} {incr n} {
		set arg [lindex $args $n]
		switch -- $arg {
			-label_cb {
				incr n
				set as_struct_data($wn,label_cb) [lindex $args $n]
			}
			default {
				if {[llength $list]==0} {
					set list $arg 
				} else {
					lappend passthrough $arg
				}
			}
		}
	}
	global Tree
	eval Tree:create $wn / $passthrough
	pack_struct_butts $list "" $wn
#	$wn bind x <1> \
#		"show_struct_select $wn %W %x %y"
#	$wn bind x <Double-1> \
#		"show_struct_open $wn"
	bind $wn <1> \
		"show_struct_select $wn %W %x %y"
	bind $wn <Double-1> \
		"show_struct_open $wn"
	return $wn
}

proc show_struct_select {wn W x y} {
  global Tree as_struct_data
  set lbl [Tree:labelat $W $x $y]
  if {$lbl=={}} {
	return
  }
  Tree:setselection $W $lbl
  eval $as_struct_data($wn,label_cb) "$Tree($wn,$lbl)"
}

proc show_struct_open {wn} {
	#puts "show_struct_open $wn"
	global Tree
	set item [Tree:getselection $wn]
	if {$item==""} {
		return
	}
	set pathname $Tree($wn,$item)
 	set ext [file extension $pathname] 
	switch $ext {
		.su -
		.xsu {
			launch_startup_editor "" $pathname
		}
		default {
			launch_text_editor "" $pathname
		}
	}
}

proc pack_struct_butts {list path wn} {
	global Tree
	set nam [file tail [lindex $list 0]]
	set dir [lindex $list 0]
	#regsub -all {[\\]} $dir "\\\\" dir
	#puts "set Tree($wn,$path/$nam) $dir"
	set Tree($wn,$path/$nam) $dir
	if {![file exists $dir]} {
		set color gray
	} elseif {![file writable $dir]} {
		set color red
	} elseif {![file readable $dir]} {
		set color brown
	} else {
		set color black
	}
	Tree:newitem $wn $path/$nam -fill $color
	Tree:open $wn $path
        foreach item [lindex $list 1] {
		pack_struct_butts $item $path/$nam $wn	
        }
}
