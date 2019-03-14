
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: synwin.tcl,v 1.12 2000/09/14 15:32:41 karl Exp $
# $Log: synwin.tcl,v $
# Revision 1.12  2000/09/14 15:32:41  karl
# Made all fields non-expandable, since expandable doesn't work with
# the scrollable frame.
#
# Revision 1.11  2000/09/12  21:13:29  karl
# Fixed a bug that could occur if a syntax string was not a valid TCL list.
# Added a scrollbar to the frame for syntax strings that create
# templates too large for the screen.  Shrunk the Add and Edit File buttons.
#
# Revision 1.10  2000/07/11  18:08:50  karl
# Added code to initialize the command edit template window with the
# parms from the most recently executed command of that name in the
# current session window.
# Added read-only warning when editing files from within command edit
# template window.
#
# Revision 1.9  1999/08/24  15:37:52  karl
# Normalized to use edit_any_script for script edits.
#
# Revision 1.8  1999/03/17  21:56:32  karl
# Added synwin_sub to allow windows to be started as children of a parent.
# Added trim of syntax string to avoid bogus non-tagged parm with name of
# command in attribute window.
# Added return or window name if synwin is called with a callback.
#
# Revision 1.7  1998/10/20  22:11:31  karl
# Fixed bug caused by treating syntax string as a TCL list.
#
# Revision 1.6  1997/10/29  23:29:34  love
# Modified a place where a temporary file name was manually generated
# to use the tempfilename procedure to make it more portable.
# Also modified the code to use the file delete command when
# running Tcl7.6 instead of exec'ing rm which isn't portable.
#
# Revision 1.5  1997/05/13  17:22:51  karl
# Made text objects stretch when window is resized.
#
# Revision 1.4  1997/04/10  20:35:57  karl
# Fixed problem with losing data in a scrolling frame for suffixed parms
#
# Revision 1.3  1996/11/04  21:58:52  karl
# Fixed bug that kept "Edit File" window from saving changes to files.
#
# Revision 1.2  1996/10/16  19:49:32  jasonm
# changed the edit script window to behave more like the ones in eqb.
# it has a save button, and :wq, :w, etc. work correctly
#
# Revision 1.1  1996/08/27  16:18:48  karl
# Initial revision
#
#########################################################################

#  SYNWIN SUBROUTINES - These routines can be reused in other apps
#########################################################################
# This proc creates a dialog box based on the syntax string for a command.

# Each new synwin window will have a unique ID, determined by this counter.
set sw_cnt 0

set bigparms {{help 4} {explain 8}}
proc synwin {synstr input {callback {}} {scrfile {}} {vibindings 0}} {
	synwin_sub "" $synstr $input $callback $scrfile $vibindings
}

