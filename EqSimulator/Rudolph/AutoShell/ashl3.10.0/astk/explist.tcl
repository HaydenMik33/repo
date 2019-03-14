
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

proc get_state {wn index} {
	global explist
	if {[info exists explist($wn,$index,expanded)]} {
		return $explist($wn,$index,expanded)
	} else {
		return -1
	}
}

proc changelist {list path pos value} {
	#puts "list=$list path=$path pos=$pos value=$value"
	set target [lindex $path 0]
	if {[llength $path]>1} {
			#puts "Handling parent"
			#puts "Searching '$list' for '$target'"
		set targetpos [lsearch $list "$target *"]
			#puts "targetpos=$targetpos"
		set targetlst [lindex $list $targetpos]
			#puts "targetlst=$targetlst"
		set sublist [changelist [lindex $targetlst 2] [lrange $path 1 end] \
			$pos $value]
			#puts "targetlst=$targetlst"
		set targetlst [lreplace $targetlst 2 2 $sublist]
		set list [lreplace $list $targetpos $targetpos $targetlst]
			#puts "returning: $list"
		return $list
	} else {
			#puts "Handling child"
		set targetpos [lsearch $list "$target *"]
			#puts "targetpos=$targetpos"
		set targetlst [lindex $list $targetpos]
			#puts "targetlst=$targetlst"
		set targetlst [lreplace $targetlst $pos $pos $value]
			#puts "targetlst=$targetlst"
		set list [lreplace $list $targetpos $targetpos $targetlst]
			#puts "returning: $list"
		return $list
	}
}

#set list {a b {c 1 {1 {2 1 {x y z}} 3}} d}
#puts "list=$list"
#set list [changelist $list "c 2" 1 0]
#puts "list=$list"

proc expandable_listbox_get {wn index} {
	global indentstr
	set str [$wn get $index]
	while {[string first $indentstr $str]==0} {
		set str [string range $str [string length $indentstr] end]	
	}
	set str [string range $str 1 end]
	#puts "$str"
	return $str
}

proc expandable_listbox_init {wn statearray} {
	global explist
	global indentstr
	bind $wn <Double-Button-1> "expand_collapse $statearray %W"
}

proc expand_collapse {statearray W} {
		global indentstr explist
		set itemnum [lindex [$W curselection] 0]
		if {$itemnum==""} {
			return
		}
		set itemstr [$W get $itemnum]
		#set itempath $explist($W,$itemnum,path)
		#set expanded $explist($W,$itemnum,expanded)
		if {[info exists explist($W,$itemnum,expanded)]} {
			#puts "explist($W,$itemnum,expanded)=$explist($W,$itemnum,expanded)"
			#puts "itemstr=$itemstr"
			global $statearray
			set list $explist($W,elements)
			if {$explist($W,$itemnum,expanded)=="1"} {
				set nl [changelist $explist($W,elements) \
					[split [string trim \
					$explist($W,$itemnum,path) /] /] 1 0]
				set ${statearray}(showatstart,[string \
					range $itemstr 1 end]) 0
			} else {
				set nl [changelist $explist($W,elements) \
					[split [string trim \
					$explist($W,$itemnum,path) /] /] 1 1]
				set ${statearray}(showatstart,[string \
					range $itemstr 1 end]) 1
			}
			set explist($W,elements) $nl
			$W delete 0 end
			#el_insert $W "" 0 $explist($W,elements)
			expandable_listbox_fill $W $explist($W,elements)
			$W yview $itemnum
		}
}

proc expandable_listbox_fill {wn list} {
	global explist
	global indentstr
	if {[info exists explist]} {
		unset explist
	}
	set explist($wn,elements) $list
	$wn delete 0 end
	el_insert $wn "" 0 $explist($wn,elements)
}

set indentstr "  "
proc el_insert {wn path index list} {
	global explist indentstr
	#puts "Inserting $list"
	foreach item $list {
		set itemstr ""
		set itemval [lindex $item 0]
		foreach el [split $path /]  {
			append itemstr $indentstr		
		}
		if {[llength $item]>1} {
			set expanded [lindex $item 1]
			set sublist [lindex $item 2]
			if {$expanded==1} {
				append itemstr "-"
				append itemstr $itemval
				#puts "Inserting $itemstr"
				$wn insert $index $itemstr
				set explist($wn,$index,path) $path/$itemval
				set explist($wn,$index,expanded) $expanded
				incr index
				set index [el_insert $wn $path/$itemval $index $sublist]
			} else {
				append itemstr "+"
				append itemstr $itemval
				#puts "Inserting $itemstr"
				$wn insert $index $itemstr
				set explist($wn,$index,path) $path/$itemval
				set explist($wn,$index,expanded) $expanded
				incr index
			}
		} else {
			append itemstr " "
			append itemstr $itemval
			#puts "Inserting $itemstr"
			$wn insert $index $itemstr
			set explist($wn,$index,path) $path/$itemval
			incr index
		}

	}
	return $index
}

#expandablelist .dummy -list {{local 1 {timer qsrv eqsrv}} {remote 0 {smssrv datasrv oraclesrv}} {noreader 0 {tk123133 eqb56757 oldclient}}}
#{a b {c 1 {1 {2 1 {x y z}} 3}} d}
#{ a b { c 1 { 1 { 2 1 { x y z }} 3 }} d }
#pack .dummy
#update idletasks
#puts [expandablelist .xxx]
#puts [winfo exists .xxx]
