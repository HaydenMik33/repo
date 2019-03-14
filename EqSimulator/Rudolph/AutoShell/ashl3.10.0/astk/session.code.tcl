
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: session.code.tcl,v 1.15 2000/08/02 20:22:21 karl Exp $
# $Log: session.code.tcl,v $
# Revision 1.15  2000/08/02 20:22:21  karl
# Fixed sys>waiting entry leak.
#
# Revision 1.14  2000/07/07  21:53:11  karl
# Made icon and window titles more concise.
# Added "closest match" to display reply/data messages in case the
# sender name doesn't match the original destination (aci_out/aci_in).
# Fixed problem with selection colors.
#
# Revision 1.13  1999/08/24  15:18:40  karl
# Added "are you sure" at exit command to servers.
#
# Moved an_escquotes proc to fileselect.tcl
#
# Revision 1.12  1999/06/02  17:36:02  karl
# Moved some procs to aim.code.tcl to support buttons copied there.
#
# Revision 1.11  1999/05/13  22:23:08  karl
# Added code to cause AC talk window to show incoming command messages.
#
# Revision 1.10  1999/05/11  23:14:47  karl
# Added code to turn off command completion at the first mouse click in
# the command entry field..
#
# Revision 1.9  1999/03/17  21:42:59  karl
# Added code to deiconify window after raising in case it was minimized.
#
# Revision 1.8  1999/02/22  20:01:27  karl
# Fixed srv_data and added srv_reply so that reply/data messages
# containing ctxt aren't lost.
#
# Revision 1.7  1999/01/08  22:34:14  karl
# Added an_escquotes proc to fix bug where command history entries
# containing quotes were getting truncated.
#
# Revision 1.6  1998/12/11  21:13:40  karl
# Added code to erase a server's command history.
# Changed to not use server name as widget name and allow changing servers
# in a session.
# Added code to support "c srvname" and drag-n-drop to change session server.
# Added ! to turn on command completion and !! to repeat previous cmd.
#
# Revision 1.5  1998/10/20  21:55:54  karl
# Changed so eraser button only erases results, not commands.
#
# Revision 1.4  1998/09/01  19:03:09  karl
# Added erase_output, string_expression, shell_command, procs for new buttons.
# Added asis and asdatareply options when sending messages.
# Added srv_data hook command to catch incoming messages with messed up
# context.
#
# Revision 1.3  1998/08/05  22:11:15  karl
# Added code to handle servers with periods in their name.
#
# Revision 1.2  1998/07/17  20:55:48  karl
# Fixed result trimming to trim currenv parm if AC is run under tcltksrv.
#
# Revision 1.1  1998/07/16  15:38:55  karl
# Initial revision
#

proc load_session_hist {wn srvname {mode pull}} {
	global env 
	if {[file exists $env(HOME)/.aimhist.log]} {
		set fid [open $env(HOME)/.aimhist.log r]
		set prevcmd ""
		if {$mode=="erase"} {
			set nfid [open $env(HOME)/.aimhist.tmp w]
		}
		while {![eof $fid]} {
			set ln [gets $fid]
			if {$ln==""} {
				continue
			}
			set colonloc [string first ": " $ln]
			set histname [string range $ln 0 [expr $colonloc - 1]]	
			set histcmd [string range $ln [expr $colonloc + 2] end]	
			#puts "histname=$histname histcmd=$histcmd"
			if {$mode=="erase"} {
				if {$srvname!=$histname} {
					puts $nfid $ln
				}
			} else {
				if {$srvname==$histname && $histcmd!=$prevcmd \
					&& [string compare $histcmd ""]!=0 } {
					add_command_to_output $wn $histcmd
					set prevcmd $histcmd
				}
			}
			
		}
		close $fid
		if {$mode=="erase"} {
			close $nfid
			file delete $env(HOME)/.aimhist.log
			file rename $env(HOME)/.aimhist.tmp \
				$env(HOME)/.aimhist.log
		}
	}
}