proc synwin_sub {pw synstr input callback scrfile vibindings} {
	global swinfo
	global ttfont pn  frnum  sw_cnt
	set cmdname  [lindex [split [string trim $synstr] " \t\n"] 0]
	incr sw_cnt
	#puts "synwin_sub input=$input"

	set synstr [string trim $synstr]
	if {![info complete $synstr]} {
		tk_dialog .err ERROR "Syntax string for $cmdname has bad format!" \
			error 0 OK
		return
	}
	# Initialize entry for this window.
	set swid $pw.c${sw_cnt}_$cmdname
	set swinfo($swid,var) var$sw_cnt
	set swinfo($swid,flg) flg$sw_cnt
	set swinfo($swid,opt)  ""
	set swinfo($swid,cmdname)  $cmdname
	set swinfo($swid,input)  $input
	set swinfo($swid,scrfile)  $scrfile
	set swinfo($swid,msgstr)  $cmdname
	set swinfo($swid,vibindings)  $vibindings
	set swinfo($swid,callback) $callback

	upvar #0 $swinfo($swid,var) sw_var
	upvar #0 $swinfo($swid,flg) sw_flg
	#if {[info exists sw_var]} {unset sw_var}
	#if {[info exists sw_flg]} {unset sw_flg}

	set wn $swid
    set geometry "+[winfo pointerx .]+[winfo pointery .]"
	toplevel $wn 
	wm geometry $wn $geometry
	pack propagate $wn 0
	$wn configure -height 380
	$wn configure -width 620
	wm title $wn "$cmdname parameters"
	wm withdraw $wn
	wm protocol $wn WM_DELETE_WINDOW "doCancel $wn $swid"

	# Syntax display is disabled for now.
	if {0} {
		# Count carriage returns to determine size
		set crcount 0
		set tmpstr $synstr
		set crloc [string first "\n" $tmpstr]
		while {$crloc!=-1} {
			incr crcount	
			set tmpstr [string range $tmpstr [expr $crloc + 1] end]
			set crloc [string first "\n" $tmpstr]
		}
	
		# Escape curly braces to protect from interpreter.
		regsub -all {\\\{} $synstr "\{" tmpstr	
		regsub -all {\\\}} $tmpstr "\}" tmpstr	
	
		# Display syntax string at top of window.
		text $wn.assyntax -width 70 -height $crcount -bd 4 \
			-relief groove
		$wn.assyntax insert 1.0 $tmpstr
		pack $wn.assyntax
	}

	# Create button to allow cancel, send or doc viewing.
	frame $wn.buttons 
	pack $wn.buttons -side bottom -fill x 
	button $wn.buttons.send -text "OK"
	if {$callback!=""} {
		$wn.buttons.send configure -command "
			global swinfo
			if {\[eas_check $swid\]} {
				fmtcmd $swid $wn.parms.clip.tmp
				destroy $wn
				#puts \"msgstr=\$swinfo($swid,msgstr)\"
				$callback \"\$swinfo($swid,msgstr) \$swinfo($swid,opt)\"
				catch {global $swinfo($swid,flg); unset $swinfo($swid,flg)}
				catch {global $swinfo($swid,var); unset $swinfo($swid,var)}
			}
		"
	} else {
		$wn.buttons.send configure -command "
			if {\[eas_check $swid\]} {
				fmtcmd $swid $wn.parms
				destroy $wn
				catch {global $swinfo($swid,flg); unset $swinfo($swid,flg)}
				catch {global $swinfo($swid,var); unset $swinfo($swid,var)}
			}
		"
	}	
	button $wn.buttons.clear -text Clear -command "
		clear_all_values $swid $wn
		"
	button $wn.buttons.cancel -text Cancel -command "
		global swinfo 
		if {\[eas_check $swid\]} {
			set swinfo($swid,msgstr) CaNcEl
			destroy $wn
		}
	"
	pack $wn.buttons.send $wn.buttons.clear $wn.buttons.cancel \
		-side left -expand 1 -padx 3 -pady 3    


	# Add field at bottom to allow user to type in any fields not 
	# included in dialog (enumerated fields, for example).
	frame $wn.typframe
	label $wn.typframe.typlab -text "Additional Parms" 
	entry $wn.typframe.typspace -relief sunken -textvariable swinfo($swid,opt) -bg white -fg black
	if {$callback!=""} {
		bind $wn.typframe.typspace <Return> "
			global swinfo
			fmtcmd $swid \[winfo toplevel %W\].parms
			destroy \[winfo toplevel %W\]
			$callback \"\$swinfo($swid,msgstr) \$swinfo($swid,opt)\"
			catch {global $swinfo($swid,flg); unset $swinfo($swid,flg)}
			catch {global $swinfo($swid,var); unset $swinfo($swid,var)}
			break
		"
	} else {
		bind $wn.typframe.typspace <Return> "
			fmtcmd $swid \[winfo toplevel %W\].parms
			destroy \[winfo toplevel %W\]
			catch {global $swinfo($swid,flg); unset $swinfo($swid,flg)}
			catch {global $swinfo($swid,var); unset $swinfo($swid,var)}
			break
		"
	}	
#	bind $wn.typframe.typspace <Return> "
#		fmtcmd $swid \[winfo parent %W\].parms
#		destroy \[winfo parent %W\]
#		break
#	"
	pack $wn.typframe -side bottom -fill x 
	pack $wn.typframe.typlab  -side left
	pack $wn.typframe.typspace -side left -fill x -expand 1


	# Trim off command name
	set synstr [string range $synstr \
		[string wordend $synstr 0] end]
	# Replace all parens and brackets with braces (force into list notation)
	# Insert list headers (l1=optional l2=selection l3=mix-n-match) to
	# identify construct type.
	set newstr ""
	set lenstr [string length $synstr]
	for {set c 0} {$c < $lenstr} {incr c} {
		set ch [string index $synstr $c]
		switch -- $ch {
			"\{" {
				set ch2 [string index $synstr [expr $c + 1]]
				set ch3 [string index $synstr [expr $c + 1]]
#				if {$ch2 != "l"} {
					append newstr "\{l2 "
#				} else {
#					append newstr $ch
#				}
			}
			"\}" { append newstr "\}" }
			"\[" { append newstr "\{l1 " }
			"\]" { append newstr "\}" }
			"\(" { append newstr "\{l3 " }
			"\)" { append newstr "\}" }
			"," { append newstr " , " }
			default { append newstr $ch }
				
		}
		set ch [string index $synstr 0]
		
	}
	set synstr $newstr
	#puts "newstr=$newstr"

	# Keep count of parms
	set pn 0
	# Keep count of frames
	set frnum 0
	# Create master frame around top-level parms
	scrollframe $wn.parms -vertical 
	pack $wn.parms -side bottom -fill both -expand 1
	set focus_field ""
	# For each single parm or group of parms...
	#puts "synstr=$synstr"
	foreach part $synstr {
		# Add it/them to the dialog box.
		set newfield [add_entries $swid $part white $wn.parms.clip.tmp]
		# Set focus to first entry field.
		if { $focus_field == "" && $newfield != "" } {
			set focus_field $newfield
		}
	}
	
	update idletasks
	#puts "wm reqheight=[winfo reqheight $wn]"
	#puts "wm height=[winfo height $wn]"
	if {[winfo reqheight $wn]>500} {
		wm geometry $wn [winfo reqwidth $wn]x500
	}
	wm deiconify $wn
	tkwait visibility $wn
	#grab $wn
	if {$focus_field!=""} {
		focus $focus_field
	}
	
	#an_cmd store file=vars.jnk
	if {$callback==""} {
		# Disable rest of application until this window terminates.
		# This window will place it's results into msgstr.
		tkwait window $wn
		if {$swinfo($swid,msgstr)!="CaNcEl"} {
			#puts "wn=$wn"
			set cmdname [string range $wn [expr [string first _ $wn]+1] end]
			#puts "cmdname=$cmdname"
			#return "$cmdname $swinfo($swid,msgstr) $swinfo($swid,opt)"
			return "$swinfo($swid,msgstr) $swinfo($swid,opt)"
			#return "[string range $wn 2 end] $msgstr $sw_msgopts"
		} else {
			return ""
		}
	} else {
		return $wn
	}
}

