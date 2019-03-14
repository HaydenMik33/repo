global configDir
set configDir ../../[dv_get >toolid]

an_proc initialize {initialize} {Do setup activity} {{0 Success} {1 "Error parsing configuration file"}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	global configDir

	an_cmd restore file=$configDir/simdata.dv variable=simdata

	set >simdata>TransactionAbort [dv_get >simdata>StartupStates>TransactionAbort]
	set >simdata>TimeoutAll [dv_get >simdata>StartupStates>TimeoutAll]

	set dvPtr [dv_getptr >simdata>svid>ControlState]
	if {$dvPtr == "" || [dv_sublist -root $dvPtr] == ""} {
		an_lg $logName "$procName:  failed - no definition for ControlState SVID"
	} else {
		dv_set >simdata>ControlState [dv_get >simdata>StartupStates>ControlState]
	}
	set dvPtr [dv_getptr >simdata>svid>ProcessState]
	if {$dvPtr == "" || [dv_sublist -root $dvPtr] == ""} {
		an_lg $logName "$procName:  failed - no definition for ProcessState SVID"
	} else {
		dv_set >simdata>ProcessState [dv_get >simdata>StartupStates>ProcessState]
	}

	an_return $currenv 0
}

an_proc setTimeoutAll {setTimeoutAll {true, false}} {Make all transactions timeout} {{0 Success}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	if {[info exists true]} {
		dv_set >simdata>TimeoutAll "true"
	} else {
		dv_set >simdata>TimeoutAll "false"
	}
	an_return $currenv 0
}
an_proc getTimeoutAll {getTimeoutAll} {Get current setting for the flag} {{0 Success}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	set value [dv_get >simdata>TimeoutAll]
	if {"$value" == ""} {
		an_write $currenv "value=false"
	} else {
		an_write $currenv "value=$value"
	}
	an_return $currenv 0
}


an_proc setTransactionAbort {setTransactionAbort {true, false}} {Make all transactions return SxF0} {{0 Success}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	# sorry for violating DRY
	if {[info exists true]} {
		dv_set >simdata>TransactionAbort "true"
	} else {
		dv_set >simdata>TransactionAbort "false"
	}
	an_return $currenv 0
}
an_proc getTransactionAbort {getTransactionAbort} {Get current setting for the flag} {{0 Success}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	set value [dv_get >simdata>TransactionAbort]
	if {"$value" == ""} {
		an_write $currenv "value=false"
	} else {
		an_write $currenv "value=$value"
	}
	an_return $currenv 0
}

global ControlStates
array set ControlStates {
	Off-Line 1
	Local 4
	Remote 5
}
an_proc setControlState {setControlState state=Off-Line|Local|Remote} {Changes the reply for the ControlState SVID query} {{0 Success} {1 "No control state SVID has been defined"}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	global ControlStates
	set value $ControlStates($state)
	set dvPtr [dv_getptr >simdata>svid>ControlState]
	if {$dvPtr == "" || [dv_sublist -root $dvPtr] == ""} {
		set returnCode 1
	} else {
		dv_set >simdata>ControlState $value
		# This is somewhat tool specific; not sure how to generalize yet
		if {$state == "Off-Line"} {
			set event [dv_get >simdata>events>ControlStateOFFLINE]
			an_lg $logName "$procName: event is $event"
		} elseif {$state == "Local"} {
			set event [dv_get >simdata>events>ControlStateLOCAL]
			an_lg $logName "$procName: event is $event"
		} else {
			set event [dv_get >simdata>events>ControlStateREMOTE]
			an_lg $logName "$procName: event is $event"
		}
		if {$event != ""} {
			an_cmd sendEvent event=$event
		}
		set returnCode 0
	}
	an_lg $logName "$procName: returning $returnCode"
	an_return $currenv $returnCode
}
proc returnControlState {} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	global ControlStates

	set currentValue [dv_get >simdata>ControlState]
	set found ""
	foreach {state value} [array get ControlStates] {
		if {$value == $currentValue} {
			set found $state
			break
		}
	}	
	if {$found == ""} {
		return "Unknown"
	} else {
		return "$found"
	}
}
an_proc getControlState {getControlState} {Get current setting} {{0 Success} {1 "No control state SVID has been defined"}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	set value [returnControlState]
	if {$value == "1"} {
		set returnCode 1
	} else {
		an_write $currenv "value=$value"
		set returnCode 0
	}
	an_return $currenv $returnCode
}