proc set_server_name {wn newname} {

	#puts "setting server name to $newname"
		global sessnames sessids aci_comm_type
		set currname $sessnames([winfo toplevel $wn])
		set sessnames([winfo toplevel $wn]) $newname
		unset sessids($currname)
		set sessids($newname) [winfo toplevel $wn]
	set base [winfo toplevel $wn]
	global name  env tcl_platform
	#regsub -all {=} $newname {.} newname
	if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
	set uname "AC"
	} else {
	set uname $env(LOGNAME)
	}
	set hname [lindex [split [info hostname] .] 0]
	# This is specialized for the Windows standalone version of talk -- on
	# windows, seeing the hostname and username is kind of redundant.
	if { [array names env -exact STANDALONE]!="" && $env(STANDALONE) == true } {
		if {[.serverlist size] > 0} {
			.serverlist delete 0
		}
		.serverlist insert 0 [append a " " "$newname"]
		.serverlist selection clear 0 end
		.serverlist selection set 0
		wm title $base "$newname"
	} else {
		wm title $base "$newname:$hname:$uname"
	}
	wm iconname $base "$newname:$hname:$uname"
	
	load_session_hist $wn $newname
	#regsub -all {=} $wn {.} wn 
	
	after 500 check_server $wn $newname
	
}
proc {check_server} {wn newname} {
	global aci_comm_type myHostname
	# Send a 'help' and invoke talk on the response
	if { "$aci_comm_type" == "IPC" } {
		an_msgsend 0 $newname help -an_reply_cb "set_server_name2 wn=$wn"
	} else {
		if { [catch { an_msgsend 0 $newname help -an_reply_cb "set_server_name2 wn=$wn" } errcode] } { 
			# If error and this is the ACI version, make nice error message.
			global aim_qinfo
			set servername [unmangle_aci_name $newname]
			if [info exists aim_qinfo($servername,id)] {
				set inetaddr $aim_qinfo($servername,id)
				set hostname [an_inetaddrtoname $inetaddr ]
				# save it for future use
				set aim_qinfo($servername,hn) $hostname
        		
				set button [tk_messageBox -message \
				"Unable to contact $servername.\nIt was last started on host $hostname ($inetaddr)\n\nWould you like to remove the name?" \
				-type yesno -icon warning -parent $wn]
			} else {
				set button [tk_messageBox -message \
				"Unable to contact $servername.\n\nWould you like to remove the ACI name?" \
				-type yesno -icon warning -parent $wn] 
			}
			if {$button == "yes"} {
				catch {exec aci_send -N $servername -w 1 $myHostname noop}
				cancel_session $wn
				after 1000
				refresh_serverlist
			}
		}
	}
}

an_proc set_server_name2 {} {} {} {
	#puts "anparms bef  $anparms"
#	foreach tag "fr to reply command comment ctxt an_form wn" {
#		set tagpos [lsearch $anparms "$tag *"]
#		if {$tagpos!=-1} {
#			set anparms [lreplace $anparms $tagpos $tagpos]
#		}
#	}
	an_delete_cb $currenv
	#puts "anparms aft  $anparms"
}

proc add_command_to_output {wn cmdtext} {
	global name
	[winfo toplevel $wn].outputframe.output configure -state normal
	[winfo toplevel $wn].outputframe.output insert end "$name: " mynames
	[winfo toplevel $wn].outputframe.output insert end "$cmdtext\n" commands
	[winfo toplevel $wn].outputframe.output see end
	[winfo toplevel $wn].outputframe.output configure -state disabled 
}

