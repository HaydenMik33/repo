
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: genappl.tcl,v 1.12 2000/08/02 20:21:22 karl Exp $
# $Log: genappl.tcl,v $
# Revision 1.12  2000/08/02 20:21:22  karl
# Fixed sys>waiting entry leak.
#
# Revision 1.11  2000/07/14  15:09:48  karl
# Added  Option to configure which DV browser to use.
#
# Revision 1.10  2000/06/14  22:44:47  karl
# Fixed to abort gracefully if edit_su fails.
#
# Revision 1.9  1999/09/20  19:56:25  karl
# Changed "Name Server..." to "Name Queue..." and fixed it to work
# more correctly.
#
# Revision 1.8  1999/08/24  14:58:47  karl
# Added "Options" button to default button set.
# Added launch_and_watch features.
#
# Revision 1.7  1999/03/31  22:51:37  karl
# Added ability to rename the executable.
#
# Revision 1.6  1999/02/22  19:36:32  karl
# Fixed generic edit window to watch error.log and stdout.
# Took out reference to SFC Server.
# Fixed to record new file name correctly.
# Made stdout/error.log checks continuous.
#
# Revision 1.5  1998/12/11  21:10:27  karl
# Added notice and cancel option before starting a server.
#
# Revision 1.4  1998/09/01  18:58:24  karl
# Renamed name_serversrv to name_server.
# Added error.log check when running servers.
#
# Revision 1.3  1998/07/16  14:52:14  karl
# Changed open_server to take a filename and not ask for one itself.
#
# Revision 1.2  1998/07/01  18:04:33  karl
# Changed fileselect call to newfileselect.
#
# Revision 1.1  1996/08/27  16:25:45  karl
# Initial revision
#
proc open_server {applname} {
	global options
	if {$applname==""} {
		set applname noname.su
	}
#	if {[file extension $applname]==""} {
#		append applname ".su"
#	}
#	if {[file extension $applname]!=".su"} {
#		tk_dialog .error "ERROR" \
#			"Applications must have an extension of .su" \
#			error "" OK
#		return
#	}
	
	set buttons "{{Run Server} {run_server }} \
		{{View DVs} {view_dvs {} }} \
		{{View Logs...} {view_logs {} }} \
		{{Stop Server} {stop_server }} \
		{{Name Queue...} {name_server }} \
		{{Executable...} {name_exe }} \
		{{Options...} {set_options }}"
	set appid [edit_su $applname "
log name=all level=1
set scrsyntax=on
ldscript file=[file rootname [file tail $applname]].scr
		" $buttons $options(appledit) $options(vibindings)]
    if {$appid==""} {
        return ""
    }
	global appInfo
	if {[info exists appInfo($appid,srvname)] && \
		$appInfo($appid,srvname)!=""} {
		set srvname $appInfo($appid,srvname)
	} else {
		set srvname [file tail [file rootname $applname]]
		set appInfo($appid,srvname) $srvname
	}
	if {![info exists appInfo($appid,exename)] || \
		$appInfo($appid,exename)==""} {
		set appInfo($appid,exename) nullsrv
	}
	foreach butt $appInfo($appid,buttnames) {
		$butt configure -state disabled
	}
	change_butt_state $appid "Run Server" normal
	change_butt_state $appid "Name Queue..." normal
	change_butt_state $appid "Executable..." normal
	change_butt_state $appid "Options..." normal
	catch {an_msgsend 0 $srvname "get CWD omit_from_logs" -an_reply_cb \
		"open_server2 srvname=$srvname appid=$appid"}
	return $appid
}

an_proc open_server2 {} {} {} {
	change_butt_state $appid "Run Server" disabled
	change_butt_state $appid "View DVs" normal
	change_butt_state $appid "View Logs..." normal
	change_butt_state $appid "Stop Server" normal
	change_butt_state $appid "Name Queue..." normal
	change_butt_state $appid "Executable..." normal
	an_delete_cb $currenv
}

set CT(set) "set"
set CT(defcmdu) "defcmd"
set CT(defcmdi) "defcmd internal"
set CT(include) "include"
set CT(ldscript) "ldscript"
set CT(log) "log"
set CT(restore) "restore"
set CT(tclinclude) "tclinclude"
#set CT(set) "variable"
#set CT(defcmdu) "user cmd"
#set CT(defcmdi) "internal cmd"
#set CT(include) "include file"
#set CT(ldscript) "script file"
#set CT(log) "log settings"
#set CT(restore) "DV file"
#set CT(defchart) "chart instances"
#set CT(sfc) "step trigger"

# table to classify commands
set cmdtable "
    {{$CT(set)} {set %N=VALUE} do_set edit_set 1=}
    {{$CT(defcmdi)} {defcmd name=%N internal} do_defcmdi edit_defcmdi name}
    {{$CT(defcmdu)} {defcmd name=%N reply.0=Success} do_defcmdu edit_defcmdu name}
    {{$CT(include)} {include file=%N} do_include edit_include file}
    {{$CT(ldscript)} {ldscript file=%N} do_ldscript2 edit_ldscript2 file}
    {{$CT(restore)} {restore file=%N} do_restore edit_restore file}
    {{$CT(log)} {log name=%N} do_log edit_log name}
    {{$CT(tclinclude)} {tclinclude file=%N} do_tclinclude edit_tclinclude file}
"


proc stop_server {filename appid} {
	global appInfo cmdInfo buttinfo aci_comm_type
	set srvname $appInfo($appid,srvname)
	if {[info exists appInfo($appid,pid)]} {
		law_stopwatching $appInfo($appid,pid)
	}
	if { $aci_comm_type == "ACI" } {
		catch {an_msgsend 0 $srvname "exit removeq noreply"}
	} else {
		an_msgsend 0 qsrv "removequeue name.1=$srvname" 
	}
	set buttnames $appInfo($appid,buttnames)
	foreach butt $buttnames {
		$butt configure -state disabled
	}
	change_butt_state $appid "Run Server" normal
	change_butt_state $appid "Name Queue..." normal
	change_butt_state $appid "Executable..." normal
	#[lindex $buttnames 0] configure -state normal
	diagfile_cancel error.log
	diagfile_cancel $srvname.out
}

proc name_server {filename appid} {
	global appInfo 
	if {![info exists appInfo($appid,srvname)]} {
		set appInfo($appid,srvname) [file rootname [file tail 
			$appInfo($appid,sufile)]]
	}
	set newvalue [get_string "Queue Name:" $appInfo($appid,srvname)]
	if {$newvalue!=""} {
		set appInfo($appid,srvname) \
			[file rootname [file tail $newvalue]]
		#set appInfo($appid,sufile) $newvalue
	}
	foreach butt $appInfo($appid,buttnames) {
		$butt configure -state disabled
	}
	change_butt_state $appid "Run Server" normal
	change_butt_state $appid "Name Queue..." normal
	change_butt_state $appid "Executable..." normal
	catch {an_msgsend 0 $appInfo($appid,srvname) "get CWD omit_from_logs" -an_reply_cb \
		"open_server2 srvname=$appInfo($appid,srvname) appid=$appid "}
}

proc name_exe {filename appid} {
        global appInfo 
        set newvalue [get_string "Executable Name:" $appInfo($appid,exename)]
        if {$newvalue!=""} {
                set appInfo($appid,exename) $newvalue
        }
}

proc set_options {filename appid} {
	toplevel .tmp
	frame .tmp.editor
	pack .tmp.editor
	frame .tmp.dvbrowser
	pack .tmp.dvbrowser

	label .tmp.editor.lab -text "Text Editor"
	radiobutton .tmp.editor.anp -text anp \
		-variable options(texteditor) -value anp
	radiobutton .tmp.editor.vi -text vi \
		-variable options(texteditor) -value "xterm -e vi"
	entry .tmp.editor.other -textvariable options(texteditor)
	pack .tmp.editor.anp .tmp.editor.vi .tmp.editor.other -side left	

	label .tmp.dvbrowser.lab -text "DV Browser"
	radiobutton .tmp.dvbrowser.dvb -text dvb \
		-variable options(dvviewer) -value "dvb -f"
	radiobutton .tmp.dvbrowser.anp -text anp \
		-variable options(dvviewer) -value "anp"
	radiobutton .tmp.dvbrowser.vi -text vi \
		-variable options(dvviewer) -value "xterm -e vi"
	entry .tmp.dvbrowser.other -textvariable options(dvviewer)
	pack .tmp.dvbrowser.dvb .tmp.dvbrowser.anp .tmp.dvbrowser.vi .tmp.dvbrowser.other -side left	

	button .tmp.ok -text OK -command "destroy .tmp"
	pack  .tmp.ok
	grab .tmp
	tkwait window .tmp
	save_options
}

proc run_server {filename appid} {
	global appInfo cmdInfo aci_comm_type
	set srvname $appInfo($appid,srvname)
	set exename $appInfo($appid,exename)

	change_butt_state $appid "Run Server" disabled
	if { $aci_comm_type == "ACI" } {
		if [ catch {an_msgsend 0 $srvname "exit removeq" \
			-an_reply_cb "run_server2 srvname=$srvname exename=\"$exename\"\
			filename=$filename appid=$appid"} ] {
				an_cmd run_server2 srvname=$srvname exename="$exename" \
					filename=$filename appid=$appid
		}

	} else {
		an_msgsend 0 qsrv "removequeue name.1=$srvname" \
			-an_reply_cb "run_server2 srvname=$srvname exename=\"$exename\"\
			filename=$filename appid=$appid"
	}
}

an_proc run_server2 {} {} {} {
	global buttinfo appInfo cmdInfo
	set rc [scrl_dialog .tmp Launching \
		"About to execute:\n$exename \"set name=$srvname\" \"set startup=$filename\" >& $srvname.out &" "" 0 OK Cancel -height 4]
	if {$rc!=0} {
		change_butt_state $appid "Run Server" normal
		return
	}
	if {[file exists $srvname.out]} {
		file delete -force $srvname.out
	}
	diagfile_precheck error.log
	set pid [launch_and_watch "$exename \"set name=$srvname\" \
		\"set startup=$filename\""]
	if {$pid==-1} {
		change_butt_state $appid "Run Server" normal
		return
	}
	set appInfo($appid,pid) $pid
	after 2000
	diagfile_postcheck error.log continuous
	global buttinfo
	catch {an_msgsend 0 $srvname "get CWD omit_from_logs" -an_reply_cb \
		"open_server2 srvname=$srvname \
		appid=$appid"}
}

proc view_dvs {ctxt filename appid} {
	global appInfo options
	set srvname $appInfo($appid,srvname)
	browsedvs $srvname $options(dvviewer) .
}

proc view_logs {ctxt filename appid} {
	global appInfo name options
	set srvname $appInfo($appid,srvname)
	viewlogs $srvname . $options(vibindings)
}

proc load_options {} {
	global options
	set options(texteditor) "anp"
	set options(dvviewer) "dvb -f"
	set options(sueditor) "srve"
	if {[file exists ~/.srverc]} {
		source ~/.srverc
	}
}

proc save_options {} {
	global options
	set fid [open ~/.srverc w]
	puts $fid "global options"
	foreach el [array names options] {
		puts $fid "set options($el) {$options($el)}"
	}
	close $fid
}

load_options