proc doCancel {wn swid} {
	global swinfo 
	if {[eas_check $swid]} {
		set swinfo($swid,msgstr) CaNcEl
		destroy $wn
	}
}

proc clear_all_values {swid wn} {
	global swinfo
	global $swinfo($swid,var)
	#puts "clear_all_values $swid $wn"
	#puts "Looping through elements in $swinfo($swid,var)"
	foreach el [array names $swinfo($swid,var) "$wn.*"] {
		eval set val \$$swinfo($swid,var)($el)
		#puts "variable $swinfo($swid,var)($el)=$val"
		set $swinfo($swid,var)($el) ""
	}
}


set frnum 0
proc add_entries {swid synpart color wn } {
	global pn frnum swinfo
	upvar #0 $swinfo($swid,var) sw_var
	upvar #0 $swinfo($swid,flg) sw_flg
	set cmdname $swinfo($swid,cmdname)
	set scrfile $swinfo($swid,scrfile)
	set input $swinfo($swid,input)
	
	incr frnum
	set ll [llength $synpart]
	#puts "synpart=$synpart"
	if {$ll>1} {
		# Optional items
		set lt [lindex $synpart 0]
		if {$lt=="l1"} {
			#puts "optional"
			for { set lp 1 } { $lp < $ll } {incr lp 1} {
				add_entries $swid [lindex $synpart $lp] \
					lightgray $wn 
			}
			
		# Multiple choice
		} elseif {$lt == "l2"} {
			#puts "muiltiple"
			set wn $wn.l$frnum
			frame $wn -relief raised -bd 2 
			pack $wn -side top -anchor w -ipadx 15 -padx 15
			for { set lp 1 } { $lp < $ll } {incr lp 1} {
				#puts "lp=$lp part=[lindex $synpart $lp]"

				if {[lindex $synpart $lp] == ","} {
					frame $wn.sep$lp -relief sunken -bd 2 \
						-height 4
					pack $wn.sep$lp -side top -anchor w \
						-fill x
				} else {
					add_entries $swid \
						[lindex $synpart $lp] \
						gray $wn 
				}
			}
		# Mix-N-Match
		} elseif {$lt == "l3"} {
			#puts "mixnmatch"
			set wn $wn.l$frnum
			frame $wn -relief raised -bd 2 
			pack $wn -side top -anchor w
			for { set lp 1 } { $lp < $ll } {incr lp 1} {
				if {[lindex $synpart $lp] == ","} {
				} else {
					add_entries $swid [lindex $synpart $lp] \
						gray $wn 
				}
			}
		}
	} else {
		set i [lindex $synpart 0]
		frame $wn.$pn 
		set expandable 0
		#pack $wn.$pn -side top -anchor w 
		# Tagged parms
		if {[regsub {=} $i " " i]} {
			set prmnm [lindex $i 0]
			set expandable [add_tagged $swid $i $wn $color $pn]
			set opn $pn
			#puts "pack $wn.$pn -side top -anchor w -expand $expandable -fill both"
			#pack $wn.$pn -side top -anchor w -expand $expandable -fill both
			pack $wn.$pn -side top -anchor w -expand 0 -fill both
			incr pn
			return ""
		# Non-tagged parms
		} else {
			set prmnm [lindex $i 0]
			label $wn.$pn.lab -width 15 -anchor e
			#puts "Adding $wn.$pn.rad"
			checkbutton $wn.$pn.rad -text $i -relief flat \
				-variable $swinfo($swid,flg)($wn.$pn) -onvalue $prmnm \
				-offvalue "" -anchor e -tristatevalue NONE
			if {[lsearch $input $prmnm]>=0} {
				global $swinfo($swid,flg)
				set $swinfo($swid,flg)($wn.$pn) $prmnm
			}
			bind $wn.$pn.rad <Button-1> "
				global swinfo
				upvar #0 \$swinfo($swid,flg) sw_var
				if {\$sw_var(\[winfo parent %W\]) != {} } {
					%W deselect
					break
				}
			"
			pack $wn.$pn -side top -anchor w 
			pack $wn.$pn.lab $wn.$pn.rad -side left 
			incr pn
			return ""
		}
	}
}