proc erase_output {wn {mode results}} {
	[winfo toplevel $wn].outputframe.output configure -state normal
	set ranges [[winfo toplevel $wn].outputframe.output tag ranges results]
	set len [llength $ranges]
	while {$len>0} {
		set start [lindex [split [lindex $ranges [expr $len-2]] .] 0].0
		set end [lindex $ranges [expr $len-1]]
		set ranges [lrange $ranges 0 [expr $len-3]]
		[winfo toplevel $wn].outputframe.output delete $start $end	
		set len [llength $ranges]
	}
	if {$mode=="all"} {
		set ranges [[winfo toplevel $wn].outputframe.output tag ranges commands]
		set len [llength $ranges]
		while {$len>0} {
			set start [lindex [split [lindex $ranges \
				[expr $len-2]] .] 0].0
			set end [lindex $ranges [expr $len-1]]
			set ranges [lrange $ranges 0 [expr $len-3]]
			[winfo toplevel $wn].outputframe.output delete $start $end	
				set len [llength $ranges]
		}
	
		global sessnames
		set srvname $sessnames([winfo toplevel $wn])
		load_session_hist $wn $srvname erase
	}
	#[winfo toplevel $wn].outputframe.output delete 1.0 end
	[winfo toplevel $wn].outputframe.output configure -state disabled 
}

proc string_expression {wn} {
	set cmdtext [string trim [[winfo toplevel $wn].inputframe.commandentry \
		get 1.0 end]]
	if {[string compare $cmdtext ""]==0} {
		repeat_command $wn 1
		set cmdtext [string trim [[winfo toplevel $wn].inputframe.commandentry \
			get 1.0 end]]
		if {[string compare $cmdtext ""]==0} {
			return
		}
	}
	[winfo toplevel $wn].inputframe.commandentry delete 1.0 end
	[winfo toplevel $wn].inputframe.commandentry mark set insert 1.0
	add_command_to_output $wn $cmdtext
	set rs [an_strex $cmdtext]
	[winfo toplevel $wn].outputframe.output configure -state normal
	#[winfo toplevel $wn].outputframe.output insert end "$sn: " srvnames
	[winfo toplevel $wn].outputframe.output insert end "[string trim $rs "\n"]\n" \
		results
	[winfo toplevel $wn].outputframe.output see end
	[winfo toplevel $wn].outputframe.output configure -state disabled 
}

proc shell_command {wn} {
	set cmdtext [string trim [[winfo toplevel $wn].inputframe.commandentry \
		get 1.0 end]]
	if {[string compare $cmdtext ""]==0} {
		repeat_command $wn 1
		set cmdtext [string trim [[winfo toplevel $wn].inputframe.commandentry \
			get 1.0 end]]
		if {[string compare $cmdtext ""]==0} {
			return
		}
	}
	[winfo toplevel $wn].inputframe.commandentry delete 1.0 end
	[winfo toplevel $wn].inputframe.commandentry mark set insert 1.0
	add_command_to_output $wn $cmdtext
	
	if {[catch {set rs [eval exec $cmdtext]}]} {
		global errorInfo
		set rs [lindex [split $errorInfo "\n"] 0]
	}
	[winfo toplevel $wn].outputframe.output configure -state normal
	#[winfo toplevel $wn].outputframe.output insert end "$sn: " srvnames
	[winfo toplevel $wn].outputframe.output insert end "[string trim $rs "\n"]\n" \
		results
	[winfo toplevel $wn].outputframe.output see end
	[winfo toplevel $wn].outputframe.output configure -state disabled 
	
}

