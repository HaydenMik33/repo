
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: ctsrv.tcl,v 1.16 2002/01/18 16:27:28 karl Exp $
# $Log: ctsrv.tcl,v $
# Revision 1.16  2002/01/18 16:27:28  karl
# Increased height allowed for text by one pixel.
# Added code to restrict template field data length as does Ctsrv.
# Added check for window already displayed.
# Added initialization of template data structure to avoid concurrent access conflicts.
# upper and lower fixed to support string expressions.
# Fixed to handle field names containing periods.
# Fixed to allow hotkey abort even if missing required fields.
# Fixed to support global hotkeys.
# Fixed problem with leftover data from previous windows.
#
# Revision 1.15  2001/05/17 19:07:24  karl
# Fixed bug that could cause field data to hang around from previous
# displays of a showwindow window.
#
# Revision 1.14  2001/03/22 20:25:15  karl
# Fixed bug that caused TK t_disp to not display templates
# Fixed a bug in showmenu that created corrupt menu
# windows if the number of selections was not evenly
# divisible by the number of columns.
#
# Revision 1.13  2000/12/14 22:52:22  karl
# Added load of antkdialog.tcl.  Fixed main window to not be closable
# with the window manager.
#
# Revision 1.12  2000/11/02 23:05:42  karl
# Fixed windows and menus to treat window close as a "Cancel".
# Fixed a file handle leak at every call to t_disp that used "infile".
#
# Revision 1.11  2000/09/14 23:03:18  karl
# Moved visibility binding setup out to separate proc.
#
# Revision 1.10  2000/09/11  21:34:11  karl
# Changed background from gaudy blue to gray.
# Added sw_toplevels=ON DV to force showwindow windows to be created
# as separate toplevel windows instead of frames placed in the main win.
# Added the sw_center=ON DV option to cause toplevel showwindow windows
# to be centered in the main window.  Added ct_keymap functionality
# to allow user to define more Ctsrv-to-Tk bind mappings.
# Added "publish" capability to hotkeys to emulate the same in Ctsrv.
# Fixed auxillary toplevels to stay on top of main screen.  Fixed
# reply data parms to be sorted.  Added "skip_auto_pages" to t_disp
# to allow template pages marked am=A to not be displayed.
# Added Shift-Tab to field traversals.  Added Up and Down keys as well.
#
# Revision 1.9  2000/08/14  21:36:46  karl
# Added "emulate_ims_keys" option to t_disp.
#
# Revision 1.8  2000/08/11  17:26:39  karl
# Fixed problems related to hotkey behavior, including the "return"
# option, in showmenu and t_disp.
#
# Revision 1.7  2000/08/08  20:48:52  karl
# Fixed showmenu and t_disp data to be properly quoted.
#
# Revision 1.6  2000/07/13  15:21:50  karl
# Fixed a bug where new template revisions would not be used, because
# templates were stored in DVs by id alone and not rev.
#
# Revision 1.5  2000/07/07  21:03:30  karl
# Made main window optional or creatable by developer.
# Initialized fonts and and character sizes.
# Made restricted size entry fields restrict data size.
# Separated showwindow code so showwindow commands can be intercepted
# and preprocessed (MIHO OI).
# Added strexing of color, bcolor, and box window attributes.
# Added code to convert Ctsrv color names into TK color names.
# Made hotkey buttons optional.
# Fixed bug in floating point type checking.
# changed an_clear to an_clearstdout.
# Added hotkeys, infile, in_tag, outfile, and out_tag to t_disp.
# Added ability to place templates in arbitrary locations.
#
# Added t_update command.
# Added t_hide command.
#
# Revision 1.4  1998/07/21  21:05:39  karl
# Fixed "hits" variable stack trace bug.
# Fixed an_msgsend stack trace bug.
# Fixed growth bug caused by old data scrolling out of a field in "print".
# Fixed growth bug cause by leftover window array data.
#
# Revision 1.3  1997/12/05  17:11:53  karl
# Fixed !="" integer errors.
#
# Revision 1.2  1997/11/03  19:16:48  karl
# Added simple an_strex so Ctsrv commands will work in wishsrv/tcltksrv that
# don't contain an an_strex C command.
#
# Revision 1.1  1997/10/30  22:14:19  karl
# Initial revision
#

source $env(TK_LIBRARY)/dialog.tcl
source $env(ASTK_DIR)/antkdialog.tcl

