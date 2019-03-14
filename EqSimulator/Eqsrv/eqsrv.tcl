
global log
set log [dv_get >name]
append log "_verb"

an_proc S1F3_postreceive {} {} {} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"

	an_write $currenv [addTypes "SV"]
}

an_proc S2F13_postreceive {} {} {} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"

	an_write $currenv [addTypes "ECV"]
}


proc addTypes {variableName} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"
	
	# Set the secsmessage pointer back to the beginning, so you can re-decode with types
	sx_reset

	append varPlusType $variableName "_TYPE"

	set listSize [sx_getnextitem]
	an_lg -level 3 $log "listSize=$listSize"
	set index 1
	set typeString ""
	while { $index <= $listSize } {
		set type [sx_gettypestring]
	
		if {$type != "L"} {
			append typeString "$varPlusType.$index=[sx_getantypestring] "
			sx_getnextitem
		} else {
			if {[sx_getsize] == 0} {
				append typeString "$varPlusType.$index=List "
				sx_skipitem
			} else {
				set sublistSize [sx_getnextitem]
				append typeString "$varPlusType.$index=List "
				set sublistIndex 1
				set sublistValue ""
				while { $sublistIndex <= $sublistSize } {
					append typeString "$varPlusType.$index.$sublistIndex=[sx_getantypestring] " 
					sx_getnextitem
					incr sublistIndex
				}
			}
		}	
		incr index
	}
	return $typeString
}



an_proc S2F17_prereply {} {} {} {
		dv_set >ncparms>TIME [clock format [clock seconds] -format "%y%m%d%H%M%S"]
}



an_proc S6F1_prereply {} {} {} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"
	
	# Set the secsmessage pointer back to the beginning, so you can re-decode with types
	sx_reset
	# Skip STIME, SMPLN and TRID
	an_lg -level 3 $log "TRID: [sx_getnextitem]"
	an_lg -level 3 $log "SMPLN: [sx_getnextitem]"
	an_lg -level 3 $log "STIME: [sx_getnextitem]"
	an_lg -level 3 $log "Sample count: [sx_getnextitem]"
	

	addTypesToSysMsg "SV_TYPE"
	an_cmd store file=out.txt variable=sys>msg
}
proc addTypesToSysMsg {varPlusType} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"
	

	set listSize [sx_getnextitem]
	an_lg -level 3 $log "listSize=$listSize"
	set index 1
	set root [dv_getptr >sys>msg]
	while { $index <= $listSize } {
		addTypesRecursively $root $varPlusType $index
		incr index
	}
	return
}
proc addTypesRecursively {root varPlusType index} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"
	set type [sx_gettypestring]
	
	if {$type != "L"} {
		dv_set -root $root "$varPlusType.$index" "[sx_getantypestring]"
		sx_getnextitem
	} else {
		if {[sx_getsize] == 0} {
			dv_set -root $root "$varPlusType.$index" "L,0"
			sx_skipitem
		} else {
			set sublistSize [sx_getnextitem]
			set sublistIndex 1
			while { $sublistIndex <= $sublistSize } {
				addTypesRecursively $root $varPlusType.$index $sublistIndex
				incr sublistIndex
			}
		}
	}	
}


an_proc S6F11_prereply {} {} {} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"
	
	# Set the secsmessage pointer back to the beginning, so you can re-decode with types
	sx_reset
	# Skip DATAID and CCEID
	sx_getnextitem
	an_lg -level 3 $log "DATAID: [sx_getnextitem]"
	an_lg -level 3 $log "CEID: [sx_getnextitem]"
	
	set reportCount [sx_getnextitem]
	an_lg -level 3 $log "Report count: $reportCount"
	set index 1
	set root [dv_getptr >sys>msg]

	while { $index <= $reportCount } {
		sx_getnextitem
		sx_getnextitem

		set vName "V_TYPE."
		append vName $index
		addTypesToSysMsg $vName
		incr index
	}
	#an_cmd store file=out.txt variable=sys>msg
}


an_proc S6F9_prereply {} {} {} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"
	
	# Set the secsmessage pointer back to the beginning, so you can re-decode with types
	sx_reset
	# Skip PFCD, DATAID and CCEID
	sx_getnextitem
	an_lg -level 3 $log "PFCD: [sx_getnextitem]"
	an_lg -level 3 $log "DATAID: [sx_getnextitem]"
	an_lg -level 3 $log "CEID: [sx_getnextitem]"
	
	set reportCount [sx_getnextitem]
	an_lg -level 3 $log "Report count: $reportCount"
	set index 1
	set root [dv_getptr >sys>msg]

	while { $index <= $reportCount } {
		sx_getnextitem
		sx_getnextitem

		set vName "DVVAL_TYPE."
		append vName $index
		addTypesToSysMsg $vName
		incr index
	}
}