proc add_tagged {swid parm wn color pn } {
	global swinfo
	upvar #0 $swinfo($swid,var) sw_var
	set input $swinfo($swid,input)
	set scrfile $swinfo($swid,scrfile) 
	set cmdname $swinfo($swid,cmdname) 
	set callback $swinfo($swid,callback) 
	global bigparms
	#puts "parm='$parm'"
	set prmnm [lindex $parm 0]
	set prmspec [lindex $parm 1]
	set expandable 0
	# Enumerated parms
	if {[regsub {\.} $prmnm " " prnnm]} {
		set prefix [lindex $prmnm 0]
		set sufflen [string length [lindex $prmnm 1]] 
		label $wn.$pn.lab -text [lindex [split $prmnm "."] 0] \
			-width 15  -anchor e
		pack $wn.$pn.lab -side left
		arraybox $swid $wn.$pn.arr 3 $color 3 \
			[lindex [split $prmnm "."] 0]
		pack $wn.$pn.arr -side left -fill both -expand 1
		set expandable 0
		
	# Selection parameters
	} elseif {[string first "|" $prmspec]>=0} {
		label $wn.$pn.lab -text $prmnm -width 15 \
			-anchor e
		pack $wn.$pn.lab -side left
		set items [split $prmspec "|"]
		set cnt 0
		foreach item $items {
			if {[string match "%*" $item]}	{
				if {[string match "*%*d*" $item]} {
					set wdth 10
				} else {
					set wdth 30
				}
				set sw_var($wn.$pn) [get_list_val $input $prnnm]
				#puts "$wn.$pn.ent$cnt var is $swinfo($swid,var)($wn.$pn)"
				entry $wn.$pn.ent$cnt -relief sunken \
					-textvariable \
						$swinfo($swid,var)($wn.$pn) \
					-bg $color  -width $wdth
				pack $wn.$pn.ent$cnt -side left 
			} else {
				set sw_var($wn.$pn) [get_list_val $input $prnnm]
				#puts "$wn.$pn.ent$cnt var is $swinfo($swid,var)($wn.$pn)"
				radiobutton $wn.$pn.ent$cnt \
					-variable $swinfo($swid,var)($wn.$pn) \
					-bg $color \
					-text $item \
					-value $item \
					-tristatevalue NONE
				pack $wn.$pn.ent$cnt -side left 
			}
			incr cnt
		}
	# Normal tagged parms
	} else {
		set prmspec [lindex $parm 1]
		label $wn.$pn.lab -text $prmnm -width 15 \
			-anchor e
		if {[string match "*%*d*" $prmspec]} {
			set wdth 10
		} else {
			set wdth 30
		}
		# puts "input=$input"
		set sw_var($wn.$pn) [get_list_val $input $prnnm]
		if {[set bigparmpos [lsearch $bigparms "$prmnm *"]]>=0} {
			set bigparmht [lindex [lindex $bigparms $bigparmpos] 1]
			#puts "Adding $wn.$pn.vie"
			#puts "$wn.$pn.vie var is $sw_var($wn.$pn)"
			viedit $wn.$pn.vie -relief sunken \
				-bg $color -fg black -width 65 -height $bigparmht \
				-vibindings $swinfo($swid,vibindings) \
				-fileops no -status no
			$wn.$pn.vie.text insert 1.0 $sw_var($wn.$pn)				
			$wn.$pn.vie.text mark set insert 1.0
			pack $wn.$pn.lab $wn.$pn.vie -side left \
				-fill both -expand 1
			set expandable 1
		} else {
			#puts "Adding $wn.$pn.ent"
			#puts "$wn.$pn.ent var is $swinfo($swid,var)($wn.$pn)"
			entry $wn.$pn.ent -relief sunken \
				-textvariable $swinfo($swid,var)($wn.$pn) \
				-bg $color -fg black \
				-width $wdth
	if {$callback!=""} {
		bind $wn.$pn.ent <Return> "
			global swinfo
			fmtcmd $swid \[winfo toplevel %W\].parms.clip.tmp
			destroy \[winfo toplevel %W\]
			$callback \"\$swinfo($swid,msgstr) \$swinfo($swid,opt)\"
			catch {global $swinfo($swid,flg); unset $swinfo($swid,flg)}
			catch {global $swinfo($swid,var); unset $swinfo($swid,var)}
			break
		"
	} else {
		bind $wn.$pn.ent <Return> "
			fmtcmd $swid \[winfo toplevel %W\].parms.clip.tmp
			destroy \[winfo toplevel %W\]
			catch {global $swinfo($swid,flg); unset $swinfo($swid,flg)}
			catch {global $swinfo($swid,var); unset $swinfo($swid,var)}
			break
		"
	}	
#			bind $wn.$pn.ent <Return> "
#				set msgstr {}
#				fmtcmd $swid \[winfo toplevel %W\].parms.clip.tmp
#				destroy \[winfo toplevel %W\]
#				break
#			"
			pack $wn.$pn.lab $wn.$pn.ent -side left 
		}

		if {$prmnm=="file"} {
			button $wn.$pn.butt -text "Edit File" \
				-command "global swinfo
					edit_any_file \
					\[get_full_name $swid $wn $pn\] \
					\$swinfo($swid,vibindings)" -padx 1 -pady 0
			pack $wn.$pn.butt -side left
		} elseif {$prmnm=="name" && \
				$cmdname=="defcmd" && $scrfile!=""} {
			button $wn.$pn.butt -text "Edit Script" \
				-command "sw_editscript $swid $wn $pn"
			pack $wn.$pn.butt -side left
		}
	}
	#puts "returning expandable=$expandable"
	return $expandable
}

