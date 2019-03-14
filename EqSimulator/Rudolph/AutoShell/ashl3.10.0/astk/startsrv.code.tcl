
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: startsrv.code.tcl,v 1.13 2000/12/14 23:03:49 karl Exp $
# $Log: startsrv.code.tcl,v $
# Revision 1.13  2000/12/14 23:03:49  karl
# Cleaned up and shortened server launching code.
#
# Revision 1.12  2000/11/02 23:12:48  karl
# Commented out annoying dialog at server start.
#
# Revision 1.11  2000/09/14 15:10:04  karl
# Added Clear button to clear out fields for new entries.
#
# Revision 1.10  2000/09/11  22:14:14  karl
# Improved server launcher so that most recent launches are at the
# opt of the list of previous launches in the pulldown, and the most
# recent launch is the default.   Also fixed launcher to stop watching
# a process before restarting it, to avoid annoying warning window.
#
# Revision 1.9  2000/08/11  20:20:50  karl
# Added working dir browse.
#
# Revision 1.8  2000/07/07  22:07:43  karl
# Added code to protect vertical bars in command-line commands.
#
# Revision 1.7  1999/08/24  15:32:37  karl
# Added launch_and_watch features and configurable editors.
#
# Revision 1.6  1999/03/17  21:49:09  karl
# Fixed bug that could occur if server launcher attributes contained variable
# references.
#
# Revision 1.5  1998/12/11  21:21:04  karl
# Added code to launch text and server editors.
#
# Revision 1.4  1998/10/20  22:02:44  karl
# Added code to automatically read in server launcher data when the name
# field is updated.  Added -DACxxx options to AC-launched java programs
# to make them easier for AC to find in the process list.  Added stab
# before launching a server. Fixed bug related to working directory in
# pre/post launch error check.  Added "Don't show this window next time"
# option to "has been executed" window.
#
# Revision 1.3  1998/09/01  19:11:07  karl
# Added dropdoen menu for existing .go scripts.
# Got rid of extra dialog and save-and-run.
# Added ability to launch wishsrv, aci_in, and java servers in addition to
# standard nullsrv-based servers.
# Added error.log and stdout/stderr check when starting processes.
#
# Revision 1.2  1998/07/16  20:57:37  karl
# Fixed tclstartup bug.  Added code to initialize srvname field if
# window name contains a name.
#
# Revision 1.1  1998/07/16  15:36:16  karl
# Initial revision
#
set sortlist {}
foreach goscript [glob -nocomplain ~/*.go] {
	file stat $goscript stat
	lappend sortlist "$stat(mtime) {$goscript}"
}
set sortlist [lsort -decreasing -dictionary $sortlist]
set choices {}
foreach el $sortlist {
	lappend choices [file tail [file rootname [lindex $el 1]]]
}

drop $base.dropframe.srvname -choices $choices \
	-variable aim_srvstart($base,srvname)
pack $base.dropframe.srvname -expand 1 -fill both
#bind $base.dropframe.srvname <FocusOut> {
global aim_srvstart
trace variable aim_srvstart($base,srvname) w "read_srv_data $base"
proc read_srv_data {wn name1 name2 op} {
	global aim_srvstart
	if {[file exists ~/.$aim_srvstart([winfo toplevel $wn],srvname).dta]} {
		source ~/.$aim_srvstart([winfo toplevel $wn],srvname).dta
		foreach el [array names aim_srvstart "tmp,*"] {
			#puts "setting aim_srvstart([winfo toplevel $wn],[lindex [split $el ,] 1])"
			set aim_srvstart([winfo toplevel $wn],[lindex [split $el ,] 1]) \
				$aim_srvstart($el)
		}
	}
}
proc clear_srv_data {rn} {
		global aim_srvstart
		set aim_srvstart($rn,logvol) 0
		set aim_srvstart($rn,startup) ""
		set aim_srvstart($rn,logsize) 64
		set aim_srvstart($rn,javaclass) ""
		set aim_srvstart($rn,username) ""
		set aim_srvstart($rn,cmdlinecmds) ""
		set aim_srvstart($rn,tclstartup) ""
		set aim_srvstart($rn,executable) ""
		set aim_srvstart($rn,workdir) ""
}

if {[llength $choices]} {
	set aim_srvstart($base,srvname) [lindex $choices 0]
}

proc ss_save {rn {postdialog 1}} {
	global aim_srvstart aim_options tcl_platform
	#puts "aim_srvstart($rn,srvname)=$aim_srvstart($rn,srvname)"
	#puts "aim_srvstart($rn,executable)=$aim_srvstart($rn,executable)"
	if {	![info exists aim_srvstart($rn,srvname)] ||
		[string trim $aim_srvstart($rn,srvname)]=="" ||
		![info exists aim_srvstart($rn,executable)] ||
		[string trim $aim_srvstart($rn,executable)]==""} {
		tk_dialog .err ERROR \
			"Server Name and Executable are required." \
			error 0 OK
		return -1
	}
	if { $tcl_platform(platform) == "windows" } {
		set fid [open ~/$aim_srvstart($rn,srvname).bat w]
	} else {
		set fid [open ~/$aim_srvstart($rn,srvname).go w]
		puts $fid ":"
		puts $fid "# Bourne-Shell Launcher for $aim_srvstart($rn,srvname)"
	}
	if {	[info exists aim_srvstart($rn,workdir)] &&
		[string trim $aim_srvstart($rn,workdir)]!=""} {
		puts $fid "cd $aim_srvstart($rn,workdir)"
	}
	set cmdstr ""
	#append cmdstr "nohup $aim_srvstart($rn,executable) "
	append cmdstr "$aim_srvstart($rn,executable) "
	#puts "aim_srvstart($rn,executable)='$aim_srvstart($rn,executable)'"
	if [string match "java*" [file tail $aim_srvstart($rn,executable)]] {
		if {![info exists aim_srvstart($rn,javaclass)] ||
		    $aim_srvstart($rn,javaclass)==""} {
			tk_dialog .err ERROR \
				"Java Class name is required." \
				error 0 OK
			return -1
		}
		append cmdstr "-DAC$aim_srvstart($rn,javaclass) $aim_srvstart($rn,javaclass) "
	}
	switch [file tail $aim_srvstart($rn,executable)] {
	    wishsrv {
		append cmdstr "-name $aim_srvstart($rn,srvname) "
	    }
	    aci_in {
		append cmdstr "-n$aim_srvstart($rn,srvname) "
	    }
	    default {
		append cmdstr "\"set name=$aim_srvstart($rn,srvname)\" "
	    }
	}
	if {	[info exists aim_srvstart($rn,startup)] &&
		[string trim $aim_srvstart($rn,startup)]!=""} {
		switch [file tail $aim_srvstart($rn,executable)] {
		    wishsrv {
			append cmdstr \
				"-file $aim_srvstart($rn,startup) "
		    }
		    aci_in {
		    }
		    default {
			append cmdstr \
				"\"set startup=$aim_srvstart($rn,startup)\" "
		    }
		}
	}
	if {	[info exists aim_srvstart($rn,tclstartup)] &&
		[string trim $aim_srvstart($rn,tclstartup)]!=""} {
		switch [file tail $aim_srvstart($rn,executable)] {
		    wishsrv {
			append cmdstr \
				"-file $aim_srvstart($rn,tclstartup) "
		    }
		    aci_in {
		    }
		    default {
			append cmdstr \
				"\"set tclstartup=$aim_srvstart($rn,tclstartup)\" "
		    }
		}
	}
	if {$aim_srvstart($rn,logvol)!=0 || $aim_srvstart($rn,logsize)!=64} {
		switch [file tail $aim_srvstart($rn,executable)] {
		    wishsrv {
			append cmdstr "-loglevel $aim_srvstart($rn,logvol) "
		    }
		    aci_in {
			append cmdstr "-l$aim_srvstart($rn,logvol) "
		    }
		    default {
			append cmdstr "\"log name=all level=$aim_srvstart($rn,logvol) size=$aim_srvstart($rn,logsize)\" "
		    }
		}
	}
	if {	[info exists aim_srvstart($rn,cmdlinecmds)] &&
		[string trim $aim_srvstart($rn,cmdlinecmds)]!=""} {
			set temp $aim_srvstart($rn,cmdlinecmds)
			regsub -all {\|} $temp {\|} temp
			append cmdstr "$temp "
	}
	if {	[info exists aim_srvstart($rn,username)] &&
		[string trim $aim_srvstart($rn,username)]!=""} {
		regsub -all {\\} $cmdstr {\\\\} cmdstr
		regsub -all {"} $cmdstr {\\"} cmdstr
		puts -nonewline $fid \
			"su $aim_srvstart($rn,username) -c 'sh -c "
		puts -nonewline $fid $cmdstr
		puts -nonewline $fid "'"
#		puts -nonewline $fid \
#			">>$aim_srvstart($rn,srvname).out 2>&1 &\"'"
	} else {
		puts -nonewline $fid $cmdstr
#		puts -nonewline $fid \
#			">>$aim_srvstart($rn,srvname).out 2>&1 &"
	}
	close $fid
	set fid [open ~/.$aim_srvstart($rn,srvname).dta w]
	puts $fid "global aim_srvstart"
	foreach el [array names aim_srvstart "$rn,*"] {
		set val $aim_srvstart($el)
		puts $fid "set aim_srvstart(tmp,[lindex [split $el ,] 1]) {$val}"
	}
	close $fid
	if {$postdialog}  {
		tk_dialog .info SAVED \
			"Bourne-Shell server start script stored to ~/$aim_srvstart($rn,srvname).go" "" 0 OK 
	}
	global env tcl_platform
	if { $tcl_platform(platform) == "windows" } {
		file attributes $env(HOME)/$aim_srvstart($rn,srvname).bat -readonly 0
	} else {
		exec chmod +x $env(HOME)/$aim_srvstart($rn,srvname).go
	}
	return 0
}

proc ss_save_and_start {rn} {
	global aim_srvstart aim_options
	if [ss_save $rn 0] {
		return
	}
	destroy [winfo toplevel $rn]
	#puts "looking for aim_srvstart($aim_srvstart($rn,srvname),pid)"
	if {[info exists aim_srvstart($aim_srvstart($rn,srvname),pid)]} {
		#puts "stopping watch of $aim_srvstart($aim_srvstart($rn,srvname),pid)"
		law_stopwatching $aim_srvstart($aim_srvstart($rn,srvname),pid)
	}
	#catch {exec stab $aim_srvstart($rn,srvname)}
	if {[catch {an_msgsend 0 $aim_srvstart($rn,srvname) "exit removeq" \
			-an_replycb "ss_save_and_start2 rn=$rn"}]} {
		ss_save_and_start3 $rn
		return
	}
	global exittimeout
	set exittimeout($rn) [after 2000 "ss_save_and_start3 $rn"]
}

an_proc ss_save_and_start2 {} {} {} {
	global exittimeout
	catch {after cancel $exittimeout($rn)}
	#puts "Inside ss_save_and_start2"
	ss_save_and_start3 $rn
}

proc ss_save_and_start3 {rn} {
	global aim_srvstart aim_options tcl_platform
	#puts "Inside ss_save_and_start3"
	if [info exists aim_srvstart($rn,workdir)] {
		set wd "$aim_srvstart($rn,workdir)/"
	} else {
		set wd ""
	}
	error_log_precheck
	diagfile_precheck ${wd}$aim_srvstart($rn,srvname).out
	if {$tcl_platform(platform) == "windows" } {
		set fid [open ~/$aim_srvstart($rn,srvname).bat r]
		set rc [scrl_dialog .confirm "Starting Server" "About to execute:\n \
	~/$aim_srvstart($rn,srvname).bat: \
	[read $fid]" warning 0 OK Cancel]
	} else {

		set fid [open ~/$aim_srvstart($rn,srvname).go r]
		set rc [scrl_dialog .confirm "Starting Server" "About to execute:\n \
	~/$aim_srvstart($rn,srvname).go: \
	[read $fid]" warning 0 OK Cancel]
	}
	if {$rc!=0} {
		return
	}
	if {$tcl_platform(platform) == "windows" } {
		set pid [launch_and_watch ~/$aim_srvstart($rn,srvname).bat]
	} else {
		set pid [launch_and_watch ~/$aim_srvstart($rn,srvname).go]
	}

	if [diagfile_postcheck ${wd}$aim_srvstart($rn,srvname).out] {
		return
	}
	if [error_log_postcheck] {
		return
	}
	#puts "recording aim_srvstart($aim_srvstart($rn,srvname),pid)=$pid"
	set aim_srvstart($aim_srvstart($rn,srvname),pid) $pid
#	if {![info exists aim_options(storedialog)] ||
#			$aim_options(storedialog)==1} {
#                set rc [tk_dialog .info EXECUTED "Bourne-Shell server start script ~/$aim_srvstart($rn,srvname).go has been executed.  You may need to refresh the queue list." "" 0 OK "Don't show this window next time"]
#		if {$rc==1} {
#		set aim_options(storedialog) 0
#		}
#	}

}

proc ss_get_dir {rn field {ext ""}} {
	set fn [dirselect]
	if {$fn!=""} {
		global aim_srvstart
		set aim_srvstart($rn,$field) $fn
	}
}

proc ss_get_open_file {rn field {ext ""}} {
	if {$ext!=""} {
		set fn [tk_getOpenFile -filetypes $ext]
	} else {
		set fn [tk_getOpenFile]
	}
	if {$fn!=""} {
		global aim_srvstart
		set aim_srvstart($rn,$field) $fn
	}
}

global aim_srvstart
set aim_srvstart($base,logsize) 64
set aim_srvstart($base,logvol) 0
focus $base.dropframe.srvname
if {![regexp {^[0-9][0-9]*$} [string range $base 3 end]]} {
	wm title $base "[string range $base 3 end] Server Launcher"
	set aim_srvstart($base,srvname) [string range $base 3 end]
	focus $base.executable
} else {
	wm title $base "Server Launcher"
}

proc launch_tcl_editor {rootname} {
        global aim_options aim_srvstart
        set txtfile $aim_srvstart($rootname,tclstartup)
        set dirname [file dirname $txtfile]
        set filename [file tail $txtfile]
        if {$filename!=""} {
                exec sh -c "cd $dirname ; \
			$aim_options(texteditor) $filename" &
        }
}

proc launch_su_editor {rootname} {
        global aim_options aim_srvstart
        set txtfile $aim_srvstart($rootname,startup)
        set dirname [file dirname $txtfile]
        set filename [file tail $txtfile]
        if {$filename!=""} {
                exec  sh -c "cd $dirname ; \
			$aim_options(sueditor) $filename" &
        }
}

