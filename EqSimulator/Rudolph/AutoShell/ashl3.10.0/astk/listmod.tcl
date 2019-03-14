
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

proc changelist {list path pos value} {
	set target [lindex $path 0]
	if {[llength $path]>1} {
			puts "Handling parent"
			puts "Searching '$list' for '$target'"
		set targetpos [lsearch $list "$target *"]
			puts "targetpos=$targetpos"
		set targetlst [lindex $list $targetpos]
			puts "targetlst=$targetlst"
		set sublist [changelist [lindex $targetlst 2] [lrange $path 1 end] \
			$pos $value]
			puts "targetlst=$targetlst"
		set targetlst [lreplace $targetlst 2 2 $sublist]
		set list [lreplace $list $targetpos $targetpos $targetlst]
			puts "returning: $list"
		return $list
	} else {
			puts "Handling child"
		set targetpos [lsearch $list "$target *"]
			puts "targetpos=$targetpos"
		set targetlst [lindex $list $targetpos]
			puts "targetlst=$targetlst"
		set targetlst [lreplace $targetlst $pos $pos $value]
			puts "targetlst=$targetlst"
		set list [lreplace $list $targetpos $targetpos $targetlst]
			puts "returning: $list"
		return $list
	}
}

set list {a b {c 1 {1 {2 1 {x y z}} 3}} d}
puts "list=$list"
set list [changelist $list "c 2" 1 0]
puts "list=$list"


