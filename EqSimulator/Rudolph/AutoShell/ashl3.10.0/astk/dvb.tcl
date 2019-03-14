
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

#!/bin/sh 
# \
#if test x$ASTK_DIR = x; then \
#	ASTK_DIR=/home/dyson/ashl3/astk; \
#	export ASTK_DIR
# \
#fi

# Find tcltksrv in path and feed this file to it \
#exec tcltksrv name=dvb$$ tclstartup="$0" \
#"args=\"$1\" \"$2\" \"$3\" \"$4\" \"$5\""
# Exit the launcher \
#exit

# $Id: dvb.in,v 1.2 2002/03/18 20:11:25 xsphcamp Exp $
# $Log: dvb.in,v $
# Revision 1.2  2002/03/18 20:11:25  xsphcamp
# Fixed all the <script>.in's to work with shells which don't allow exporting
# and setting the value of environment variables as a single command.
#
# It looks like Solaris does lazy constructing of objects if they are defined in
# a shared library. This caused a findlog() of mq_hist to fail in nullflow.cxx. I
# changed nullflow to use the direct referece instead of findlog() to a pointer.
#
# Added a zero return to the end of setenv() so it actaully properly returns
# success. It is now verified to work under Solaris.
#
# Somehow I missed cleaning up nullsrv.hxx, so included here is a switch to
# relative path inclusion of all headers.
#
# Revision 1.1  2002/03/11 07:49:20  xsphcamp
# All the scripts in astk have been moved to <script>.in so that the necessary
# environment variabels (e.g. TCL_LIBRARY, ASTK_DIR) can be set automatically
# based on compile time settings if the user does not already have them set. User
# settings will override these.
#
# configure.in has been updated to generate the scripts from the .in's.
#
# astk/Makefile.am has been cleaned a bit as a result of script genning.
#
# Revision 1.3  2000/08/15 22:50:28  karl
# Added window title
#
# Revision 1.2  2000/07/07  21:21:00  karl
# Fixed bug in usage string.
# Fixed to not conflict with variable names used in DVs.
# Added expand and collapse options.
# Added DV search by path or string.  Added dv_getpath command.
# Added configuration options.
#
# Revision 1.1  2000/04/25  17:22:16  karl
# Initial revision
#

wm withdraw .

proc print_usage {} {
	set msg    "USAGE: dvb -f dvfilename \[-expandall\]\n"
	append msg "          -or- \n"
	append msg "       dvb servername \[-expandall\]"
	puts "\n$msg"
	exit
}

an_proc get_server_cwd {} {} {} {
	if {$reply!=0} {
		puts "\n$dvb_servername couldn't store DV image at $dvb_filename.\n$comment"
		exit
	}
	an_msgsend 0 $dvb_servername "getdvs variable=CWD" -an_reply_cb \
		"load_runtime_dvs dvb_filename=$dvb_filename dvb_expandall=$dvb_expandall dvb_tmpfile=$dvb_tmpfile dvb_servername=$dvb_servername"
}

an_proc load_runtime_dvs {} {} {} {
	dvb_create_win $CWD/$dvb_filename $dvb_expandall $dvb_servername $dvb_tmpfile
}

proc dvb_close_win {} {
	dvb_save_options
	exit 
}

proc dvb_expand_win {w} {
	global dvb_options
	if {[info exists dvb_options(hidesysbin)] &&
		$dvb_options(hidesysbin)} {
		dvv_expand $w "sys>bin"
	} else {
		dvv_expand $w 
	}
}

proc dvb_collapse_win {w} {
	dvv_collapse $w
}

proc dvb_show_search_win {w mode} {
	global dvb_data
	if {[winfo exists $w.search]} {
		raise $w.search
	}
	if {$mode=="path"} {
		set prompt "Enter DV or DV path to find:"
	} else {
		set prompt "Enter string to find in DV name or value:"
	}
	toplevel $w.search
	label $w.search.prompt -text $prompt
	pack $w.search.prompt
	entry $w.search.searchstr -textvariable dvb_data($w,searchstr)
	pack $w.search.searchstr
	focus $w.search.searchstr
#	radiobutton  $w.search.up -text "Search Upwards" \
#		-value 0 -variable dvb_data($w,searchdir)
#	pack $w.search.up
#	radiobutton  $w.search.down -text "Search Downwards" \
#		-value 1 -variable dvb_data($w,searchdir)
#	pack $w.search.down
	button $w.search.find -text Find \
		-command "dvb_search $w $mode"
	pack $w.search.find -side left  -expand 1
	bind $w.search.searchstr <Return> "$w.search.find invoke"
	button $w.search.cancel -text Cancel -command "destroy $w.search"
	pack $w.search.cancel -side left -expand 1
}