proc send_message {wn mode} {
	#puts "mode=$mode"
	global sessions aim_options comp_flags
	#puts "Inside send_message"
	#global sessids sessnames
	#foreach el [array names sessids] {
	#	puts "sessids($el)=$sessids($el)"
	#}
	#foreach el [array names sessnames] {
	#	puts "sessnames($el)=$sessnames($el)"
	#}
	if {[info exists aim_options(cmdcompletion)] &&
		$aim_options(cmdcompletion)} {
		set comp_flags([winfo toplevel $wn]) 1
	} else {
		set comp_flags([winfo toplevel $wn]) 0
	}
	#regsub -all {=} $wn {.} wn
	#set srvname [string range [winfo toplevel $wn] \
	#	[string length ".session"] end]
	global sessnames sessids
#	foreach el [array names sessnames] {
#		puts "sessnames($el)=$sessnames($el)"
#	}
#	foreach el [array names sessids] {
#		puts "sessids($el)=$sessids($el)"
#	}
	set srvname $sessnames([winfo toplevel $wn])
	#puts "srvname=$srvname"
	set cmdtext [string trim [[winfo toplevel $wn].inputframe.commandentry \
		get 1.0 end]]
	#puts " srvname $srvname cmd $cmdtext wn $wn"
	if {[string compare $cmdtext ""]==0} {
		repeat_command $wn 1
		set cmdtext [string trim [[winfo toplevel $wn].inputframe.commandentry \
			get 1.0 end]]
		if {[string compare $cmdtext ""]==0} {
			return
		}
	}
	[winfo toplevel $wn].inputframe.commandentry delete 1.0 end
	[winfo toplevel $wn].inputframe.commandentry mark set insert 1.0
	if {[string range $cmdtext 0 1]=="c "} {
		set newname [string range $cmdtext 2 end]
		#global sessnames sessids
		#set sessnames([winfo toplevel $wn]) $newname
		#unset sessids($srvname)
		#set sessids($newname) [winfo toplevel $wn]
		set_server_name [winfo toplevel $wn] $newname
		return
	} 
	#regsub -all {=} $srvname {.} srvname
	#puts " srv $srvname cmd $cmdtext"
	if {$mode=="asdatareply"} {
		#puts "Sending asdatareply: $cmdtext"
		an_msgsend 0 $srvname $cmdtext -notcmd
	} elseif {$mode=="asis"} {
		#puts "Sending asis: $cmdtext"
		set list [an_msg_to_tcl $cmdtext]
		set toloc [lsearch $list "to *"]
		set frloc [lsearch $list "fr *"]
		if {$frloc>=0} {
			set srvname [lindex [lindex $list $toloc] 1]
			#puts "changed srvname to $srvname"
		}
		if {[lsearch $list "do *"]>=0} {
			#puts "Sending commmand"
			an_msgsend 0 $srvname $cmdtext -raw
		} else {
			#puts "Sending non-commmand"
			an_msgsend 0 $srvname $cmdtext -raw
		}
	} else {
		#puts "Sending normal commmand to $srvname: $cmdtext"
		scan $cmdtext "%s%s" firstword secondword
		if {$firstword=="exit"} {
			set msg "Are you sure you want to terminate the "
			append msg "process named $srvname?"
			set rc [tk_messageBox -type yesno -icon warning -message $msg -parent $wn]
			if {$rc=="no"} {
				return
			}
		}
		an_msgsend 0 $srvname $cmdtext
	}
	an_cmd lg name=aimhist msg=\"$srvname: [an_escquotes $cmdtext]\"
	add_command_to_output $wn $cmdtext
}

#proc an_escquotes {str} {
#	set len [string length $str]
#	set newstr ""
#	for {set n 0} {$n<$len} {incr n} {
#		set c [string index $str $n]
#		if {$c=="\"" || $c=="\\"} {
#			append newstr "\\"
#		}
#		append newstr $c
#	}
#	return $newstr
#}

proc closest_wn {sn} {
	global sessnames sessids
	#puts "sn=$sn"
	set prefix [lindex [split $sn _] 0]
	#puts "prefix=$prefix"
	set matches [array names sessids "$prefix*"]
	#puts "matches=$matches"
	#puts "array names sessids=[array names sessids]"
	if {[llength $matches]>0} {
		#puts "returning $sessids([lindex $matches 0])"
		return $sessids([lindex $matches 0])
	}
	if {[array size sessids]>0} {
		#puts "returning $sessids([lindex [array names sessids] 0])"
		return $sessids([lindex [array names sessids] 0])
	}
}