global ProcessStates
array set ProcessStates {
	Off 0
	Setup 1
	Ready 2
	Executing 3
	Wait 4
	Abort 5
}
an_proc setProcessState {setProcessState state=Off|Setup|Ready|Executing|Wait|Abort} {Changes the reply for the ProcessState SVID query} {{0 Success} {1 "No process state SVID has been defined"}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	global ProcessStates
	set value $ProcessStates($state)
	set dvPtr [dv_getptr >simdata>svid>ProcessState]
	if {$dvPtr == ""} {
		set returnCode 1
	} else {
		dv_set >simdata>ProcessState $value
		set returnCode 0
	}
	set event [dv_get >simdata>events>ProcessStateChange]
	if {$event != ""} {
		# this is not quite right yet
		an_lg $logName "$procName: sending event $event"
		an_cmd sendEvent event=$event 
	}
	an_lg $logName "$procName: returning $returnCode"
	an_return $currenv $returnCode
}
an_proc getProcessState {getProcessState} {Get current setting} {{0 Success} {1 "No process state SVID has been defined"}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	global ProcessStates

	set dvPtr [dv_getptr >simdata>svid>ProcessState]
	if {$dvPtr == "" || [dv_sublist -root $dvPtr] == ""} {
		set returnCode 1
	} else {
		set currentValue [dv_get >simdata>ProcessState]
		set found ""
		foreach {state value} [array get ProcessStates] {
			if {$value == $currentValue} {
				set found $state
				break
			}
		}	
		if {$found == ""} {
			an_write $currenv "value=Unknown"
		} else {
			an_write $currenv "value=$found"
		}
		set returnCode 0
	}
	an_return $currenv $returnCode
}
an_proc sendEvent {sendEvent event=ProcessStarted|ProcessCompleted|ProcessAborted|%d} {Generate and send an S6F11 event message with optional report data} {{0 Success} {1 "Event by that name is not configured"}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	global configDir
	an_cmd restore file=$configDir/simdata.dv variable=simdata

	if {[string index $event 0] == "P"} {
		set ceid [dv_get >simdata>events>$event]
		if {$ceid == ""} {
			set returnCode 1
		}
	} else {
		set ceid $event
	}
	an_lg $logName "$procName: sendEvent with ceid $event"
	if {! [info exists returnCode]} {
		an_msgsend $currenv [dv_get >name] "event_send eq=[dv_get >toolid] DATAID=1 CEID=$ceid DATAID_TYPE=UI4 CEID_TYPE=UI4 [addReports $ceid]"
		set returnCode 0
	}
	an_return $currenv $returnCode
}

proc addReports {ceid} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	set reply ""
	set reportIdPtrs [dv_getgbs >simdata>eventLinks>$ceid>*]
	if {$reportIdPtrs != ""} {
		set reportIndex 1
		foreach reportIdPtr $reportIdPtrs {
			set vidPtrs [dv_getgbs >simdata>reports>[dv_getname -root $reportIdPtr]>*]
			if {$vidPtrs != ""} {
				append reply "RPTID.$reportIndex=[dv_getname -root $reportIdPtr] "
				set vidIndex 1
				foreach vidPtr $vidPtrs {
					set vidName [dv_getname -root $vidPtr]
					# check for process state VID
					set ptr [dv_getptr >simdata>svid>ProcessState]
					an_lg $logName "$procName: vidName=$vidName psVid=[dv_getname -root [dv_sublist -root $ptr]]"
					if {$vidName == [dv_getname -root [dv_sublist -root $ptr]]} {
						an_lg $logName "$procName: got ProcessState VID"
						if {[dv_get >simdata>ProcessState] != ""} {
							set simValue [dv_get >simdata>ProcessState]
						} else {
							set simValue [dv_get >simdata>StartupStates>ProcessState]
						}
					} else {
						an_lg $logName "$procName: not ProcessState VID"
						set simValue [dv_get >simdata>dvid>$vidName]
						if {$simValue == ""} {
							if {[dv_getname >simdata>svid>trace>$vidName] == ""} {
								set simValue [dv_get >simdata>dvid>DEFAULT]
							} else {
								set simValue [lindex [getValAndType $vidName] 0]
							} 
						} else {
							set simValue [lindex [getValAndType $vidName] 0]
						}
					}
					append reply "V.$reportIndex.$vidIndex=$simValue "
					incr vidIndex
				}	
			}
			incr reportIndex
		}
	}
	return $reply
}

