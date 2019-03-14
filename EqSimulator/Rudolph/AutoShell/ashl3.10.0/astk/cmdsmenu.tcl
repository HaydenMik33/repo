
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: cmdsmenu.tcl,v 1.1 2000/04/25 17:19:56 karl Exp $
# $Log: cmdsmenu.tcl,v $
# Revision 1.1  2000/04/25 17:19:56  karl
# Initial revision
#

proc ccm_build_cmds_menu {menu} {
	global ccmcmds ccm_ids
	set n 0
	foreach ccmcmd $ccmcmds {
		
		set label [lindex $ccmcmd 0]
		set ccm_id [lindex $ccmcmd 1]
		set speclist [lrange $ccmcmd 2 end]

		if {$menu!="" && $label=="separator"} {
			$menu add separator
			continue
		}

		if {$ccm_id!=""} {
			set ccm_ids($ccm_id) $speclist
		}

		if {$menu!=""} {
			$menu add command -label $label \
				-command "ccm_create_cmd_dialog $n {$label} \
					{$speclist}"
		}
		incr n
	}
}

proc ccm_create_cmd_field {parent row specstr} {
	global ccm_values ccm_attrs ccm_fieldrows ccm_remember ccm_fieldnames
	#puts "specstr=$specstr"
	
	set fieldname [lindex $specstr 0]

	set rememberpos [lsearch $specstr "remember"]
	if {$rememberpos>=0} {
		#puts "setting flag to remember $fieldname of $parent,$row"
		set ccm_attrs($parent,$row,remember) 1
		if {[info exists ccm_remember($fieldname)]} {
			#puts "retrieving $fieldname for $parent,$row"
			set ccm_values($parent,$row) $ccm_remember($fieldname)
		}
	} else {
		#puts "no flag to remember $fieldname of $parent,$row"
		set ccm_attrs($parent,$row,remember) 0
	}

	set booleanpos [lsearch $specstr "boolean"]
	if {$booleanpos>=0} {
		set onpos [lsearch $specstr "onvalue *"]
		if {$onpos>=0} {
			set onvalue [lindex [lindex $specstr $onpos] 1]
		} else {
			set onvalue 1
		}
		set offpos [lsearch $specstr "offvalue *"]
		if {$offpos>=0} {
			set offvalue [lindex [lindex $specstr $offpos] 1]
		} else {
			set offvalue 0
		}
	}

	set attrpos [lsearch $specstr "size *"]
	if {$attrpos>=0} {
		set size [lindex [lindex $specstr $attrpos] 1]
	} else {
		set size 20x1
	}
	set sizelist [split $size x]
	#puts "sizelist=$sizelist"
	set width [lindex $sizelist 0]
	if {[llength $sizelist]>1} {
		set height [lindex $sizelist 1]
	} else {
		set height 1
	}


	label $parent.lab$row -text "$fieldname:"
	set ccm_attrs($parent,$row,lab) $fieldname
	grid $parent.lab$row -row $row -column 0 -sticky e
	if {$booleanpos>=0} {
		checkbutton $parent.ent$row -variable ccm_values($parent,$row) \
			-onvalue $onvalue -offvalue $offvalue
		grid $parent.ent$row -row $row -column 1 -sticky w
	} elseif {$height==1} {
		entry $parent.ent$row -textvariable ccm_values($parent,$row) \
			-width $width
		bind $parent.ent$row <Return> "$parent.ok invoke"
		grid $parent.ent$row -row $row -column 1 -sticky we
	} else {
		text $parent.txt$row -width $width -height $height \
			-yscrollcommand "$parent.scl$row set"
		grid $parent.txt$row -row $row -column 1 -sticky nsew
		scrollbar $parent.scl$row -command "$parent.txt$row yview"
		grid $parent.scl$row -row $row -column 2 -sticky wns
	}

	# Initialize the variable for this field
	if {![info exists ccm_values($parent,$row)]} {
		set ccm_values($parent,$row) ""
	}

	# Store the name of this field
	set ccm_fieldrows($parent,$fieldname) $row
	set ccm_fieldnames($parent,$row) $fieldname

	# Display file browse button is specified.
	set attrpos [lsearch $specstr "browse"]
	if {$attrpos>=0} {
		button $parent.brw$row -text "Browse..." -padx 2 -pady 1 \
			-command "ccm_browse_for_file $parent $row"
		grid $parent.brw$row -row $row -column 2 
	}

	# Mark field as optional if specified
	set attrpos [lsearch $specstr "opt"]
	if {$attrpos>=0} {
		set ccm_attrs($parent,$row,opt) 1
	} else {
		set ccm_attrs($parent,$row,opt) 0
	}

	# Store prefix if specified
	set attrpos [lsearch $specstr "pref *"]
	if {$attrpos>=0} {
		set ccm_attrs($parent,$row,pref) [lindex [lindex $specstr $attrpos] 1]
	} else {
		set ccm_attrs($parent,$row,pref) ""
	}
}