proc sw_editscript {swid wn pn} {
	global swinfo options
	upvar #0 $swinfo($swid,var) sw_var
	if {[info exists options(texteditor)]} {
		set editorcmd $options(texteditor)
	} else {
		set editorcmd anp
	}	
#	edit_any_script $swinfo($swid,scrfile) $sw_var($wn.$pn) \
#		$swinfo($swid,vibindings)
	eas_start [file rootname $swinfo($swid,scrfile)] "" $sw_var($wn.$pn) SL "\treturn 0" $editorcmd "" "" $swid

}

proc name_to_help {wn name1 name2 op} {
	global $name1
	eval set newval \$$name1\($name2\)
	foreach child [get_children [winfo parent $wn]] {
		if {[winfo name $child]=="lab" && 
				[$child cget -text]=="help"} {
			set parent [winfo parent $child]
			set text [$parent.vie.text get 1.0 end]	
			set text [string trim $text]
			set firstword [lindex [split $text] 0]
			set fwlen [string length $firstword]
			$parent.vie.text delete 1.0 end
			set text "${newval}[string range $text $fwlen end]"
			$parent.vie.text insert 1.0 $text
			$parent.vie.text mark set insert 1.0
		}
	}
}

proc get_children {wn} {
	set children [winfo children $wn]
	if {$children==""} {
		return $wn
	} else {
		foreach child $children {
			eval lappend list [get_children $child]
		}
		return $list
	}
}

