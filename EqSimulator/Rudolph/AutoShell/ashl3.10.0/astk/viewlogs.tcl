
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: viewlogs.tcl,v 1.12 2000/08/08 20:53:21 karl Exp $
# $Log: viewlogs.tcl,v $
# Revision 1.12  2000/08/08 20:53:21  karl
# Turned off follow mode on log viewing (can be enabled manually).
#
# Revision 1.11  1999/08/24  15:44:49  karl
# Fixed to handle tagged log command results.
#
# Revision 1.10  1999/03/17  22:02:41  karl
# Added code to deiconify the log window after raising it in case it had
# been minimized.
#
# Revision 1.9  1998/12/11  21:28:04  karl
# Added code to remember existing log windows and raise them instead of
# reproducing them.
# Fixed problem with log results from Java servers.
#
# Revision 1.8  1998/10/20  22:12:37  karl
# Fixed to allow results=%s data as well as free-form (java).
#
# Revision 1.7  1998/09/01  19:19:32  karl
# Changed "log tag" call to "log" for better compatibility with older
# servers.
#
# Revision 1.6  1998/07/16  14:54:24  karl
# Fixed bug where nonexistant srvname var was being accessed.
#
# Revision 1.5  1998/01/19  22:15:35  love
# Modified to use file join, file pathtype when creating absolute
# paths, and running a tcl version later than 7.4
#
# Revision 1.4  1997/10/30  22:17:14  love
# Added changes mailed by Karl to create a list of log file names
# from the log command reply instead of assuming that the logs
# resided in the CWD of the srv.  The list of log file names
# is used for deleting the log files.
#
# Ported to tcltksrv.  Modified log request to use the
# tag parameter because tcltksrv doesn't preserve unprotected
# white space in the reply messages like wishsrv does.  tcltksrv
# does an unparse of the received message after adding in
# some tagged parameters.
#
# Modified to use the file delete command when running Tcl7.6 or newer
# for portability.
#
# Revision 1.3  1996/12/11  20:06:27  karl
# Changed rescan logs button to reread the log attribute info as well.
#
# Revision 1.2  1996/11/13  16:44:50  karl
# Fixed a "catch toplevel" call.
#
# Revision 1.1  1996/08/27  16:22:49  karl
# Initial revision
#

set ll_c 0

proc viewlogs {srvname win {vibindings 0}} {
	global ll_list
	if {[info exists ll_list($srvname)] && 
	    [winfo exists $ll_list($srvname)]} {
		raise $ll_list($srvname)
		wm deiconify $ll_list($srvname)
		return
	}
	if [catch {an_msgsend 0 $srvname "get CWD omit_from_logs" -an_reply_cb "srv_cwd win=$win vibindings=$vibindings"}] {
		disp_error "Couldn't send to $srvname.  Make sure it is running." [getWin]

	}
}

proc getWin {} {
	if {[winfo exists .talk]} {
		return ".talk"
	} elseif {[winfo exists .serverlist]} {
		return ".serverlist"
	} else {
		return "."
	}
}


# This is invoked when "Server Logs" is pressed.  It gets the CWD of the
# server, then request log information.
an_proc srv_cwd {} {} {} {
	#puts "inside srv_cwd"
	if [catch {an_msgsend 0 $fr "log" -an_reply_cb \
		"log_list cwd=$CWD vibindings=$vibindings win=$win"}] {
		disp_error "Couldn't send to $fr.  Make sure it is running." $win
	}
}

proc get_log_info {srvname wn vibindings} {
	#puts "inside get_log_info"
	if [catch {an_msgsend 0 $srvname "get CWD omit_from_logs" -an_reply_cb \
		"get_log_info2 wn=$wn vibindings=$vibindings"}] {
		disp_error "Couldn't send to $srvname.  Make sure it is running." .
	}
}

an_proc get_log_info2 {} {} {} {
	#puts "inside get_log_info2"
	if [catch {an_msgsend 0 $fr "log omit_from_logs" -an_reply_cb \
		"get_log_info3 cwd=$CWD wn=$wn vibindings=$vibindings"}] {
		disp_error "Couldn't send to $srvname.  Make sure it is running." .
	}
}