proc dv_getpath {ptr root} {
	#puts "dv_getpath called with ptr=$ptr root=$root"
	set dvpath ">[dv_getname -root $ptr]"
	if {$ptr==$root} {
		return $dvpath
	}
	set junk $ptr
	set ptr [dv_getparent $ptr]
	#puts "parent of $junk is $ptr, dvpath=$dvpath"
	while {$ptr!="" && $ptr!=$root} {
		#puts "dv_getpath while >[dv_getname -root $ptr]$dvpath"
		set dvpath ">[dv_getname -root $ptr]$dvpath"
		set junk $ptr
		set ptr [dv_getparent $ptr]
		#puts "    parent of $junk is $ptr, dvpath=$dvpath"
	}
	#puts "dv_getpath returning '$dvpath'"
	return $dvpath
}

proc dvb_search {w mode} {
	global dvb_data Tree
	set found 0
	if {""==$dvb_data($w,searchptr)} {
		set dvb_data($w,searchptr) $dvb_data($w,topdv)
	}
	# Loop through this DV list, from top to bottom.
	while {""!=$dvb_data($w,searchptr) && !$found} {
		#puts "dvb_search while [dv_getname -root $dvb_data($w,searchptr)]=[dv_get -root $dvb_data($w,searchptr)]"
		set dvname [dv_getname -root $dvb_data($w,searchptr)]
		set dvval [dv_get -root $dvb_data($w,searchptr)]
		set dvpath [dv_getpath $dvb_data($w,searchptr) [dv_getparent $dvb_data($w,topdv)]]
		#puts "mode=$mode dvpath=$dvpath dvb_data($w,searchstr)=$dvb_data($w,searchstr)"
		set fixedstr $dvb_data($w,searchstr)	
		if {$mode=="path" && [string length $fixedstr] &&
			[string index $fixedstr 0]!=">"} {
			set fixedstr "*>$fixedstr"
		}
		if {($mode=="string" && \
			([string match "*$fixedstr*" $dvname] || \
			 [string match "*$fixedstr*" $dvval])) \
			 || \
			($mode=="path" && \
			([string match $fixedstr $dvpath])) } {
			#puts "Marking $dvpath"
			set setselrc [Tree:setselection $w $dvpath]
			#puts "setselrc=$setselrc"
			# If the found DV was visible, mark it as a hit.
			if {!$setselrc} {
				#puts "Tree($w:selidx)=$Tree($w:selidx)"
				set bbox [$w bbox $Tree($w:selidx)]
				#puts "bbox=$bbox"
				set y [lindex $bbox 1]
				set sr [$w cget -scrollregion]
				#puts "sr=$sr"
				set height [expr [lindex $sr 3] - [lindex $sr 1]]
				set midwin [expr [winfo height $w] / 2]
				set frac [expr ($y+0.0-$midwin) / $height]
				#puts "frac=$frac"
				set yview [$w yview]
				#puts "yview=$yview"
				if {$frac<[lindex $yview 0] || $frac>[lindex $yview 1]} {
					$w yview moveto $frac
				}
				set found 1
			}
		} 
		set sublist [dv_sublist -root $dvb_data($w,searchptr)]
		# If current DV has sublist, jump down into it.
		if {$sublist!=""} {
			#puts "Descending into sublist"
			set dvb_data($w,searchptr) $sublist
		# Otherwise, look for the DV following the curent one.
		} else {
			#puts "Looking for next DV"
			set next [dv_next -root $dvb_data($w,searchptr)]
			# If the current DV is the last in the list....
			if {$next==""} {
				#puts "End of DV list, getting parent"
				# Jump back up to the parent.
				set parent [dv_getparent $dvb_data($w,searchptr)]	
				if {$parent==[dv_getparent $dvb_data($w,topdv)]} {
					#puts "Wrapped around, returning null"
					set dvb_data($w,searchptr) ""
				} else {
					# And get the next DV in the list.
					#puts "Getting next DV in parent's list"
					set next [dv_next -root $parent]
					# If there is no next DV, keep jumping up to parent
					while {$next=="" && $parent!="" && \
							$parent!=[dv_getparent $dvb_data($w,topdv)]} {
						#puts "dvb_search while"
						set parent [dv_getparent $parent]
						set next [dv_next -root $parent]
					}
					if {$parent==[dv_getparent $dvb_data($w,topdv)]} {
						#puts "Wrapped around, returning null"
						set dvb_data($w,searchptr) ""
						
					} else {	
						set dvb_data($w,searchptr) $next
					}
				}
			} else {
				#puts "Getting next DV"
				set dvb_data($w,searchptr) $next
			}
		}
	}
	if {!$found} {
		set msg "Not found . . . returning to top of DV list."
		tk_dialog .tmp "Not Found" $msg warning 0 OK
		Tree:setselection $w ""
	}
}

