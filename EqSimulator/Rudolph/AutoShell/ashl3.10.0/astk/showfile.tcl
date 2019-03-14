
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: showfile.tcl,v 1.2 1997/01/09 19:31:18 karl Exp $
# $Log: showfile.tcl,v $
# Revision 1.2  1997/01/09 19:31:18  karl
# Added code to trap error when dv file can't be read.
#
# Revision 1.1  1996/08/27  16:17:49  karl
# Initial revision
#
set s_f_c 0
# Generic routine to load and display a file.
proc show_file {filepath position {vibindings 0}} {
	#puts "Inside show_file vibindings=$vibindings"
	global s_f_c
	text .dummy
	set ttfont [.dummy cget -font]
	destroy .dummy
	incr s_f_c
	toplevel .sfwin$s_f_c
	wm title .sfwin$s_f_c "Viewing $filepath"
	wm withdraw .sfwin$s_f_c
	button .sfwin$s_f_c.ok -text "OK" -command "destroy .sfwin$s_f_c" 
	frame .sfwin$s_f_c.cont -bd 2 -relief ridge
	pack .sfwin$s_f_c.cont -side top -fill both -expand 1
	pack .sfwin$s_f_c.ok -side bottom
#	scrollbar .sfwin$s_f_c.cont.dvlistscroll \
#		-command ".sfwin$s_f_c.cont.dvlist.text yview"
	viedit .sfwin$s_f_c.cont.dvlist -width 80 -height 25 -relief sunken \
		-scroll yes -fileops no \
		-vibindings $vibindings \
		-highlightthickness 0
#		-yscrollcommand ".sfwin$s_f_c.cont.dvlistscroll set" 
	pack .sfwin$s_f_c.cont.dvlist -side left -fill both -expand 1
#	pack .sfwin$s_f_c.cont.dvlistscroll -side left -fill both
	.sfwin$s_f_c.cont.dvlist.text delete 1.0 end
	if [catch {set f [ open $filepath ]}] {
		.sfwin$s_f_c.cont.dvlist.text insert end \
			"Couldn't open $filepath!"
	} else {
		while { ![eof $f]} {
			.sfwin$s_f_c.cont.dvlist.text insert end [read $f 1000]
		}
		close $f
	}
	set wh [lindex [.sfwin$s_f_c.cont.dvlist.text configure -height] 4]
	if { $position == "end" } {
		.sfwin$s_f_c.cont.dvlist.text yview "end-[expr $wh*3/4] lines"
	} else {
		.sfwin$s_f_c.cont.dvlist.text yview -pickplace $position
	}
        # Set dv text widget so that dv list can't be entered
        .sfwin$s_f_c.cont.dvlist.text configure -state disabled
	#tkwait visibility .sfwin$s_f_c
        #grab .sfwin$s_f_c
	#do_vi .sfwin$s_f_c.cont.dvlist.text
	focus .sfwin$s_f_c.cont.dvlist.text
	.sfwin$s_f_c.cont.dvlist.text mark set insert 1.0
	update idletasks; wm deiconify .sfwin$s_f_c
	return .sfwin$s_f_c.cont.dvlist.text
}