an_proc get_log_info3 {} {} {} {
	#puts "inside get_log_info3"
	set an_data [get_an_body $an_form]
	#puts "DEBUG: get_log_info3 an_data=$an_data"

	add_log_buttons $wn $cwd $fr $an_data $vibindings
}

# This shows the log information and creates buttons to allow reading or
# rescanning the logs.
an_proc log_list {} {} {} {

	text .temp
	set ttfont [.temp cget -font]
	destroy .temp

	#set an_form [lindex [lindex $anparms [lsearch $anparms "an_form *"]] 1]
	#puts "DEBUG: log_list: anparms=\"$anparms\""
	#puts "DEBUG: log_list: an_form=\"$an_form\""
	if [info exists results] {
		set an_data $results
	} else {
		set an_data [get_an_body $an_form]
	}
	#set an_data $results
	#puts "DEBUG: log_list: an_data=\"$an_data\""
	set srvname $fr
	global ll_c
	set wn .ll$ll_c
	incr ll_c
	if {[winfo exists $wn]} { return }
    	lassign [winfo pointerxy .] x y
	toplevel $wn
    	wm geometry $wn +[expr $x - 200]+[expr $y - 200]
	global ll_list
	set ll_list($srvname) $wn
	wm title $wn "Log View"
	label $wn.cwd -text "CWD: $cwd" \
		-relief groove
	message $wn.loglist -width 20c\
		-text $an_data \
		-font $ttfont -relief groove
	pack $wn.cwd $wn.loglist -side top -fill x
	#puts "DEBUG: log_list: an_data=$an_data"
	set fl [add_log_buttons $wn $cwd $srvname $an_data $vibindings]
	frame $wn.butts

	global tcl_version
	if { $tcl_version > "7.4" } {
		button $wn.erase -text "Erase All Logs" \
			-command "erase_logs \"$fl\" $wn $srvname $vibindings"
	} else {
		button $wn.erase -text "Erase All Logs" \
			-command "catch {exec sh -c {rm $fl}}
					catch {destroy $wn.logs}
					get_log_info $srvname $wn $vibindings"
	}

	button $wn.update -text "Rescan Logs" \
		-command "catch {destroy $wn}
			viewlogs $srvname $wn $vibindings"
	button $wn.exit -text "OK" -command "destroy $wn"
	pack $wn.erase $wn.update $wn.exit \
		-side left -fill x -expand 1 -in $wn.butts
	pack $wn.butts -side top -fill x -expand 1
	#wtree $wn
}