an_proc sendAlarm {sendAlarm ALCD=%2s ALID=%d ALTX=%s} {Generate and send an S5F1 alarm message} {{0 Success} {1 Error}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	if {[string length $ALCD] == 1} {
		set ALCD 0$ALCD
	}
	an_msgsend $currenv [dv_get >name] "alarm_send eq=[dv_get >toolid] ALCD=$ALCD ALID=$ALID ALTX=\"$ALTX\""
	set returnCode 0

	an_return $currenv $returnCode
}


proc checkGlobalFlags {stream sf} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	an_lg $logName "$procName: checking TransactionAbort=[dv_get >simdata>TransactionAbort]"

	if {[dv_get >simdata>TransactionAbort] == "true"} {
		catch {an_cmd sxsend str=$stream fun=0 eq=[dv_get >toolid] systembytes=[dv_get >sys>msg>systembytes]} errmsg
		if [info exists errmsg] {
			an_lg $logName "$procName: error $errmsg"
		}
		dv_set >handlers>$sf>noreply
		set returnCode false
	} elseif {[dv_get >simdata>TimeoutAll] == "true"} {
			dv_set >handlers>$sf>noreply
			set returnCode false
	} else {
		dv_delete >handlers>$sf>noreply
		set returnCode true
	}
	an_lg $logName "$procName: returning $returnCode"
	return $returnCode
}

an_proc setAck {setAck streamFunction=S1F13|S2F15|S2F41|S5F3|S2F23|S2F33|S2F35|S2F37|S1F15|S1F17|S2F21|S2F27|S2F31|S2F43|S2F49|S3F17|S7F1|S7F3|S7F23|S10F3|S10F5|S10F9|S14F9|S16F11|S16F15 {good, bad}} {Tell Simulator to return good or bad ack to the given stream and function} {{0 Success}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	if {[info exists good]} {
		dv_set >simdata>$streamFunction 00
	} else {
		dv_set >simdata>$streamFunction 01
	}
	an_return $currenv 0
}


an_proc S1F3_prereply {} {} {} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	if {[checkGlobalFlags 1 S1F3]} {
		an_cmd defsxncode str=1 fun=4 clear
		foreach svidIndexPtr [dv_getgbs >sys>msg>SVID>*] {
			set index [dv_getname -root $svidIndexPtr]
			set svid [dv_get -root $svidIndexPtr]
			set svPtrList [dv_getgbs >simdata>svid>*>$svid]
			an_lg $logName "$procName Index $index SVID $svid svPtrList $svPtrList"
			if {[llength $svPtrList] == 0} {
				an_cmd defsxncode str=1 fun=4 pos=1,$index type=LIST value=0
			} else {
				set valAndType [getValAndType $svid]
				an_lg $logName "$procName: valAndType=$valAndType lindex=[lindex $valAndType 0]"
				an_cmd defsxncode str=1 fun=4 pos=1,$index value="[lindex $valAndType 0]" type=[lindex $valAndType 1]
			}
		}
	}
	an_lg $logName "$procName: ending"

}

an_proc S1F1_prereply {} {} {} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	global configDir
	an_cmd restore file=$configDir/simdata.dv variable=simdata

	if {[checkGlobalFlags 1 S1F1]} {
		dv_set >ncparms>MDLN [dv_get >simdata>MDLN]
		dv_set >ncparms>SOFTREV [dv_get >simdata>SOFTREV]
	}
	an_lg $logName "$procName: ending"
}


an_proc S1F13_prereply {} {} {} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"

	an_lg $logName "$procName: starting"
	global configDir
	an_cmd restore file=$configDir/simdata.dv variable=simdata

	putAckInNcparms [lindex [info level 0] 0] "COMMACK"

	if {[checkGlobalFlags 1 S1F13]} {
		dv_set >ncparms>MDLN [dv_get >simdata>MDLN]
		dv_set >ncparms>SOFTREV [dv_get >simdata>SOFTREV]
	}
	an_lg $logName "$procName: ending"
}


