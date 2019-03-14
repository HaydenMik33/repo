
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

#
# This code is based on aim.tcl -- it implements a MS Windows
# version of the standalone 'talk' GUI.
#

set auto_path [linsert $auto_path 0 $env(ASTK_DIR)]
source $env(ASTK_DIR)/antkdialog.tcl

option add *font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* 
option add *Entry.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*
option add *Text.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*

source $env(ASTK_DIR)/aim.images.tcl

source $env(ASTK_DIR)/session.images.tcl

source $env(ASTK_DIR)/ashlSupportEmail.tcl

source $env(ASTK_DIR)/aim.acicode.tcl

source $env(ASTK_DIR)/tree.tcl

proc load_options {} {
	global aim_options
	set aim_options(texteditor) "anp"
	set aim_options(dvviewer) "dvb -f"
	set aim_options(browsercmd) "firefox"
	set aim_options(storedialog) "1"
	set aim_options(showatstart,zombies) "1"
	set aim_options(showatstart,locals) "1"
	set aim_options(showatstart,remotes) "1"
	set aim_options(cmdcompletion) "1"
	set aim_options(hidesysbin) "1"
	set aim_options(sueditor) "srve"
	set aim_options(showclients) "0"
	set aim_options(onlyshow) "*"
	set aim_options(background) "#2985B6"
	set aim_options(foreground) "white"
	set aim_options(adminmode) "0"
	set aim_options(usericons1) ""
	set aim_options(usericons2) ""
	if {[file exists ~/.aimrc]} {
		source ~/.aimrc
	}
	set aim_options(showatstart) {}
	foreach el [array names aim_options showatstart,*] {
		if {$aim_options($el)==1} {
			lappend aim_options(showatstart) [lindex \
				[split $el ,] 1]
		}
	}
}

proc save_options {} {
	global aim_options
	set fid [open ~/.aimrc w]
	puts $fid "global aim_options"
	foreach el [array names aim_options] {
		puts $fid "set aim_options($el) {$aim_options($el)}"
	}
	close $fid
}

load_options



proc show_smile {} {
        for {set n 2} {$n<8} {incr n} {
                .label#1 configure -image sfcsmi$n
                update idletasks
                after 100
        }
}
 
proc hide_smile {} {
        for {set n 6} {$n>0} {incr n -1} {
                .label#1 configure -image sfcsmi$n
                update idletasks
                after 100
        }
}

global env
an_cmd log name=aimhist create
set homedir [regsub -all \\\\ $env(HOME) /]
an_cmd log name=aimhist file="$homedir/.aimhist.log" namestamp=0

set balloonwidget ""
set balloonid ""
set balloonhelp(msgtype) "Selects type of message to send to server."
bind all <Enter> { catch {
	#tkButtonEnter %W
	global balloonid balloonwidget

			#[focus]=="" || 
			#[winfo toplevel [focus]]!=[winfo toplevel %W]
	if {$balloonwidget=="%W" || [winfo toplevel %W]==".balloon"} {
		return
	}
	set tl [winfo toplevel %W]
	set focus [focus]
	if {$focus!=""} {
		set focus [winfo toplevel $focus]
	} else {
		return
	}
	set bh_image ""
	set bh_text ""
	if {[lsearch [%W configure] "-image *"]>=0} {
		set bh_image [%W cget -image]
	}
	if {[lsearch [%W configure] "-text *"]>=0} {
		set bh_text [%W cget -text]
	}
	if {$bh_image!="" && $bh_text!=""} {
		catch {after cancel $balloonid}
		set balloonid [after 1000 "show_balloon_help %W {$bh_text}"]
		set balloonwidget %W
	} elseif {[info exists balloonhelp([winfo name %W])]} {
		catch {after cancel $balloonid}
		set balloonid [after 1000 "show_balloon_help %W {$balloonhelp([winfo name %W])}"]
		set balloonwidget %W
	} else {
	}
	#break
}}

bind all <Leave> {
	#tkButtonLeave %W
	global balloonwidget balloonid
	catch {after cancel $balloonid}
	if {[winfo exists .balloon]} {
		destroy .balloon
	}
	#break
}

bind all <ButtonPress> {
	global balloonwidget balloonid
	catch {after cancel $balloonid}
	catch {destroy .balloon}
}

bind Text <Control-Key-x> "[bind Text <<Cut>>]"
bind Text <Control-Key-c> "[bind Text <<Copy>>]"
bind Text <Control-Key-v> "[bind Text <<Paste>>]"
bind Entry <Control-Key-x> "[bind Entry <<Cut>>]"
bind Entry <Control-Key-c> "[bind Entry <<Copy>>]"
bind Entry <Control-Key-v> "[bind Entry <<Paste>>]"

proc show_balloon_help {wn text} {
	global balloonwidget
	catch {destroy .balloon}
	toplevel .balloon 
	message .balloon.text -text $text -bg #FFFF99 -width 100
	pack .balloon.text
	set bw [winfo reqwidth .balloon.text]
	set bh [winfo reqheight .balloon.text]
	set xp [winfo rootx $wn]
	set yp [expr [winfo rooty $wn]+[winfo height $wn]]
	set sw [expr [winfo screenwidth $wn] - 55]
	set sh [expr [winfo screenheight $wn] - 55]
	if {[expr $xp+$bw]>$sw} {
		set xp [expr $sw-$bw]
	}
	if {[expr $yp+$bh]>$sh} {
		set yp [expr $sh-$bh]
	}
	wm geometry .balloon +$xp+$yp
	wm overrideredirect .balloon 1
	update idletasks
	raise .balloon
}

set myname [dv_get >name]
global aci_comm_type
global aci_conf
if { $aci_comm_type == "ACI" } {
	set aci_conf [dv_get >aci_conf]
} else {
	set aci_conf ""
}
global sessnames sesscount sessids
set sesscount 0
wm withdraw .
set env(LOGNAME) $env(USERNAME)
set env(STANDALONE) true
set winid .talk
set base .talk
toplevel $winid
frame .talk.cwd
listbox .serverlist
frame .talk.serverlist
label .talk.acname
label .acname
menu .file
menu .edit
menu .os
menu .srv
menu .help
frame .usericons1
frame .usericons2
set sessnames($winid) $myname
set sessids($myname) $winid
session_ui $winid
incr sesscount

