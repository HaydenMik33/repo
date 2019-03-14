
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: dvv.tcl,v 1.3 2000/12/14 22:54:24 karl Exp $
# $Log: dvv.tcl,v $
# Revision 1.3  2000/12/14 22:54:24  karl
# Fixed so that any > characters in DV names will be displayed as )
# characters, to avoid bugs caused by path delimiter conflicts.
#
# Revision 1.2  2000/07/07  21:24:46  karl
# Added expand and collapse methods.  Added choose_dv_viewer command.
#
# Revision 1.1  2000/04/25  17:20:36  karl
# Initial revision
#

proc dvv_populate {w ptr path} {
	global errorInfo dvv
	foreach dvptr [dv_getgbs -root $ptr *] {
		set dvname [dv_getname -root $dvptr]
		regsub -all {>} $dvname {)} dvname
		set val [dv_get -root $dvptr]
		#puts "populating dvname=$dvname val=$val"
		set sublist [dv_sublist -root $dvptr]
		#set size [dv_sizeof $dvptr]
		if {$dvv($w,showlineends)} {
			set values [list = $val \266]
		} else {
			set values [list = $val]
		}
		if {[string length $val]>0} {
			Tree:newitem $w $path>$dvname -values $values \
				-valuecolors {black #0000EE black} -fill #EE0000
		} else {
			Tree:newitem $w $path>$dvname -fill #EE0000
		}
		if {$sublist!=""} {
			dvv_populate $w $dvptr $path>$dvname
			if {$dvv($w,expandall) && \
					![string match ">sys>bin>*" $path>$dvname]} {
				Tree:open $w $path>$dvname
			}
		}
	}
}

proc dvv_expand {w {except {}}} {
	#puts "dvv_expand $w $except"
	Tree:openAll $w > $except
}

proc dvv_collapse {w} {
	Tree:closeAll $w >
}

proc dv_sizeof {dvptr} {
	set sz 0
	incr sz [string length [dv_getname -root $dvptr]]
	incr sz [string length [dv_get -root $dvptr]]
	foreach ptr [dv_getgbs -root $dvptr *] {
		incr sz [dv_sizeof $ptr]	
	}
	return $sz
}

proc dvv_getdvptr {w} {
	global dvv
	#puts "[dv_getname -root $dvv($w,dvptr)] is root,"
	#puts "[dv_getname -root [dv_sublist -root $dvv($w,dvptr)]] is first in sublist."
	return [dv_sublist -root $dvv($w,dvptr)]
}

proc dvv_browse {w args} {
	global dvv tcl_platform
	set passedargs {}
	set dvv($w,filename) ""
	set dvv($w,expandall) 0
	set dvv($w,showlineends) 0
	for {set n 0} {$n<[llength $args]} {incr n} {
		set arg [lindex $args $n]
		switch -- $arg {
			"-file" {
				incr n
				set dvv($w,filename) [lindex $args $n]
			}
			"-expandall" {
				incr n
				set dvv($w,expandall) [lindex $args $n]
			}
			"-showlineends" {
				set dvv($w,showlineends) 1
			}
			default {
				lappend passedargs $arg
			}	
		}
	}
   eval Tree:create $w > $passedargs
	
	if {$dvv($w,filename)!=""} {
		set fid [open $dvv($w,filename) r]
		set dvvtmp [dv_set >dvv>$w]
		#puts "dvvtmp=$dvvtmp"
		set dvv($w,dvptr) $dvvtmp
		
		if [catch {dv_restore -root $dvvtmp $fid} errmsg] {
			close $fid
			set fid [open $dvv($w,filename) r]
			set row 1
			set braceCount 0
			set lineIn [gets $fid]
			while {![eof $fid]} {
				if {[regexp ".+\}.*" [string trim $lineIn]]} {
					if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
						an_lg [dv_get >name]_err "ERROR: Mismatched braces in file, possibly starting at row $row."
					} else {
						puts "[dv_get >name]: ERROR: Mismatched braces in file, possibly starting at row $row."
					}
					close $fid
					exit
				} else {
					if {[string index [string trimleft $lineIn] 0] == "\{"} {
						incr braceCount
					} elseif {[string index [string trimleft $lineIn] 0] == "\}"} {
						incr braceCount -1
					}
					if {$braceCount < 0} {
						if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
							an_lg [dv_get >name]_err "Mismatched braces in file, possibly extra close-brace at row $row."
						} else {
					  		puts "[dv_get >name]: ERROR: Mismatched braces in file, possibly extra close-brace at row $row."
					  	}
					  close $fid
					  exit
					}
				}
				incr row
				set lineIn [gets $fid]
			}
			if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
				an_lg [dv_get >name]_err "ERROR: $errmsg"
			} else {
				puts "[dv_get >name]: ERROR: $errmsg"
			}
			close $fid
			exit
		}		
		
		
		close $fid
		dvv_populate $w $dvvtmp {}
	}
	bind $w <Destroy> "catch {dv_delete -root $dvvtmp}"
#	$w bind label <1> {
#	  set lbl [Tree:labelat %W %x %y]
#	  Tree:setselection %W $lbl
#	}
#	$w bind value1 <1> {
#	  set lbl [Tree:labelat %W %x %y]
#	  Tree:setselection %W $lbl
#	}

	return $w
}

proc choose_dv_viewer {} {
    global options
    set geometry "+[winfo pointerx .]+[winfo pointery .]"
    toplevel .cdv
    wm geometry .cdv $geometry

    button .cdv.ok -text "  OK  " -command "destroy .cdv"
    pack .cdv.ok -side bottom

    label .cdv.lab -text "DV Viewer Command:"
    pack .cdv.lab -side left

    radiobutton .cdv.anp -text "anp" -value anp \
        -variable options(dvviewer)
    pack .cdv.anp -side left

    radiobutton .cdv.vi -text "VI" -value "xterm -e vi" \
        -variable options(dvviewer)
    pack .cdv.vi -side left

    radiobutton .cdv.dvv -text "dvb" -value "dvb -f" \
        -variable options(dvviewer)
    pack .cdv.dvv -side left

    entry .cdv.ent \
        -textvariable options(dvviewer)
    pack .cdv.ent -side left
    grab .cdv
}