proc edit_any_script {scrfile scriptname {vibindings 0}} {
	#puts "inside edit_any_script"
	if {$scriptname==""} {
		disp_error "You must provide a command name first."
		return
	}  
	set script [pull_script2 $scrfile $scriptname]
	if {$script=="Pull_Script_Abort"} {
		return 
	}
	if {$script==""} {
		set script "startscript $scriptname\n	return 0\nendscript\n"
	}
	set sn $scriptname
	toplevel .s$sn 
	wm withdraw .s$sn
	viedit .s$sn.viedit -vibindings $vibindings \
		-savecommand "sw_save_script $scrfile $sn" \
		-width 80 -height 20
	.s$sn.viedit.text insert 1.0 $script
	.s$sn.viedit.text mark set insert 1.0
	
	frame .s$sn.butts
	button .s$sn.butts.ok -text OK -command "
			if {\[sw_save_script $scrfile $sn \
				\[.s$sn.viedit.text get 1.0 end\]\]==0} {
				destroy .s$sn
			}
		"
	button .s$sn.butts.save -text "Save" -command \
		"sw_save_script $scrfile $sn \[.s$sn.viedit get 1.0 end\]"

	
	button .s$sn.butts.cancel -text Cancel -command "destroy .s$sn"
	pack .s$sn.butts.ok .s$sn.butts.save .s$sn.butts.cancel -side left \
		-expand 1 -padx 3 -pady 3
	
	pack .s$sn.viedit -fill both -expand 1
	pack .s$sn.butts -fill x
	focus .s$sn.viedit.text
	update idletasks; wm deiconify .s$sn
}

proc arraybox {swid textname numentries color height prmnm} {
	global swinfo
	upvar #0 $swinfo($swid,var) sw_var
	set input $swinfo($swid,input)
	#puts "height=$height numentries=$numentries"
	
	frame $textname -relief groove -bd 2 
	text $textname.sfr -height [expr $height * 1.75] -width 44 \
		-yscrollcommand "$textname.sb set"
	scrollbar $textname.sb -command "$textname.sfr yview"
	pack $textname.sfr -side left -fill both -expand 1
	pack $textname.sb -side left -fill y
	button $textname.add -text Add \
		-command "global swinfo
			upvar #0 \$swinfo($swid,var) sw_var
			arraybox_add $swid $textname \$sw_var($textname.num) \
				3 $color" -pady 0 -padx 1
	pack $textname.add -side top 
	set vn 1
	foreach item $input {
		set tag [lindex $item 0]
		if {[string match "$prmnm.*" $item]} {
			set parts [split $tag "."]
			set suffix [join [lrange $parts 1 end] "."]
			set val [lindex $item 1]
			set sw_var($textname.sfr.val$vn) $val
			set sw_var($textname.sfr.suf$vn) $suffix
			incr vn
		}
	}	
	incr vn -1
	if {$vn > $numentries} {
		set numentries $vn
	}
	arraybox_add $swid $textname 0 $numentries $color 
	#$textname.sfr yview end
		
}

