
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: cmdlist.code.tcl,v 1.13 2000/11/02 23:04:10 karl Exp $
# $Log: cmdlist.code.tcl,v $
# Revision 1.13  2000/11/02 23:04:10  karl
# Fixed bug that could cause extra "help" replies in Talk window
# when Command List button was pressed.
#
# Revision 1.12  2000/08/15 17:34:42  karl
# Fixed bug that would break the synwin template if a parameter named
# "syntax" existed in the syntax string.
#
# Revision 1.11  2000/08/02  20:03:24  karl
# Fixed sys>waiting leaks.
#
# Revision 1.10  2000/07/07  21:01:27  karl
# Added code to initialize command template window with arguments from the
# invocation of the command.
#
# Revision 1.9  1999/10/06  18:28:01  karl
# Fixed AC to use "tag" on document commands that request command help,
# to avoid problems with words in explain strings conflicting with routing tags.
#
# Revision 1.8  1999/05/13  22:26:39  karl
# Fixed bug that kept AC command send template windows from working.
#
# Revision 1.7  1999/05/11  23:07:24  karl
# Added aim_ prefix to variables passed around to fix conflict with
# tags named "srvname" or "cmdname".
#
# Revision 1.6  1999/03/17  21:38:12  karl
# Added code to trim syntax string before building command input window
# to avoid command showing as non-tagged parameter.
#
# Revision 1.5  1998/12/11  21:06:11  karl
# Fixed to not use server name as widget name.
#
# Revision 1.4  1998/10/20  21:49:20  karl
# Fixed to allow tagged form of "help" syntax results (java).
#
# Revision 1.3  1998/09/01  18:52:25  karl
# Added command_help procedure.
# Changed to remember command list level per session.
#
# Revision 1.2  1998/08/05  22:09:42  karl
# Added code to handle servers with periods in their name.
#
# Revision 1.1  1998/07/16  15:33:53  karl
# Initial revision
#
proc cancel_cmdlist {wn base} {
	destroy [winfo toplevel $wn]
	# clean up variable so you can redisplay the list
	global cmdlevel
    if [info exists cmdlevel($base)] {
	 unset cmdlevel($base)
    }
}

global sessions
trace variable sessions($base,cmdlevel) w "change_cmd_level $base"
proc change_cmd_level {base name1 name op} {
	global sessions
	set srvname [string range [winfo toplevel $base] \
		[string length ".cmdlist"] end]
	regsub -all {____} $srvname {.} srvname

	if [ catch {an_msgsend 0 $srvname "help level=$sessions($base,cmdlevel)" \
		-an_reply_cb "change_cmd_level2 wn=$base"} ] {
        tk_messageBox -message "Could not send 'help' message to $srvname." \
            -type ok -icon warning -parent $base
	}
}

an_proc change_cmd_level2 {} {} {} {
        foreach tag "fr to reply command comment ctxt currenv an_form wn" {
                set tagpos [lsearch $anparms "$tag *"]
                if {$tagpos!=-1} {
                        set anparms [lreplace $anparms $tagpos $tagpos]
                }
        }
	$wn.cmdlist delete 0 end
	foreach cmd $anparms {
		$wn.cmdlist insert end $cmd
	}
	#an_delete_cb $currenv
}

proc get_an_body1 {an_msg} {
         regsub "^fr=.+to=\[^ \n\t\]+" "$an_msg" "" an_msg
         regsub "reply=.+\$" "$an_msg" "" an_msg
         regsub "\n\n" "$an_msg" "\n" an_msg
         return $an_msg
}

proc command_help {wn} {
	set srvname [string range [winfo toplevel $wn] \
		[string length ".cmdlist"] end]
        set cs [[winfo toplevel $wn].cmdlist curselection]
        if {$cs==""} {
        tk_messageBox -message "You must select a command first!" \
            -type ok -icon warning -parent $wn
		return
	}
	set cmdname [[winfo toplevel $wn].cmdlist get [lindex $cs 0]]
	regsub -all {____} $srvname {.} srvname
	an_msgsend 0 $srvname "document command=$cmdname tag" \
		-an_reply_cb  "command_help2 aim_srvname=$srvname 
		aim_cmdname=$cmdname wn=$wn"
}

an_proc command_help2 {} {} {} {
	if {[info exists results] && [string length $results]>0} {
		set tmp $results
	} else {
		set tmp [split $an_form "\n"]
		set tmp [join [lrange $tmp 1 [expr [llength $tmp] - 2]] "\n"]
	}
	an_delete_cb $currenv
	scrl_dialog .c$aim_cmdname "cmdname Help" $tmp "" 0 OK -width 80 \
		-height 25 -bg white -font fixed
}