set ct_keymap(^\[) "Escape"

if {![info exists wincnt]} {
	set wincnt 0
}

proc ct_restore {filename} {
	set fid [open $filename  r]
	if {$fid!=""} {
		dv_restore $fid
		close $fid
	}
}

# Find out how big a character is.
text .dummy
set inputfont [.dummy cget -font]
set font $inputfont
#set inputfont -*-fixed-*-*-*--*-140-*-*-*-*-*-*
#set font -*-fixed-*-*-*--*-140-*-*-*-*-*-*
set charheight [expr [font metrics $font -linespace] + 4]
set charwidth [expr [font measure $font m]+1]
destroy .dummy
option add *Entry.font $font
option add *Label.font $font
option add *Button.font $font
option add *Radiobutton.font $font
option add *Checkbutton.font $font

proc ct_createmain {} {
	global charwidth charheight env
	image create photo logoimg -file $env(ASTK_DIR)/asembgr.gif
	# Create main window (this should be optional)
	set ct_mainname [dv_get ct_mainname]
	if {$ct_mainname==""} {
		set ct_mainname .screen
	} 
	frame $ct_mainname -width [expr $charwidth*80] \
		-height [expr $charheight*25] \
		-background #B2B2B2
	pack $ct_mainname -fill both -expand 1
	update idletasks
	wm minsize . [winfo reqwidth .] [winfo reqheight .]
	label $ct_mainname.logo -image logoimg -anchor center -background #B2B2B2
	pack $ct_mainname.logo -expand 1 -fill both 
	update idletasks
	#bind . <FocusIn> { foreach child [winfo children .] { raise $child } }
	#bind . <Visibility> { 
	#	if {"%W"=="." && "%s"=="VisibilityUnobscured"} {
	#	foreach child [winfo children .] { 
	#		raise $child 
	#	} 
	#	}
	#}
	wm deiconify .
	wm protocol . WM_DELETE_WINDOW return
	update idletasks
}

proc td_restrict_var_len {maxlen name1 name2 op} {
	global $name1
	global tk_version
	eval set newval \$$name1\($name2\)
	set len [string length $newval]
	set currfld [focus]
	set pos [$currfld index insert]
	#puts "checking if $name1 field $currfld, currently $len, pos $pos,  exceeds $maxlen"
	if {$len>$maxlen} {
		set trimmedval [string range $newval 0 [expr $maxlen - 1]]
		#puts "	trimming $name1\($name2\) to $trimmedval"
		eval set $name1\($name2\) $trimmedval
		#puts "	trimmed"
	}
	if {$pos==$maxlen} {
		#puts "	tabbing"
		if {$tk_version >= 8.4} {
			tk::unsupported::ExposePrivateCommand tkTabToWindow
		}
		tkTabToWindow [tk_focusNext [focus]]
	}
}

proc restrict_var_len {maxlen name1 name2 op} {
	global $name1
	eval set newval \$$name1\($name2\)
	set len [string length $newval]
	if {$len>$maxlen} {
		bell
		set trimmed [string range $newval 0 [expr $len-2]]
		set $name1\($name2\) $trimmed
	}
}

set showwindow_code {
	# Store extra args in DVS
	set inputparms [info vars]
	foreach tag {window currenv an_form anparms do} {
		set pos [lsearch $inputparms $tag]
		if {$pos>=0} {
			set inputparms [lreplace $inputparms $pos $pos]
		}
	}

	global wincnt font inputfont charheight charwidth windata
	set windowname [file tail $window]
	foreach el [array names windata] {
		#puts "Checking $windata($el) against $windowname"
		if {$windata($el)==$windowname} {
			an_return $currenv 1
			return 0
		}
	}
	set ct_mainname [dv_get ct_mainname]
	if {$ct_mainname==""} {
		set ct_mainname .screen
	} 
	set winid $ct_mainname.win$wincnt
	incr wincnt
	# Keep track of whether this window has any input fields.
	set inputwin false

	set dwdir [dv_get dwdir]
	#puts "dwdir=$dwdir"
	if {[string first {/} $window ]==-1 && $dwdir!=""} {
		set dwdir "$dwdir/"
	} else {
		set dwdir ""
	}
	#puts "dwdir=$dwdir"
	# Load the window DV file if it is not already in memory.
	if {[dv_getptr >sys>dw>$window]==""} {
		set fid [open ${dwdir}$window r]
		if {$fid==""} {
			tk_dialog .tmp Error \
				"Error: Window file $window not found!" \
				error 0 OK
			return 1
		}
		set tmpptr [dv_set sys>dw]
		#puts "restoring $window...."
		dv_restore -root $tmpptr $fid
		close $fid
	}
#set fid [open junkdvs w]
#dv_store $fid
#close $fid
	set winnmptr [dv_getptr sys>dw>$windowname]
	dv_setval $winnmptr $winid
	set winnm [dv_getname -root $winnmptr]

	dv_delete sys>$winnm
	foreach parm $inputparms {
		#puts "initializing $parm"
		if {[array exists $parm]} {
			foreach el [array names $parm] {
				regsub {\.} $el {.} el
				#puts "  initializing ${parm}.$el"
				eval dv_set sys>$winnm>${parm}>$el \
					\$${parm}($el)
			}
		} else {
			eval dv_set sys>$winnm>$parm \$$parm
		}
	}

	set windata($winid,name) $winnm
	set windata($winid,currenv) $currenv
	#puts "doing winnm=$winnm"
	set title [dv_get -root $winnmptr title]
	set hotkeys [string trim [dv_get -root $winnmptr hotkeys] |]|[dv_get hotkeys]
	set lines [dv_get -root $winnmptr lines]
	set cols [dv_get -root $winnmptr cols]
	set doublebox [sw_fixcolor [dv_get -root $winnmptr doublebox]]
	set X [dv_get -root $winnmptr X]
	set Y [dv_get -root $winnmptr Y]
	set color [dv_get -root $winnmptr color]
	set bcolor [dv_get -root $winnmptr bcolor]
	set box [dv_get -root $winnmptr box]
	set tcolor [dv_get -root $winnmptr tcolor]
	if {[string first "(" $bcolor]>=0} {
		set bcolor [an_strex $bcolor]
	}
	if {[string first "(" $color]>=0} {
		set color [an_strex $color]
	}
	if {[string first "(" $box]>=0} {
		set box [an_strex $box]
	}
	if {[string first "(" $tcolor]>=0} {
		set box [an_strex $tcolor]
	}
	if {$bcolor==""} {
		set bcolor blue
	}
	if {$tcolor==""} {
		set tcolor white
	}
	if {$box==""} {
		set box white
	}
	set color [sw_fixcolor $color]
	set bcolor [sw_fixcolor $bcolor]
	set tcolor [sw_fixcolor $tcolor]
	set box [sw_fixcolor $box]
	set winheight [expr $charheight*$lines]
	set winwidth [expr $charwidth*$cols]
	if {$doublebox!=""} {
		set box $doublebox
	}

	set fldcnt 0
	set boxptrs [dv_getgbs -root $winnmptr *box]
	#puts "boxptrs=$boxptrs"
	set rootx [winfo rootx [winfo toplevel $ct_mainname]]
	set rooty [winfo rooty [winfo toplevel $ct_mainname]]
	set sw_toplevels [dv_get sw_toplevels]
	set sw_center [dv_get sw_center]
	if {[lsearch "on ON On yes YES Yes 1 true TRUE True" \
			$sw_toplevels]>=0} {
		toplevel $winid -width [expr $winwidth+4] \
			-height [expr $winheight+4] \
			-background $bcolor
		wm title $winid $winnm
		wm protocol $winid WM_DELETE_WINDOW {return}
		an_keep_on_top $winid
		#wm transient $winid
		if {$title!=""} {
			wm title $winid [string trim $title ~]
		}
	} else {
		if {$boxptrs!=""} {
			frame $winid -width [expr $winwidth+4] \
				-height [expr $winheight+4] \
				-background $bcolor -relief raised \
				-borderwidth 2
			place $winid -x [expr $charwidth*$X] \
				-y [expr $charheight*$Y]
		} else {
			frame $winid -width $winwidth -height $winheight \
				-borderwidth 0 -background $bcolor
			#wm overrideredirect $winid 1
			place $winid -x [expr $charwidth*$X] \
				-y [expr $charheight*$Y]
		}
	}
	if {$box!=""} {
		set boxwid 2
		frame $winid.box1 -width [expr $winwidth-8] \
			-height [expr $winheight-8] \
			-background $bcolor -borderwidth 3 -relief ridge
		place $winid.box1 -x 4 -y 4
	}
	set indentstr ""
	regexp {^[~]+} $title indentstr
	set titleindent [string length $indentstr]
	#puts "title=$title indentstr=$indentstr titleindent=$titleindent"
	if {$title!=""} {
		label $winid.title -text [string trim $title ~] \
			-background $bcolor -foreground $tcolor \
			-relief ridge -borderwidth 2 -pady 0 -padx 0
		place $winid.title -x [expr $titleindent*$charwidth] -y 0
	}
	set fieldptrs [dv_getgbs -root $winnmptr fields>*]

	foreach fieldptr $fieldptrs {
		set fldnm [dv_getname -root $fieldptr]
		#puts "doing fldnm=$fldnm"
		flush stdout
		set fldX [dv_get -root $fieldptr X]
		set fldY [dv_get -root $fieldptr Y]
		set fldXpos [expr $fldX * $charwidth]
		set fldYpos [expr $fldY * $charheight]
		set flddata [dv_get -root $fieldptr data]
		#puts "flddata=$flddata"
		set fldlines [dv_get -root $fieldptr lines]
		set inputflag [dv_getptr -root $fieldptr input]
		set selectionflag [dv_getptr -root $fieldptr selection]
		set outputflag [dv_getptr -root $fieldptr output]
		#set tokenixedflag [dv_getptr -root $fieldptr tokenized]
		set constantflag [dv_getptr -root $fieldptr constant]
		set hiddenflag [dv_getptr -root $fieldptr hidden]
		#set lineflag [dv_getptr -root $fieldptr line]
		#set doublelineflag [dv_getptr -root $fieldptr doubleline]
		#set protectedflag [dv_getptr -root $fieldptr protected]
		#set boxflag [dv_getptr -root $fieldptr box]
		#set doubleboxflag [dv_getptr -root $fieldptr doublebox]
		set scrollflag [dv_getptr -root $fieldptr scroll]
		#puts "fieldptr=$fieldptr"
		if {$fldlines==""} {
			set fldlines 1
		}
		set fldcols [dv_get -root $fieldptr cols]
		if {$fldcols==""} {
			if {[string compare $flddata ""]} {
				set fldcols [string length $flddata]
			} else {
				set fldcols 1
			}
		}
		set fldcolor [dv_get -root $fieldptr color]
		if {[string first "(" $fldcolor]>=0} {
			set fldcolor [an_strex $fldcolor]
		}
		if {$fldcolor==""} {
			set fldcolor $color
		}
		set fldcolor [sw_fixcolor $fldcolor]
		set fldbcolor [dv_get -root $fieldptr bcolor]
		if {[string first "(" $fldbcolor]>=0} {
			set fldbcolor [an_strex $fldbcolor]
		}
		if {$fldbcolor==""} {
			set fldbcolor $bcolor
		}
		set fldbcolor [sw_fixcolor $fldbcolor]
		set fldid $winid.f$fldcnt
		#puts "fldid=$fldid fldnm=$fldnm"
		dv_setval $fieldptr $fldid
		global winflds
		set winflds($fldid) $fldnm
		incr fldcnt
		# If this is on the bottom line and there is a border,
		# make it look like part of the border.
		if {$constantflag!="" && $fldY==[expr $lines-1] && $box!=""} {
			label $fldid \
				-text [string trim $flddata ~] \
				-font $font -background $bcolor \
				-foreground $box -relief ridge \
				-padx 0 -pady 0 \
				-borderwidth 2 -anchor nw -justify left
			place $fldid -x $fldXpos -y [expr $fldYpos-2]
		} elseif {$constantflag!=""} {
			label $fldid -text $flddata -width $fldcols \
				-height $fldlines -font $font -anchor nw \
				-justify left
			place $fldid -x $fldXpos -y $fldYpos
		} elseif {$inputflag!="" || $hiddenflag!=""} {
			if {[string compare $flddata  ""]} {
				if {[info commands an_strex]!=""} {
					set windata($fldid) [an_strex \
						$flddata]
				} else {
				if {[string index $flddata 0]=="("} {
					set windata($fldid) [dv_get \
						[string trim $flddata \
							" ()*"]]
		
				} else {
					set windata($fldid) $flddata		
				}
				}
			}
			entry $fldid -width $fldcols -font $inputfont \
				-highlightthickness 1 -borderwidth 1 \
				-textvariable windata\($fldid\)
			if {$hiddenflag!=""} {
				$fldid configure -show "*"
			}
			#puts "watching windata($fldid) to exceed $fldcols"
			trace variable windata($fldid) w "restrict_var_len $fldcols"
			bind $fldid <Return> "
				sw_sendreply $currenv $winid
			"
			if {$scrollflag==""} {
				bind $fldid <KeyPress> {
				set curval [%W get]
				if {[lsearch "BackSpace Delete 
					Left Right  Tab Down Up
					Return" %K]==-1 && \
					[string length $curval]>=\
						[%W cget -width]} {
					set nfld [tk_focusNext %W]
					focus $nfld
					#puts [winfo class $nfld]
					if {[winfo class $nfld]=="Entry"} {
						global tk_version
						if {$tk_version >= 8.4} {
							tk::unsupported::ExposePrivateCommand tkEntryInsert
						}
						tkEntryInsert $nfld %A
					}
					break
				}
				}
			}
				
			place $fldid -x $fldXpos -y $fldYpos
			if {$inputwin=="false"} {
				focus $fldid
			}
			set inputwin true
		} elseif {$outputflag!=""} {
			if {[string compare $flddata ""]} {
				if {[info commands an_strex]!=""} {
					#puts "using an_strex"
					set flddata [an_strex \
						$flddata]
				} else {
				#puts "not using an_strex"
				if {[string range $flddata 0 1]=="(*"} {
					set flddata [dv_get \
						[string trim $flddata \
							" ()*"]]
		
				} 
				}
			}
			label $fldid -text $flddata -width $fldcols \
				-height $fldlines -font $font -anchor nw \
				-borderwidth 2 -highlightthickness 0 \
				-relief groove -justify left

			place $fldid -x $fldXpos -y $fldYpos
			
		} else {
			continue
		}
		if {$fldbcolor!=""} {
			$fldid configure -background $fldbcolor \
				-highlightbackground $bcolor 
		}
		if {$fldcolor!=""} {
			$fldid configure -foreground $fldcolor
			if [winfo exists ${fldid}ul] {
				${fldid}ul configure -background $fldcolor
			}
		}
	}	
	if {[lsearch "on ON On yes YES Yes 1 true TRUE True" \
			$sw_toplevels]>=0} {
		if {[lsearch "on ON On yes YES Yes 1 true TRUE True" \
                        $sw_center]>=0} {
			set mainwid [winfo width [winfo toplevel $ct_mainname]]
			set mainht [winfo height [winfo toplevel $ct_mainname]]
			set swwid [winfo reqwidth $winid]
			set swht [winfo reqheight $winid]
			wm geometry $winid \
				+[expr $rootx+($mainwid/2-$swwid/2)]+[expr \
				$rooty+($mainht/2-$swht/2)]
		} else {
			wm geometry $winid \
				+[expr $rootx+($charwidth*$X)]+[expr \
				$rooty+($charheight*$Y)]
		}
	}
	#puts "hotkeys=$hotkeys \[dv_get buttonsifhotkeys\]=[dv_get buttonsifhotkeys]"
	# If there are hotkeys, assume it is an input window.
	if {$hotkeys!="" && [dv_get buttonsifhotkeys]=="true"} {
		set inputwin true
	}
	if {$inputwin=="true"} {
		set buttwin [sw_makebuttons $winid $inputwin $currenv \
			$hotkeys sw_sendreply sw_senddata $bcolor]
		if {[winfo children $buttwin]!=""} {
			$winid configure -height [expr $winheight+($charheight*1.5)]
			place $winid.buttons -relwidth 1 -x 0 -y [expr $charheight*$lines]
		}
	}
		
}

an_proc showwindow {showwindow window=%s} {
Works just like showwindow in Ctsrv.  For more information, refer to the
Ctsrv document. Supported options are:

Windows:
	- dwdir DV
	- title, ~ indent
	- hotkeys 
	- box, doublebox
	- color
	- bcolor
	- If there are input fields or hotkeys, the window is assumed to
	  be an input window and will have an OK button (same as send key).
	  If the hotkeys contain a ^[, there will also be an ESCAPE button.
	  All other hotkeys will create a button to match the hotkey.

Fields:
	- data
	- input, output, constant
	- scroll
	- color
	- bcolor 
	- type
	- upper
	- lower
	- regexp
	- required

Other options will be added as needed.
} {
{0 Success}
{1 "Window already shown or file not found"}} {
	global showwindow_code
	uplevel 1 [eval $showwindow_code]
}



proc sw_makebuttons {winid inputwin currenv hotkeys replymsgcmd datamsgcmd
		bcolor} {
	global charheight charwidth
	frame $winid.buttons -height [expr $charheight*1.5] 
	if {$bcolor!=""} {
		$winid.buttons configure -background $bcolor
		$winid.buttons configure -highlightbackground $bcolor
	}
	if {$inputwin=="true"} {
		button $winid.buttons.ok -text "OK" \
			-pady 0 \
			-command "$replymsgcmd $currenv $winid"
		if {$bcolor!=""} {
			$winid.buttons.ok configure -background $bcolor
			$winid.buttons.ok configure -highlightbackground $bcolor
		}
		#puts "doing bindings for $winid"
		bind $winid <Return> "$winid.buttons.ok invoke; break"
		bind $winid.buttons.ok <Return> "$winid.buttons.ok invoke; break"
		bind $winid <Down> {focus [tk_focusNext %W]}
		bind $winid <Up> {focus [tk_focusPrev %W]}
		pack $winid.buttons.ok -side left -expand 1 -padx 20
	}
	if {$hotkeys!=""} {
		#puts "hotkeys=$hotkeys"
		set hkcnt 1
		foreach hotkey [split [string trim $hotkeys |] |] {
			set key [string range $hotkey 0 0]
			if {$key=="^"} {
				set key [string range $hotkey 0 1]
				set hkstring [string range $hotkey 2 end]
			} else {
				set hkstring [string range $hotkey 1 end]
			}
			#puts "key=$key hkstring=$hkstring"
			#switch $key {
			#	{^[} -
			#	{} {
			#		set key Escape
			#	}
			#}	
			global ct_keymap
			if {[info exists ct_keymap($key)]} {
				set keylist $ct_keymap($key)
				set key [lindex $keylist 0]
				if {[llength $keylist]>1} {
					set keytext [lindex $keylist 1]
				} else {
					set keytext $key
				}
			} else {
				set keytext $key
			}
	
			if {[string match "* return" $hkstring]} {
				button $winid.buttons.hk$hkcnt -text $keytext \
					-pady 0 \
					-command "$replymsgcmd $currenv $winid {$hkstring}"
			} else {
				button $winid.buttons.hk$hkcnt -text $keytext \
					-pady 0 \
					-command "$datamsgcmd $currenv $winid {$hkstring}"
			}
			bind $winid.buttons.hk$hkcnt <Return> \
				"$winid.buttons.hk$hkcnt invoke"
			if {[string length $key]>1} {
				set key <$key>
			} 
			bind [winfo toplevel $winid] $key \
				"$winid.buttons.hk$hkcnt invoke"
			if {$bcolor!=""} {
				$winid.buttons.hk$hkcnt configure -background $bcolor
				$winid.buttons.hk$hkcnt configure -highlightbackground $bcolor
			}
			pack $winid.buttons.hk$hkcnt -side left -expand 1 \
				-padx 20
			incr hkcnt
			
		}
	}
	if {[focus]=="."} {
		focus $winid
	}
	return $winid.buttons
}

proc sw_getwindata {winid} {
	set data ""
	global windata winflds
#set fid [open junkdvs w]
#dv_store $fid
#close $fid
	set winnm $windata($winid,name)
	#puts "winnm=$winnm"
	foreach field [lsort [array names windata $winid.*]] {
		#puts "field=$field"
		set fldnm $winflds($field)
		#puts "fldnm=$fldnm"
		#puts "set fieldptr \[dv_getptr sys>dw>$winnm>fields>$fldnm\]	"
		set fieldptr [dv_getptr sys>dw>$winnm>fields>$fldnm]	
		set fldtype [dv_get -root $fieldptr type]
		set fldupper [an_strex [dv_get -root $fieldptr upper]]
		set fldlower [an_strex [dv_get -root $fieldptr lower]]
		set fldregexp [dv_get -root $fieldptr regexp]
		set requiredflag [dv_getptr -root $fieldptr required]
		#puts "fldnm=$fldnm fieldptr=$fieldptr requiredflag=$requiredflag fldregexp=$fldregexp"
		if {$requiredflag!="" && \
			(![info exists windata($field)] || \
				$windata($field)=="")} {
			return -code error "$fldnm is required."
		}	
		if {$fldregexp!="" && [string first "\{" $fldregexp]==-1 \
				&& [info exists windata($field)] &&
			$windata($field)!=""} {
			if {[regexp "$fldregexp" $windata($field)]==0} {
				return -code error "$fldnm must match $fldregexp."
			}
		}
		if {$fldlower!="" && [info exists windata($field)] &&
			$windata($field)!="" &&
			$windata($field)<$fldlower} {
			return -code error "$fldnm must be $fldlower or higher."
		}
		if {$fldupper!="" && [info exists windata($field)] &&
			$windata($field)!="" &&
			$windata($field)>$fldupper} {
			return -code error "$fldnm must be $fldupper or lower."
		}
		if {$fldtype!="" && [info exists windata($field)] &&
			$windata($field)!="" } {
			switch $fldtype {
			"d" {
				if {![regexp {^(|[+-])[0-9]+$} \
					$windata($field)]} {
					return -code error \
						"$fldnm must be integer"
				}
			}
			"f" {
				if {![regexp {^(|[+-])[0-9]*(|(\.[0-9]+))(|([eE][+-][0-9]+))$} \
					$windata($field)]} {
					return -code error \
						"$fldnm must be float"
				}
			}			
			}
		}
		if {[string compare $windata($field) ""]} {
			if {[llength [split $windata($field)]]>1} {
				append data "$fldnm=\"$windata($field)\" "
			} else {
				append data "$fldnm=$windata($field) "
			}
		}
	}
	return $data
}

proc sw_sendreply {currenv winid {hkstring {}}} {
	global ct_sendflag
	if {$ct_sendflag==0} {
		return
	}
	set rc [catch "sw_getwindata $winid" rs]
	if {$rc!=0 && [string length $hkstring]==0} {
		tk_dialog .tmp ERROR! $rs error 0 OK
	} else {
		if {$rc!=0} {
			set rs ""
		}
		catch {
		an_clearstdout $currenv
		an_write $currenv "$rs $hkstring"
		an_return $currenv 0
		destroy $winid
		global winflds windata
		foreach el [array names winflds "$winid.*"] {
			#puts "deleting winflds($el)"
			unset winflds($el)
		}
		foreach el [array names windata "$winid,*"] {
			#puts "deleting windata($el)"
			unset windata($el)
		}
		}
	}
}

proc sw_senddata {currenv winid hkstring} {
	global windata winflds
	#puts "hkstring=$hkstring"
	set winnm $windata($winid,name)
	set focus [focus]
	#puts "focus=$focus winid=$winid sm=[string match "$winid*" $focus]"
	if {$focus!="" && [string match "$winid.*" $focus] && \
		![string match "$winid.buttons.*" $focus]} {
		set fldinfo "field=$winflds($focus)"
	} else {
		set fldinfo ""
	}
	an_clearstdout $currenv
	if {[lsearch [split $hkstring " "] publish]>=0} {
		dv_delete >sys>msg
		foreach el [an_msg_to_tcl "window=$winnm $fldinfo $hkstring"] {
			an_cmd add_dataid [lindex $el 0]
			if {[llength $el]>1} {
				dv_set >sys>msg>[lindex $el 0] [lindex $el 1]
			} else {
				dv_set >sys>msg>[lindex $el 0]
			}
		}
		an_cmd publish 
	}
	an_write $currenv "window=$winnm $fldinfo $hkstring"
	an_senddata $currenv 
	if {[lsearch [split $hkstring] return]>=0} {
		destroy $winid
		global winflds windata
		foreach el [array names winflds "$winid.*"] {
			unset winflds($el)
		}
		foreach el [array names windata "$winid,*"] {
			unset windata($el)
		}
	}
}

proc sw_fixcolor {ctsrvcolor} {
	if {$ctsrvcolor!=""} {
		# If it is a DV reference
		if {[string range $ctsrvcolor 0 1]=="(*"} {
			set dvpath [string trim $ctsrvcolor "(* 	)"]
			#puts "dvpath=$dvpath"
			set ctsrvcolor [dv_get $dvpath]
		}
		# Now see if it is a DOSANSI-style color name
		switch $ctsrvcolor {
			hicyan { return lightcyan }
			hiblack { return gray }
			hibrown { return yellow }
			hiwhite { return white }
			white { return lightgray }
			default {
				return $ctsrvcolor
			}
		}
	}
	return $ctsrvcolor
}

proc sw_puttext {fldid text} {
	set fldwidth [$fldid cget -width]
	set fldheight [$fldid cget -height]
	set whilecount 0
	while {[string compare $text ""]} {
		incr whilecount
		if {$whilecount>100} {
			an_cmd lg name=error msg="aborted spinning while loop"
			puts "aborted spinning while loop"
			break
		}
		#puts "text='$text'"
		# Get existing text
		set oldtext [$fldid cget -text]
		#puts "oldtext=$oldtext"
		# Figure out width of text
		set lines [split $oldtext "\n"]
		#puts "lines='$lines'"
		if {[llength $lines]==0} {
			set chunksize $fldwidth
		} else {
			set lastline [lindex $lines [expr [llength $lines]-1]]
			set lastlinelen [string length $lastline]
			if {$lastlinelen==$fldwidth} {
				set chunksize $fldwidth
			} else {
				set chunksize [expr $fldwidth-$lastlinelen]
			}
		}
		#puts "chunksize=$chunksize"
		set chunk [string range $text 0 [expr $chunksize-1]]
		append oldtext $chunk
		if {$chunksize>=[string length $text]} {
			set text ""
		} else {
			set text [string range $text $chunksize end]
		}
		if {[string compare $text ""]} {
			append oldtext "\n"
		}
		set linelist [split $oldtext "\n"]
		set linecount [llength $linelist]
		if {$linecount>$fldheight} {
			set oldtext [join [lrange $linelist \
				[expr $linecount-1-$fldheight] \
				[expr $linecount-1]] "\n"]
		}
		$fldid configure -text $oldtext
	}
}

set printcode {
	set winid [dv_get sys>dw>$window]	
	if {$do=="print"} {
		set tmp $field
		unset field
		set field(1) $tmp
		if [info exists data] {
			set tmp $data
			unset data
			set data(1) $tmp
		}
		if [info exists clear] {
			set tmp $clear
			unset clear
			set clear(1) $tmp
		}
	}
	#puts "printing into fields: [array names field]"
	foreach fld [array names field] {
		set fldid [dv_get sys>dw>$window>fields>$field($fld)]
		if {$fldid==""} {
			continue
		}
		if {[info exists clearall] || [info exists clear($fld)]} {
			#puts "clearing $fld"
			$fldid configure -text ""
		}
		#puts "fldid=$fldid fldnm=$field($fld)"
		if {$fldid==""} {
			continue
		}
		set prevtext [$fldid cget -text]
		if [info exists data($fld)] {
			#sw_puttext $fldid $prevtext$data($fld)
			sw_puttext $fldid $data($fld)
			#$fldid configure -text "$prevtext$data($fld)"
		}
	}
	an_return $currenv 0
}

an_proc multprint {multprint [field.<enum>=%s] [data.<enum>=%s]
                 [{clearall,clear.<enum>}]
                  window=%s [color=%s] [bcolor=%s]
                 } {
Same as Ctsrv's multprint command.  See syntax string for supported options.
} {
{0 Success}
{1 "Window not found"}
{2 WARNING} 
} $printcode

an_proc print { print field=%s window=%s [data=%s] [clear]
               [color=%s] [bcolor=%s]
} {
Same as Ctsrv's print command.  See syntax string for supported options.
} {
{0 Success}
{1 "Window not found"}
{2 WARNING}
}  $printcode

an_proc showmenu {  showmenu name=%s {o0=%s [o1=%s [o2=%s....]], o.<enum>=%s}
                    X=%d Y=%d [lines=%d]
                    [columnar [cols=%d]] [color=%s] [bcolor=%s]
                    [selection]
                    [hotkeys=%s] [title=%s]
} {
Same as Ctsrv's showmenu command.  See syntax string for supported options.
Scrolling menus are not yet supported.  Default selections and quick-selection
keys are not yet supported.
} {
{0	Success}
{1	"w_show failed"}
} {
	global windata wincnt charwidth charheight
	#puts "Inside showmenu"
	if [info exists o0] {
		for {set n 0} {[info exists o$n]} {incr n} {
			eval set o($n) \$o$n
		}
	}
	if ![info exists lines] {
		set lines [array size o]
	}
	#puts "lines=$lines"
	if ![info exists cols] {
		set cols 1
	}
	if [info exists columnar] {
		set colsize [expr int([array size o] / $cols)]
		if {[expr [array size o] % $cols]} {
			incr colsize
		}
	} else {
		set colsize $lines
	}
	#puts "colsize=$colsize"
	set winid .win$wincnt
	set windata($winid,name) $name
        incr wincnt
	set rootx [winfo rootx .]
	set rooty [winfo rooty .]
	
	toplevel $winid  
	if [info exists bcolor] {
		$winid configure -background [sw_fixcolor $bcolor]
	}
	wm title $winid $name
	wm protocol $winid WM_DELETE_WINDOW {return}
	if {[info exists title]} {
		wm title $winid [string trim $title ~]
	}
	wm geometry $winid +[expr $rootx+($charwidth*$X)]+[expr \
		$rooty+($charheight*$Y)]

	frame $winid.opts 
	pack $winid.opts -side top
	for {set n 0} {$n<$cols} {incr n} {
		#puts "creating $winid.c$n"
		frame $winid.c$n 
		pack $winid.c$n -side left -expand 1 -fill both \
			-in $winid.opts
	}

	set colcnt 1
	set colnum 0
	if ![info exists hotkeys] { set hotkeys ""}
	#puts "[lsort -integer [array names o]]"
	foreach option [lsort -integer [array names o]] {
		#puts "doing $o($option)"
		set fldid $winid.c$colnum.b$colcnt
		if [info exists selection] {
			checkbutton $fldid -text $o($option) \
				-variable windata($fldid) \
				-onvalue $o($option) \
				-offvalue "" \
				-anchor w
				
		} else {
			#puts "setting windata($fldid)"
			set windata($fldid) ""
			button $fldid -text $o($option) -anchor w -command "
				global windata
				set windata($fldid) {$o($option)}
				sm_sendreply $currenv $winid {}
			"
	
		}		
		if [info exists bcolor] {
			$fldid configure -background [sw_fixcolor $bcolor]
			$fldid configure -highlightbackground [sw_fixcolor $bcolor]
		}
		if [info exists color] {
			$fldid configure -foreground [sw_fixcolor $color]
		}
		pack $fldid -side top -fill x 
		
		if {![info exists firstfield]} {
			set firstfield $fldid
		}
		incr colcnt
		if {$colcnt>$colsize} {
			incr colnum
			set colcnt 1
		}
		#puts "'$o($option)'"
	}
	if ![info exists bcolor] { set bcolor ""}
	if [info exists selection] {
		set buttwin [sw_makebuttons $winid true $currenv \
			$hotkeys sm_sendreply sm_senddata $bcolor]
		if {[winfo children $buttwin]!=""} {
			pack $buttwin -side bottom -fill x -expand 1
		}
	} else {
		set buttwin [sw_makebuttons $winid false $currenv \
			$hotkeys sm_sendreply sm_senddata $bcolor]
		if {[winfo children $buttwin]!=""} {
			pack $buttwin -side bottom -fill x -expand 1
		}
	}
	focus $firstfield
	tkwait visibility $winid
	#grab -global $winid
	an_keep_on_top $winid
}

proc sm_sendreply {currenv winid {hkstring {}}} {
	global windata
	global ct_sendflag
	if {$ct_sendflag==0} {
		return
	}
	#puts "winid=$winid"
	set winnm $windata($winid,name)
	set els [lsort -dictionary [array names windata $winid.*]]
	set optnum 0
	set hits {}
	#puts "els=$els"
	foreach el $els {
		if {$windata($el)!=""} {
			#puts "optnum=$optnum windata($el)={$windata($el)}"
			lappend hits "$optnum {$windata($el)}"
		}
		incr optnum
	}
	
	an_clearstdout $currenv
	an_write $currenv "menu=$winnm "
	set optcount [llength $hits]
	set elenum 0
	#puts "hits=$hits"
	foreach hit $hits {
		if {$optcount>1 || \
		    [dv_getname >sys>waiting>$currenv>selection]!=""} { 
			an_write $currenv "option.$elenum=[lindex $hit 0] "
			an_write $currenv "text.$elenum=\"[lindex $hit 1]\" "
			incr elenum
		} else {
			an_write $currenv "option=[lindex $hit 0] "
			an_write $currenv "text=\"[lindex $hit 1]\" "
		}
	}
	
	an_write $currenv "numopts=$optcount "
	if {[string length $hkstring]} {
		an_write $currenv "$hkstring"
	}
	an_return $currenv 0
	destroy $winid
	global winflds windata
	foreach el [array names winflds "$winid.*"] {
		unset winflds($el)
	}
	foreach el [array names windata "$winid,*"] {
		unset windata($el)
	}
}

proc sm_senddata {currenv winid hkstring} {
	global windata winflds
	set winnm $windata($winid,name)
	an_clearstdout $currenv
	an_write $currenv "menu=$winnm $hkstring"
	an_senddata $currenv 
}

an_proc w_hide {w_hide window=%s} {
Same as Ctsrv's w_hide command.
} {
{0 Success}
{1 "No such Window"}} {
	global windata
	#an_cmd store file=vars.jnk
	foreach el [array names windata *,name] {
		if {$windata($el)==$window} {
			set winid [lindex [split $el ,] 0]
			global ct_sendflag
			set tmp $ct_sendflag
			set ct_sendflag 1
			sw_sendreply $windata($winid,currenv) $winid 
			set ct_sendflag $tmp
		}
	}
	an_return $currenv 0
}

if {![info exists tplcnt]} {
	set tplcnt 0
}

an_proc t_disp {t_disp file=%s [id=%s rev=%s] 
	[parm.<id>.<occ>=%s]
	[lock.<id>.<occ>=0|1] [lockall]
	[nopage.<enum>=%d] 
	[hotkeys=%s]
	[infile=%s [in_tag=%s]] [outfile=%s [out_tag=%s]]
	[emulate_ims_keys]
	[skip_auto_pages]
} {
Same as Ctsrv's t_disp command.  See syntax string for supported options.
Many options are not yet supported.  Please report those that need to be
added.
} {
{0 Success}
{1 "Unable to load template"}
{5 "Unable to open infile"}
} {
	#puts "Inside t_disp"
	set dummy 123
	global max charwidth charheight value dtype len tplcnt font tpldata

	if {![info exists id]} {
		set id [file rootname [file tail $file]]
	}
	if {![info exists rev]} {
		set rev [file extension $file]
	}
	set tpldvptr [dv_getptr >template>$id>$rev]	
	if {$tpldvptr==""} {
		if {![file readable $file]} {
			an_return $currenv 1
			return
		}
		dv_set >template>$id>$rev ""
		set fid [ open $file r ]
		dv_restore >template>$id>$rev $fid
		close $fid
	}
	if [info exists value] {
		unset value
	}

	set bg black
	set pt cyan
	set ct white
	set ot green
	set rt pink
	set ct_mainname [dv_get ct_mainname]
	if {$ct_mainname==""} {
		set ct_mainname .screen
	} 
	set tplid $ct_mainname.tpl$tplcnt
	#puts "tplid=$tplid"
	set tpldata($tplid,name) $id
	set tpldata($tplid,rev) $rev
	if {[info exists outfile]} {
		set tpldata($tplid,outfile) $outfile
	} else {
		set tpldata($tplid,outfile) ""
	}
	if {[info exists out_tag]} {
		set tpldata($tplid,out_tag) $out_tag
	} else {
		set tpldata($tplid,out_tag) ""
	}
	if {[info exists infile]} {
		set tpldata($tplid,infile) $infile
	} else {
		set tpldata($tplid,infile) ""
	}
	if {[info exists in_tag]} {
		set tpldata($tplid,in_tag) $in_tag
	} else {
		set tpldata($tplid,in_tag) ""
	}
	set tpldata($tplid,currenv) $currenv
	incr tplcnt

        set rootx [winfo rootx [winfo toplevel $ct_mainname]]
        set rooty [winfo rooty [winfo toplevel $ct_mainname]]
        set td_toplevels [dv_get td_toplevels]
        set td_center [dv_get td_center]
        if {[lsearch "on ON On yes YES Yes 1 true TRUE True" \
                        $td_toplevels]>=0} {
                toplevel $tplid -width [expr 80*$charwidth] \
                        -height [expr 20*$charheight] \
                        -background black
                wm title $tplid "Data Collection Template - $id.$rev"
                wm protocol $tplid WM_DELETE_WINDOW {return}
                an_keep_on_top $tplid
        } else {
		frame $tplid -width [expr 80*$charwidth] \
			-height [expr 20*$charheight] \
			-background $bg 
		set rc [place $tplid -x 0 -y [expr 3*$charheight]]
		#puts "'place $tplid -x 0 -y [expr 3*$charheight]' returned $rc"
	}
	update idletasks
		frame $tplid.button_frame 

		button $tplid.prev_button -text "Previous"  -pady 0
		pack $tplid.prev_button -in $tplid.button_frame -side left

		button $tplid.next_button -text "Next" -pady 0
		pack $tplid.next_button -in $tplid.button_frame -side left 

		button $tplid.accept_button -text "OK" \
		  -pady 0 -command "td_sendreply $currenv $tplid"
		pack $tplid.accept_button -in $tplid.button_frame -side left

	if {[info exists hotkeys] && $hotkeys!=""} {
		#puts "hotkeys=$hotkeys"
		set hkcnt 1
		foreach hotkey [split [string trim $hotkeys |] |] {
			set key [string range $hotkey 0 0]
			if {$key=="^"} {
				set key [string range $hotkey 0 1]
				set hkstring [string range $hotkey 2 end]
			} else {
				set hkstring [string range $hotkey 1 end]
			}
#			switch $key {
#				{^[} -
#				{} {
#					set key Escape
#				}
#			}	
			global ct_keymap
			if {[info exists ct_keymap($key)]} {
				set keylist $ct_keymap($key)
				set key [lindex $keylist 0]
				if {[llength $keylist]>1} {
					set keytext [lindex $keylist 1]
				} else {
					set keytext $key
				}
			} else {
				set keytext $key
			}
			button $tplid.hk$hkcnt -text $keytext \
				-pady 0 \
				-command "td_senddata $currenv $tplid {$hkstring}"
			bind $tplid.hk$hkcnt <Return> "$tplid.hk$hkcnt invoke"
			if {[string length $key]>1} {
				set key <$key>
			}
			bind [winfo toplevel $tplid] $key \
				"$tplid.hk$hkcnt invoke"
			if {[info exists bcolor] && $bcolor!=""} {
				$tplid.hk$hkcnt configure -background $bcolor
				$tplid.hk$hkcnt configure -highlightbackground $bcolor
			}
			pack $tplid.hk$hkcnt -in $tplid.button_frame -side left -expand 1 \
				-padx 20
			incr hkcnt
			
		}
	}
#		button $tplid.cancel_button -text "Cancel" 
#		button $tplid.cancel_button -text "Cancel Logout" \
#		  -state disabled -pady 0
#		pack $tplid.cancel_button -in $tplid.button_frame -side left
		place $tplid.button_frame -relwidth 1 -relx 0.5 -rely 1 \
			-anchor s

	set page_list [dv_getgbs >template>$id>$rev>page.*]
	#set num_pages [llength $page_list]
	set tpldata($tplid,pageseq) {}
	
	foreach page_ptr $page_list {
		set page [dv_get -root $page_ptr page]
		set am [dv_get -root $page_ptr am]
		set skippage 0
		foreach el [array names nopage] {
			#puts "el=$el page=$page nopage($el)=$nopage($el)"
			if {$nopage($el)==$page} {
				set skippage 1
			}
		}
		if {$skippage || ([info exists skip_auto_pages] && $am=="A")} {
			continue
		}
		lappend tpldata($tplid,pageseq) $page
		frame $tplid.pg$page -width [expr 80 * $charwidth] \
			-height [expr 18 * $charheight] -bg $bg
		#place $tplid.pg$page -in $tplid -x 0 -y 0 
		set parmid_list [dv_getgbs -root $page_ptr parmid.*]
		foreach parmid_ptr $parmid_list {
			set parmnum [dv_get -root $parmid_ptr parmid]
			#puts "parmnum=$parmnum"
			if {[string index $parmnum 0]=="K"} {
				set tmp_parm $parmnum
			} else {
				set tmp_parm [format %04d $parmnum]
			}
			set len($parmnum) [dv_get -root $parmid_ptr len]
			set max($parmnum) [dv_get -root $parmid_ptr max]
			set req [dv_get -root $parmid_ptr req]
			set uom [dv_get -root $parmid_ptr uom]
			set cal [dv_get -root $parmid_ptr cal]
			set pos [dv_get -root $parmid_ptr pos]
			set dtype($parmnum) [dv_get -root $parmid_ptr dtype]
			set x [expr $pos % 80]
			set y [expr ($pos / 80 - 4) - 1]
			if {$uom == ""} {
				set tmp [dv_get -root $parmid_ptr parmdesc]
				set parmdesc "$tmp_parm $tmp : "
			} else {
				set tmp [dv_get -root $parmid_ptr parmdesc]
				set parmdesc "$tmp_parm $tmp ($uom): "
			}
			set parmdesc_len [string length $parmdesc]
			set parm_space [expr $len($parmnum)+2]
			label $tplid.parm_label($parmnum) -text "$parmdesc" \
				-font $font -bg $bg -fg $pt
			place $tplid.parm_label($parmnum) \
				-x [expr $x * $charwidth] \
				-y [expr $charheight * $y] \
				-in $tplid.pg$page
			
			set cy $y
			set cx [expr $x + $parmdesc_len]
			set box_x_max [expr $parm_space * ((80 - $cx) / \
				$parm_space)]
			#puts "parm_space=$parm_space box_x_max=$box_x_max cx=$cx cy=$cy"
			for {set i 0} {$i < $max($parmnum)} {incr i} {
				set tmp_pos [expr $i * $parm_space]
				if {$box_x_max} {
					set tmp_x [expr $tmp_pos % $box_x_max]
					set tmp_y [expr $tmp_pos / $box_x_max]
				} else {
					set tmp_x 0
					set tmp_y 0
				}
				set occ [expr $i + 1]
				set prmoccid $tplid.po${page}-${parmnum}-${occ}
				if {$cal == "T"} {
					entry $prmoccid \
					    -font $font -relief sunken \
					    -width $len($parmnum) \
					    -borderwidth 0 \
					    -highlightthickness 0 \
					    -bg $bg -fg $ct \
					    -state disabled
					set uc $ct
				} elseif {$occ <= $req} {
					entry $prmoccid \
					    -font $font -relief sunken \
					    -width $len($parmnum) \
					    -borderwidth 0 \
					    -highlightthickness 0 \
                                  	    -bg $bg -fg $rt
					set uc $rt
				} else {
					entry $prmoccid \
					    -font $font -relief sunken \
					    -width $len($parmnum) \
					    -borderwidth 0 \
					    -highlightthickness 0 \
                                  	    -bg $bg -fg $ot
					set uc $ot
				}
				if {$cal!="T" && ![info exists \
					tpldata($tplid,$page,firstfield)]} {
					set tpldata($tplid,$page,firstfield)\
						$prmoccid
				}
				$prmoccid \
					configure -textvariable	 \
					tpldata($prmoccid) \
					-insertbackground white
				set tpldata($prmoccid) ""
				#puts "watching tpldata($prmoccid) to exceed $len($parmnum)"
				trace variable tpldata($prmoccid) \
					w "td_restrict_var_len $len($parmnum)"
				if {[info exists emulate_ims_keys] || \
				    [dv_get emulate_ims_keys]!=""} {
					bind $prmoccid <Up> \
						"[bind all <Shift-Key-Tab>];break"
					bind $prmoccid <KP_Tab> \
						"[bind all <Shift-Key-Tab>];break"
					bind $prmoccid <KP_Enter> \
						"td_sendreply $currenv $tplid"
					bind $prmoccid <Return> \
						"[bind all <Key-Tab>]"
					bind $prmoccid <Down> \
						"[bind all <Key-Tab>]"
				} else {
					bind $prmoccid <Up> \
						"[bind all <Shift-Key-Tab>];break"
					bind $prmoccid <KP_Tab> \
						"[bind all <Shift-Key-Tab>];break"
					#puts "p2=[bind $prmoccid <Shift-Key-Tab>]"
					bind $prmoccid <Return> \
						"td_sendreply $currenv $tplid"
					bind $prmoccid <Down> \
						"[bind all <Key-Tab>]"
				}
			
				place $prmoccid \
					-x [expr ($cx + $tmp_x) * $charwidth]\
					-y [expr $charheight * ($cy+$tmp_y)]\
					-in $tplid.pg$page
				frame ${prmoccid}u \
					-width [winfo reqwidth \
					$prmoccid] \
					-height 1 -relief flat -bg $uc
				place ${prmoccid}u \
					-in $prmoccid \
					-relx 0.5 -rely 1.0 -anchor n \
					-bordermode outside
			}
		}
		set com_list [dv_getgbs -root $page_ptr com.*]
		foreach com_ptr $com_list {
			set text [dv_get -root $com_ptr text]
			set pos [dv_get -root $com_ptr pos]
			set x [\
				expr $pos % 80 + 1]
			set y [expr ($pos / 80 - 4) - 1]
			label $tplid.com_label($com_ptr) -text "$text" \
				-font $font \
				-bg $bg -fg $ct
			place $tplid.com_label($com_ptr) \
				-x [expr $x * $charwidth] \
				-y [expr $charheight * $y] -in $tplid.pg$page
		}
	}
	if {[info exists infile]} {
		set ifid [open $infile r]
		if {$ifid==""} {
			an_return $currenv 5
			return
		} else {
			dv_delete >tmp>t_disp
			set tmpgb [dv_set >tmp>t_disp]
			dv_restore -root $tmpgb $ifid 
			close $ifid
			set parmptr [dv_sublist -root $tmpgb parm]
			while {$parmptr!=""} {
				set occptr [dv_sublist -root $parmptr]
				set parmname [dv_getname -root $parmptr]
				while {$occptr!=""} {
					set occname [dv_getname -root $occptr]
					set occvalue [dv_get -root $occptr]
					set parm($parmname.$occname) $occvalue
					set occptr [dv_next -root $occptr]
				}
				set parmptr [dv_next -root $parmptr]
			}
		}
	}
	foreach inparm [array names parm] {
		set parmnm [lindex [split $inparm .] 0]
		set parmocc [string trimleft [lindex [split $inparm .] 1] 0]
		set parmpage [td_getpage $tplid $parmnm]
		unset tpldata($tplid.po${parmpage}-${parmnm}-${parmocc})
		set tpldata($tplid.po${parmpage}-${parmnm}-${parmocc}) \
			$parm($inparm)
	}
	if {[info exists lockall]} {
		foreach parmid [lsort [array names tpldata $tplid.*]] {
			#puts "locking $parmid"
			$parmid configure -state disabled
		}
	}
	if {[info exists unlock]} {
		foreach parmid [array names unlock] {
			set parmnm [lindex [split $parmid .] 0]
			set parmocc [string trimleft [lindex \
				[split $parmid .] 1] 0]
			set parmpage [td_getpage $tplid $parmnm]
			$tplid.po${parmpage}-${parmnm}-${parmocc} \
				configure -state normal		
		} 
	}
	if {[info exists lock]} {
		foreach parmid [array names lock] {
			set parmnm [lindex [split $parmid .] 0]
			set parmocc [string trimleft [lindex \
				[split $parmid .] 1] 0]
			set parmpage [td_getpage $tplid $parmnm]
			$tplid.po${parmpage}-${parmnm}-${parmocc} \
				configure -state disabled		
		} 
	}
        if {[lsearch "on ON On yes YES Yes 1 true TRUE True" \
                        $td_toplevels]>=0} {
                if {[lsearch "on ON On yes YES Yes 1 true TRUE True" \
                        $td_center]>=0} {
                        set mainwid [winfo width [winfo toplevel $ct_mainname]]
                        set mainht [winfo height [winfo toplevel $ct_mainname]]
                        set swwid [winfo reqwidth $tplid]
                        set swht [winfo reqheight $tplid]
                        wm geometry $tplid \
                                +[expr $rootx+($mainwid/2-$swwid/2)]+[expr \
                                $rooty+($mainht/2-$swht/2)]
                } else {
#                        wm geometry $tplid \
#                                +[expr $rootx+($charwidth*80/2)]+[expr \
#                                $rooty+($charheight*20/2)]
                }
		}


	flip_page $tplid current
#	set dumpfid [open dump.tv w]
#	set anames [array names tpldata]
#	foreach kjmidx $anames {
#		puts $fid "tpldata($kjmidx)=$tpldata($kjmidx)"
#	}
#	close $dumpfid
	#an_return $currenv 0
	#puts "leaving t_disp"
}

proc td_senddata {currenv tplid hkstring} {
	#puts "currenv=$currenv tplid=$tplid hkstring=$hkstring"
	#an_clearstdout $currenv
	global tpldata
	an_write $currenv $hkstring
	if {[string match "* return" $hkstring]} {
		an_return $currenv 0
		destroy $tplid
		foreach el [array names tpldata $tplid\[,.\]*] {
			unset tpldata($el)
		}	
	} else {
		an_senddata $currenv 
	}
	an_clearstdout $currenv
}


an_proc t_update {t_update id=%s rev=%s parm.<id>.<occ>=%s \
         [lock.<id>.<occ>=0|1]} {
Emulates the t_update command in Ctsrv, except that locked parms
and parm validation are not yet implemented.
} {
{0 Success}
{1 "Template not found"}
} {
	global tpldata
	#puts "Inside t_update"
	#puts "anparms=$anparms"
	set dumpfid [open dump1.tv w]
	set els [array names tpldata]
	#puts "els=$els"
	foreach index $els {
		#puts "tpldata($index)=$tpldata($index)"
		puts $fid "tpldata($index)=$tpldata($index)"
	}
	close $dumpfid
	global tpldata
	set tpnum ""
	foreach el [array names tpldata "*,name"] {
		#puts "el=$el"
		if {$tpldata($el)==$id} {
			#puts "tpnum=$tpnum"
			set tpnum [string range $el 10 end]
		}
	}
	if {$tpnum==""} {
		an_return $currenv 1
		return
	}
	set ct_mainname [dv_get ct_mainname]
	if {$ct_mainname==""} {
		set ct_mainname .screen
	} 
	foreach suffix [array names parm] {
		#puts "suffix=$suffix"
		set parmid [lindex [split $suffix .] 0]
		set parmocc [string trimleft [lindex [split $suffix .] 1] 0]
		set page [td_getpage $ct_mainname.tp$tpnum $parmid]
		unset tpldata($ct_mainname.tp$tpnum.po${page}-${parmid}-${parmocc})		
		set tpldata($ct_mainname.tp$tpnum.po${page}-${parmid}-${parmocc}) \
            $parm($suffix)
	
	}
	set dumpfid [open dump2.tv w]
	global tpldata
	set els [array names tpldata]
	foreach index $els {
		puts $fid "tpldata($index)=$tpldata($index)"
	}
	close $dumpfid
	an_return $currenv 0
}

an_proc tclvars {tclvars array=%s file=%s} \
{Dumps tcl vars to a file.} {{0 Success}} {
    set fid [open $file w]
    global $array
    set els [array names $array]
    foreach index $els {
        eval puts $fid "${array}\(\$index\)=\$${array}\(\$index\)"
    }
    close $fid
	an_return $currenv 0
}

proc td_sendreply {currenv tplid {forcereply 0}} {
	global tpldata
	global ct_sendflag
	if {$ct_sendflag==0} {
		return
	}
	set rc [catch "td_gettpldata $tplid $forcereply" rs]
	if {$rc!=0} {
		tk_dialog .tmp ERROR! $rs error 0 OK
		raise [winfo toplevel $tplid]
	} else {
		set outfile $tpldata($tplid,outfile)
		if {$outfile==""} {
			an_write $currenv $rs
		}
		an_return $currenv 0
		destroy $tplid
		foreach el [array names tpldata $tplid\[,.\]*] {
			unset tpldata($el)
		}	
	}
}

proc td_getpage {tplid parmname} {
	global tpldata
	set tplname $tpldata($tplid,name)
	set tplrev $tpldata($tplid,rev)
	set pgptr [dv_getptr >template>$tplname>$tplrev>page.1]
	while {$pgptr!="" && [set found [dv_getptr -root $pgptr \
		parmid.$parmname]]==""} {
		set pgptr [dv_next -root $pgptr]
	}
	if {$found==""} {
		return ""
	} else {
		return [lindex [split [dv_getname -root $pgptr] .] 1]
	}
}

proc td_gettpldata {tplid {forcereply 0}} {
	set rs ""
	global tpldata tplflds
#set fid [open junkdvs w]
#dv_store $fid
#close $fid
#an_cmd store file=junktcl
	set tplname $tpldata($tplid,name)
	set tplrev $tpldata($tplid,rev)
	set outfile $tpldata($tplid,outfile)
	set out_tag $tpldata($tplid,out_tag)
	if {$outfile!=""} {
		dv_delete >tmp>t_disp
		set gbptr [dv_set >tmp>t_disp>out]
	}
	set parmsdone {}
	foreach parm [lsort [array names tpldata $tplid.*]] {
		#puts "parm=$parm"
		set parmstr [string range [lindex [split $parm .] end] 2 end]
		set pagenum [lindex [split $parmstr -] 0]
		set parmnum [lindex [split $parmstr -] 1]
		set occnum [lindex [split $parmstr -] 2]
		set parmptr [dv_getptr \
			template>$tplname>$tplrev>page.$pagenum>parmid.$parmnum]	
		set reqnum [dv_get -root $parmptr req]
		set fldtype [dv_get -root $parmptr dtype]
		set fldlower [dv_get -root $parmptr lower]
		set fldupper [dv_get -root $parmptr upper]
		set fldcal [dv_get -root $parmptr cal]
		set attr [dv_get -root $parmptr attr]
		set data $tpldata($parm)
		#puts "tplid=$tplid tplname=$tplname parmstr=$parmstr "
		#puts "pagenum=$pagenum occnum=$occnum reqnum=$reqnum "
		#puts "fldtype=$fldtype attr=$attr "
		#puts "fldlower=$fldlower fldupper=$fldupper"
		if {$forcereply==0 && \
				$data=="" && $occnum<=$reqnum && $fldcal!="T"} {
			return -code error \
				"Parm $parmnum.$occnum is required."
		}	
		if {$forcereply==0 && \
				$fldtype!="" && [string compare $data ""] } {
			switch $fldtype {
			"I" {
				if {![regexp {^(|[+-])[0-9]+$} \
					$data]} {
					return -code error \
						"Parm $parmnum.$occnum must be integer"
				}
			}
			"F" {
				if {![regexp {^(|[+-])[0-9]*(|(\.[0-9]+))(|([eE][+-][0-9]+))$} \
					$data]} {
					return -code error \
						"Parm $parmnum.$occnum must be float"
				}
			}			
			}
		}
		if {$fldlower!=+0.0E+00 || $fldupper!=+0.0E+00} {
			set checkrange 1
		} else {
			set checkrange 0
		}
		if {$forcereply==0 && $checkrange &&
			[string compare $data ""] &&
			$data<$fldlower} {
			return -code error "Parm $parmnum.$occnum must be above $fldlower."
		}
		if {$forcereply==0 && $checkrange &&
			[string compare $data ""] &&
			$data>$fldupper} {
			return -code error "Parm $parmnum.$occnum must be below $fldupper."
		}
		if {[string compare $data ""]} {
			append rs "parm.$parmnum.[format %03d $occnum]=$data\n"
			append rs "parm.$parmnum.dtype=$fldtype\n"
			append rs "parm.$parmnum.attr=$attr\n"
			if {$outfile!=""} {
				if {[lsearch $parmsdone $parmnum]==-1} {
					dv_set -root $gbptr $parmnum>dtype $fldtype
					dv_set -root $gbptr $parmnum>attr $attr
					lappend parmsdone $parmnum
				}
				dv_set -root $gbptr $parmnum>[format %03d $occnum] $data
			}
		}
	}
	if {$outfile!=""} {
		set ofid [open $outfile w]
		if {$out_tag!=""} {
			set tmpname [dv_getname -root $gbptr]
			dv_setname $gbptr $out_tag
		}
		dv_store -root $gbptr $ofid
		if {$out_tag!=""} {
			dv_setname $gbptr $tmpname
		}
		close $ofid
	}
	return  $rs
}

proc flip_page {tplid dir} {
	global tpldata
	#puts "A tpldata($tplid,currpage)=$tpldata($tplid,currpage) tpldata($tplid,pageseq)=$tpldata($tplid,pageseq) dir=$dir"
	if {![info exists tpldata($tplid,currpage)]} {
		set tpldata($tplid,currpage) \
			 [lindex $tpldata($tplid,pageseq) 0]
	}
	set currpage $tpldata($tplid,currpage)
	set pageseq $tpldata($tplid,pageseq)
	#puts "B tpldata($tplid,currpage)=$tpldata($tplid,currpage) tpldata($tplid,pageseq)=$tpldata($tplid,pageseq) dir=$dir"

	if {$dir=="current" || \
	    ($dir=="next" && [lindex $pageseq end]==$currpage) || \
	    ($dir=="prev" && [lindex $pageseq 0]==$currpage)} {
		set newpage $currpage
	} elseif {$dir=="next"} {
		set newpage [lindex $pageseq \
			[expr [lsearch $pageseq $currpage] + 1]]
	} else {
		set newpage [lindex $pageseq \
			[expr [lsearch $pageseq $currpage] - 1]]
	}
	
	place forget $tplid.pg$currpage
	place $tplid.pg$newpage -in $tplid -x 0 -y 0 

	set tpldata($tplid,currpage) $newpage
	#puts "C tpldata($tplid,currpage)=$tpldata($tplid,currpage) tpldata($tplid,pageseq)=$tpldata($tplid,pageseq) dir=$dir"

	$tplid.next_button configure -state disabled
	$tplid.prev_button configure -state disabled

	if {$newpage!=[lindex $pageseq end]} {
		$tplid.next_button configure \
		  -command "flip_page $tplid next" \
		  -state normal
	}
	if {$newpage!=[lindex $pageseq 0]} {
		$tplid.prev_button configure \
		  -command "flip_page $tplid prev" \
		  -state normal
	}
	if {[info exists tpldata($tplid,$newpage,firstfield)]} {
		focus $tpldata($tplid,$newpage,firstfield)
	}
}

proc cancel_template {currenv tplid} {

	$tplid.accept_button configure -state disabled
	$tplid.cancel_button configure -state diSABLED

	an_return $currenv 1
}

proc accept_template {currenv id tplid} {
	
	global value
	global dtype
	global len
	global max
	global tpldata

	$tplid.accept_button configure -state disabled
	$tplid.cancel_button configure -state disabled

	# WARNING:  Below regular expressions most likely need some work!
	set pattern(A) {^.+$}
	set pattern(I) {^-?[0-9]+$}
	set pattern(S) {^.+$}
	set pattern(F) {^-?[0-9]*\.[0-9]*$|^-?[0-9]+$}
	set pattern(M) {^.+$}

	set tplrev $tpldata($tplid,rev)
	set parmid_list [dv_getgbs >template>$id>$tplrev>page.*>parmid.*]
	foreach parmid_ptr $parmid_list {
		set parm [dv_get -root $parmid_ptr parmid]
		for {set occ 1} {$occ <= $max($parm)} {incr occ} {
			if {[regexp $pattern($dtype($parm)) \
					$value($parm,$occ)] == 0 || \
					[string length $value($parm,$occ)]>\
					 $len($parm)} {
				set value($parm,$occ) ""
			} else {
				an_write $currenv  { }
				an_write $currenv  \
					"parm.$parm.$occ=\"$value($parm,$occ)\""
			}
		}
	}
	an_return $currenv 0
}

set ct_sendflag 1
an_proc keys {keys send=%s} {
Provides the send key enable/disable functionality of Ctsrv's keys command.
An empty "send" value will disable window accepts.  An non-empty value will
enable them.
} {
{0 Success}
} {
	global ct_sendflag
	if {$send==""} {
		set ct_sendflag 0
	} else {
		set ct_sendflag 1
	}
	an_return $currenv 0
}


if {[info commands an_strex]==""} {

proc an_strex {string} {
	puts "running Tcl an_strex"
	regsub -all {\(left[ 	]} $string {[string_left } string
	regsub -all {\(right[ 	]} $string {[string_right } string
	regsub -all {\(\*[ 	]} $string {[dv_get } string
	regsub -all {\)} $string {]} string
	eval set result \"$string\"
	return $result
}

proc string_left {string count} {
	return [string range $string 0 [expr $count-1]]
}
}
if {![info exists no_ctsrv_main]} {
	ct_createmain
}

an_proc t_hide {t_hide id=%s rev=%s} { Same as Ctsrv t_hide } {{0 Success}} {
	global tpldata
	set ct_mainname [dv_get ct_mainname]
	if {$ct_mainname==""} {
		set ct_mainname .screen
	} 
	foreach el [array names tpldata "*,name"] {
		if {$tpldata($el)==$id} {
			set tplnum [lindex [split [lindex [split $el .] 2] ,] 0]
			set origenv $tpldata($ct_mainname.$tplnum,currenv)
			td_sendreply $origenv $ct_mainname.$tplnum 1
			break
		}
	}

}
