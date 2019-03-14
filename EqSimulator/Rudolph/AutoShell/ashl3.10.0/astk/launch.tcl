
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

#!/bin/sh
# Find wish8.0 in path and feed this file to it \
exec wish8.0 "$0" "$@"

source $env(ASTK_DIR)/getstring.tcl
set law_count 0
# We need to find a ps-like command for windows and put this back.  But
# hopefully without the OS-dependent string parsing stuff.
if {[info exists tcl_platform] && $tcl_platform(platform) == "windows"}  {
set law_on 1
} else {
set law_on 0
}
set law_interval 2000

# Executes a UNIX command as a background process and watches its stdout
# and stderr for output.   Any output causes a window to pop-up notifying
# the user of the problem.  Clicking "Stop showing this error".
proc launch_and_watch {cmd} {
	global law_count law_fids law_on law_cmds  law_interval
	incr law_count

	# Taking out stdout/stderr watch until it can be fixed to not leak
	# file handles.
	#set p [open "|cat" r+]
	#set pid [eval exec $cmd >&@ $p &]
	#fconfigure $p -blocking 0 -buffering none
	#fileevent $p readable "law_handler {$cmd} $p $pid"

	# Just start the process for now, ignore output.
	set rc [catch {set pid [eval exec $cmd &]}]
	if {$rc!=0} {
		tk_dialog .err ERROR "Couldn't execute $cmd." error 0 OK
		return -1
	}

	#set law_fids($pid) $p
	set law_cmds($pid) $cmd
	if {!$law_on} {
		after $law_interval law_checkprocesses			
	}
#	set p [open "|cat" r+]
#	set f [open "|$cmd 2>@ $p &" r+]
#	fconfigure $f -blocking 0
#	fconfigure $p -blocking 0
#	fileevent $f readable "law_handler {$cmd} $f $pid"
#	fileevent $p readable "law_handler {$cmd} $p $pid"
	return $pid
}

proc law_handler {cmd fid pid} {
	global law_fids law_on law_cmds law_interval
	set r [read $fid]
	if {$r!=""} {
		set rc [law_warn $pid "$law_cmds($pid)\n\n
wrote the following to stdout/stderr:\n\n$r"]
		if {$rc==-1} {
			law_stopwatching $pid
		}
	} else {
		#puts "nothing to read"
	}
}

proc law_checkprocesses {} {
	global law_fids law_on law_cmds law_cputimes law_interval
	global law_nextcheck
	global tcl_platform
	if {[info exists law_cmds]} {
		foreach pid [array names law_cmds] {
			#puts "checking $pid"
			set rc ""
			catch {
				set rc [lindex [split \
					[exec ps -lp $pid] "\n"] 1]
			}
			#puts "rc='$rc'"
			if {$rc==""} {
				set msg "$law_cmds($pid)\n"
				append msg "The process above has "
				append msg "stopped running."
				set rc [law_warn $pid $msg notrunning]
				law_stopwatching $pid 
			} else {
				if  {[regexp {\d+:\d+:\d+} $rc a] == 1} {
                                        set tlist [split $a :]
                                        set secs [string trim [lindex $tlist 1]]
                                        set hunds [string trim [lindex $tlist 2]]
                                } elseif  { [regexp {\d+:\d+} $rc a] == 1} {
                                        set tlist [split $a :]
                                        set secs [string trim [lindex $tlist 0]]
                                        set hunds [string trim [lindex $tlist 1]]
                                }	
				if {[string length $hunds]>1 &&
					[string index $hunds 0]=="0"} {
					set hunds [string index $hunds 1]
				}	
				set decsecs [expr $secs * 100 + $hunds]
				lappend law_cputimes($pid) $decsecs
				set spinperiod 4
				set spinslope 4
				if {[llength $law_cputimes($pid)]>$spinperiod} {
					set law_cputimes($pid) [lrange $law_cputimes($pid) 1 end]
					set slope [expr [lindex $law_cputimes($pid) end] - \
						[lindex $law_cputimes($pid) 0]]
					if {$slope>$spinslope} {
						set msg "$law_cmds($pid)\n\n"
						append msg "The process above may "
						append msg "be spinning (stuck "
						append msg "in a loop, perhaps).  "
						append msg "It may not respond "
						append msg "to command requests."
						set rc [law_warn $pid $msg]
						if {$rc==-1} {
							law_stopwatching $pid
						}
					}					
				}
			}
		}
		if {[array size law_cmds]>0} {
			catch {after cancel $law_nextcheck}
			set law_nextcheck [after $law_interval \
				law_checkprocesses]
		}
	}
}

set warncount 0
proc law_warn {pid msg {mode running}} {
	global warncount
	incr warncount
	if {$mode=="notrunning"} {
		set rc [tk_dialog .tmp$warncount WARNING $msg warning 0 \
			OK ]
	} else {
		set rc [tk_dialog .tmp$warncount WARNING $msg warning 0 \
			OK "Kill the Process" "Stop warning me"]
	}
	switch $rc {
		0 {
			return 0
		}
		1 {
			exec kill $pid	
			return -1
		}
		2 {
			return -1
		}
	}
}


proc law_stopwatching {pid} {
	#puts "stopping watch on $pid"
	global law_fids law_on law_cmds law_time law_interval
	#close $law_fids($pid)
	#catch { fileevent $law_fids($pid) readable "" }
	#catch { unset law_fids($pid) }
	catch { unset law_cmds($pid) }
}

# Test code (comment out for production use)
#set str "tclsrv name=testcore startup=testcore.su"
#launch_and_watch $str