an_proc S2F13_prereply {} {} {} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	global configDir
	an_cmd restore file=$configDir/simdata.dv variable=simdata

	if {[checkGlobalFlags 1 S2F13]} {
		an_cmd defsxncode str=2 fun=14 clear
		foreach vidIndexPtr [dv_getgbs >sys>msg>ECID>*] {
			set index [dv_getname -root $vidIndexPtr]
			set vid [dv_get -root $vidIndexPtr]
			set value [dv_get >simdata>ecid>$vid]
			an_lg $logName "$procName Index $index VID $vid value $value"
			if {"$value" == ""} {
				an_cmd defsxncode str=2 fun=14 pos=1,$index type=LIST value=0
			} else {
				an_cmd defsxncode str=2 fun=14 pos=1,$index type=ASC value=$value
			}
		}
	}
	an_lg $logName "$procName: ending"
}

proc getValAndType {svid} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting svid=$svid"
	global configDir
	an_cmd restore file=$configDir/simdata.dv variable=simdata

	set ptr [dv_getptr >simdata>svid>ControlState]
	an_lg $logName "looking at [dv_getname -root [dv_sublist -root $ptr]]"
	if {$svid == [dv_getname -root [dv_sublist -root $ptr]]} {
		set val [dv_get >simdata>ControlState]
		an_lg $logName "$procName: $svid returning ControlState $val"
		return [list $val UI4]
	} else {
		set ptr [dv_getptr >simdata>svid>ProcessState]
		if {$svid == [dv_getname -root [dv_sublist -root $ptr]]} {
			set val [dv_get >simdata>ProcessState]
			an_lg $logName "$procName: $svid returning ProcessState $val"
			return [list $val UI4]
		}
	}

	set sv [dv_get >simdata>svid>trace>$svid]
	if {$sv == ""} {
		set sv [dv_get >simdata>dvid>$svid]
	}
	if {$sv == ""} {
		set sv [dv_get >simdata>svid>trace>DEFAULT]
	}	
	#set sv [dv_get -root $valPtr SV]
	set type ASC
	an_lg $logName "sv=$sv type=$type"
	if {"$sv" == "clock"} {
		# Current time in YYYYMMDDhhmmsscc
		an_lg $logName "$procName: $svid returning current time"
		return [list [clock format [clock seconds] -format "%Y%m%d%H%M%S00"] $type]

	} elseif {"$sv" == "random"} {
		# Random number between 1 and 10
		an_lg $logName "$procName: $svid returning random number"
		return [list [expr {rand() * 10}] $type]

	} elseif {"$sv" == "slope"} {
		# Increment then decrement
		set val [dv_get >RUNDATA>$svid>VAL]
		set op [dv_get >RUNDATA>$svid>OP]

		if {"$val" == "" || $val < 1} {
			set val 1
			set op "+"
		} elseif {$val > 9} {
			set val 9 
			set op "-"
		} else {
			an_lg $logName "getValAndType: evaluating |$val $op 1|"
			set expression "$val $op 1"
			set val [expr $expression]
		}
		# Save current val for next query
		dv_set >RUNDATA>$svid>VAL $val
		dv_set >RUNDATA>$svid>OP $op
		an_lg $logName "$procName: $svid returning $val"
		return [list $val $type]

	} elseif {"$sv" == "onoff"} {
		# On for 10 iterations, off for 10
		set val [dv_get >RUNDATA>$svid>VAL]
		set count [dv_get >RUNDATA>$svid>COUNT]
		an_lg $logName "getValAndType: val=$val count=$count"

		if {"$val" == ""} {
			set val 00
			set count 0
		} elseif {$count > 9} {
			if {$val == "00"} {
				set val "FF"
			} else {
				set val "00"
			}
			set count 0
		} else {
			incr count
		}
		# Save current val for next query
		dv_set >RUNDATA>$svid>VAL $val
		dv_set >RUNDATA>$svid>COUNT $count
		return [list $val $type]
		
	} elseif {"$sv" == "novalue"} {
		set val ""
		an_lg $logName "$procName: $svid returning $val"
		return [list $val $type]

	} else {
		an_lg $logName "$procName: $svid returning val $sv type $type"
		if {[string first " " $sv] > 0} {
			return [list "$sv" $type]
		} else {
			return [list $sv $type]
		}
	}

	an_lg $logName "getValAndType: ending"

}