#proc dvb_rename_dv {w} {
#	puts "w=$w"
#	set dvpath [Tree:getselection $w]
#	puts "dvpath=$dvpath"
#	Tree:dump $w dump1.tv
#	Tree:changeitem $w $dvpath XXXX
#	Tree:dump $w dump2.tv
#}
#
#proc dvb_edit_dv_val {w} {
#	global dvb_data
#	set dvpath [Tree:getselection $w]
#	set dvval [Tree:getvalue $w $dvpath 1]
#	set newval [get_string "Enter new value for $dvpath:" $dvval dvb_CaNcEl]
#	if {"dvb_CaNcEl"==$newval} {
#		return
#	}
#	if {$dvb_data($w,servername)!=""} {
#		XXX
#	} else {
#		dvb_edit_dv_val_finish $w $dvpath $newval
#	}
#}
#
#proc dvb_edit_dv_val_finish {w dvpath newvalue} {
#	Tree:changevalue $w $dvpath 1 $newvalue
#}
#
proc dvb_create_win {filename expandall servername tmpfile} {
	wm protocol . WM_DELETE_WINDOW dvb_close_win
	wm title . "DV Browser - [file tail $filename]"
	set w .dvb
	global dvb_data
	#puts "servername=$servername tmpfile=$tmpfile tmpfile=$tmpfile"
	set dvb_data($w,servername) $servername
	set dvb_data($w,tmpfile) $tmpfile
	set dvb_data($w,filename) $filename
	set dvb_data($w,searchstr) ""
	set dvb_data($w,searchdir) 1
	dvv_browse $w -file $filename -expandall $expandall \
		-yscrollcommand ".scrly set" \
		-xscrollcommand ".scrlx set" \
		-width 400 -height 400
	set dvb_data($w,searchptr) [dvv_getdvptr $w]
	set dvb_data($w,topdv) [dvv_getdvptr $w]
	#puts "set dvb_data($w,topdv) to $dvb_data($w,topdv) name=[dv_getname -root $dvb_data($w,topdv)]"
	scrollbar .scrly -command "$w yview"
	scrollbar .scrlx -command "$w xview" -orient horizontal
	frame .menubar
	pack .menubar -side top -fill x 
	menubutton .menubar.file -text File -menu .menubar.file.menu
#	menubutton .menubar.edit -text Edit -menu .menubar.edit.menu 
	menubutton .menubar.find -text Find -menu .menubar.find.menu 
	menubutton .menubar.view -text View -menu .menubar.view.menu
	menubutton .menubar.config -text Config -menu .menubar.config.menu
	pack .menubar.file .menubar.find .menubar.view .menubar.config -side left
	menu .menubar.file.menu -tearoff 0
#	menu .menubar.edit.menu -tearoff 0
	menu .menubar.find.menu -tearoff 0
	menu .menubar.view.menu -tearoff 0
	menu .menubar.config.menu -tearoff 0
	.menubar.file.menu add command -label "Exit" \
		-command "dvb_close_win"
#	.menubar.file.menu add command -label "Save" \
#		-command dvb_save \
#		-state disabled
#	if {$dvb_data($w,servername)==""} {
#		.menubar.file.menu entryconfigure "Save" -state normal
#	}
#	.menubar.file.menu add command -label "Save As.." \
#		-command dvb_save_as \
#		-state normal
	.menubar.view.menu add command -label "Expand All" \
		-command "dvb_expand_win $w"
	.menubar.view.menu add command -label "Collapse All" \
		-command "dvb_collapse_win $w"
	.menubar.find.menu add command -label "Find DV" \
		-command "dvb_show_search_win $w path" 
	.menubar.find.menu add command -label "Find String" \
		-command "dvb_show_search_win $w string" 
#	.menubar.edit.menu add command -label "Rename" \
#		-command "dvb_rename_dv $w" \
#		-state disabled
#	.menubar.edit.menu add command -label "Edit Value" \
#		-command "dvb_edit_dv_val $w" \
#		-state disabled
#	.menubar.edit.menu add command -label "Add" \
#		-command "dvb_add_dv $w" \
#		-state disabled
#	.menubar.edit.menu add command -label "Delete" \
#		-command "dvb_delete_dv $w" \
#		-state disabled
	.menubar.config.menu add checkbutton -label "Hide sys>bin" \
		-onvalue 1 -offvalue 0 -variable dvb_options(hidesysbin)
	.menubar.config.menu add checkbutton -label "Expand all at startup" \
		-onvalue 1 -offvalue 0 -variable dvb_options(expandall)
	pack .scrlx -fill x -side bottom
	pack $w -expand 1 -fill both -side left
	pack .scrly -fill y -side left

    $w bind label <1> {
		dvb_click_dv %W %x %y
    }
    $w bind value1 <1> {
		dvb_click_dv %W %x %y
    }

	update idletasks; wm deiconify .
	# Signal exec_and_wait to delete the file
	#puts "READY"
	tkwait window $w
	if {$tmpfile!=""} {
		an_msgsend 0 $servername "system msg=\"rm -f $tmpfile\""	
	}
}