an_proc srv_reply {} {} {} {
	global sessnames sessids
	#puts "Inside srv_reply"
	#foreach el [array names sessids] {
	#	puts "sessids($el)=$sessids($el)"
	#}
	#foreach el [array names sessnames] {
	#	puts "sessnames($el)=$sessnames($el)"
	#}
	if {[info exists fr]} {
		set sn $fr
		if {[info exists sessids($sn)]} {
			set wn $sessids($sn)
		} else {
			set wn [closest_wn $sn]
		} 
		#puts "wn=$wn"
		an_display_results "$an_form wn=$wn sn=$sn" $currenv	
	}
}

an_proc srv_data {} {} {} {
	global sessnames sessids
	#puts "Inside srv_data"
	#foreach el [array names sessids] {
	#	puts "sessids($el)=$sessids($el)"
	#}
	#foreach el [array names sessnames] {
	#	puts "sessnames($el)=$sessnames($el)"
	#}
	if {[info exists fr]} {
		set sn $fr
		if {[info exists sessids($sn)]} {
			set wn $sessids($sn)
		} else {
			set wn [closest_wn $sn]
		}
		an_display_results "$an_form wn=$wn sn=$sn" $currenv	
	}
}

an_proc srv_command {} {} {} {
	global sessnames sessids
	if {[info exists fr]} {
		set sn $fr
		if {[info exists sessids($sn)]} {
			set wn $sessids($sn)
		}
		an_display_results "$an_form wn=$wn sn=$sn" $currenv	
	}
}

proc trim_extra {str} {
	set rs [string trim $str]
	set ls [string last " " $rs]
	while {[string match " currenv=*" [string range $rs $ls end]] ||
		[string match " sn=*" [string range $rs $ls end]] ||
		[string match " wn=*" [string range $rs $ls end]]} {
		set rs [string trim [string range $rs 0 [expr $ls - 1]]]
		set ls [string last " " $rs]
	}
	return $rs
}

an_proc display_results {} {} {} {
	#puts "wn=$wn sn=$sn"
	if {![winfo exists $wn]} {
		return
	}
	set rs [trim_extra $an_form]
	regsub -all "\n\n" $rs "\n" rs
	#an_cmd lg name=$sn msg=\"$rs\"
	[winfo toplevel $wn].outputframe.output configure -state normal
	[winfo toplevel $wn].outputframe.output insert end "$sn: " srvnames
	[winfo toplevel $wn].outputframe.output insert end "$rs\n" \
		results
	[winfo toplevel $wn].outputframe.output see end
	[winfo toplevel $wn].outputframe.output configure -state disabled 
}

proc cancel_session {wn} {
	global sessnames sessids env
	set nm $sessnames([winfo toplevel $wn])
	unset sessnames([winfo toplevel $wn])
	unset sessids($nm)
	# STANDALONE is set only if you're running a windows NT talk session
	# outside of the AC.  If true, when you exit, we want to destroy the 
	# whole tcltksrv.
	if {[array names env -exact STANDALONE]!="" && $env(STANDALONE) == true } {
		destroy .
	} else {
		destroy [winfo toplevel $wn]
	}
}