proc ccm_browse_for_file {parent row} {
	global ccm_values
	ccm_cmds_cwd_changed
	set x [tk_getOpenFile -initialdir [pwd] \
		-initialfile $ccm_values($parent,$row)]
	#puts "x=$x pwd=[pwd]"
	if {[string match "[pwd]*" $x]} {
		set x [string range $x [expr [string length [pwd]]+1] end]
	}
	#puts "x=$x"
	if {[string compare $x ""]} {
		set ccm_values($parent,$row) $x
	}
}

proc ccm_run_command {cmdstrs toplevel fldcount} {
	global ccm_values ccm_attrs ccm_fieldnames ccm_remember
	if {$toplevel!=""} {
		for {set r 0} {$r<$fldcount} {incr r} {
			set slave [grid slaves $toplevel -row $r -col 1]
			#puts "slave=$slave"
			set class [winfo class $slave]
			#puts "class=$class"
			if {$class=="Text"} {
				set ccm_values($toplevel,$r,value) \
					[string trim [$slave get 1.0 end]]
			} else {
				set ccm_values($toplevel,$r,value) \
					$ccm_values($toplevel,$r)
			}
			set fieldname $ccm_fieldnames($toplevel,$r)
			if {$ccm_attrs($toplevel,$r,remember)} {
				#puts "remembering $fieldname value of $toplevel,$r"
				set ccm_remember($fieldname) $ccm_values($toplevel,$r,value)
			}
			
			if {$ccm_attrs($toplevel,$r,opt)==0 && 
				[string compare [string trim $ccm_values($toplevel,$r,value)] ""]==0} {
				tk_dialog .err ERROR \
					"$ccm_attrs($toplevel,$r,lab) is required!" \
					error 0 OK
				return
			}
			if {[string compare $ccm_attrs($toplevel,$r,pref) ""] &&
				[string compare [string trim $ccm_values($toplevel,$r,value)] ""]!=0} {
				set ccm_values($toplevel,$r,value) \
					"$ccm_attrs($toplevel,$r,pref)$ccm_values($toplevel,$r,value)"
			}
		}
	}
	set allresults ""
foreach cmdstr $cmdstrs {
	#puts "before escape cmdstr=$cmdstr"
	foreach el [array names ccm_values "$toplevel,*,value"] {
		regsub -all {"} $ccm_values($el) {\\"} ccm_values($el)
	}
	set evalledstr [string trim [subst $cmdstr]]
	#puts "after eval evalledstr=$evalledstr"
	if {[string first "*" $cmdstr]>=0} {
		set cmdstr ""
		foreach el [split $evalledstr] {
			if {[string first "*" $el]>=0} {
				set arg [join [glob $el]]
			} else {
				set arg $el
			}
			append cmdstr "$arg "
		}
	} else {
		set cmdstr $evalledstr
	}
	#puts "after globbing cmdstr=$cmdstr"
	#return
	set errflag [catch {eval exec $cmdstr} results]
	if {[string length $allresults]>0} {
		append  allresults "\n"
	}
	append allresults $results
	}
	set rc [scrl_dialog .err "COMMAND RESULTS" $allresults info 0 OK "Edit and Retry"]
	if {$rc==0} {
		if {$toplevel!=""} {
			destroy $toplevel	
		}
	}
}

