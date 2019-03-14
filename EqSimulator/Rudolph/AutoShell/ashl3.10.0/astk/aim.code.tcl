
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: aim.code.tcl,v 1.21 2000/09/14 15:08:01 karl Exp $
# $Log: aim.code.tcl,v $
# Revision 1.21  2000/09/14 15:08:01  karl
# Changed pop-up launcher menus to be a little harder to accidentally drop.
# Added right-click on server list to post Srv menu.
#
# Revision 1.20  2000/08/02  19:59:52  karl
# Fixed sys>waiting leaks.  Added error window if file struct requested
# for app with no startup file.
#
# Revision 1.19  2000/07/06  22:29:06  karl
# Added CWD entry on main window.
# Added warnings when opening read-only files.
# Abstracted show_struct_main so it can be called from anywhere.
# Added ability to define multiple queue name filters under options.
# Added dvb* filter to queue name filters.
# Took out a leftover tclvarjnk debugging DV dump.
# Added code to shut down gracefully if window is terminated by WM.
# Changed iconized window names to be more concise.
# Added Configurable Command Macro menu.
# Shrunk the icon images on the toolbar config window, to fit on screen.
# Added admin mode.
#
# Revision 1.18  2000/02/17  15:35:37  karl
# Fixed problem where the last menu option of each pull-down was not
# available at the toolbar configuration screen.
#
# Revision 1.17  1999/08/23  22:48:48  karl
# Added "are you sure" before allowing "exit" to be sent to servers.
# Added option to choose colors for the main window.
# Added support for 100+ queues "qsrv list compact".
# Added a menu and made buttons optional and configurable.
# Added help menu with About and links to docs.
#
# Revision 1.16  1999/07/23  14:21:54  karl
# Added hidden queue filter.
#
# Revision 1.15  1999/06/02  17:32:21  karl
# Added file structure, cmd list, dv view, and log view buttons to
# main window.  Added ability to debug by server name as well as
# script name.
#
# Revision 1.14  1999/05/11  23:03:44  karl
# Fixed a "bad window" stack trace related to sessids() array.
# Fixed to use "compact" option of qsrv's list command if it is available,
# so systems with more than 100 queues will be displayed correctly.
# Fixed a "bad window" stack bug related to drag-n-drop session change.
#
# Revision 1.13  1999/03/31  22:46:42  karl
# Added Script Debugger launcher button
#
# Revision 1.12  1999/03/17  21:25:51  karl
# Added code to deiconify windows when raising them to the foreground in
# case they have been minimized.
#
# Revision 1.11  1998/12/14  20:23:11  karl
# Added support for .sfc files at SFCE launch button.
#
# Revision 1.10  1998/12/11  20:55:11  karl
# Fixed a bug in the "recent files" launcher menus.
#
# Revision 1.9  1998/12/11  19:11:28  karl
# Added "recent files" list to launcher button menus.
# Added capability to change message dest with "c name" or by drag-n-drop
# from main window.
# Fixed main window to remember expanded/collapsed entries between runs.
# Fixed iconname for main window to be abbreviated to a meaningful string.
#
# Revision 1.8  1998/10/20  21:43:47  karl
# Added AC to list of executables detected by procinfo.
# Added filter capability to procinfo window.
# Fixed so opening session that is already open raises the existing window
# instead of stack tracing.
# Added code to move server list view to selection after update.
# Added "Delete Dead Queues" button to queue/proc info window.
#
# Revision 1.7  1998/09/01  18:43:25  karl
# Added processes_info, process_info procedures.
# Fixed some "window already exists" stack traces.
# Added "wait" cursor to some slow functions.
# Took out relative positioning of queue info window.
# Added procs to launch spectcl and WB.
# Improved process/queue info window.
#
# Revision 1.6  1998/08/05  22:19:26  karl
# Made New at launch require a file name.
#
# Revision 1.5  1998/08/05  22:05:21  karl
# Added checks for no filename before opening EQB, SFCE, or text edit.
# Added code to handle servers with periods in their name.
# Added code to allow customization of which server types to show at start.
# Added code to collect user name info for queue and process info window.
# Added readerstat info at queue/process info window.
#
#
# Revision 1.41 1998/08/03  13:42 justin
# Added code to display User Id on Qinfo list
#
# Revision 1.4  1998/07/22  14:31:58  karl
# Fixed stack trace bug when there were no locals or zombies.
#
# Revision 1.3  1998/07/17  20:45:56  karl
# Fixed Startup Editor Launcher to find both .xsu and .su files.
#
# Revision 1.2  1998/07/16  20:59:57  karl
# Added "Are you sure" before stopping a server.
# Added use of selection if available to start server button.
#
# Revision 1.1  1998/07/16  15:35:46  karl
# Initial revision
#

global aim_cwd
set aim_cwd [pwd]
rename cd old_cd
proc cd {{dir {}}} {
	global aim_cwd
	set rc [eval old_cd $dir]
	set aim_cwd [pwd]
	return $rc
}

proc aim_changecwd {} {
	global aim_cwd 
	set aim_cwd [dirselect]
}

bind $base.cwd <Return> {
	global aim_cwd
	if {[catch {old_cd $aim_cwd}]} {
		set aim_cwd [pwd]
	}
}