proc repeat_command {wn {editflag 0}} {
	set tagranges [[winfo toplevel $wn].outputframe.output tag ranges sel]
	#puts "tagranges=$tagranges"
	if {$tagranges!=""} {
		set line [[winfo toplevel $wn].outputframe.output get \
			[lindex $tagranges 0] \
			[lindex $tagranges 1]]
	} else {
		set tagranges [[winfo toplevel $wn].outputframe.output tag ranges commands]
		if {$tagranges!=""} {
			set length [llength $tagranges]
			set line [[winfo toplevel $wn].outputframe.output get \
				[lindex $tagranges [expr $length - 2]] \
				[lindex $tagranges [expr $length - 1]]]
		} else {
			set line ""
		}
	}

	set line [string trim $line]
	if {$line!=""} {
		set curname [string range [winfo toplevel $wn] \
			[string length ".session"] end]
		#puts "curname=$curname"
		#puts "line=$line"
		if [regexp {^[^ \n\t][^ \n\t]*: .*} $line] {
			set seploc [string first ": " $line]
			set cmd [string range $line [expr $seploc + 2] end]
#			set srvname [string range $line 0 [expr $seploc - 1]]
			set srvname $curname
		} else {
			set cmd $line
			set srvname $curname
		}
		if {$srvname!=$curname} {
			set_server_name $wn $srvname
		}
	
		[winfo toplevel $wn].inputframe.commandentry delete 1.0 end
		[winfo toplevel $wn].inputframe.commandentry insert 1.0 $cmd
		if {$editflag==0} {
			[winfo toplevel $wn].buttonframe2.send invoke
		}
	}
}


bind $base.inputframe.commandentry <Key-Return> "key_return %W; break"
bind $base.inputframe.commandentry <Key-BackSpace> "key_backspace %W"
bind $base.inputframe.commandentry <Key> {if [key_pressed %W %K %A] break}
bind $base.inputframe.commandentry <Key-exclam> {if [key_exclamation %W %K %A] break}
bind $base.inputframe.commandentry <Button-1> {
	global aim_options comp_flags
	set cmdtext [string trim [%W get 1.0 end]]
	if {[string length $cmdtext]>0}  {
		set comp_flags([winfo toplevel %W]) 0
	}
}

proc key_backspace {wn} {
	global aim_options comp_flags
	set tw [winfo toplevel $wn]
	set cmdtext [string trim [$tw.inputframe.commandentry \
		get 1.0 end]]
	if {[string length $cmdtext]==1} {
		if {[info exists aim_options(cmdcompletion)] &&
				$aim_options(cmdcompletion)} {
			set comp_flags($tw) 1
		} else {
			set comp_flags($tw) 0
		}
	}
}

proc key_return {wn} {
	send_message $wn ascommand
}

proc key_exclamation {wn key char} {
	global comp_flags
	set tw [winfo toplevel $wn]
	set cmdtext [string trim [$tw.inputframe.commandentry \
		get 1.0 end]]
	if {[string compare $cmdtext ""]==0} {
		if {[info exists comp_flags($tw)] && $comp_flags($tw)} {
			set ranges [$tw.outputframe.output tag ranges commands]
			set len [llength $ranges]
			set start [lindex $ranges [expr $len-2]]
			set end [lindex $ranges [expr $len-1]]
			set lastcmd [$tw.outputframe.output get  $start $end]
			#puts "lastcmd=$lastcmd"
			$tw.inputframe.commandentry delete 1.0 end
			$tw.inputframe.commandentry insert 1.0 [string trim $lastcmd]
			set comp_flags($tw) 0
			return 1
		} else {
			set comp_flags($tw) 1
			return 1
		}
	} else {
		return 0
		#catch {tkEntryInsert $wn $char}
	}
}

