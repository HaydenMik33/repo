
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: tailfile.tcl,v 1.8 2000/08/08 20:52:41 karl Exp $
# $Log: tailfile.tcl,v $
# Revision 1.8  2000/08/08 20:52:41  karl
# Changed to make follow mode optional.
#
# Revision 1.7  1999/08/24  15:39:19  karl
# Added use of configurable text editor.
#
# Revision 1.6  1999/02/22  20:06:21  karl
# Added auto-follow option.
#
# Revision 1.5  1997/11/07  19:48:58  karl
# Fixed infinite window generator bug caused when a file was deleted
# while it was being "followed".
#
# Revision 1.4  1997/09/22  15:45:27  jasonm
# Changed to make filename the window title instead of some tempwin junk
#
# Revision 1.3  1997/08/26  18:25:55  karl
# Fixed file pointer leak at tailfile window.
#
# Revision 1.2  1996/11/11  23:22:26  karl
# Changed to force view to end of file at start.
#
# Revision 1.1  1996/08/27  16:19:32  karl
# Initial revision
#
set tf_c 0
# Array of "follow" flags.
set tf_f(0) 0

proc tf_search {tfwin} {
	set found 0
	global tf_searchstr tf_sd tf_sp
	while {$found==0 && ($tf_sd=="+" ? $tf_sp < [$tfwin index end] :
				           $tf_sp > 1.0)    } {
		set str [$tfwin get $tf_sp "$tf_sp + 1 lines linestart"]
		if {[regexp -indices $tf_searchstr $str matchpos]} {
			set found 1
			set matchstart [lindex $matchpos 0]
			set matchend [expr [lindex $matchpos 1] + 1]
			if {[set currsel [$tfwin tag ranges sel]]!=""} {
				$tfwin tag remove sel [lindex $currsel 0] \
					[lindex $currsel 1]
			}
			$tfwin tag add sel \
				[$tfwin index "$tf_sp + $matchstart chars"] \
				[$tfwin index "$tf_sp + $matchend chars"] 
			set tf_sp \
				[$tfwin index "$tf_sp + 
				[expr $matchend+1] chars"]
			$tfwin mark set insert $tf_sp
			$tfwin yview $tf_sp
		} else {
			set tf_sp [$tfwin index "$tf_sp $tf_sd 1 lines linestart"]
		}
	}		
	set found 0
}

proc tf_getsearch {tfwin} {
	toplevel .tf_search
	entry .tf_search.entry -textvariable tf_searchstr -bg white \
		-relief sunken
	bind .tf_search.entry <Return> "tf_search $tfwin"
	radiobutton .tf_search.forward -text Forward -variable tf_sd \
		-value +
	radiobutton .tf_search.backward -text Backward -variable tf_sd \
		-value -
	frame .tf_search.butts
	button .tf_search.next -text "Find Next"  -command "tf_search $tfwin"
	bind .tf_search.entry <Return> "tf_search $tfwin"
	button .tf_search.cancel -text Cancel -command "destroy .tf_search"
	pack .tf_search.entry .tf_search.forward .tf_search.backward \
		.tf_search.butts -side top -fill x -expand 1 -anchor w
	pack .tf_search.next .tf_search.cancel \
		-in .tf_search.butts -side left -fill x -expand 1
	focus .tf_search.entry
}

proc tailfile {filepath {buttonName ""} {vibindings 0} {followmode 0}} {
        if {[info exists options(texteditor)]} {
                set editorcmd $options(texteditor)
        } else {
                set editorcmd anp
        }
        if {$editorcmd=="anp" || \
                [string match "*anp *" $editorcmd] || \
                [string match "*anp" $editorcmd]} {
			append editorcmd " -buttons -tailfile"
			if {$followmode!=0} {
				set followstr -follow
			} else {
				set followstr ""
			}	
        }
	eval exec $editorcmd $filepath $followstr -showfollow &
}

proc oldtailfile {filepath {buttonName ""} {vibindings 0} {followmode 0}} {
      global tf_c tf_f tf_p tf_searchstr tf_sd tf_sp

	if {[info exists tf_p($filepath)]} {
		return
	}
	set tf_p($filepath) 1
	# If file doesn't exist...
	if {[catch "open $filepath r" f]} {
		# Try to create it.
		if {[set f [ open $filepath w]]==""} {
			# Abort if can't create
			return 1
		}
		# If could create, close the file, then reopen for reading.
		close $f
		if {[set f [ open $filepath r]]==""} {
			return 2
		}
	}
	if {![file exists $filepath]} {
		return 3
	}
	file stat $filepath finfo
	set inode $finfo(ino)

	set tf_searchstr ""
	set tf_sd +
	set tf_sp 1.0
	# Make sure window name is unique.
	incr tf_c
	set tf_f(.tmpwin$tf_c) 0
	toplevel .tmpwin$tf_c
	wm withdraw .tmpwin$tf_c
	wm title .tmpwin$tf_c $filepath
        #wm resizable .tmpwin$tf_c 0 0
	frame .tmpwin$tf_c.butts
	wm protocol .tmpwin$tf_c WM_DELETE_WINDOW \
		"tailfile_stop $filepath $f
		destroy .tmpwin$tf_c"
	button .tmpwin$tf_c.ok -text "OK" -command "
		tailfile_stop $filepath $f
		destroy .tmpwin$tf_c"	 
	button .tmpwin$tf_c.follow -text "Follow" -command "
		global tf_f
		set tf_f(.tmpwin$tf_c) 1
		.tmpwin$tf_c.follow configure -state disabled
	        tailfile_update $filepath $f $inode .tmpwin$tf_c"
	button .tmpwin$tf_c.searchf -text "Search" \
		-command "tf_getsearch .tmpwin$tf_c.cont.t.text"
	# Create frame for text and scrollbar
	frame .tmpwin$tf_c.cont -bd 2
	scrollbar .tmpwin$tf_c.cont.s  -command "
		global tf_f; set tf_f(.tmpwin$tf_c) 0
		.tmpwin$tf_c.follow configure -state normal
		.tmpwin$tf_c.cont.t.text yview"
	viedit .tmpwin$tf_c.cont.t -relief raised -width 80 \
		-exportselection 1 \
		-vibindings $vibindings \
		-status no -scroll no -fileops no \
		-yscrollcommand ".tmpwin$tf_c.cont.s set"
	focus .tmpwin$tf_c.cont.t.text
	pack .tmpwin$tf_c.cont.s -side right -fill y 
	pack .tmpwin$tf_c.cont.t -side left -fill both -expand 1
	pack .tmpwin$tf_c.cont -side top -fill both -expand 1
	pack .tmpwin$tf_c.butts -side top -fill x 
	pack .tmpwin$tf_c.follow .tmpwin$tf_c.searchf .tmpwin$tf_c.ok\
		-in .tmpwin$tf_c.butts \
		-side left -fill x  -expand 1
	.tmpwin$tf_c.cont.t.text delete 1.0 end

	while {[gets $f linebuf]> -1} {
          .tmpwin$tf_c.cont.t.text insert end "$linebuf\n"
	}
	do_vi .tmpwin$tf_c.cont.t.text
	.tmpwin$tf_c.cont.t.text see end
	.tmpwin$tf_c.cont.t.text configure -state disabled
	# tailfile_update $filepath $f $inode .tmpwin$tf_c
#        if {$buttonName != ""} {
#         $buttonName configure -state disabled
#         tkwait window .tmpwin$tf_c 
#         $buttonName configure -state normal
#        }
	#wtree .tmpwin$tf_c
	update idletasks; wm deiconify .tmpwin$tf_c
	if {$followmode} {
		.tmpwin$tf_c.follow invoke
	}
}

proc tailfile_stop {filepath f} {
	close $f
	global tf_p
	unset tf_p($filepath)
}

proc tailfile_update {filepath f inode tfwin} {
	global junkflag tf_f

        # If Follow mode has been set, then read rest of file and insert into
	#  text widget
	if { $tf_f($tfwin) } {
	  if {![winfo exists $tfwin]} {
		return 5
	  }
	$tfwin.cont.t.text configure -state normal
	  while {[gets $f linebuf]> -1 } {
		$tfwin.cont.t.text insert end "$linebuf\n"
	  }
	  if {$tf_f($tfwin)} {
		$tfwin.cont.t.text yview end
	  }
	$tfwin.cont.t.text configure -state disabled
	  if [catch {file stat $filepath finfo}] {
		tk_dialog .tmptf ERROR "File $filepath disappeared." error 0 OK
		return
	  }
	  if {![file exists $filepath]} {
		after 500 "tailfile_update $filepath $f $inode $tfwin"
	  }
	  if {$inode != $finfo(ino)} {
		close $f
		if {[set f [ open $filepath r]]==""} {
			return 4
		} 
		file stat $filepath finfo
		set inode $finfo(ino)
	  }
	  after 500 "tailfile_update $filepath $f $inode $tfwin"
	  set wh [lindex [$tfwin.cont.t.text configure -height] 4]
	  # Check to see if follow mode has been set
	}
}
#bind all <Enter> {global help_currwin;set help_currwin %W}
#bind all <F1> {global help_currwin;puts "$help_currwin fired"; break}
#source viedit.tcl
#source util.tcl
#tailfile /home/karl/test/demo/sfc/verbose.log
#tkwait visibility .tmpwin1
#tkwait window .tmpwin1
#exit
