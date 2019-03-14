
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: aim.tcl,v 1.10 2000/08/08 19:26:41 karl Exp $
# $Log: aim.tcl,v $
# Revision 1.10  2000/08/08 19:26:41  karl
# Added global grab error windows.
#
# Revision 1.9  2000/07/07  20:49:13  karl
# Added dvviewer and adminmode options.
#
# Revision 1.8  1999/08/23  22:56:46  karl
# Moved load/save_options routines.
#
# Revision 1.7  1999/05/13  18:31:03  karl
# Fixed bug that occurred when moving mouse over balloonhelp buttons
# when many other windows were displayed (empty stack trace).
#
# Revision 1.6  1999/05/11  23:10:30  karl
# Fixed bug that caused balloon help to appear even if window didn't have
# focus.
#
# Revision 1.5  1998/12/18  16:43:41  karl
# Added easter egg.
#
# Revision 1.4  1998/12/11  19:16:39  karl
# Added hard-coding of font names to avoid TK8.0/eXceed ugly fonts.
# Cleaned up option loading/saving.
#
# Revision 1.3  1998/10/20  21:47:51  karl
# Added save_options proc.
#
# Revision 1.2  1998/09/01  18:49:20  karl
# Added bindings for Control-X,C,V.
# Added option for which queues to show at start.
#
# Revision 1.1  1998/07/16  15:37:33  karl
# Initial revision
#

set auto_path [linsert $auto_path 0 $env(ASTK_DIR)]
source $env(ASTK_DIR)/antkdialog.tcl

option add *font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* 
option add *Entry.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*
option add *Text.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*

source $env(ASTK_DIR)/aim.images.tcl

source $env(ASTK_DIR)/session.images.tcl

source $env(ASTK_DIR)/ashlSupportEmail.tcl

source $env(ASTK_DIR)/version.tcl

source $env(ASTK_DIR)/aim.acicode.tcl

proc load_options {} {
	global aim_options aci_comm_type
	set aim_options(texteditor) "anp"
	set aim_options(dvviewer) "dvb -f"
	set aim_options(browsercmd) "firefox"
	set aim_options(storedialog) "1"
    if { $aci_comm_type == "ACI" } {
		set aim_options(showatstart,zombies) "0"
	} else {
		set aim_options(showatstart,zombies) "1"
	}
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
	set aim_options(xclipboard) "0"
	set aim_options(geometry) "+25+25"
	set aim_options(rememberwindow) "0"
	set aim_options(persistoptions) "1"
	if {[file exists ~/.aimrc] && [file readable ~/.aimrc]} {
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
	if {$aim_options(rememberwindow) == "1"} {
		set aim_options(geometry) [wm geometry .]
	} else {
		set aim_options(geometry) "+25+25"
	}
	if {$aim_options(persistoptions) == "1"} {
		catch {
			set fid [open ~/.aimrc w]
			puts $fid "global aim_options"
			foreach el [array names aim_options] {
				puts $fid "set aim_options($el) {$aim_options($el)}"
			}
		}
		catch {close $fid}
	} else {
		if {[file exists ~/.aimrc] && [file writable ~/.aimrc]} {
			set fid [open ~/.aimrc r]
			set lineIn [gets $fid]
			while {![eof $fid]} {
				if {"$lineIn" == "set aim_options(persistoptions) {1}"} {
					append tmpOptions "set aim_options(persistoptions) {0}\n"
				} else {
					append tmpOptions $lineIn "\n"
				}
				set lineIn [gets $fid]
			}
			close $fid
			set fid [open ~/.aimrc w]
			puts $fid $tmpOptions
			close $fid
		}
	}
}



load_options
if {$aim_options(xclipboard)==1} {
	start_xclipboard
}
global add_filter
if {[info exists aim_options(onlyshow)]} {
	set add_filter $aim_options(onlyshow)
} else {
	set add_filter "*"
}
aim_ui .
#bind .label#1 <ButtonPress> show_smile
#bind .label#1 <ButtonRelease> hide_smile
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