an_proc sendTraceData {} {} {} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting, trid=$trid"
		
	an_cmd defsxncode str=6 fun=1 clear
	set smpln [dv_get >TRACE>$trid>SMPLN]
	set stime [clock format [clock seconds] -format "%Y%m%d%H%M%S00"]
	an_cmd defsxncode str=6 fun=1 pos=1,1 value=$trid type=UI4
	an_cmd defsxncode str=6 fun=1 pos=1,2 value=$smpln type=UI4
	an_cmd defsxncode str=6 fun=1 pos=1,3 value=$stime type=ASC
	
	set index 1
	set svPtr [dv_sublist >TRACE>$trid>SVID]
	while {"$svPtr" != ""} {
		set svid [dv_getname -root $svPtr]
		# check for List type
		set listSize [dv_get >simdata>svid>trace>$svid>LIST_SIZE]
		if {$listSize == ""} {
			# Encode a single SVID value, not a list
			set valAndType [getValAndType $svid]
			an_lg $logName "$procName: valAndType=$valAndType lindex=[lindex $valAndType 0]"
			an_cmd defsxncode str=6 fun=1 pos=1,4,$index value="[lindex $valAndType 0]" type=[lindex $valAndType 1]
		} else {
			if {$listSize == "0"} {
				an_lg $logName "$procName: encoding position 1,4,$index as L,0"
				an_cmd defsxncode str=6 fun=1 pos=1,4,$index type=LIST size=0 value=0
			} else {
				# Encode a bunch of sublist items
				for {set subindex 1} {$subindex <= $listSize} {incr subindex} {
					set valAndType [getValAndType $svid]
					an_lg $logName "$procName: encoding position 1,4,$index,$subindex"
					an_cmd defsxncode str=6 fun=1 pos=1,4,$index,$subindex value=[lindex $valAndType 0] type=[lindex $valAndType 1]
				}
			}
		}		
		incr index
		set svPtr [dv_next -root $svPtr]
	}	
	set msg "send_trace eq=[dv_get >toolid] TRID=$trid SMPLN=$smpln STIME=$stime"
	an_lg $logName "$procName: sending trace message: $msg"
	an_cmd sxsend str=6 fun=1 eq=[dv_get >toolid]

	dv_set >TRACE>$trid>SMPLN [incr smpln]
}


an_proc S2F23_postreply {} {} {} {
	
	# if TOTSMP > 0
	# 	Under >TRACE add the trid, TOTSMP, List of SVID
	# 	Turn DSPER into seconds
	# 	set timer to call sendTraceData TRID=%s
	# else 
	#	Under >Trace delete the trid
	#	cancel timer
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	set ack [dv_get >simdata>S2F23]
       	if {$ack == "01" || [dv_get >handlers>S2F23>noreply] != ""} {
		an_lg $logName "$procName: not starting or stopping trace because bad ack set or timeoutAll set"
	} else {

		# First stop the previous trace if needed
		set trid [dv_get >sys>msg>TRID]
		an_lg $logName "$procName: removing timer id=$trid"
		catch {an_cmd cancel id=$trid}
		an_lg $logName "$procName: cancelled timer id=$trid"
		dv_delete >TRACE>$trid	

		# Set a timer to send the trace data
		set totsmp [dv_get >sys>msg>TOTSMP]
		an_lg $logName "$procName: totsmp is $totsmp"
		if {$totsmp > 0} {
			set dsper [expr {[dv_get >sys>msg>DSPER]}]
			an_lg $logName "$procName: totsmp $totsmp trid $trid dsper $dsper"
			# Save in dvs
			set svidList [dv_set >TRACE>$trid>SVID]
			foreach svidIndexPtr [dv_getgbs >sys>msg>SVID>*] {
				dv_set -root $svidList [dv_get -root $svidIndexPtr]
			}
			dv_set >TRACE>$trid>SMPLN 1

			an_lg $logName "$procName: setting timer id=$trid"
			an_msgsend $currenv [dv_get >name] "send msg=do=\"sendTraceData trid=$trid\" seconds=$dsper iterations=$totsmp id=$trid noreply"
		}

	}
}

proc putAckInNcparms {scriptName variableName} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	
	set streamFunction [string range $scriptName 3 [expr [string last "_" $scriptName] - 1]]
	an_lg $logName "$procName: sf is $streamFunction"
	set ack [dv_get >simdata>$streamFunction]
       	if {$ack == ""} {
		dv_set >ncparms>$variableName "00"
	} else {
		an_lg $logName "$procName: setting >ncparms>$variableName $ack"
		dv_set >ncparms>$variableName $ack
	}
}

an_proc S2F15_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "EAC"
}