proc stop_server {wn} {
	global aci_comm_type
	set cs [.serverlist curselection]
	if {$cs!=""} {
		set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
		set rc [tk_messageBox -message \
			"Are you sure you want to stop $cn?" \
			-type yesno -icon question -parent .serverlist]
		
		if {$rc=="yes"} {
			if { $aci_comm_type == "ACI" } {
				set cn [mangle_aci_name $cn]	
			}
       	 	if [ catch {an_msgsend 0 $cn exit -an_reply_cb "stop_server2"} ] {
				tk_messageBox -message "Send exit command to $cn failed." \
					-type ok -icon warning -title "Warning" -parent .serverlist
			}
	
		}
	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}

an_proc stop_server2 {} {} {} {
	if {$reply!="0"} {
		tk_messageBox -message \
			"Exit command to $fr failed." -type ok -icon error -title "Error" -parent .serverlist
	} else {
		refresh_serverlist
	}
	an_delete_cb $currenv
}

proc kill_server {wn} {
	global aim_qinfo myHostname tcl_platform
	set cs [.serverlist curselection]
	if {$cs!=""} {
		set cn [expandable_listbox_get .serverlist [lindex $cs 0]]

		# If it isn't running on my box, you can't kill it
		if { $aim_qinfo($cn,hn) != $myHostname } {
			tk_messageBox -message "You can only use this command to kill local processes." \
					-type ok -icon error -title "Error" -parent .serverlist
			return
		} else {

			# If you can't get a process ID, you can't kill it.
			if [string equal -length 5 "ashl." $cn] {
   			   	set toName [string range $cn 5 end]
			} else {
				set toName $cn
			}
		    if [ catch {set reply [exec sendmq $toName -t 2 -max 1 -r \
					do=getdvs variable="sys>pid" ] } ] {
				tk_messageBox -message "Unable to query $cn for process ID.  It must be killed using task manager" \
					-type ok -icon error -title "Error" -parent .serverlist
				return
			} else {
				if [info exists reply] {
					set replyList [split $reply]
					set t [lsearch -regexp $replyList "sys.pid="]
					if { $t > -1 } {
						set val [lindex $replyList $t]
				        set pid [lindex [split $val =] 1]
					} else {
						tk_messageBox -message "The process $cn is alive but has not returned a process ID.  It must be killed using task manager" \
						-type ok -icon error -title "Error" -parent .serverlist
						return
					}
				} else {
					tk_messageBox -message "The process $cn is alive but has not returned a process ID.  It must be killed using task manager" \
					-type ok -icon error -title "Error" -parent .serverlist
					return
				}
			}
		}

		# Kill the process belonging to pid 
		set rc [tk_messageBox -message \
			"Are you sure you want to kill process $pid?" \
			-type yesno -icon question -parent .serverlist]
		
		if {$rc=="yes"} {
			if { [info exists tcl_platform] && 
			$tcl_platform(platform) == "windows"} {
				exec processterminate $pid
			} else {
				exec kill -9 $pid
			}
		}

	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}



global sscount 
set sscount 0
proc start_server {wn} {
	global sscount aci_comm_type
	set cs [.serverlist curselection]
	if {$cs!=""} {
		set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
		if { $aci_comm_type == "ACI" } {
			set cn [mangle_aci_name $cn]	
		}
   		set x [expr [winfo pointerx .] - 200]
   		set y [winfo pointery .]
		toplevel .ss$cn
		wm geometry .ss$cn +$x+$y
		startsrv_ui .ss$cn
	} else {
   		set x [expr [winfo pointerx .] - 200]
   		set y [winfo pointery .]
		toplevel .ss$sscount
		wm geometry .ss$sscount +$x+$y
		startsrv_ui .ss$sscount
		incr sscount
	}
}

proc processes_info {wn} {
	global env aim_info aci_comm_type
	if {[winfo exists .procsinfo]} {
		raise .procsinfo
		wm deiconify .procsinfo
		return
	}
	[winfo toplevel $wn] configure -cursor watch
	update idletasks
	if { $aci_comm_type == "ACI" } {
		set binloc 1
	# On unix, if qsrv is in your path, just show AutoShell processes
	} else {
		set paths $env(PATH)
		set binloc ""

		foreach path [split $paths :] {
			if [file exists $path/qsrv] {
				set binloc $path
				break
			}	
		}
	}

	set pstext [exec ps -ef]
	set text ""
	if {$binloc==""} {
		set text $pstext
	} else {
		set exelist { aci_ srv scrdebug sendmq sfcedit smsgate 
			talk timer AC}
		set pslist [split $pstext "\n"]
		foreach psline $pslist {
			foreach exe $exelist {
				#puts "Looking for $exe in $psline"
				if {[string first $exe $psline]>=0} {
				    append text \
					"[string range $psline 0 14
					][string range $psline 24 32
					][string range $psline 41 end]\n"
				    break
				}
			}
		}
	}
  	set x [expr [winfo pointerx .] - 0]
   	set y [expr [winfo pointery .] + 10]
	toplevel .procsinfo
	wm geometry .procsinfo +$x+$y
	wm title .procsinfo "Process Info"
	frame .procsinfo.butts 
	pack .procsinfo.butts -side bottom
	button .procsinfo.butts.ok -text " OK " -command "destroy .procsinfo"
	pack .procsinfo.butts.ok -side left
	label .procsinfo.butts.filterlab -text "filter:"
	pack .procsinfo.butts.filterlab -side left
	entry .procsinfo.butts.filter 
	pack .procsinfo.butts.filter -side left
	bind .procsinfo.butts.filter <Return> {
		global procsinfo_text
		set str [.procsinfo.butts.filter get]
		.procsinfo.txt configure -state normal
		.procsinfo.txt delete 1.0 end
		foreach line [split $procsinfo_text "\n"] {
			if [string match "*$str*" $line] {
				.procsinfo.txt insert end "$line\n"
			}
		}
		.procsinfo.txt configure -state disabled
	}
	scrollbar .procsinfo.scrlx -command ".procsinfo.txt xview" \
		-orient horizontal
	pack .procsinfo.scrlx -side bottom -fill x 
	text .procsinfo.txt -width 80 -height 20  -wrap none \
		-xscrollcommand ".procsinfo.scrlx set" \
		-yscrollcommand ".procsinfo.scrl set" -font fixed
	pack .procsinfo.txt -side left -expand 1 -fill both
	scrollbar .procsinfo.scrl -command ".procsinfo.txt yview"
	pack .procsinfo.scrl -side left -fill y 
	.procsinfo.txt insert 1.0 $text
	global procsinfo_text
	set procsinfo_text $text
	.procsinfo.txt configure -state disabled
	#scrl_dialog .procsinfo "Process Info" $text "" 0 OK -font fixed
	[winfo toplevel $wn] configure -cursor $aim_info(normalcursor)
}

proc process_info {wn} {
	if {[winfo exists .procinfo]} {
		raise .procinfo
		wm deiconify .procinfo
		return
	}
	set cs [.serverlist curselection]
	if {$cs!=""} {
		set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
		return
	}

	global aci_comm_type
	if { $aci_comm_type == "ACI" } {
		set cn [mangle_aci_name $cn]	
		if [catch { an_msgsend 0 $cn {getdvs -r variable=>sys>argv} -an_reply_cb "process_info_2 wn=$wn cn=$cn" } errmsg] {
			tk_messageBox -message "Server $cn is not running." \
			-type ok -icon error -title "Error" -parent .serverlist
		}
	} else {
		an_cmd process_info_2 wn=$wn cn=$cn
	}
}

an_proc process_info_2 {} {} {} {
	global aci_comm_type

	set text2 ""
	if { $aci_comm_type == "ACI" } {

		foreach ii [array names sys] {
			if {"$ii" != "argv"} {
				append text2 $sys($ii) " "
			}
		}
	

	} else {
		if {[catch {set text [exec ps -ef | grep $cn | grep -v grep]}]} {
			tk_messageBox -type ok -icon warning -message "No such process found" -parent .serverlist
			return
		}
		foreach psline [split $text "\n"] {
			append  text2 "[string range $psline 0 14
				][string range $psline 24 32
				][string range $psline 41 end]\n"
		}
	}
  	set x [expr [winfo pointerx .] - 10]
   	set y [expr [winfo pointery .] - 100]
	toplevel .procinfo
	wm geometry .procinfo +$x+$y
	wm title .procinfo "Process Info"
	button .procinfo.ok -text " OK " -command "destroy .procinfo"
	pack .procinfo.ok -side left
	scrollbar .procinfo.scrlx -command ".procinfo.txt xview" \
		-orient horizontal
	pack .procinfo.scrlx -side bottom -fill x 
	text .procinfo.txt -width 80 -height 10 -wrap none \
		-xscrollcommand ".procinfo.scrlx set" \
		-yscrollcommand ".procinfo.scrl set" -font fixed
	pack .procinfo.txt -side left -expand 1 -fill both
	scrollbar .procinfo.scrl -command ".procinfo.txt yview"
	pack .procinfo.scrl -side left -fill y
	.procinfo.txt insert 1.0 $text2
	.procinfo.txt configure -state disabled
}

proc choose_color {varname title} {
	global aim_options
	set ret [tk_chooseColor -initialcolor $aim_options($varname) \
		-title $title]
	#puts "ret=$ret"
	if {$ret!=""} {
		set aim_options($varname) $ret
	}
}