proc key_pressed {wn key char} {
	global comp_flags
	if {$char==""} {
		#catch {tkEntryInsert $wn $char}
		return 0
	}
	if {!$comp_flags([winfo toplevel $wn])} {
		#catch {tkEntryInsert $wn $char}
		return 0
	}
	#puts "wn=$wn"
	if {[$wn tag ranges sel]!=""} {
		set cmdtext [string trim [[winfo toplevel $wn].inputframe.commandentry \
			get 1.0 sel.first]]
	} else {
		set cmdtext [string trim [[winfo toplevel $wn].inputframe.commandentry \
			get 1.0 end]]
	}
	#puts "cmdtext=$cmdtext"
	#puts "Looking for '$cmdtext$char'"
	#puts "searching $wn"
	set match [[winfo toplevel $wn].outputframe.output search -backwards $cmdtext$char end 1.0]
	if {$match!=""} {
		set iscmd [lsearch [[winfo toplevel $wn].outputframe.output tag \
			names $match] commands]
		set isbeg [lsearch [[winfo toplevel $wn].outputframe.output tag \
			names "$match - 1 chars"] mynames]
		#puts "match=$match iscmd=$iscmd isbeg=$isbeg"
		while {($iscmd==-1 || $isbeg==-1) && $match!=""} {
			set match [[winfo toplevel $wn].outputframe.output search \
				-backwards $cmdtext$char "$match - 1 chars" 1.0]
			if {$match!=""} {
				set iscmd [lsearch [[winfo toplevel \
					$wn].outputframe.output tag names $match] commands]
				set isbeg [lsearch [[winfo toplevel \
					$wn].outputframe.output tag names \
					"$match - 1 chars"] mynames]
			}
			#puts "match=$match iscmd=$iscmd isbeg=$isbeg"
		}
	}
	if {$match!="" && $iscmd!=-1 && $isbeg!=-1} {
		#puts "match=$match iscmd=$iscmd isbeg=$isbeg"
	#	[winfo toplevel $wn].outputframe.output tag remove sel 1.0 end
	#	[winfo toplevel $wn].outputframe.output tag add sel $match "$match lineend"
	#	[winfo toplevel $wn].outputframe.output see $match
		#puts "len=[string length $cmdtext$char]"
		set matchstr [[winfo toplevel $wn].outputframe.output get $match \
			"$match lineend"]
		#puts "matchstr=$matchstr"
		set len [string length $cmdtext$char]
		$wn delete 1.0 end
		$wn insert 1.0 $matchstr
		$wn tag remove sel 1.0 end
		$wn tag add sel 1.$len end
		return 1
	} else {
		return 0
		#catch {tkEntryInsert $wn $char}
	}
}

$base.outputframe.output tag configure sel -background #FFFF99

$base.outputframe.output tag configure commands -foreground black
$base.outputframe.output tag configure mynames -foreground red 

$base.outputframe.output tag configure srvnames -background white -foreground blue
$base.outputframe.output tag configure results -background white -foreground black 
$base.outputframe.output tag raise sel


$base.outputframe.output configure -state disabled

#bind $base.outputframe.output <Button-1> "[bind Text <Button-1>];
#	[bind Text <Double-Button-1>]; break"
bind $base.outputframe.output <Button-1> "[bind Text <Button-1>];
	[bind Text <Double-Button-1>]; break"
bind $base.outputframe.output <Double-Button-1> "[bind Text <Triple-Button-1>]; break"
bind $base.outputframe.output <Triple-Button-1> "repeat_command  $base.outputframe.output 0"

global sessnames tcl_platform
set srvname $sessnames([winfo toplevel $base])
#set srvname [string range $base \
#	[string length ".session"] end]
set_server_name $base $srvname
global env comp_flags
if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
	set uname "AC"
} else {
	set uname $env(LOGNAME)
}
set hname [lindex [split [info hostname] .] 0]
#wm title $base "[wm title $base] ($uname on $hname)"
global sessions
#tk_optionMenu $base.mtf.msgtype sessions($base,msgtype) \
#	"Command Mode" "Reply/Data Mode" "As Is Mode" 
#pack $base.mtf.msgtype -fill y -side left

$base configure -bg #2985B6
proc config_all {cont} {
	foreach child [winfo children $cont] {
		if {[winfo class $child]=="Frame"} {
	      		$child configure -background #2985B6
			config_all $child
		} else {
	      		$child configure -highlightbackground #2985B6
		}
	}
}
config_all $base

global aim_options
if {[info exists aim_options(cmdcompletion)] &&
	$aim_options(cmdcompletion)} {
	set comp_flags($base) 1
} else {
	set comp_flags($base) 0
}