proc arraybox_add {swid textname currnum num color} {
	global swinfo
	upvar #0 $swinfo($swid,var) sw_var
	$textname.sfr configure -state normal
	for {set n [expr $currnum + 1]} \
			{ $n <= [expr $currnum + $num ]}  \
			{incr n} {
		$textname.sfr insert end "\n"
		$textname.sfr window create $n.0 \
			-create "entry $textname.sfr.suf$n -textvariable \
				$swinfo($swid,var)($textname.sfr.suf$n) -bg $color -fg black -width 10"
		$textname.sfr window create "$n.0 lineend" \
			-create "entry $textname.sfr.val$n -textvariable \
				$swinfo($swid,var)($textname.sfr.val$n) -bg $color -fg black -width 30 "
	}
	set sw_var($textname.num) [expr $currnum + $num ]
	$textname.sfr configure -state disabled
}

# This function looks through all the children of a window for parm fields,
# and appends their values to the msgstr for the current command.  It will
# recurse to handle nested frames.
proc fmtcmd {swid widget} {
	global swinfo
	upvar #0 $swinfo($swid,var) sw_var
	upvar #0 $swinfo($swid,flg) sw_flg
	foreach i [winfo children $widget] {
		# Is this a regulat tagged parameter?
		if {[string match "ent*" [winfo name $i]] ||
		    [string match "vie*" [winfo name $i]] } {
			# Get the parm name from the label at the same level.
			set pname [lindex [[winfo parent $i].lab \
				configure -text] 4]
			# If this parm isn't already in the message being built . . .
			if {[string match "*\[ 	\n\]$pname=*" $swinfo($swid,msgstr)]==0} {
				if {[string match "vie*" [winfo name $i]]} {
					set pval [string trim [$i.text get 1.0 end]]
				} else {
					set pval $sw_var([winfo parent $i])
				}
				if {$pval!=""} {
				  if {[string index $pval 0]!="\""
					  && [regexp "\[ \n\t\]" $pval]} {
				#regsub -all "\n" $pval "\n\\" pval
					  append swinfo($swid,msgstr) " $pname=\"$pval\""
				  } else {
					  append swinfo($swid,msgstr) " $pname=$pval"
				  }
				}
			}
		# If this is a flag (non-tagged) type parameter.
		} elseif {[winfo name $i]=="rad"} {
			set pname [lindex [[winfo parent $i].rad \
				configure -text] 4]
			set pval $sw_flg([winfo parent $i])
			if {$pval!=""} {
				append swinfo($swid,msgstr) " $pname"
			}
				
		# If this is a suffixed parameter (enumerated).
		} elseif {[winfo name $i]=="sfr"} {
			set lines [$i get 1.0 end]
			set lc 1
			foreach line [split $lines "\n"] {
				if [catch {set subname [lindex \
					[$i window cget $lc.0 -create] 1]}] {
					break
				}
				$i see $lc.0
				# Get the parm name from the label two levels up.
				set pname [lindex [[winfo parent [winfo parent \
					[winfo parent $subname]]].lab configure -text] 4]
				#puts "prefix=$pname"
				# Suffix name is stored in variable attached to sufx entry box.
				set psuf $sw_var($subname)
				#puts "suffix=$psuf"
				# If it doesn't already exist in the string . . .
				if {[string match "*\[ 	\n\]$pname.$psuf=*" \
						$swinfo($swid,msgstr)]==0} {
					set pval $sw_var([winfo parent $subname].val[string range \
						[winfo name $subname] 3 end])
					#puts "value=$pval"
					if {$pval!=""} {
					  if {[string index $pval 0]!="\""
						  && [regexp "\[ \n\t\]" $pval]} {
						  append swinfo($swid,msgstr) " $pname.$psuf=\"$pval\""
					  } else {
						  append swinfo($swid,msgstr) " $pname.$psuf=$pval"
					  }
					}
				} 
				incr lc
			}
		} else {
			fmtcmd $swid $i
		}

	}
	#puts "swinfo($swid,msgstr)=$swinfo($swid,msgstr)"
}