an_proc S6F3_prereply {} {} {} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"
	
	# Set the secsmessage pointer back to the beginning, so you can re-decode with types
	sx_reset
	# Skip DATAID and CCEID
	sx_getnextitem
	an_lg -level 3 $log "DATAID: [sx_getnextitem]"
	an_lg -level 3 $log "CEID: [sx_getnextitem]"
	
	set reportCount [sx_getnextitem]
	an_lg -level 3 $log "Report count: $reportCount"
	set index 1
	set root [dv_getptr >sys>msg]

	while { $index <= $reportCount } {
		sx_getnextitem
		sx_getnextitem
		sx_getnextitem
		# Skip the DVNAME
		sx_skipitem
		set vName "DVVAL_TYPE."
		append vName $index
		addTypesToSysMsg $vName
		incr index
	}
}

an_proc S7F19_postreceive {} {} {} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"

		an_write $currenv [addTypes "PPID"]

}

an_proc defineEncodeDecode {defineEncodeDecode stream=%s function=%s encode=%s decode=%s} {Erase the current encode and decode structures for the message and define new ones} {{0 Success} {1 Error from eqsrv}} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"
	
	catch {
		if {$encode != ""} {
			an_cmd defsxncode str=$stream fun=$function clear
			set lines [split $encode "\n"]
			foreach line $lines {
				an_cmd defsxncode str=$stream fun=$function $line
			}
		}
	
		if {$decode != ""} {
			set function [expr $function + 1]
			an_cmd defsxdcode str=$stream fun=$function clear
			set lines [split $decode "\n"]
			foreach line $lines {
				an_cmd defsxdcode str=$stream fun=$function $line
			}
		}
	} errmsg
	if {[info exists errmsg] && $errmsg != ""} {
		an_lg -level 0 $log "[lindex [info level 0] 0] error: $errmsg"
		an_write $currenv "Error in encode/decode: $errmsg"
		an_return $currenv 1
	} else {
		an_lg -level 3 $log "[lindex [info level 0] 0] complete; args: [lrange [info level [info level]] 1 end]"
		an_return $currenv 0
	}

}

an_proc defineAndSend {defineAndSend eqCommand=%s eq=%s [messages=%s]} {Erase the current encode and decode structures for the message and define new ones} \
		{{0 Success} {1 timeout} {2 "transaction aborted (SXF0)"} {3 "unexpected return"} {4 "error in sending message"} {5 "equipment not configured"} {6 "error in construction of SECS message"} {7 "error from eqsrv"} {15 "ACK was not 0"} {98 "internal error"} {99 "received stream 9 (S9FX)"}} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"
	catch {
		if {[info exists messages] && $messages != ""} {
			set lines [split [string trim $messages] "\n"]
			foreach line $lines {
				
				an_lg -level 3 $log "[lindex [info level 0] 0]: executing: |an_cmd $line|"
				#an_cmd store file=1.txt
				set t "an_cmd $line"
				catch {uplevel 1 $t}
			}
		}
		
		an_msgsend $currenv $to "$eqCommand eq=$eq" -an_reply_cb defineAndSendReply

	} errmsg
	if {[info exists errmsg] && $errmsg != ""} {
		an_lg -level 0 $log "[lindex [info level 0] 0] error: $errmsg"
		an_write $currenv "Error in encode/decode: $errmsg"
		an_return $currenv 1
	} else {
		an_lg -level 3 $log "[lindex [info level 0] 0] complete; args: [lrange [info level [info level]] 1 end]"
		# must not do an_return here
	}

}

an_proc defineAndSendReply {} {} {{0 Success} {1 Error}} {
	global log
	an_lg -level 3 $log "[lindex [info level 0] 0] starting; args: [lrange [info level [info level]] 1 end]"

	if {$reply == 0} {
		an_savemsg -at >sys>waiting>$currenv>eqsrvReply $an_form
		set root [dv_getptr >sys>waiting>$currenv>eqsrvReply]
		foreach tag {"ctxt" "fr" "to" "reply" "comment" "command"} {
			dv_delete -root $root $tag
		}
		set reply [an_buildmsg >sys>waiting>$currenv>eqsrvReply]
		an_write $currenv $reply
		an_return $currenv 0
	} else {
		an_write $currenv "errorCode=$reply errorMsg=$comment"
		an_return $currenv $reply
	}
}
	