proc dvb_click_dv {W x y} {
      set lbl [Tree:labelat $W $x $y]
      Tree:setselection $W $lbl
#	.menubar.edit.menu entryconfigure "Rename" -state normal	
#	.menubar.edit.menu entryconfigure "Edit Value" -state normal	
#	.menubar.edit.menu entryconfigure "Add" -state normal	
#	.menubar.edit.menu entryconfigure "Delete" -state normal	
}


proc dvb_load_options {} {
	global dvb_options
	set dvb_options(hidesysbin) "1"
	set dvb_options(expandall) "1"
	if {[file exists ~/.dvbrc]} {
		source ~/.dvbrc
	}
}

proc dvb_save_options {} {
	global dvb_options
	set fid [open ~/.dvbrc w]
	puts $fid "global dvb_options"
	foreach el [array names dvb_options] {
		puts $fid "set dvb_options($el) {$dvb_options($el)}"
	}
	close $fid
}

dvb_load_options
source $env(ASTK_DIR)/dvv.tcl
source $env(ASTK_DIR)/tree.tcl
global dvb_data
	#set fileId [open jack a+ 0666]
	#puts $fileId "dvb arg=$argv"
#set args [dv_get args]
#set args {-f viewdvs_data} 
set args $argv
set servername ""
set filename ""
set expandall $dvb_options(expandall)
for {set n 0} {$n<[llength $args]} {incr n} {
	set arg [lindex $args $n]
	switch -- $arg {
		{-u} {
			print_usage
		}
		{-f} {
			incr n
			set filename [lindex $args $n]
		}
		{-expandall} {
			set expandall 1
		}
		{default} {
			if {$servername==""} {
				set servername $arg
				#puts $fileId "dvb servername=$servername"
			}
		}
	}
}
	#puts $fileId "dvb filename=$filename"
	#close $fileId
if {$filename=="" && $servername==""} {
	print_usage
	exit
}

set auto_path [linsert $auto_path 0 $env(ASTK_DIR)]

set tmpfile ""
if {$filename==""} {
	set tmpfile dvb[pid].tmp
	set rc [catch {
		an_msgsend 0 $servername \
			"store file=$tmpfile" \
			-an_reply_cb "get_server_cwd dvb_filename=$tmpfile dvb_tmpfile=$tmpfile dvb_expandall=$expandall dvb_servername=$servername"
		}]
	if {$rc} {
		puts "\n$servername not responding."
		exit
	}
} else {
	dvb_create_win $filename $expandall "" ""
}

#update idletasks; wm deiconify .