# This procedure displays all the log files in the current servers working
# directory, and allows viewing of the file contents.
proc add_log_buttons {win cwd srvname an_data {vibindings 0}} {
	#puts "DEBUG: win=$win cwd=$cwd srvname=$srvname an_data=\n$an_data"
	# Used to determine if log file buttons should be recreated
	set destroyed 0
	# If log file buttons & 'action' buttons exist, destroy them
	#  so we can rebuild a new list of log file buttons
	if { [winfo exists $win.butts] } {
		destroy $win.butts $win.erase $win.update $win.exit
		set destroyed 1
	}

	text .dummy
	set ttfont [.dummy cget -font]
	destroy .dummy

	frame $win.logs -bd 2
	pack $win.logs -fill x

	set lines [lrange [split $an_data "\n"] 1 end]
	set num 0
	set fl {}
	#puts "lines=$lines"
	foreach line $lines {
		#puts "line=$line"
		if {[string trim $line "\""]=="" || \
		    [string match "name *" $line]} {
			continue
		}
		set fn [lindex $line 1]
		#set line [string trim $line]
		#set fn [string range $line 0 \
		#	[expr [string wordend $line 0] -1 ]]

		# Skip any blank lines
		if { $fn == "" } {
			continue
		}

		# If the path is already an absolute path, use the file name as is
		global tcl_version
		if { $tcl_version > "7.4" } {
			if { [file pathtype $fn] == "relative" } {
				set pn [file join $cwd $fn]
			} else {
				set pn $fn
			}
		} else {
			if { [string range $fn 0 0]=="/" } {
				set pn $fn
			} else {
				set pn $cwd/$fn
			}
		}

		append fl " $pn"

		set fi ""
		set details ""

#added , windows option for the time being to come up with a better code pe 1/28/03 
		global tcl_platform
		if {[info exists tcl_platform] && $tcl_platform(platform) == "windows"} {

			catch {

			set fsize [file size $pn]
			set mtime [file mtime $pn]
			#puts "fowner=$fowner fsize=$fsize mtime=$mtime"
			set fi "View [file tail $pn]"
			set info "($fsize bytes, changed "
			append info "[clock format $mtime \
				-format {%b %D %H:%M:%S}])"
			
			set details	"name: [file tail \
				[file rootname $pn]]\n"
			append details	"bytes: $fsize\n"
			append details	"changed: [clock format $mtime \
                                -format {%b %D %H:%M:%S}]\n"
			append details	"dir: [file dirname $pn]\n"
			}
		} else {
			catch {
			set fowner [file attributes $pn -owner]
			set fsize [file size $pn]
			set mtime [file mtime $pn]
			set perms [file attributes $pn -permissions]
			#puts "fowner=$fowner fsize=$fsize mtime=$mtime"
			set fi "View [file tail $pn]"
			set info "($fsize bytes, changed "
			append info "[clock format $mtime \
				-format {%b %D %H:%M:%S}])"
			
			set details	"name: [file tail \
				[file rootname $pn]]\n"
			append details	"bytes: $fsize\n"
			append details	"changed: [clock format $mtime \
                                -format {%b %D %H:%M:%S}]\n"
			append details	"dir: [file dirname $pn]\n"
			append details	"owner: $fowner\n"
			append details	"permissions: $perms\n"
			}
		}
		
		if {$fi!=""} {

			frame $win.logs.f$num

			button $win.logs.f$num.d -text "Details"
			bind $win.logs.f$num.d <ButtonPress> "
				[list pop_info_show $details]
			"
			bind $win.logs.f$num.d <ButtonRelease> pop_info_hide
			pack $win.logs.f$num.d -side left

			button $win.logs.f$num.b \
				-text $fi  \
				-relief raised \
				-command "tailfile $pn $win.logs.f$num \
					$vibindings 0" \
				-anchor w 
			pack $win.logs.f$num.b -side left
					
			label $win.logs.f$num.i -text $info
			pack $win.logs.f$num.i -side right

			pack $win.logs.f$num -side top -fill x
			incr num 
		}
	}

	# Rebuild the action buttons if they were destroyed in 1st step of
	#  proc
	if { $destroyed==1 } {
		frame $win.butts

		global tcl_version
		if { $tcl_version > "7.4" } {
			button $win.erase -text "Erase All Logs" \
				-command "erase_logs \"$fl\" $win $srvname $vibindings"
		} else {
			button $win.erase -text "Erase All Logs" \
				-command "catch {exec sh -c \"rm $fl\"}
				catch {destroy $win.logs}
				get_log_info $srvname $win $vibindings"
		}

		button $win.update -text "Rescan Logs" \
			-command "catch {destroy $win}; viewlogs $srvname $win $vibindings"
		button $win.exit -text "OK" -command "destroy $win"
			pack $win.erase $win.update $win.exit \
			-side left -fill x -expand 1 -in $win.butts
		pack $win.butts -side top -fill x -expand 1
	}

	# Return list of log file names
	return $fl
}

proc erase_logs {fl win srvname vibindings} {
	set errorfiles ""
	foreach logfile $fl {
		if [catch {file delete -force $logfile}]  {
			append errorfiles $logfile "\n"
		}
	}
	if {"$errorfiles" != ""} {
		tk_dialog .warn WARNING "The following logs are in use or write-protected and cannot be deleted:\n$errorfiles" \
			warning 0 OK
	}
	catch {destroy $win.logs}
	get_log_info $srvname $win $vibindings"
}

proc get_an_body {an_msg} {
        set reploc [string last "reply=" $an_msg]
        set toloc [string first  "to=" $an_msg]
	set bodoff [string first " " [string range $an_msg $toloc end]]
        set body [string range $an_msg \
		[expr $toloc+$bodoff] [expr $reploc-1]]
        return $body
}

#source tailfile.tcl
#source viedit.tcl
#bind all <Enter> {global help_currwin;set help_currwin %W}
#bind all <F1> {global help_currwin;puts "$help_currwin fired"; break}
#viewlogs sem