proc send_command {wn base} {
	#puts "send_command wn=$wn"
	set srvname [string range [winfo toplevel $wn] \
		[string length ".cmdlist"] end]
        set cs [[winfo toplevel $wn].cmdlist curselection]
        if {$cs==""} {
		return
	}
	set cmdname [[winfo toplevel $wn].cmdlist get [lindex $cs 0]]
	#regsub -all {____} $srvname {.} srvname

	global cmdlist
	an_msgsend 0 $srvname "help command=$cmdname" \
			-an_reply_cb  "send_command2 aim_srvname=$srvname aim_cmdname=$cmdname wn=$wn"

    # Reset command list so it won't be blank next time
    global cmdlevel
    unset cmdlevel($base)
}

an_proc send_command2 {} {} {} {
        set an_form [lindex [lindex $anparms [lsearch $anparms "an_form *"]] 1]
	if [info exists syntax] {
		set cmdsyntax $syntax
	} else {
	        set cmdsyntax [get_an_body1 $an_form]
	}
	an_delete_cb $currenv
	global cmdlist
	set cmdlist($aim_srvname,$aim_cmdname,syntax) $cmdsyntax
	regsub -all {____} $aim_srvname {.} aim_srvname
	show_command_template $aim_srvname $aim_cmdname $wn
	destroy [winfo toplevel $wn]
}

an_proc send_command3 {} {} {} {
        set an_form [lindex [lindex $anparms [lsearch $anparms "an_form *"]] 1]
        set cmddoc [get_an_body1 $an_form]
	#puts "cmddoc=$cmddoc"
	global cmdlist
	set cmdlist($srvname,$cmdname,doc) $cmddoc
	#puts "Ready to send command to $cmdname in $srvname using $cmddoc"
	show_command_template $aim_srvname $aim_cmdname $wn
	destroy [winfo toplevel $wn]
}

proc show_command_template {srvname cmdname wn} {
	global cmdlist sessids
	set input ""
	set fixedsyn [string trim \
		[as_syn_exceptions $cmdlist($srvname,$cmdname,syntax)]]
	if {[info exists sessids($srvname)]} {
		set swn $sessids($srvname)
		set fixedsyn [string trim \
				[as_syn_exceptions $cmdlist($srvname,$cmdname,syntax)]]
		#puts "searching $swn"
		set match [[winfo toplevel $swn].outputframe.output search -backwards "$cmdname " \
				end 1.0]
		if {$match!=""} {
				set iscmd [lsearch [[winfo toplevel $swn].outputframe.output tag \
					names $match] commands]
				set isbeg [lsearch [[winfo toplevel $swn].outputframe.output tag \
					names "$match - 1 chars"] mynames]
				#puts "match=$match iscmd=$iscmd isbeg=$isbeg"
				while {($iscmd==-1 || $isbeg==-1) && $match!=""} {
						set match [[winfo toplevel $swn].outputframe.output search \
						-backwards "$cmdname " "$match - 1 chars" 1.0]
						if {$match!=""} {
								set iscmd [lsearch [[winfo toplevel \
									$swn].outputframe.output tag names $match] commands]
								set isbeg [lsearch [[winfo toplevel \
									$swn].outputframe.output tag names \
									"$match - 1 chars"] mynames]
						}
						#puts "match=$match iscmd=$iscmd isbeg=$isbeg"
				}
		}
		if {$match!="" && $iscmd!=-1 && $isbeg!=-1} {
				#puts "found previous command: $match"
				set prevcmd [[winfo toplevel $swn].outputframe.output get $match \
					"$match lineend"]
				catch {set input [an_msg_to_tcl $prevcmd]}
		}
	}

	set outcmd [synwin $fixedsyn $input]
	#puts "$srvname: $outcmd"
	if {[string compare $outcmd ""]!=0} {
		
		regsub -all {\.} $srvname {____} srvname
		#puts "srvname=$srvname"
		global sessnames sessids
		set wid $sessids($srvname)
		$wid.inputframe.commandentry delete 1.0 end
		$wid.inputframe.commandentry insert 1.0 $outcmd
		$wid.buttonframe2.send invoke

#		an_msgsend 0 $srvname $outcmd \
#			-an_reply_cb "display_results wn=.session$srvname sn=$srvname"
	} 
}

proc as_syn_exceptions { syn_in } {
        return $syn_in
}
#puts " base $base"
bind $base.cmdlist <Double-Button-1> {
	[winfo toplevel %W].send invoke	
}
$base configure -bg #2985B6
proc config_all {cont} {
        foreach child [winfo children $cont] {
                if {[winfo class $child]=="Frame"} {
                        config_all $child
                } else {
                        $child configure -highlightbackground #2985B6
                }
        }
}
config_all $base
global cmdlevel
if {![info exists cmdlevel($base)]} {
	set sessions($base,cmdlevel) 1
	set cmdlevel($base) ""
	# Make window manager close call the cancel command too
	wm protocol $base WM_DELETE_WINDOW "cancel_cmdlist $base.button#1 $base"
}