proc edit_any_file {name {vibindings 0}} {
	global options
        if {[info exists options(texteditor)]} {
                set editorcmd $options(texteditor)
        } else {
                set editorcmd anp
        }
	set fileparts [split $name "."]
	set ext [lindex $fileparts end]
	#puts "ext=$ext"
	if {$ext=="ssu" || $ext=="su"} {
		edit_su $name "" 
	} else {
		if {[warn_read_only $name]} {
			return
		}
		eval exec $editorcmd $name &
#		set topname .f[join $fileparts "_"]
#		if {[winfo exists $topname]} {
#			return
#		}
#		toplevel $topname
#                wm title $topname "$name"
#		viedit $topname.vi -vibindings $vibindings
#		frame $topname.butts
#		button $topname.butts.ok -text Ok -command "
#			if {\[catch {set fh \[open $name w\] }\]} {
#				tk_dialog .tmp ERROR \
#				  {Can't save changes.  Check permissions} \
#				  error 0 OK	
#				return
#			}
#			puts \$fh \[$topname.vi.text get 1.0 end\]
#			close \$fh
#			destroy $topname
#		"
#		button $topname.butts.cancel -text Cancel -command "
#			destroy $topname
#		"
#		pack $topname.butts.ok $topname.butts.cancel -side left \
#			-expand 1 -padx 3 -pady 3
#
#		pack $topname.vi -expand 1 -fill both
#		pack $topname.butts
#		if {[file readable $name]} {
#			set fh [open $name r]
#			$topname.vi.text insert 1.0 [read $fh]
#			close $fh
#		}
#		$topname.vi.text mark set insert 1.0
#		focus $topname.vi.text
	}
}

proc get_full_name {swid wn pn} {
	global swinfo
	upvar #0 $swinfo($swid,var) sw_var
	set cheeruns [winfo children $wn]
	set pathval ""
	#an_cmd store file=junkvars
	foreach child $cheeruns {
		# If it has a label
		if {[winfo exists $child.lab]} {
			# and it is a path field.
			# puts "Getting text for $child.lab"
			if {[$child.lab cget -text]=="path"} {
				set pathval $sw_var($wn.[winfo name $child]) 
				break
			}	
		}
	}	
	# puts "pathval=$pathval"
	if {$pathval!=""} {
		set pathval [string trimright $pathval "/"]
		append pathval "/"
	}
        # mcnair - changed to cut (rel) from filename
        set name "$pathval$sw_var($wn.$pn)"
        regsub {\(rel\)} $name "" name
	return  $name
}

proc get_list_val {list name} {
	set matchpos [lsearch $list "$name *"]
	if {$matchpos>=0} {
		set matchitem [lindex $list $matchpos]
		return [lindex $matchitem 1]	
	} else {
		return ""
	}
}

proc sw_save_script {scriptfile scriptname text} {

   set filename [tempfilename sw[pid]]
   set fh [open $filename w]
   puts $fh $text
   close $fh
 
   set warnings [exec chkscr $filename]

   global tcl_version
   if { $tcl_version == "7.4" } {
      exec rm $filename
   } else {
      file delete -force $filename
   }
 
   if {$warnings != ""} {
      regsub $filename $warnings "" warnings
      set rc [tk_dialog .warning Warning $warnings \
                             warning 0 "Save Anyway" "Cancel Changes" \
			     "Return to Edit"]
      if {$rc==2} {
	return -1
      } elseif {$rc==1} {
	return 0
      } 

      
   }
   push_script2 $scriptfile $scriptname $text
   return 0
}