an_proc S2F41_prereply {} {} {} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"
	

	set currentControlState [returnControlState]
	if {$currentControlState == "Off-Line"} {
		dv_set >ncparms>HCACK "01"
	} else {
		putAckInNcparms [lindex [info level 0] 0] "HCACK"

		if {[dv_get >ncparms>HCACK] == "00"} {
			set rcmd [dv_get >sys>msg>RCMD]
			if {$rcmd == "LOCAL"} {
				an_cmd setControlState state=Local
			} elseif {$rcmd == "REMOTE"} {
				an_cmd setControlState state=Remote
			} elseif {$rcmd == "PP-SELECT"} {
				# do smart stuff someday	
				an_lg $logName "$procName: sending event 40"
				an_cmd sendEvent event=60
			} elseif {$rcmd == "START"} {
				an_cmd setProcessState state=Executing
				an_lg $logName "$procName: sending event 100"
				an_cmd sendEvent event=100
				an_lg $logName "$procName: setting timer"
				an_msgsend $currenv [dv_get >name] "send msg=do=sendSomeEvents id=E seconds=5 noreply"
				an_msgsend $currenv [dv_get >name] "send msg=do=sendSomeAlarms id=A seconds=3 noreply"
				#an_msgsend $currenv [dv_get >name] "send msg=do=processingComplete id=C seconds=20 noreply"
			} elseif {$rcmd == "STOP"} {
				an_cmd setProcessState state=Abort
				an_msgsend $currenv [dv_get >name] "cancel id=E noreply"
				an_msgsend $currenv [dv_get >name] "cancel id=C noreply"
				an_msgsend $currenv [dv_get >name] "cancel id=A noreply"
			} elseif {$rcmd == "NEXT"} {
				an_cmd setProcessState state=Ready
			} elseif {$rcmd == "WAIT"} {
				an_cmd setProcessState state=Wait
				an_msgsend $currenv [dv_get >name] "cancel id=E noreply"
				an_msgsend $currenv [dv_get >name] "cancel id=C noreply"
				an_msgsend $currenv [dv_get >name] "cancel id=A noreply"
			} elseif {$rcmd == "CONTINUE"} {
				an_cmd setProcessState state=Executing
				an_msgsend $currenv [dv_get >name] "send msg=do=processingComplete id=C seconds=10 noreply"
			}	
		}
	}
	an_lg $logName "$procName: complete"
}

an_proc processingComplete {processingComplete} {doc} {{0 Success}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	global ProcessStates
	an_lg $logName "$procName: setting ProcessState to $ProcessStates(Ready)"
	dv_set >simdata>ProcessState $ProcessStates(Ready)
	set event [dv_get >simdata>events>ProcessCompleted]
	if {$event != ""} {
		# this is not quite right yet
		an_lg $logName "$procName: sending ProcessCompleted event $event"
		an_cmd sendEvent event=$event 
	}
	an_lg $logName "$procName: sending ProcessStateChange event $event"
	set event [dv_get >simdata>events>ProcessStateChange]
	if {$event != ""} {
		an_lg $logName "$procName: sending event $event"
		an_cmd sendEvent event=$event 
	}
	an_lg $logName "$procName: complete"
}
an_proc sendSomeEvents {sendSomeEvents} {doc} {{0 Success}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	an_lg $logName "$procName: sending event 30"
	an_cmd sendEvent event=30
	after 1000
	an_lg $logName "$procName: sending event 40"
	an_cmd sendEvent event=40

	an_lg $logName "$procName: complete"
}
an_proc sendSomeAlarms {sendSomeAlarms} {doc} {{0 Success}} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	an_lg $logName "$procName: sending alarm 1301"
	an_cmd sendAlarm ALID=1301 ALCD=10 ALTX="Bad vacuum"
	after 300
	an_lg $logName "$procName: sending alarm 1303"
	an_cmd sendAlarm ALID=1303 ALCD=10 ALTX="Heat water"
	after 200
	an_lg $logName "$procName: sending alarm 267"
	an_cmd sendAlarm ALID=267 ALCD=10 ALTX="Gas Control Error"

	an_lg $logName "$procName: complete"
}

an_proc S5F3_prereply {} {} {} {
	# ACKC5
	putAckInNcparms [lindex [info level 0] 0] "ACKC5"
}