proc queue_info {wn} {
	if {[winfo exists .info]} {
		destroy .info
	}
	global aim_info
	set cs [.serverlist curselection]
	if {$cs!=""} {
		set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
		an_msgsend 0 qsrv list -an_reply_cb "queue_info2 wn=$wn cn=$cn"
		[winfo toplevel $wn] configure -cursor watch
	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}

an_proc queue_info2 {} {} {} {
	global aim_info
	global tcl_platform
	#puts $anparms
	foreach index [array names name] {
		if {$name($index)==$cn} {
			set istr ""
			append istr         "name:		$name($index)\n"
			if {[info exists id($index)]} {
				append istr "type: 		local\n"
				append istr "id:		$id($index)\n"
				append istr "key in dec:	$key($index)\n"
				#if linux
				if { $tcl_platform(os) == "Linux" } { 
					set ilist [exec ipcs -q -i $id($index)]
					set ilist [string trimleft $ilist]
					set ilist [string trimleft $ilist "Message Queue "]
					#remove new line feed
					regsub -all {\n} $ilist " " ilist
					#remove tabs
					regsub -all {\t} $ilist " " ilist
					#remove extra spaces
					regsub -all {[ ][ ]*} $ilist " " ilist
					#regexp {uid=(\d+)} $ilist data sub1
					#set fileId [open jack a+ 0666]
					#puts $fileId ilist=$ilist
					#puts $fileId data=$data
					#puts $fileId sub1=$sub1
					#close $fileId
					regexp {mode=(\d+)} $ilist data sub1
					append istr "key in hex:	[format %#X $key($index)]\n"
					append istr "permissions:     	$sub1\n"
					regexp {uid=(\d+)} $ilist data sub1
					set ulist [exec more /etc/passwd]
                                        set ulist [split $ulist "\n"]
                                        foreach item $ulist {
                                        	set item [split $item ":"]
                                                if { [lindex $item 2] == $sub1 } {
                                                	set sub1 [lindex $item 0]
                                                }       
                                        }	
					append istr "owner:   		$sub1\n"
					regexp {change_time=(\w+)\s(\w+)\s(\d+)\s(\d+:\d+:\d+)\s(\d+)} $ilist data sub1 sub2 sub3 sub4 sub5
					append istr "create time:     	$sub1 $sub2 $sub3 $sub4 $sub5\n"
					regexp {cbytes=(\d+)} $ilist data sub1
					append istr "waiting bytes:   	$sub1\n"
					regexp {qnum=(\d+)} $ilist data sub1
					append istr "waiting msgs:    	$sub1\n"
					regexp {qbytes=(\d+)} $ilist data sub1
					append istr "maximum bytes:   	$sub1\n"
					regexp {lspid=(\d+)} $ilist data sub1
					set pname unknown
					set io [exec ipcs -q -p]
					foreach ln [split $io "\n"] {
						if {$sub1 == [lindex $ln 3]} {
							set sid [lindex $ln 0]
							foreach i [array names id] {
                                        			if {$id($i)==$sid} {
                                               				set pname $name($i)
								}
							}
                                                }
                                        }
					append istr "last sender: 	$sub1 ($pname)\n"
					regexp {send_time=(\w+)\s(\w+)\s(\d+)\s(\d+:\d+:\d+)\s(\d+)} $ilist data sub1 sub2 sub3 sub4 sub5
					append istr "last send time: 	$sub1 $sub2 $sub3 $sub4 $sub5\n"
					regexp {lrpid=(\d+)} $ilist data sub1
					set pname unknown
					set io [exec ipcs -q -p]
                                        foreach ln [split $io "\n"] {
                                                if {$sub1 == [lindex $ln 3]} {
                                                        set sid [lindex $ln 0]
                                                        foreach i [array names id] {
                                                                if {$id($i)==$sid} {
                                                                        set pname $name($i)
                                                                }
                                                        }
                                                }
                                        }
                                        append istr "last reader:	$sub1 ($pname)\n"
					regexp {rcv_time=(\w+)\s(\w+)\s(\d+)\s(\d+:\d+:\d+)\s(\d+)} $ilist data sub1 sub2 sub3 sub4 sub5
                                        append istr "last read time:  	$sub1 $sub2 $sub3 $sub4 $sub5\n"

					
				} else {
					set ilist [exec ipcs -qopa |\
						 grep "q\[ \]\[ \]*$id($index) "]
					append istr "key in hex:	[lindex $ilist 2]\n"
					append istr "permissions:	[lindex $ilist 3]\n"
					append istr "owner:		[lindex $ilist 4]\n"
					append istr "create time:	[lindex $ilist 14]\n"
					append istr "waiting bytes:	[lindex $ilist 8]\n"
					append istr "waiting msgs:	[lindex $ilist 9]\n"
					append istr "maximum bytes:	[lindex $ilist 10]\n"
#				set sid [lindex [exec ipcs -qopa |\
#					 grep ^.*[lindex $ilist 11]" | head -1] 1]
				
					set sname "unknown"
					# Look for sender PID in LRPID column,
					# and get associated QID.
					set io [exec ipcs -qopa]
					foreach ln [split $io "\n"] {
						if {[lindex $ln 12]==
					    		[lindex $ilist 11]} {
							set sid [lindex $ln 1]
							foreach i [array names id] {
								if {$id($i)==$sid} {
							  		set sname $name($i)
								}
							}
							break
						}
					}
					append istr "last sender:	[lindex $ilist 11]($sname)\n"
					append istr "last send time:	[lindex $ilist 13]\n"

					set sname "unknown"
					set io [exec ipcs -qopa]
					foreach ln [split $io "\n"] {
						if {[lindex $ln 12]==
					    		[lindex $ilist 12]} {
							set sid [lindex $ln 1]
							foreach i [array names id] {
								if {$id($i)==$sid} {
							  		set sname $name($i)
								}
							}
							break
						}
					}
					append istr "last reader:	[lindex $ilist 12]($sname)\n"
					append istr "last read time:	[lindex $ilist 14]\n"
				}
					
			} else {
				append istr "type: remote or aliased\n"
				append istr "loc: $loc($index)\n"
			}
   			set x [expr [winfo pointerx .] - 10]
   			set y [expr [winfo pointery .] - 100]
			toplevel .info
			wm geometry .info +$x+$y
			#	+[winfo rootx [winfo toplevel $wn]]+[winfo \
			#	rooty [winfo toplevel $wn]]
			wm title .info "Queue Information for $cn"
			label .info.lab -text $istr -justify left
			pack .info.lab -side top
			button .info.ok -text OK -command "destroy .info"
			pack .info.ok -side top
        		[winfo toplevel $wn] configure -cursor \
				$aim_info(normalcursor)
			#tkwait window .info
			an_delete_cb $currenv
			return
		}
			
	}
	tk_messageBox -message \
		"$cn is no longer known to Qsrv!  Try the Refresh button." \
		-type ok -icon error -title "Error" -parent .serverlist
	an_delete_cb $currenv
}

proc queue_flush {wn} {
	global aim_qinfo
        set cs [.serverlist curselection]
        if {$cs!=""} {
                set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
		if {[info exists aim_qinfo($cn,id)]} {
			set rc [tk_messageBox -message "Are you sure you want to remove all messages from $cn's queue?" \
			-type yesno -icon question -parent .serverlist]
			
			if {$rc=="yes"} {
				tk_messageBox -title "RESULTS" -message [exec see -r $aim_qinfo($cn,id)] \
					-type ok -icon info -parent .serverlist
			}
		} else {
			tk_messageBox -message \
				"$cn is either remote or aliased and can't be removed." \
				-type ok -icon error -title "Error" -parent .serverlist
		}
	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}

proc queue_delete {wn} {
	global aim_qinfo
        set cs [.serverlist curselection]
        if {$cs!=""} {
                set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
		if {[info exists aim_qinfo($cn,id)]} {
			set rc [tk_messageBox -message "Are you sure you want to delete $cn's queue?" \
			-type yesno -icon question -parent .serverlist]
			if {$rc=="yes"} {
				an_msgsend 0 qsrv "removequeue name.1=$cn" \
					-an_reply_cb "queue_delete2 $wn"
			}
		} else {
			tk_messageBox -message \
				"$cn is either remote or aliased and can't be removed." \
				-type ok -icon error -title "Error" -parent .serverlist
		}
	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}

an_proc queue_delete2 {} {} {} {
	if {$reply!="0"} {
		tk_messageBox -message \
			"Queue could not be deleted. $comment" -type ok -icon error -title "Error" -parent .serverlist
	} else {
		refresh_serverlist
	}
	an_delete_cb $currenv
}

proc remove_aci_name {wn} {
	global aim_qinfo myHostname

    set cs [.serverlist curselection]
    if {$cs!=""} {
        set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
		if {[info exists aim_qinfo($cn,id)]} {
			set rc [tk_messageBox -message "Are you sure you want to remove the ACI name $cn?  This will make the process (if it is running) unreachable via ACI" \
			-type yesno -icon question -parent .serverlist]
			if {$rc=="yes"} {
				# This is not especially brilliant.  I'm just sending a 
				# nameserver registration with my own server socket, then 
				# removing it.
				catch {exec aci_send -N $cn -w 1 $myHostname noop}
				after 1500
				refresh_serverlist
			}
		} else {
			tk_messageBox -message \
				"$cn is either remote or aliased and can't be removed." \
				-type ok -icon error -title "Error" -parent .serverlist
		}
	} else {
		tk_messageBox -message "You must select an ACI name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}

proc get_file_name {mode {filetypes {{"Any File" *}}}} {
	global aim_options
        if {$mode=="open"} {
		#if {[info exists aim_options(previous,$filetypes)] &&
		#	$aim_options(previous,$filetypes)!=""} {
		#	set fn [tk_getOpenFile -filetypes $filetypes] \
		#		-initialfile $aim_options(previous,$filetypes)
		#} else {
			set fn [tk_getOpenFile -filetypes $filetypes]
		#}
		#if {$fn!=""} {
		#	set aim_options(previous,$filetypes) $fn
		#}
                return $fn 
        } else {
		return [tk_getSaveFile -filetypes $filetypes]
	}
}

proc launch_spectcl {mode {txtfile {}}} {
	global aim_options tcl_platform
	if {$txtfile==""} {
		set txtfile [get_file_name $mode {{"SpecTcl GUI Windows" {.ui}}}]
	}
	set dirname [file dirname $txtfile]
	set filename [file tail $txtfile]
	if {$filename!=""} {
		add_recent spectcl $txtfile
		if {[warn_read_only $txtfile]} {
			return
		}
		if { [info exists tcl_platform] && 
		$tcl_platform(platform) == "windows"} {
			regsub -all {/} $dirname {\\\\} dospath
			exec acapplauncher $dospath spectcl $filename &
		} else {
			exec sh -c "cd $dirname ; spectcl $filename" &
		}
	}
}

proc launch_wb {mode {txtfile {}}} {
	global aim_options tcl_platform
	if {$txtfile==""} {
		set txtfile [get_file_name $mode]
	}
	set dirname [file dirname $txtfile]
	set filename [file tail $txtfile]
	if {$filename!=""} {
		add_recent wb $txtfile
		if { [info exists tcl_platform] && 
		$tcl_platform(platform) == "windows"} {
			regsub -all {/} $dirname {\\\\} dospath
			exec acapplauncher $dospath wb $filename &
		} else {
			exec sh -c "cd $dirname ; wb $filename" &
		}
	}
}

proc launch_scrd {mode {scrfile {}}} {
	global tcl_platform
	if {($mode=="scr") } {
		if {$scrfile==""} {
			set scrfile [get_file_name open \
				{{"Script File" .scr} {"Tcl Script" .tcl}}]
		}
		set dirname [file dirname $scrfile]
		set filename [file tail $scrfile]
		if {$filename!="" } {
			add_recent scrd $scrfile
			exec sh -c "cd $dirname ; scrd $filename" &
		}
	} else {
		if {$scrfile==""} {
        		set cs [.serverlist curselection]
		        if {$cs==""} {
				tk_messageBox -message \
					"You must select a server name first!" \
					-type ok -icon info -title "Selection needed" -parent .serverlist
				return
			} else {
		                set scrfile \
					[expandable_listbox_get \
					.serverlist [lindex $cs 0]]
				if { $tcl_platform(platform) == "windows" } {
					regexp ashl. $scrfile counter 
					set scrfile [string range $scrfile [string length $counter] end]
				}
			}
		}
		set filename $scrfile
		if {$filename!="" } {
			add_recent scrd $scrfile
			if { $tcl_platform(platform) == "windows" } {
				exec scrd $scrfile
			} else { 
				exec sh -c "scrd $filename" &
			}
			
		}
	}
}

proc launch_text_editor {mode {txtfile {}}} {
	global aim_options tcl_platform
	if {$txtfile==""} {
		set txtfile [get_file_name $mode]
	}
	set dirname [file dirname $txtfile]
	set filename [file tail $txtfile]
	if {$filename!=""} {
		add_recent text $txtfile
		if {[warn_read_only $txtfile]} {
			return
		}
		if { [info exists tcl_platform] && 
		$tcl_platform(platform) == "windows"} {
			regsub -all {/} $dirname {\\\\} dospath
			exec acapplauncher $dospath $aim_options(texteditor) $filename &
		} else {
			exec sh -c "cd $dirname ; $aim_options(texteditor) $filename" &
		}
	}
}

proc launch_startup_editor {mode {sufile {}}} {
	global aim_options tcl_platform
	if {$sufile==""} {
		set sufile [get_file_name $mode {{"Startup Files" {.xsu .su}}}]
	}
	set dirname [file dirname $sufile]
	set filename [file tail $sufile]
	if {$filename!="" } {
		add_recent srv $sufile
	        if {[file extension $filename]==""} {
			set filename "$filename.su"
		}       
		if { [info exists tcl_platform] && 
		$tcl_platform(platform) == "windows"} {
			regsub -all {/} $dirname {\\\\} dospath
			exec acapplauncher $dospath $aim_options(sueditor) $filename &
		} else {
			exec sh -c "cd $dirname ; $aim_options(sueditor) $filename" &
		}
	}
}

proc launch_eqb {mode {eqbfile {}}} {
	global tcl_platform
	if {$eqbfile==""} {
		set eqbfile [get_file_name $mode {{"EQB File" .eqb}}]
	}
	set dirname [file dirname $eqbfile]
	set basename [file rootname [file tail $eqbfile]]
	if {$basename!="" } {
		add_recent eqb $eqbfile
		if { [info exists tcl_platform] && 
		$tcl_platform(platform) == "windows"} {
			regsub -all {/} $dirname {\\\\} dospath
			exec acapplauncher $dospath eqb $basename &
		} else {
			exec sh -c "cd $dirname ; eqb $basename" &
		}
	}
}

proc launch_sfce {mode {sfcefile {}}} {
	global tcl_platform
	if {$sfcefile==""} {
		set sfcefile [get_file_name $mode {{"SFCE File" .xfc} {"Old SFC File" .sfc}}]
	}
	set dirname [file dirname $sfcefile]
	set basename [file rootname [file tail $sfcefile]]	
	#puts " basename $basename sfcefile $sfcefile dirname $dirname"
	if {$basename!=""} {
		add_recent sfce $sfcefile
		if { [info exists tcl_platform] && 
		$tcl_platform(platform) == "windows"} {
			regsub -all {/} $dirname {\\\\} dospath
			exec acapplauncher $dospath sfce $basename &
		} else {
			exec sh -c "cd $dirname ; sfce $basename" &
		}
	}
}

proc launch_viewdvs_main {wn} {
		global aim_options aci_comm_type
        set cs [.serverlist curselection]
        if {$cs!=""} {
                set srvname [expandable_listbox_get .serverlist [lindex $cs 0]]
			if { $aci_comm_type == "ACI" } {
				set srvname [mangle_aci_name $srvname]
			}
        	browsedvs $srvname $aim_options(dvviewer) [winfo parent .serverlist]
	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}

proc launch_viewdvs {wn} {
        global sessnames aim_options
        set srvname $sessnames([winfo toplevel $wn])
        browsedvs $srvname $aim_options(dvviewer) [winfo parent .serverlist]
}

# This one is run from ac
proc launch_viewlogs_main {wn} {
	global aci_comm_type

    set cs [.serverlist curselection]
    if {$cs!=""} {
        set srvname [expandable_listbox_get .serverlist [lindex $cs 0]]
		if { $aci_comm_type == "ACI" } {
			set srvname [mangle_aci_name $srvname]
		}
       	viewlogs $srvname [winfo parent .serverlist]
	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}

# This one is run from talk
proc launch_viewlogs {win srvname} {
        viewlogs $srvname $win
}

proc show_struct_main {fromwhere} {
	global aci_comm_type

	set cs [.serverlist curselection]
	if {$cs!=""} {
		if { $aci_comm_type == "ACI" && $fromwhere == "from_ac"} {
			set srvname [expandable_listbox_get .serverlist [lindex $cs 0]]
			set srvname [mangle_aci_name $srvname]
				
		} elseif { $aci_comm_type == "ACI" && $fromwhere != "from_ac" } {
			set srvname $fromwhere
		} else {
			set srvname [expandable_listbox_get .serverlist [lindex $cs 0]]
	 	}
		
		find_configfile_names $srvname "show_struct_cb $srvname ."
	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}

proc show_struct_cb {srvname wn list} {
	if {[llength $list]==0} {
		tk_messageBox -message "$srvname has no startup file." \
			-type ok -icon error -title "Error" -parent .serverlist
		return
	}
    if {[winfo exists .struct$srvname]} {
        raise .struct$srvname
        wm deiconify .struct$srvname
        return
    }
	set wn .struct$srvname
    toplevel $wn
    frame $wn.butts
    pack $wn.butts -side bottom
	label $wn.label -width 60 -relief sunken -anchor w
	pack $wn.label -fill x -side bottom
    as_struct_win $wn.tree $list \
		-label_cb "$wn.label configure -text" \
		-yscrollcommand "$wn.sb set"
	pack $wn.tree -padx 5 -pady 5 -expand 1 -fill both -side left
	scrollbar $wn.sb -command "$wn.tree yview"
	pack $wn.sb -side right -fill y

    button $wn.butts.edit -text Edit \
        -command "show_struct_open $wn.tree"
    pack $wn.butts.edit -side left -padx 10 -pady 5
    button $wn.butts.cancel -text Cancel \
        -command "destroy $wn"
    pack $wn.butts.cancel -side left -padx 10 -pady 5
}



proc show_cmd_list_main {wn} {
	global aci_comm_type
    set cs [.serverlist curselection]
    if {$cs!=""} {
            set srvname [expandable_listbox_get .serverlist [lindex $cs 0]]
		if { $aci_comm_type == "ACI" } {
				set srvname [mangle_aci_name $srvname]	
		}
		show_cmd_list_2 $srvname $wn
	} else {
		tk_messageBox -message "You must select a server name first!" \
			-type ok -icon info -title "Selection needed" -parent .serverlist
	}
}

proc show_cmd_list {wn} {
	global sessnames
	set srvname $sessnames([winfo toplevel $wn])
	show_cmd_list_2 $srvname $wn relative
}

proc show_cmd_list_2 {srvname wn {position free}} {
	regsub -all {\.} $srvname {____} srvname	
	if {[winfo exists .cmdlist$srvname]} {
		raise .cmdlist$srvname
		wm deiconify .cmdlist$srvname
		return
	}
	if {$position=="relative"} {
		toplevel .cmdlist$srvname
		wm geometry .cmdlist$srvname \
			+[winfo rootx [winfo toplevel $wn]]+[winfo \
			rooty [winfo toplevel $wn]]
	} else {
   		set x [expr [winfo pointerx .] - 10]
   		set y [expr [winfo pointery .] - 100]
		toplevel .cmdlist$srvname
		wm geometry .cmdlist$srvname +$x+$y
	}

	#regsub -all {"\."} $srvname {"="} srvname
	#regsub -all {\.} $srvname {=} srvname	
        #puts "Srv $srvname"
	cmdlist_ui .cmdlist$srvname
}

global sesscount
set sesscount 0

proc start_session {} {
        set cs [.serverlist curselection]
	global aim_options
#	set idx [.serverlist index @$x,$y]
#	set tmp [expandable_listbox_get .serverlist $idx]
#	if {[get_state .serverlist $idx]==1} {
#		set aim_options(showatstart,$tmp) 1
#	} elseif {[get_state .serverlist $idx]==0} {
#		set aim_options(showatstart,$tmp) 0
#	}
#	puts "state is [get_state .serverlist $idx]"
#	return
	if {$cs!=""} {
        set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
		if {[string compare $cn locals] &&
			[string compare $cn remotes] &&
			[string compare $cn zombies]} {

			global nameserver
			if {"$nameserver" != "qsrv"} {
				set cn [mangle_aci_name $cn]
			}	

			global sessnames sesscount sessids
			if {[info exists sessids($cn)] && [winfo exists $sessids($cn)]} {
				set winid $sessids($cn)
				raise $winid
				wm deiconify $winid
			} else {
				lassign [winfo pointerxy .] x y
				if {$x > 300} {
					set x [expr $x - 300]
				} else {
					set x 0
				}
				if {$y > 200} {
					set y [expr $y - 200]
				} else {
					set y 0
				}
				set winid .session$sesscount
				toplevel $winid
    				wm geometry $winid +$x+$y
				set sessnames($winid) $cn
				set sessids($cn) $winid
   	             	session_ui $winid $cn
				incr sesscount
			}
			focus $winid.inputframe.commandentry
   		 } else {
			return 
		}
	}
}

 
proc open_aim_config {} {
	set x [expr [winfo pointerx .] - 50]
	set y [expr [winfo pointery .] - 10]

	toplevel .cfg
	wm geometry .cfg +$x+$y
	aimcfg_ui .cfg
}

proc init_serverlist {} {
	global nameserver state
	
	if { "$nameserver" == "unknown" } {
		after 3000 set state timeout
		if [ catch { an_msgsend init_serverlist qsrv "get name" -an_reply_cb init_serverlist_reply_handler } ] {
			set nameserver "aci_dir"
			refresh_serverlist
		} else {	
			vwait state
			if { "$state" == "timeout" } {
				set nameserver "aci_dir"
				refresh_serverlist
			}
		}
	} else {
		refresh_serverlist
	}	
}

an_proc init_serverlist_reply_handler {} {} {} {
	global nameserver state tcl_platform

	# clean up callback for ctxt 2
	an_delete_cb $currenv

	set state "found"
	set nameserver "qsrv"
	refresh_serverlist
}
	
proc refresh_serverlist {} {
	global nameserver
	
	# queue server version
	if {$nameserver == "qsrv"} {
		an_msgsend refresh_serverlist qsrv "list compact" -an_reply_cb list_reply_handler

	# aci_dir version
	} else {

		if [ catch { set reply [exec aci_send $nameserver "list ."] } ] {
			set aci_conf [dv_get >aci_conf]
			tk_messageBox -message "Communication to aci directory server '$nameserver' failed.\nUsing ACI configuration string (nameserver:port) = $aci_conf" \
					-type ok -parent .serverlist -icon error
			an_cmd list_reply_handler

		} else {
			an_cmd list_reply_handler $reply
		}
	}
}
 
an_proc list_reply_handler {} {} {} {
	global aim_qinfo aim_info aim_options nameserver myHostaddr myHostname aci_comm_type
	catch {unset aim_qinfo}
	set locals {}
	set remotes {}
	set zombies {}
	set showlocals 0
	set showremotes 0
	set showzombies 0
	
	if {[info exists aim_options(showatstart,locals)] } {
		set showlocals $aim_options(showatstart,locals)
	}
	if {[info exists aim_options(showatstart,remotes)] } {
		set showremotes $aim_options(showatstart,remotes)
	}
	if {[info exists aim_options(showatstart,zombies)] } {
		set showzombies $aim_options(showatstart,zombies)
	}
	# normal format
	if {[info exists name]} {
		foreach suffix [array names name] {
			#puts "name name $suffix"
			set nameval $name($suffix)
			if {[hidden_queue $nameval]} {
				continue
			}
			if [info exists stat($suffix)] {
				set status $stat($suffix)
			}
			if [info exists id($suffix)] {
				set idval $id($suffix)
		    } elseif [info exists host($suffix)] {
				set idval $host($suffix)
		    } else {
				set idval -1
   	    	}
			set aim_qinfo($nameval,id) $idval
			if {[lsearch -exact $myHostaddr $idval] != -1} {
				set status reading
				set aim_qinfo($nameval,hn) $myHostname
			} else {	
				set status aci_out
				set aim_qinfo($nameval,hn) ""
			}
			if {$status=="reading"} {
				lappend locals $nameval
			} elseif {$status=="aci_out"} {
				lappend remotes $nameval
			} else {
				lappend zombies $nameval
			}
			if [info exists start($suffix)] {
				set aim_qinfo($nameval,starttime) $start($suffix)
			}
		}
	# compact format
	} else {
		foreach suffix [array names q] {

			set parts [split $q($suffix) "|"]
			set nameval [lindex $parts 0]
			if {[hidden_queue $nameval]} {
				continue
			}
			set idval [lindex $parts 1]

			# qsrv version
			if {$nameserver == "qsrv"} {
				set status [lindex $parts 2]
				if {$status==1} {
					set status reading
				} elseif {$status==0} {
					set status inactive
				} else {
					set status aci_out
				}
				set aim_qinfo($nameval,hn) ""

			# aci_dir version
			} else {
				if {[lsearch -exact $myHostaddr $idval] != -1} {
					set status reading
					set aim_qinfo($nameval,hn) $myHostname
				} else {	
					set status aci_out
					set aim_qinfo($nameval,hn) ""
				}
				set aim_qinfo($nameval,starttime) [clock format [lindex $parts 2] \
					-format "%Y-%m-%d %H:%M:%S"]
			}
			set aim_qinfo($nameval,id) $idval
			if {$status=="reading"} {
				lappend locals $nameval
			} elseif {$status=="aci_out"} {
				lappend remotes $nameval
			} else {
				lappend zombies $nameval
			}
		}
 	   if {$nameserver == "qsrv"} {  #The real qsrv, not the dummy ACI version
			lappend locals qsrv
		}
	}
	set l1 "locals $showlocals {[lsort $locals]}"
	set l2 "remotes $showremotes {[lsort $remotes]}"
	if { $aci_comm_type == "ACI" } {
		# No zombies for ACI version just yet
		set l3 {}
	} else {
		set l3 "zombies $showzombies {[lsort $zombies]}"
	}
	set list {}
	lappend list $l1 $l2 $l3

	set cs [.serverlist curselection]
	expandable_listbox_fill .serverlist $list
	an_delete_cb $currenv
	catch {
		.serverlist selection set $cs
		.serverlist see $cs
	}
}

proc is_filtered_out {name} {
	global aim_options add_filter
	foreach filter [split $add_filter :] {
#	foreach filter [split $aim_options(onlyshow) :] 
		#puts "comparing $name to $filter"
		if [string match $filter $name] {
			return 0
		}
	}
	return 1
}

proc hidden_queue {name} {
	global aim_options
	if {($aim_options(showclients)==0 && \
		([string match {ac[0-9]*} $name] || \
		[string match {tk[0-9]*} $name] || \
		[string match {sfce[0-9]*} $name] || \
		[string match {eqb[0-9]*} $name] || \
		[string match {srve[0-9]*} $name] || \
		[string match {dvb[0-9]*} $name] || \
		[string match {wb[0-9]*} $name])) || \
	    [is_filtered_out $name]} {
	    	#[string match $aim_options(onlyshow) $name]==0 
		return 1
	} else {
		return 0
	}

}

proc queue_process_info {wn} {
	global aim_info aci_comm_type
	if {[winfo exists .qinfo]} {
		raise .qinfo
		wm deiconify  .qinfo
	} else {
		#[winfo toplevel $wn] configure -cursor watch
		. configure -cursor watch
		update 
		if { $aci_comm_type == "ACI" } {
			queue_process_info2_windows $wn
		} else {
		an_msgsend 0 qsrv "list compact" \
			-an_reply_cb "queue_process_info2 wn=$wn"
		}
	}
}

# This one is for Unix
an_proc queue_process_info2 {} {} {} {
	global qpi aim_info
	catch {unset qpi}
	# Loop through queue names returned by Qsrv.
	if {[info exists name(0)]} {
		foreach suffix [array names name] {
			# If qsrv returned id info for the entry, 
			# add it to qpi array.
			if {[info exists id($suffix)]} {
				set qpi($name($suffix),id) $id($suffix)
				set qpi($name($suffix),status) $stat($suffix)
			}
		}
	} else {
		foreach suffix [array names q] {
			#puts "q($suffix)=$q($suffix)"
			set parts [split $q($suffix) "|"]
			set qname [lindex $parts 0]
			set idval [lindex $parts 1]
			set status [lindex $parts 2]
			set qpi($qname,id) $idval
			set qpi($qname,status) $status
		}
	}
	global tcl_platform

	# Get system queue info and squeeze out extra spaces.
	if { $tcl_platform(os) == "Linux" } {
		set ipcs [exec ipcs -q -p]
		set ipcs1  [exec ipcs -q]
        	regsub -all {[ ][ ]*} $ipcs1 " " ipcs1		
	} else {
		set ipcs [exec ipcs -qop]
	}
	regsub -all {[ ][ ]*} $ipcs " " ipcs

	# Get system process info 
	set ps2 [exec ps -ef]
	regsub -all {[ ][ ]*} $ps2 " " ps2

	# Initialize quick lookup array for process id to user name mapping.
	global quick
	catch {unset quick}
	foreach line2 [split $ps2 "\n"] {
	
		set line2 [string trimleft $line2]
		set lst2 [split $line2 " "]
		set pid [lindex $lst2 1]
		set uid [lindex $lst2 0]
		set quick($pid) $uid
	}

	# Loop through all system queues.
		#for Linux
	if { $tcl_platform(os) == "Linux" } {
		set temp [split $ipcs "\n"]
		set temp_length [llength $temp]
		set temp [lrange $temp 3 $temp_length]
		set temp1 [split $ipcs1 "\n"]
                set temp1_length [llength $temp1]
                set temp1 [lrange $temp1 3 $temp1_length]
		set counter 0
		foreach item $temp {
			lappend new "$item [lindex $temp1 $counter]"
			set counter [expr $counter + 1]
		}
		set temp $new
	} else {
		set temp [split $ipcs "\n"]
	}
	#foreach line [split $ipcs "\n"] 
	foreach line $temp {
		set lst [split $line " "]
		#for Linux
		if { $tcl_platform(os) == "Linux" } {
			set qid [lindex $lst 0]
		} else {
			set qid [lindex $lst 1]
		}

		# Look through all id's returned by Qsrv.
		foreach n [array names qpi "*,id"] {
			# If queue is one known to Qsrv.
			if {$qpi($n)==$qid} {
				if { $tcl_platform(os) == "Linux" } {
					set nm [lindex [split $n ","] 0]
					set qpi($nm,bytes) [lindex $lst 8]
					set qpi($nm,msgs) [lindex $lst 9]
					set qpi($nm,senderpid) [lindex $lst 2]
					set qpi($nm,readerpid) [lindex $lst 3]
					if {[info exists quick([lindex $lst 3])]} {
						set readerstat alive
					} else {
						set readerstat dead
					}
				} else {
					set nm [lindex [split $n ","] 0]
                    set qpi($nm,bytes) [lindex $lst 6]
                    set qpi($nm,msgs) [lindex $lst 7]
                    set qpi($nm,senderpid) [lindex $lst 8]
                    set qpi($nm,readerpid) [lindex $lst 9]
                    if {[info exists quick([lindex $lst 9])]} {
                    	set readerstat alive
                    } else {
                        set readerstat dead
                    }
               }

				set qpi($nm,readerstat) $readerstat
				set spid $qpi($nm,senderpid)
				set rpid $qpi($nm,readerpid)
				if {[info exists quick($rpid)]} {
					if { $tcl_platform(os) == "Linux" } { 
						#set ulist [exec grep $quick($rpid) /etc/passwd ]
						set ulist [exec more /etc/passwd]
						set ulist [split $ulist "\n"]
						foreach item $ulist {
							set item [split $item ":"]
							if { [lindex $item 2] == $quick($rpid) } {
								set qpi($nm,uid) [lindex $item 0]
							}	
						}
					} else { 
						set qpi($nm,uid) $quick($rpid)
					}
				} else {
					set qpi($nm,uid) "unknown"
				}
				break
			}
		}
	}



	foreach n [array names qpi "*,senderpid"] {
		#puts "n=$n"
		set nm [lindex [split $n ","] 0]
		set pid $qpi($n)
		foreach o [array names qpi "*,readerpid"] {
			if {$qpi($o)==$pid} {
				set nm2 [lindex [split $o ","] 0]
				set qpi($nm,sendername) $nm2
				break
			}
		}
			
	}

	queue_process_info_display $wn
	an_delete_cb $currenv
}

# for ACI releases
proc queue_process_info2_windows {wn} {
	global qpi aim_info aim_qinfo hosttable myHostaddr myHostname
	catch {unset qpi}
	if {![info exists hosttable]} {
		array set hosttable {}
	}
	set myName [dv_get >name]

	# Build up qpi(nm, name | hostname | hostaddr | starttime | readerpid | readerstat

	# Add each ACI name from aim_qinfo
	foreach el [array names aim_qinfo *,id] {
		set nm [lindex [split $el ","] 0]
		set addr $aim_qinfo($nm,id)
		set qpi($nm,hostaddr) $addr
		set qpi($nm,readerstat) ""
		# Convert to readable time string
		set qpi($nm,starttime) $aim_qinfo($nm,starttime)
		
		if { $aim_qinfo($nm,hn) == "" } {
			# Look in hosttable first:   
			if {[info exists hosttable($addr)]} {
				set aim_qinfo($nm,hn) $hosttable($addr)
			# else do an nslookup
			} else {
				set hosttable($addr) [an_inetaddrtoname $aim_qinfo($nm,id)]
				set aim_qinfo($nm,hn) $hosttable($addr)
			}
		}
		set qpi($nm,hostname) $aim_qinfo($nm,hn)

		# If it's me, just get my DVs
		if {$nm == $myName} {
			set qpi($nm,readerstat) "alive"
			set qpi($nm,readerpid) [dv_get >sys>pid]
		} elseif {$aim_qinfo($nm,hn) != "$myHostname"} {
			set qpi($nm,readerpid) "unknown"
		} else {
		# If this is a local server, talk to it and get its process info
		 	if [string equal -length 5 "ashl." $nm] {
   		     	set toName [string range $nm 5 end]
			} else {
				set toName $nm
			}
			if [info exists reply] {unset reply}
  		   	if [ catch {set reply [exec sendmq $toName -t 2 -max 1 -r \
				do=getdvs variable="sys>pid" ] } ] {
				set qpi($nm,readerstat) dead
			} else {
				if [info exists reply] {
					set qpi($nm,readerstat) "alive"
					set replyList [split $reply]
					set t [lsearch -regexp $replyList "sys.pid="]
					if { $t > -1 } {
						set val [lindex $replyList $t]
				        set readerpid [lindex [split $val =] 1]

						set qpi($nm,readerpid) $readerpid
					} else {
						set qpi($nm,readerpid) "unknown"
					}	
				} else {
					set qpi($nm,readerstat) "timeout"
				}
			}
		}
	}
	queue_process_info_display $wn
}

proc queue_process_info_display {wn} {
	global qpi aim_info aci_comm_type
  	set x [expr [winfo pointerx .] - 100]
   	set y [expr [winfo pointery .] - 100]
	toplevel .qinfo 
	wm geometry .qinfo +$x+$y
	
	scrollform_create .qinfo.gr
	set sf [scrollform_interior .qinfo.gr]
	.qinfo.gr.vport configure -height 400 -bg white
	$sf configure -bg white
	pack .qinfo.gr -expand yes -fill both

	set row 0
	set rowlabels {}
	if { $aci_comm_type == "ACI" } {
		set collabels {name hostname hostaddr starttime readerpid readerstat}
	} else {
		set collabels {name id status bytes msgs senderpid sendername readerpid readerstat uid}
	}
	set colnum 0
	foreach label $collabels {
		label $sf.r0c${colnum} -text $label  \
			-anchor w -bg blue -fg white
		grid $sf.r0c${colnum} -row 0 -column $colnum -sticky w
		incr colnum
	}
	foreach el [lsort [array names qpi]] {
		set nme [lindex [split $el ,] 0]
		set attr [lindex [split $el ,] 1]
		if {[lsearch $rowlabels $nme]==-1} {
			set rownum [ expr [llength $rowlabels] + 1]
			label $sf.r${rownum}c0 -text $nme \
				-anchor w -bg white
			grid $sf.r${rownum}c0 -row $rownum -column 0 -sticky w
			lappend rowlabels $nme
			
		}
		set rownum [expr [lsearch $rowlabels $nme] + 1]
		set colnum [lsearch $collabels $attr]
		label $sf.r${rownum}c${colnum} -text $qpi($el)  \
			-anchor w -bg white

		grid $sf.r${rownum}c${colnum} -row $rownum -column $colnum -sticky w
		if {$attr=="readerstat" && $qpi($el)=="dead"} {
			$sf.r${rownum}c${colnum} configure -bg yellow
		}
	}
	#update idletasks
	#pack $sf

	frame .qinfo.butts
	button .qinfo.butts.b -text OK -command "destroy .qinfo"
	pack .qinfo.butts.b -padx 5 -pady 10 -side left -expand 1
	if { $aci_comm_type == "IPC" } {
		button .qinfo.butts.d -text "Delete dead queues"  \
			-command "delete_dead_queues $wn"
	} else {
		button .qinfo.butts.d -text "Remove unused (dead)  names"  \
			-command "delete_dead_queues $wn"
	}
	pack .qinfo.butts.d -padx 5 -pady 10 -side left -expand 1
	pack .qinfo.butts -fill x

	update idletasks
	. configure -cursor $aim_info(normalcursor)
	focus .qinfo.gr.vport

}

proc delete_dead_queues {wn} {
	global qpi aci_comm_type aim_info
	set ques {}
	foreach el [lsort [array names qpi "*,readerstat"]] {
		if {$qpi($el)=="dead"} {
			lappend ques [lindex [split $el ,] 0]
		}
	}
	if {$ques=={}} {
		tk_messageBox -title "Error" -message \
			"There are no dead queues." \
			-type ok -icon warning -parent .serverlist
		return
	}
	if { $aci_comm_type == "IPC" } {
		set ays "Are you sure you want to delete these queues: $ques?"
	} else {
		set ays "Are you sure you want to remove these names: $ques?"
	}
	set rc [tk_messageBox -message \
		$ays -type yesno -icon question -parent .serverlist]
	
	if {$rc=="yes"} {
		[winfo toplevel $wn] configure -cursor watch
		if { $aci_comm_type == "IPC" } {
			set str ""
			set count 1
			foreach que $ques {
				append str "name.$count=$que "
				incr count
			}
			an_msgsend 0 qsrv "removequeue $str" \
				-an_reply_cb queue_delete2
			destroy .qinfo
			[winfo toplevel $wn] configure -cursor $aim_info(normalcursor)
			queue_process_info $wn	
		} else {
			foreach que $ques {
				catch {exec aci_send -N $que -w 1 dne dummy}
			}
			destroy .qinfo
			[winfo toplevel $wn] configure -cursor $aim_info(normalcursor)
			refresh_serverlist
		}
	}
}

expandable_listbox_init .serverlist aim_options
init_serverlist

global aim_options
proc add_recent {type file} {
	global aim_options
	if {[info exists aim_options(recent,$type)]} {
		set existing [lsearch $aim_options(recent,$type) $file]
		if {$existing>=0} {
			set aim_options(recent,$type) \
				[lreplace $aim_options(recent,$type) $existing \
				$existing]
		}
		set aim_options(recent,$type) \
			[linsert $aim_options(recent,$type) 0 $file]
		if {[llength $aim_options(recent,$type)]>5} {
			set aim_options(recent,$type) \
				[lrange $aim_options(recent,$type) 0 4]
		}
	} else {
			set aim_options(recent,$type) $file
	}
}

proc update_post {type proc menu index} {
	update_menu $type $proc $menu
	#set x [winfo rootx .$menu.menu]
	#set y [expr [winfo rooty .edit] + \
	#	[.$menu.menu yposition $index]]
	set x [expr [winfo pointerx .] - 10]
	set y [expr [winfo pointery .] - 10]
#	set y [expr [winfo rooty .edit] + \
#		[winfo reqheight .edit]]
	#puts "x=$x y=$y"
	.$menu.menu.${type}_new_or_open post $x $y
}

proc update_menu {type proc menu} {
	global aim_options aci_comm_type
	#puts "updating menu $type"
	catch {.$menu.menu.${type}_new_or_open delete 0 end}
	if {$menu=="srv" && $type=="scrd"} {
		if { $aci_comm_type == "IPC" } {
			.$menu.menu.${type}_new_or_open add command \
				-label "Open .scr,.tcl" \
				-command "launch_scrd {scr tcl}"
		}
		.$menu.menu.${type}_new_or_open add command \
			-label "Open Server" \
			-command "launch_scrd srv"
	} else {
		.$menu.menu.${type}_new_or_open add command \
			-label New \
			-command "launch_$proc new"
		.$menu.menu.${type}_new_or_open add command \
			-label Open \
			-command "launch_$proc open"
	}
	if {[info exists aim_options(recent,$type)]} {
		.$menu.menu.${type}_new_or_open add separator 
		foreach file $aim_options(recent,$type) {
			if {$type=="scrd"} {
				if {[file extension $file]=="scr"} {
					.$menu.menu.${type}_new_or_open \
						add command \
						-label $file -command \
						"launch_$proc scr $file"
				} else {
					.$menu.menu.${type}_new_or_open \
						add command \
						-label $file -command \
						"launch_$proc srv $file"
				}
			} else {
				.$menu.menu.${type}_new_or_open \
					add command -label $file \
					-command "launch_$proc open $file"
			}
		}
	}
}

########################################################################
# File Menu Setup
menu .file.menu -tearoff 0
#.file.menu add command -label New...
#.file.menu add command -label Open...
#.file.menu add separator
.file.menu add command -image aimcfg \
	-command open_aim_config \
	-accelerator "Options..."
.file.menu add separator
.file.menu add command -image refresh \
	-command "refresh_serverlist" \
	-accelerator "Refresh Queue List"
.file.menu add command -image session \
	-command "start_session" \
	-accelerator "Talk to Server"
.file.menu add separator
.file.menu add command -label Exit \
	-command "save_options; exit removeq"

wm protocol . WM_DELETE_WINDOW "save_options; exit removeq"

########################################################################
# Edit Menu Setup

menu .edit.menu -tearoff 0
.edit.menu add command -image aim_sfc \
	-accelerator "SFC" \
	-command "update_post sfce sfce edit 1"
.edit.menu add command -image aim_eqb \
	-accelerator "Equipment Server" \
	-command "update_post eqb eqb edit 2"
.edit.menu add command -image aim_srve \
	-accelerator "Server Startup File" \
	-command "update_post srv startup_editor edit 3"
.edit.menu add command -image aim_text \
	-accelerator "Text File" \
	-command "update_post text text_editor edit 4"
.edit.menu add command -image aim_spectcl \
	-accelerator "TK Window" \
	-command "update_post spectcl spectcl edit 5"
.edit.menu add command -image aim_wb \
	-accelerator "Ctsrv Window" \
	-command "update_post wb wb edit 6"
.edit.menu add command -image mq_step \
        -accelerator "MQ Trace" \
        -command "exec mqt &"
.edit.menu add command -image dveditor \
        -accelerator "DV File Editor" \
        -command "exec dveditor &"

menu .edit.menu.sfce_new_or_open -tearoff 0
bind .edit.menu.sfce_new_or_open <Leave> \
	".edit.menu.sfce_new_or_open unpost"

menu .edit.menu.eqb_new_or_open -tearoff 0
bind .edit.menu.eqb_new_or_open <Leave> \
	".edit.menu.eqb_new_or_open unpost"

menu .edit.menu.srv_new_or_open -tearoff 0
bind .edit.menu.srv_new_or_open <Leave> \
	".edit.menu.srv_new_or_open unpost"

menu .edit.menu.text_new_or_open -tearoff 0
bind .edit.menu.text_new_or_open <Leave> \
	".edit.menu.text_new_or_open unpost"

menu .edit.menu.spectcl_new_or_open -tearoff 0
bind .edit.menu.spectcl_new_or_open <Leave> \
	".edit.menu.spectcl_new_or_open unpost"

menu .edit.menu.wb_new_or_open -tearoff 0
bind .edit.menu.wb_new_or_open <Leave> \
	".edit.menu.wb_new_or_open unpost"

########################################################################
# Diag Menu Setup

menu .os.menu -tearoff 0
.os.menu add command -image aim_procinfo \
	-accelerator "Process List Info" \
	-command "processes_info .os.menu"
.os.menu add command -image aim_srvinfo \
	-accelerator "Individual Process Info" \
	-command "process_info .os.menu"
.os.menu add separator
.os.menu add command -image aim_quesinfo \
	-accelerator "Queue List Info" \
	-command "queue_process_info .os.menu"
global aci_comm_type
if { $aci_comm_type == "IPC" } {
.os.menu add command -image aim_queueinf \
	-accelerator "Individual Queue Info" \
	-command "queue_info .os.menu"
}
.os.menu add separator
.os.menu add command -image aim_acitest \
	-accelerator "ACI Test UI" \
	-command "exec acitest &"

########################################################################
# Srv Menu Setup

menu .srv.menu -tearoff 0
.srv.menu add command -image aim_srv \
	-accelerator "Launch a Server" \
	-command "start_server %W"
.srv.menu add command -image aim_listen \
	-accelerator "Launch Listen" \
	-command "exec listen &"
.srv.menu add separator
.srv.menu add command -image aim_scrd \
	-accelerator "Launch TK Script Debugger" \
	-command "update_post scrd scrd srv 2"
menu .srv.menu.scrd_new_or_open -tearoff 0
bind .srv.menu.scrd_new_or_open <Leave> \
	".srv.menu.scrd_new_or_open unpost"
.srv.menu add separator
.srv.menu add command -image aim_nosrv \
	-accelerator "Exit Process" \
	-command "stop_server %W"
if { $aci_comm_type == "ACI" } {
.srv.menu add command -image aim_killsrv \
	-accelerator "Terminate Process" \
	-command "kill_server %W"
} else {
.srv.menu add command -image aim_queflush \
	-accelerator "Flush Queue" \
	-command "queue_flush %W"
}
if { $aci_comm_type == "ACI" } {
.srv.menu add command -image aim_noqueue \
	-accelerator "Remove ACI name" \
	-command "remove_aci_name %W"
} else {
.srv.menu add command -image aim_noqueue \
	-accelerator "Delete Queue" \
	-command "queue_delete %W"
}
.srv.menu add separator
.srv.menu add command -image aim_struct \
	-accelerator "File Structure" \
	-command "show_struct_main from_ac"
.srv.menu add command -image aim_cmds \
	-accelerator "Command List" \
	-command "show_cmd_list_main %W"
.srv.menu add command -image aim_dvs \
	-accelerator "DV Snapshot" \
	-command "launch_viewdvs_main %W"
.srv.menu add command -image aim_logs \
	-accelerator "Logs" \
	-command "launch_viewlogs_main %W"

########################################################################
# Cmds Menu Setup

if {[ccm_cfg_files_exist .aimcmds]} {
		menubutton $base.cmds \
			-activebackground blue \
			-activeforeground yellow \
			-background #2985b6 \
			-borderwidth 1 \
			-foreground yellow \
			-menu "$base.cmds.menu" \
			-text Cmds
		grid $base.cmds -in $base.menubar  -row 1 -column 5
		menu $base.cmds.menu -tearoff 0
		ccm_load_menu_config .aimcmds $base.cmds.menu
}


########################################################################
# Help Menu Setup
global ashlSupportEmail ashlSupportWeb ashlSupportFAQ ashlSupportDoc ashlMantis
if {[array names env ASHLHOME] == ""} {
	set docLocation /opt/adventa/autoshell/prod/docs
} else {
	set docLocation "$env(ASHLHOME)/docs"
}

menu .help.menu -tearoff 0
.help.menu add command -label "AutoShell Knowledge Base" \
	-command "launch_url $ashlSupportFAQ"
.help.menu add command -label "Submit AutoShell Support Request" \
	-command "launch_url $ashlMantis"

global tcl_platform
if { $tcl_platform(platform) != "windows"} {
.help.menu add command -label "Send email to AutoShell Support" \
	-command "mail_message_win $ashlSupportEmail {}"
}
.help.menu add separator

.help.menu add command -label "Browse AutoShell Documentation" \
	-command "launch_url $ashlSupportDoc"

.help.menu add command -label "Browse AutoShell Web Site" \
	-command "launch_url $ashlSupportWeb"
.help.menu add separator

.help.menu add command -label "About AutoShell Commander" \
	-command "show_about"

proc show_about {} {
	global ashlSupportWeb ashlSupportEmail release_version copyright
	set msg		"                 AutoShell Commander \n"
	append msg	"                      Version $release_version\n\n"
	append msg  [regsub -all \n $copyright " "]
	append msg  "\n\nFor support and maintence contact:\n"
	append msg	"   $ashlSupportEmail\n\n\n"
	append msg	"Original author: Karl Minor\n"
	tk_messageBox -title "About AutoShell Commander" -message $msg -type ok -icon info -parent .serverlist
	
}

proc launch_url {url} {
	global aim_options
	eval exec $aim_options(browsercmd) $url	&
}

proc mail_message_win {emailaddr attachmenttext} {
	global aim_sendmsg
	toplevel .sendmsg
	sendmsg_ui .sendmsg		
	
	set aim_sendmsg(emaildest) $emailaddr
	.sendmsg.codedata insert 1.0 $attachmenttext
}

proc mail_message {w mode} {
	global aim_sendmsg env aci_comm_type
	set emaildest $aim_sendmsg(emaildest)
	set sendername $aim_sendmsg(sendername)
	set messagetext [$w.messagetext get 1.0 end]
	set codedata [$w.codedata get 1.0 end]
	set msg "Subject: AutoShell question\n\n"
	append msg "Question submitted via AC "
	append msg "(version [get_astk_version]) by\n"
	if { "$aci_comm_type" == "ACI" } {
	append msg "$sendername logged into [info hostname].\n\n"
	} else {
	append msg "$sendername logged in as $env(LOGNAME).\n\n"
	}
	append msg "Message Text:\n"
	append msg "--------------------------------------\n"
	append msg "[string trim $messagetext]\n"
	append msg "--------------------------------------\n\n"
	append msg "Code or Data:\n"
	append msg "--------------------------------------\n"
	append msg "[string trim $codedata]\n"
	append msg "--------------------------------------\n"
	if {$mode=="send"} {
	        set rc [catch {
			exec echo $msg \| rmail $emaildest
		} errorstr]
		if {$rc!=0} {
			tk_messageBox -message \
				"Message send failed:\n$errorstr" -type ok -icon warning -parent .serverlist
		} else {
			destroy $w
		}
	} elseif {$mode=="file"} {
		set filename [newfileselect $w save]
		if {[string trim $filename]==""} {
			return 
		}	
		set fid [open $filename w]
		puts $fid $msg
		close $fid
		destroy $w
	}
}

########################################################################
bind $base.serverlist <Double-Button-1> {+start_session}
bind $base.serverlist <ButtonPress-1> {+pickup_name %W %x %y}
bind $base.serverlist <B1-Motion> {drag_name %X %Y}
bind $base.serverlist <B1-Leave> {break}
bind $base.serverlist <ButtonRelease-1> {+drop_name %W %x %y}

bind $base.serverlist <ButtonPress-3> {

	# Check for a label: locals remotes zombies
    set cs [%W index @%x,%y]
    if {$cs!=""} {
        set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
		# If it is none of these, go ahead and select it
		if {[string compare $cn locals] &&
			[string compare $cn remotes] &&
			[string compare $cn zombies]} {
	
		    if {[winfo exists %W]} {
				%W selection clear 0 end
				%W selection set [%W index @%x,%y]
		    }

			set px [winfo pointerx %W]
			set py [winfo pointery %W]
			tk_popup .srv.menu [expr $px + 10] [expr $py + 10]
		}
	}
}
proc drag_name {x y} {
	global dragged_name
	if {![winfo exists .dragwin]} {
		toplevel .dragwin
		label .dragwin.text -text $dragged_name -bg #FFFF99 
		pack .dragwin.text
		wm geometry .dragwin +$x+$y
		wm overrideredirect .dragwin 1
		update idletasks
		raise .dragwin
	} else {
		wm geometry .dragwin +$x+$y
	}
	
}
proc pickup_name {W x y} {
	global dragged_name

	set cs [$W index @$x,$y]
	if {$cs!=""} {
		set cn [expandable_listbox_get .serverlist [lindex $cs 0]]
		set dragged_name $cn
	}
}
proc drop_name {W x y} {
	global dragged_name sessnames sessids
	#puts [$W index @$x,$y]
	if {[winfo exists .dragwin]} {
		destroy .dragwin
	}
	if {[lsearch [array names sessids] $dragged_name]>=0 && [winfo exists $sessids($dragged_name)]} {
		raise $sessids($dragged_name)
		focus $sessids($dragged_name).inputframe.commandentry
		return
	}
	set px [winfo pointerx $W]
	set py [winfo pointery $W]
	set hits [winfo containing -displayof $W $px $py]
	#puts "hits=$hits"
	if {[llength $hits]>0} {
		set tophit [lindex $hits 0]
		set hitwin [winfo toplevel $tophit]
		#puts "tophit=$tophit hitwin=$hitwin"
		if {[lsearch [array names sessnames] $hitwin]>=0 && \
		    [lsearch [array names sessids] $dragged_name]==-1} {
			#puts "dropping $dragged_name into $hitwin"
			set_server_name $hitwin $dragged_name
			raise $hitwin
			focus $hitwin.inputframe.commandentry
		}
	}
#	foreach id [array names sessids] {
#		set x1 [winfo rootx $sessids($id)]
#		set y1 [winfo rooty $sessids($id)]
#		set x2 [expr [winfo rootx $sessids($id)] + [winfo width $sessids($id)]]
#		set y2 [expr [winfo rooty $sessids($id)] + [winfo height $sessids($id)]]
#		puts "x1=$x1 y1=$y1 x2=$x2 y2=$y2 px=$px py=$py"
#		if {$px>$x1 && $px<$x2 && $py>$y1 && $py<$y2} {
#			#puts "dropping $dragged_name into $sessids($id)"
#			lappend receptacles $sessids($id)
#		}
#	}
#	if {[llength $receptacles]>0} {
#		puts "receptacles=$receptacles"
#		unset dragged_name
#	}
}


global env aci_comm_type
set hname [lindex [split [info hostname] .] 0]

if { $aci_comm_type == "ACI" } {
	set uname ""
	wm title . "AC:$hname"
	wm iconname . "AC:$hname"
} else {
	set uname $env(LOGNAME)
	wm title . "AC:$hname:$uname"
	wm iconname . "AC:$hname:$uname"
}
$base.acname configure -text [dv_get name]
#. configure -bg #2985B6
#foreach child [winfo children .] {
#	catch {$child configure -highlightbackground #2985B6}
#	if {[winfo class $child]!="Label"} {
#		$child configure -background #CCCCCC
#	}
#	if {[winfo class $child]=="Menubutton"} {
#		$child configure -background #2985B6 -foreground yellow
#	}

proc config_user_icons {} {
	global aim_options aim_usericons
    set x [expr [winfo pointerx .] - 100]
    set y [expr [winfo pointery .] - 400]

	toplevel .usericons
    wm geometry .usericons +$x+$y

	label .usericons.c0 -text "C1" -bg black -fg white 
	grid .usericons.c0 -row 0 -column 0 -sticky w -padx 2
	label .usericons.c1 -text "C2" -bg black -fg white
	grid .usericons.c1 -row 0 -column 1 -sticky w -padx 2
	label .usericons.c2 -text "Off" -bg black -fg white
	grid .usericons.c2 -row 0 -column 2 -sticky w -padx 2
	label .usericons.c3 -text "Image" -bg black -fg white
	grid .usericons.c3 -row 0 -column 3 -sticky w -padx 2
	label .usericons.c4 -text "Action" -bg black -fg white
	grid .usericons.c4 -row 0 -column 4 -sticky w -padx 2
	set fnum 1
	restore_user_icons
	foreach child [winfo children .] {
		#puts "child=$child"
		set class [winfo class $child]
		if {$class=="Menubutton"} {
			set menu [$child cget -menu]
			set i 0
			set image [$menu type $i]
			while {$i<=[$menu index end]} {
				#puts "i=$i fnum=$fnum"
				set type [$menu type $i]	
				if {$type=="command"} {
					set image [$menu entrycget $i -image]
					if {$image!="" && \
					    $image!="refresh" && \
					    $image!="session"} {
						frame_user_icons $menu $i \
							$fnum $image
						incr fnum
					}	
				}
				incr i
			} 
		}
	}
	#puts "restore_user_icons"
	restore_user_icons
	button .usericons.ok -text OK \
		-command "store_user_icons; destroy .usericons; apply_user_icons"
	grid .usericons.ok -row $fnum -column 0 -columnspan 5
	#puts "done"
}

proc store_user_icons {} {
	global aim_options aim_usericons
	set aim_options(usericons1) {}
	set aim_options(usericons2) {}
	foreach index [array names aim_usericons "*,loc"] {
		set image [lindex [split $index ,] 0]
		set cmd $aim_usericons($image,cmd)			
		set loc $aim_usericons($image,loc)			
		if {$loc==".usericons1"} {
			lappend aim_options(usericons1) [list $image $cmd]
		} elseif {$loc==".usericons2"} {
			lappend aim_options(usericons2) [list $image $cmd]
		}
	}
}

proc restore_user_icons {} {
	global aim_options aim_usericons
	foreach item $aim_options(usericons1) {
		set aim_usericons([lindex $item 0],loc) .usericons1
		set aim_usericons([lindex $item 0],cmd) [lindex $item 1]
	} 
	foreach item $aim_options(usericons2) {
		set aim_usericons([lindex $item 0],loc) .usericons2
		set aim_usericons([lindex $item 0],cmd) [lindex $item 1]
	} 
}

proc frame_user_icons {menu i fnum image} {
	global small_images
	if {![info exists small_images($image)]} {
		set small_images($image) [image create photo small$image]
		$small_images($image) copy $image -subsample 2
	}
	global aim_options aim_usericons
	set cmd [$menu entrycget $i \
		-command]
	set acc [$menu entrycget $i \
		-accelerator]
	set aim_usericons($image,cmd) $cmd
	set aim_usericons($image,loc) none
	radiobutton .usericons.u1$fnum \
		-variable aim_usericons($image,loc) \
		-value .usericons1 
	#puts "grid .usericons.u1$fnum -row $fnum -column 0"
	grid .usericons.u1$fnum -row $fnum -column 0 -sticky w
	radiobutton .usericons.u2$fnum \
		-variable aim_usericons($image,loc) \
		-value .usericons2 
	grid .usericons.u2$fnum -row $fnum -column 1 -sticky w
	radiobutton .usericons.no$fnum \
		-variable aim_usericons($image,loc) \
		-value none 
	grid .usericons.no$fnum -row $fnum -column 2 -sticky w
	label .usericons.img$fnum -image $small_images($image)
	grid .usericons.img$fnum -row $fnum -column 3 -sticky w
	label .usericons.acc$fnum -text $acc
	grid .usericons.acc$fnum -row $fnum -column 4 -sticky w
}

proc apply_user_icons {} {
	global aim_options
	foreach child [winfo children .usericons1] {
		destroy $child
	}
	foreach child [winfo children .usericons2] {
		destroy $child
	}
	foreach icon $aim_options(usericons1) {
		button .usericons1.[lindex $icon 0] -image [lindex $icon 0] \
			-command [lindex $icon 1] -height 24 -width 24
		pack .usericons1.[lindex $icon 0]
	}
	foreach icon $aim_options(usericons2) {
		button .usericons2.[lindex $icon 0] -image [lindex $icon 0] \
			-command [lindex $icon 1] -height 24 -width 24
		pack .usericons2.[lindex $icon 0]
	}
}

proc apply_color_scheme {} {
        global aim_options
        . configure -bg $aim_options(background)
        foreach child [winfo children .] {
		set class [winfo class $child]
		if {$class=="Button" || \
		    $class=="Menubutton"} {
                	$child configure -fg $aim_options(foreground)
                	$child configure -bg $aim_options(background)
                	$child configure -activeforeground \
				$aim_options(background)
                	$child configure -activebackground \
				$aim_options(foreground)
                	$child configure -highlightbackground \
				$aim_options(background)
#		} elseif {$class=="Label"} {
#                	$child configure -fg $aim_options(foreground)
#                	$child configure -bg $aim_options(background)
#                	$child configure -highlightbackground \
#				$aim_options(background)
		} elseif {$class=="Frame"} {
                	$child configure -bg $aim_options(background)
		}
        }
        foreach child "[winfo children .usericons1] \
			[winfo children .usericons2]" {
               	$child configure -highlightbackground \
			$aim_options(background)
	}
}

proc apply_admin_mode {base} {
	global aim_options
	if {[info exists aim_options(adminmode)] && $aim_options(adminmode)} {
		grid forget $base.edit
		$base.srv.menu delete 0 3
	}
}



#config_user_icons
apply_user_icons
apply_color_scheme
apply_admin_mode $base
	
global aim_info
set aim_info(normalcursor) left_ptr