proc ccm_create_cmd_dialog {eid label speclist} {
		#puts "eid=$eid label=$label speclist={$speclist}"
		global ccm_values ccm_fieldrows
		set w .tmp$eid
		toplevel $w
		grid columnconfigure $w 1 -weight 1
		wm title $w $label
	set fldcount 0
	set newstrs {}
	foreach specstr $speclist {
		#puts "doing specstr=$specstr"
		set linelen [string length $specstr]
		set cbcount 0
		set word ""
		set newstr ""
		for {set n 0} {$n<$linelen} {incr n} {
			set ch [string index $specstr $n]
			switch -- $ch {
			  \{ {
					incr cbcount
					if {$cbcount==1} {
						append newstr $word
						set word ""
					} else {
						append word $ch
					}
				}
			  \} {
					incr cbcount -1
					if {$cbcount==0} {
						if {[llength [split $word]]>1} {
							append newstr \$ccm_values($w,$fldcount,value)
							ccm_create_cmd_field $w $fldcount $word	
							incr fldcount
						} else {
							# This is reference to another field.
							set refnum $ccm_fieldrows($w,$word)
							append newstr \$ccm_values($w,$refnum,value)
						}
						#puts "FIELD$fldcount=$word"
						set word ""
					} else {
						append word $ch
					}
				}
			  \\ {
					incr n
					append word [string index $specstr $n]
				}
			  default {
				append word $ch
			  }
			}
		}	
		append newstr $word
		lappend newstrs $newstr
	}
		#puts "newstrs={$newstrs}"
		#puts "fldcount=$fldcount"
		if {$fldcount==0} {
			destroy $w
			ccm_run_command $newstrs "" $fldcount
			return
		}
		set ccm_values(cwd) [pwd]
		label $w.cwd -text "CWD:"
		grid $w.cwd -row [expr $fldcount + 1] -col 0 -sticky e
		entry $w.cwdval -textvariable ccm_values(cwd)
		grid $w.cwdval -row [expr $fldcount + 1] -col 1 -sticky ew
		button $w.cwdbrowse  -text "Browse..." -padx 2 -pady 1 \
			-command "ccm_browse_for_dir"
		grid $w.cwdbrowse -row [expr $fldcount + 1] -col 2 -sticky w

		bind $w.cwdval <Return> ccm_cmds_cwd_changed

		button $w.ok -text OK -command "ccm_cmds_cwd_changed; 
			ccm_run_command {$newstrs} $w $fldcount"
		grid $w.ok -row [expr $fldcount + 2] -col 0 -columnspan 2
		button $w.cancel -text Cancel -command "destroy $w"
		grid $w.cancel -row [expr $fldcount + 2] -col 2 -columnspan 2 
		#grab $w
}

proc ccm_browse_for_dir {} {
	global ccm_values
	set result [dirselect]
	if {[string compare $result ""]!=0} {
		set ccm_values(cwd) $result
	}
}

proc ccm_cmds_cwd_changed {} {
	global ccm_values
	if {[string compare [pwd] $ccm_values(cwd)]==0} {
		#puts "no CWD change."
		return
	}
	#puts "Changing CWD to $ccm_values(cwd)"
	if {[catch {cd $ccm_values(cwd)}]} {
		tk_dialog .err ERROR "Couldn't change to $ccm_values(cwd)!" \
			error 0 OK
		set ccm_values(cwd) [pwd]
	}
}

proc ccm_cfg_files_exist {cfgfilename} {
	global env
	if {[file readable /etc/$cfgfilename] || 
	    [file readable [file dirname $env(ASTK_DIR)]/$cfgfilename] || 
		[file readable ~/$cfgfilename]} {
		return 1
	} else {
		return 0
	}
}

proc ccm_load_menu_config {cfgfilename menu} {
	global env
	if {[file readable /etc/$cfgfilename]} {
	    source ~/etc/$cfgfilename
		ccm_build_cmds_menu $menu
		if {$menu!=""} {
			$menu add separator
		}
	}
	if {[file readable [file dirname $env(ASTK_DIR)]/$cfgfilename]} {
	    source [file dirname $env(ASTK_DIR)]/$cfgfilename
		ccm_build_cmds_menu $menu
		if {$menu!=""} {
			$menu add separator
		}
	}
	if {[file readable ~/$cfgfilename]} {
	    source ~/$cfgfilename
		ccm_build_cmds_menu $menu
	}
}

proc warn_read_only {scrfile} {
	global ccm_ids
	if {![file exists $scrfile] || [file writable $scrfile]} {
		return 0
	}
	if 	{[info exists ccm_ids(checkout_edit)]} {
		set rc [tk_dialog .err ERROR "File $scrfile is read-only!" error 1 \
			"Open for Reading Only" \
			"Cancel" \
			"Checkout for Modification"]
	} else {
		set rc [tk_dialog .err ERROR "File $scrfile is read-only!" error 1 \
			"Open for Reading Only" \
			"Cancel"]
	}
	switch $rc {
		0 {
			return 0
		}
		1 {
			return -1
		} 
		2 {
			global ccm_ids
			set cc -1
			if 	{[info exists ccm_ids(checkout_edit)]} {
				set speclist $ccm_ids(checkout_edit)
				#puts "speclist=$speclist"
				set allresults ""
				foreach specstr $speclist {
					regsub "\{\[Ff\]ile .*\}" $specstr $scrfile fixedvar
					set ec 0
					set errorCode NONE
					if {[catch {eval exec $fixedvar 2>@stdout} results]} {
						set ec 1	
						append allresults "\n$results"
						break
					} else {
						set ec 0	
						append allresults "\n$results"
					}
				}
				scrl_dialog .tmp RESULTS [string trim $allresults] info 0 OK				
			} else {
				if {[catch {exec co -l $scrfile 2>@stdout} allresults]} {
					set ec 1
				} else {
					set ec 0
				}
				scrl_dialog .tmp RESULTS $allresults info 0 OK				
			}
			return $ec
		}
	}	
}