an_proc S2F23_prereply {} {} {} {
	# TIAACK
	if {[checkGlobalFlags 2 S2F23]} {
		putAckInNcparms [lindex [info level 0] 0] "TIAACK"
	}
}


an_proc S2F33_prereply {} {} {} {
	set procName [lindex [info level 0] 0]
	set logName "[dv_get >name]_log"
	an_lg $logName "$procName: starting"

	if {[checkGlobalFlags 2 S2F33]} {

	putAckInNcparms [lindex [info level 0] 0] "DRACK"
	# if good ack
	#	if no RPTID, remove all reports and links
	#	else
	#		foreach RPTID, if no VID, remove the report and links
	#		else add the reports/VIDs
	
	if {[dv_get >ncparms>DRACK] == "00"} {
		set rptPtr [dv_getptr >sys>msg>RPTID>1]
		if {$rptPtr == ""} {
			dv_delete >simdata>reports
			foreach simEventPtr [dv_getgbs >simdata>eventLinks>*] {
				dv_delete -root $simEventPtr reports
			}
		} else {
			while {"$rptPtr" != ""} {
				set rptIndex [dv_getname -root $rptPtr]
				set rptId [dv_get -root $rptPtr]
				if {[dv_getptr >sys>msg>VID>$rptIndex>1] == ""} {
					dv_delete >simdata>reports>$rptId
					foreach simEventReportPtr [dv_getgbs >simdata>eventLinks>*>$rptId] {
						dv_delete -root $simEventReportPtr
					}
				} else {
					dv_delete >simdata>reports>$rptId
					set simReportPtr [dv_set >simdata>reports>$rptId]
					foreach vidPtr [dv_getgbs >sys>msg>VID>$rptIndex>*] {
						dv_set -root $simReportPtr [dv_get -root $vidPtr]
					}
				}
				set rptPtr [dv_next -root $rptPtr]
			}
		}
	}
	}
}

an_proc S2F35_prereply {} {} {} {
	#LRACK
	if {[checkGlobalFlags 2 S2F35]} {
	putAckInNcparms [lindex [info level 0] 0] "LRACK"
an_cmd store file=out.txt variable=>sys>msg
	if {[dv_get >ncparms>LRACK] == "00"} {
		set eventPtr [dv_getptr >sys>msg>CEID>1]
		if {$eventPtr == ""} {
			dv_delete >simdata>eventLinks
		} else {
			while {$eventPtr != ""} {
				set eventIndex [dv_getname -root $eventPtr]
				set eventId [dv_get -root $eventPtr]
				dv_delete >simdata>eventLinks>$eventId
				if {[dv_getptr >sys>msg>RPTID>$eventIndex>1] != ""} {
					foreach reportIdPtr [dv_getgbs >sys>msg>RPTID>$eventIndex>*] {
						dv_set >simdata>eventLinks>$eventId>[dv_get -root $reportIdPtr]
					}
				}
				set eventPtr [dv_next -root $eventPtr]
					
			}
		}
	}
}
}


an_proc S2F37_prereply {} {} {} {
	#ERACK
	if {[checkGlobalFlags 2 S2F37]} {
		putAckInNcparms [lindex [info level 0] 0] "ERACK"
	}
}


an_proc S1F15_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "OFLACK"
	# OFLACK
}


an_proc S1F17_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "ONLACK"
	# ONLACK
}


an_proc S2F21_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "CMDA"
	# CMDA
}


an_proc S2F27_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "CMDA"
	# CMDA
}


an_proc S2F31_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "TIACK"
	# TIACK
}


an_proc S2F43_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "RSPACK"
	# RSPACK
}


an_proc S2F49_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "HCACK"
	# HCACK
}


an_proc S3F17_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "CAACK"
	# CAACK
}


an_proc S7F1_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "PPGNT"
	# PPGNT
}


an_proc S7F3_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "ACKC7"
	# ACKC7
}


an_proc S7F23_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "ACKC7"
	# ACKC7
}


an_proc S10F3_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "ACKC10"
	# ACKC10
}


an_proc S10F5_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "ACKC10"
	# ACKC10
}


an_proc S10F9_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "ACKC10"
	# ACKC10
}


an_proc S14F9_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "OBJACK"
	# OBJACK
}


an_proc S16F11_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "ACKA"
	# ACKA
}


an_proc S16F15_prereply {} {} {} {
	putAckInNcparms [lindex [info level 0] 0] "ACKA"
	# ACKA
}

