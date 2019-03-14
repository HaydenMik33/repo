# $Id: fileselect.tcl.in,v 1.1 2002/02/18 18:29:53 xsphcamp Exp $
# $Log: fileselect.tcl.in,v $
# Revision 1.1  2002/02/18 18:29:53  xsphcamp
# Where appropriate: added auto-generation of version.tcl and tclIndex, and
# replacement of CREATION_DATE. This required the addition of
# build_tools/build_tclIndex.tcl. All the TK dev tools should now at least put up
# a window.
#
# I hereby declare this version 1.1.2 and suitable for personal use.
#
# Revision 1.6  1999/08/24 14:56:55  karl
# Added an_escquotes proc.
#
# Revision 1.5  1998/01/05  23:18:51  karl
# Added newfileselect to use native file select dialog in TK4.2+.  Had
# to patch bug with defaultextension until TK8.0.
#
# Revision 1.4  1997/11/11  23:08:37  karl
# Removed Delete and Rmdir buttons, which are very evil critters if clicked
# accidentally.
#
# Revision 1.3  1997/10/29  20:44:51  love
# Modified fileselect to Use the "file join" command to make a
# file path from the directory and file name instead of doing it
# manually.  The manual way would have required modifications on NT.
# The join option to the file command is new for Tcl7.6, so this
# is not used (the old way is) when running Tcl7.4.
#
# Revision 1.2  1997/10/29  19:59:41  love
# Modified the fileselect command to use the newer file command
# functions instead of exec'ing unix processes when using tcl7.6 or
# newer.
# Added a listfile function which will use the file command's functions
# to mimic "ls -al" when using tcl7.6 or newer.  Due to limitations
# of tcl7.4 and older, the listfile command spawns "ls".
# Added a tempfilename function to create a temporary file name for
# NT or Unix.
#
# Revision 1.1  1996/08/27  15:39:35  karl
# Initial revision
#
set astk_version "CREATION_DATE"

proc get_astk_version {} {
	global astk_version
	return $astk_version
}

########################################################################
# The following procedures are patches to fix a "defaultextension" bug
# in TK 4.2 (TCL 7.6).  First, we load the real procs to make sure they
# don't get autoloaded back over ours later, then we redefine the two
# procs affected.  This bug is fixed in TK 8.0.

if {$tcl_version=="7.6"} {
source $env(TK_LIBRARY)/tkfbox.tcl
proc tkFDialogResolveFile {context text defaultext} {

    set appPWD [pwd]
    set path [file join $context $text]

    if {[file ext $path] == ""} {
	set path "$path$defaultext"
    }

    if [catch {file exists $path}] {
	return [list ERROR $path ""]
    }

    if [file exists $path] {
	if [file isdirectory "./$path"] {
	    if [catch {
		cd $path
	    }] {
		return [list CHDIR $path ""]
	    }
	    set directory [pwd]
	    set file ""
	    set flag OK
	    cd $appPWD
	} else {
	    if [catch {
		cd [file dirname $path]
	    }] {
		return [list CHDIR [file dirname $path] ""]
	    }
	    set directory [pwd]
	    set file [file tail $path]
	    set flag OK
	    cd $appPWD
	}
    } else {
	set dirname [file dirname $path]
	if [file exists $dirname] {
	    if [catch {
		cd $dirname
	    }] {
		return [list CHDIR $dirname ""]
	    }
	    set directory [pwd]
	    set file [file tail $path]
	    if [regexp {[*]|[?]} $file] {
		set flag PATTERN
	    } else {
		set flag FILE
	    }
	    cd $appPWD
	} else {
	    set directory $dirname
	    set file [file tail $path]
	    set flag PATH
	}
    }

    return [list $flag $directory $file]
}

proc tkFDialog_ActivateEnt {w} {
    upvar #0 $w data

    set text [string trim [$data(ent) get]]
    set list [tkFDialogResolveFile $data(selectPath) $text \
		  $data(-defaultextension)]
    set flag [lindex $list 0]
    set path [lindex $list 1]
    set file [lindex $list 2]
    
    case $flag {
	OK {
	    if ![string compare $file ""] {
		# user has entered an existing (sub)directory
		set data(selectPath) $path
		$data(ent) delete 0 end
	    } else {
		tkFDialog_SetPathSilently $w $path
		set data(selectFile) $file
		tkFDialog_Done $w
	    }
	}
	PATTERN {
	    set data(selectPath) $path
	    set data(filter) $file
	}
	FILE {
	    if ![string compare $data(type) open] {
		tk_messageBox -icon warning -type ok \
		    -message "File \"[file join $path $file]\" does not exist."
		$data(ent) select from 0
		$data(ent) select to   end
		$data(ent) icursor end
	    } else {
		tkFDialog_SetPathSilently $w $path
		set data(selectFile) $file
		tkFDialog_Done $w
	    }
	}
	PATH {
	    tk_messageBox -icon warning -type ok \
		-message "Directory \"$path\" does not exist."
	    $data(ent) select from 0
	    $data(ent) select to   end
	    $data(ent) icursor end
	}
	CHDIR {
	    tk_messageBox -type ok -message \
	       "Cannot change to the directory \"$path\".\nPermission denied."\
		-icon warning
	    $data(ent) select from 0
	    $data(ent) select to   end
	    $data(ent) icursor end
	}
	ERROR {
	    tk_messageBox -type ok -message \
	       "Invalid file name \"$path\"."\
		-icon warning
	    $data(ent) select from 0
	    $data(ent) select to   end
	    $data(ent) icursor end
	}
    }
}

}
################## End of defaultextension 7.6 patch

proc newfileselect {{parentwin .} mode args} {
	global tcl_version
	if {$tcl_version=="7.4"} {
    		set i [lsearch $args "-patt"]
    		if {$i >= 0} {
			set pattlist [lindex $args [expr $i + 1]]
			set defext [lindex [lindex $pattlist 0] 1]
			set args [lreplace $args [expr $i + 1] [expr $i + 1] \
				$defext]
		}
		set rv [eval fileselect $args]
		return $rv
	}
    
    set inpwd [pwd]
    set i [lsearch $args "-patt"]
    set gfargs {}
    if {$i >= 0} {
		incr i
		set pattlist [lindex $args $i]
		set defext [lindex [lindex $pattlist 0] 1]
		set periodpos [string first "." $defext]
		if {$periodpos>=0} {
			lappend gfargs -defaultextension
			lappend gfargs [string range $defext $periodpos end]
	
		}
		lappend gfargs -filetypes
		lappend gfargs $pattlist
    }
    set dir [pwd]
    set i [lsearch $args "-dir"]
    if {$i >= 0} {
		incr i
		lappend gfargs -initialdir
		set dir [lindex $args $i]
		if {$dir=="."} {
			set dir [pwd]
		}	
		lappend gfargs $dir
    }

    set i [lsearch $args "-file"]
    if {$i >= 0} {
		incr i
		set fnin [lindex $args $i]
		set dir [file dirname $fnin]
		if {$dir=="."} {
			set dir [pwd]
		}
		lappend gfargs -initialdir
		lappend gfargs $dir
		lappend gfargs -initialfile
		lappend gfargs [file tail $fnin]
    } 
    lappend gfargs -parent
    lappend gfargs $parentwin
    if {$mode=="open"} {
    	set rv [eval tk_getOpenFile $gfargs]
    } else {
    	set rv [eval tk_getSaveFile $gfargs]
    }
	destroy $parentwin.__tk_filedialog
	
	set outdir [file dirname $rv]
	if {""!=$rv && [string compare $outdir $inpwd]} {
		cd $outdir	
	}
	return $rv
}

set fs_count 0
proc fileselect { args }  {
    
    global fs_count
    incr fs_count
    set w [toplevel .fileselect$fs_count] 
    
    #wm withdraw $w
    wm title $w "Select File"
    
    global DirName
    global FileName
    set FileName {}
    global Pattern
    global Done
    set Done ""

    canvas $w.c1
    pack $w.c1 -side top
    label $w.labeldir -text "Directory:"
    button $w.parent -text "Parent" -command " cdto {..} $w ; ChDir $w"
    button $w.home -text "Home" -command " cdto {HOME} $w; ChDir $w "
    button $w.root -text "Root" -command " cdto {/} $w; ChDir $w "
    pack $w.labeldir $w.parent $w.home $w.root \
	    -side left -in $w.c1 -padx 2m -pady 2m
    
    entry $w.dirname -width 40 -relief sunken -bd 2 -textvariable DirName
    pack  $w.dirname -side top -after $w.c1 -fill x -padx 1m -pady 2m
    
    
    canvas $w.c2
    pack $w.c2 -side bottom
    label $w.labelfile -text "File:"
    #button $w.delete -text "Delete" -command "Delete $w"
    #button $w.rmdir -text "rmdir" -command "RmDir $w"
    button $w.mkdir -text "mkdir" -command "MakeDir $w"
    button $w.rename -text "Rename" -command "Rename $w"
    pack $w.labelfile $w.mkdir $w.rename \
	    -side left -in $w.c2 -padx 2m -pady 2m
    
    entry $w.filename -width 40 -relief sunken -bd 2 \
	    -textvariable FileName
    ###pack $w.filename -side bottom 
    pack  $w.filename -side bottom -before $w.c2 \
	    -fill x -padx 1m -pady 2m
    
    canvas $w.c3
    pack $w.c3 -side bottom -before $w.filename
    label $w.lpatt -text "show:"
    entry $w.pattern -width 10  -relief sunken -bd 2 -textvariable Pattern
    button $w.ok -text "OK" -command "destroy $w ; AcceptSelection"
    button $w.cancel -text "Cancel" -command "global FileName; set FileName {};
		destroy $w"
    pack $w.lpatt $w.pattern $w.ok $w.cancel -side left \
	    -in $w.c3 -padx 3m -pady 2m
    
    listbox $w.dirs -relief sunken -borderwidth 3 \
	    -yscrollcommand "$w.scrolldir set" -setgrid 1
    pack $w.dirs -side left -expand 1 -fill both
    scrollbar $w.scrolldir -command "$w.dirs yview"
    pack $w.scrolldir -side left -after $w.dirs -fill y
    
    listbox $w.files -relief sunken -borderwidth 3 \
	    -yscrollcommand "$w.scrollfile set" \
	    -setgrid 1
    bindtags $w.files "Listbox $w.files . all"
    bind $w.files <Button-1> {FileSelection}
    pack $w.files -side right -expand 1 -fill both
    scrollbar $w.scrollfile -command "$w.files yview"
    pack $w.scrollfile -side right -before $w.files -fill y
    
    bind $w.filename <Return> "destroy $w ; AcceptSelection ; break"

	## these bindings are already implemented in the main tk libraries;
    ## same goes for $w.dirname below
    # bind $w.filename <Left> "EntryCursor $w.filename -1"
    # bind $w.filename <Right> "EntryCursor $w.filename 1"

    bind $w.filename <2> "$w.filename insert insert \"[GetXSelect]\""
    bind $w.dirname <Return> "ChDir $w"
    # bind $w.dirname <Left> "EntryCursor $w.dirname -1"
    # bind $w.dirname <Right> "EntryCursor $w.dirname 1"
    bind $w.dirname <2> "$w.dirname insert insert \"[GetXSelect]\""
    bind $w.files <Double-Button-1> "destroy $w ; AcceptSelection ; break"
    bind $w.pattern <Return> "ChDir $w"
    bind $w.dirs <Double-Button-1> "DirSelection $w"
    bind $w.dirs <1> { }


    set i [lsearch $args "-patt"]
    if {$i >= 0} {
	incr i
	set Pattern [lindex $args $i]
    } else {
	set Pattern "*"
    }
    
    set i [lsearch $args "-dir"]
    if {$i >= 0} {
	incr i
	cdto [lindex $args $i] $w
    } else {
	set DirName [pwd]
	ChDir $w
    }

    set i [lsearch $args "-file"]
    if {$i >= 0} {
	incr i
	set dirin [file dirname [lindex $args $i]]
	set fnin [file tail [lindex $args $i]]
	cdto $dirin $w
	set FileName $fnin
    } 
    
    #wm deiconify $w
 
    focus $w.filename

    set DoExecute ""
    
#    while { $Done != "Finished" }  {
#	after 50
#	update
#	set wt [selection own]
#	if {"$wt" == "$w.files"}  {
#	    FileSelection
#	}
#    }
    tkwait window $w
    
    return $FileName
}

proc EntryCursor {w dir} {
   set x [$w index insert]
   set x [expr $x + $dir]
   $w icursor $x
}

proc GetXSelect { }  {
    set s ""
    catch {set s [selection get STRING]}
    return "$s"
}

proc ChDir { w } {
    global DirName Pattern
    cd $DirName
    $w.dirs delete 0 end
    $w.files delete 0 end
    $w.dirs insert end ".."
    if {[catch {set allfiles [glob *]}]} {return}
    foreach i [lsort $allfiles] {
	if { [file isdirectory $i] } {
	    $w.dirs insert end $i
	} else {
	    if {[string match $Pattern $i]} {$w.files insert end $i}
	}
    }
}

proc AcceptSelection { } {
	global DirName FileName Done tcl_version
	if { $tcl_version == "7.4" } {
		set s $DirName
		set l [string length $s]
		if {$l > 0} {
				set s ${s}/
		}
		if {$FileName!=""} {
				set FileName ${s}${FileName}
		}
	} else {
		set FileName [file join $DirName $FileName]
	}
	set Done Finished
}

proc FileSelection { } {
	global DirName FileName
	catch {
		set f [selection get]
		set FileName $f
	}
}

proc DirSelection { w } {
    global DirName FileName
    set f [selection get]
    cd $f
    set DirName [pwd]
    ChDir $w
}

proc cdto { dir w }  {
    global DirName FileName
    if { $dir == "HOME" } { 
	cd 
    } else { 
	if {[catch {cd $dir }]} {
		tk_dialog .tmp "ERROR" \
			"Directory $dir doesn't exist or can't be accessed!" {} 0 OK
	}
    }
    set DirName [pwd]
    ChDir $w
}

proc RmDir { w } {
    global DirName FileName tcl_version
    
	if { $tcl_version == "7.4" } {
    	set s "exec rmdir $DirName"
	} else {
		set s "file delete -force $DirName"
	}
    cdto ".." $w
    eval $s
    ChDir $w
}

proc Delete { w } {
    global DirName FileName tcl_version
    
	if { $tcl_version == "7.4" } {
    	set s "exec rm $FileName"
	} else {
		set s "file delete -force $FileName"
	}
    set FileName ""
    eval $s
    ChDir $w
}

proc Rename { w } {
    global DirName FileName OldName
    
    set OldName $FileName
    set FileName ""
    focus $w.filename
    bind $w.filename <Return> "DoRename $w ; break"
}

proc DoRename { w } {
    global DirName FileName OldName tcl_version
    
	if { $tcl_version == "7.4" } {
    	set s "exec mv $OldName $FileName"
	} else {
    	set s "file rename -force $OldName $FileName"
	}
    set FileName ""
    eval $s
    bind $w.filename <Return> "AcceptSelection; destroy $w ; break"
    ChDir $w
}

proc MakeDir { w } {
    global DirName FileName
    
    set FileName ""
    focus $w.filename
    bind $w.filename <Return> "DoMakeDir $w ; break"
}

proc DoMakeDir { w } {
    global DirName FileName tcl_version
    
	if { $tcl_version == "7.4" } {
    	set s "exec mkdir $FileName"
	} else {
    	set s "file mkdir $FileName"
	}
    set FileName ""
    eval $s
    bind $w.filename <Return> "destroy $w ; AcceptSelection ; break"
    ChDir $w
}

proc listfile { fn } {

	global tcl_version
	if { $tcl_version == "7.4" } {
		return [exec ls -al $fn]

	} else {
		# get file information
		file stat $fn statbuf

		# Initialize permissions string
		set perms ""

		# Initialize check for rwx, 01 octal
		set p 01

		# Initialize check for set id on execute check, 01000 octal
		set s 01000

		# Loop 3 times to check world, group, and own permissions
		for {set i 0} {$i < 3} {incr i +1} {
			# iteration 1:
			# s == 01000 			- meaningless check, not possible
			# p == 01, 02, 04 		- check world rwx permissions
			# iteration 2:
			# s == 02000 			- check for group set id on execution
			# p == 010, 020, 040 	- check group rwx permissions
			# iteration 3:
			# s == 04000 			- check for user set id on execution
			# p == 0100, 0200, 0400	- check user rwx permissions

			# Check for set user id and execute permissions
			set perms [expr { ($statbuf(mode) & $s) ? "s" :
				[expr { ($statbuf(mode) & $p) ? "x" : "-" }] }]$perms
			set p [expr $p << 1]
			set s [expr $s << 1]

			# Check for write permissions
			set perms [expr { ($statbuf(mode) & $p) ? "w" : "-" }]$perms
			set p [expr $p << 1]

			# Check for read permissions
			set perms [expr { ($statbuf(mode) & $p) ? "r" : "-" }]$perms
			set p [expr $p << 1]


		}

		# Initialize directory check, 040000 octal
		set d 040000
		set perms [expr { ($statbuf(mode) & $d) ? "d" : "-" }]$perms

		# Create time string
		set timedate [clock format $statbuf(ctime) -format "%b %d %H:%M"]

		return [format "%s %3.3s %-9.9s%-9.9s %6.6s %s %s" \
			$perms $statbuf(nlink) $statbuf(uid) $statbuf(gid) \
			$statbuf(size) $timedate $fn]

	}
}

proc tempfilename { prefix } {
	global tcl_platform env

	# See if user defined TMP environment variable
	if {[info exists env(TMP)] && [file isdirectory $env(TMP)]} {
		set tmpdir $env(TMP)

	# See if user defined TEMP environment variable (NT)
	} elseif {[info exists env(TEMP)] && [file isdirectory $env(TEMP)]} {
		set tmpdir $env(TEMP)

	# Try to use HOME directory (Unix only)
	} elseif {[info exists env(HOME)] && [file isdirectory $env(HOME)]} {
		set tmpdir $env(HOME)

	# Try to Use $HOMEDRIVE/$HOMEPATH (NT only)
	} elseif {[info exists $env(HOMEDRIVE)] && 
			[info exists $env(HOMEPATH)] && 
				[file isdirectory $env(HOMEDRIVE)/$env(HOMEPATH)]} {
		set tmpdir $envHOMEDRIVE$env(HOMEPATH)

	# Use C:/temp if NT
	} elseif {[info exists tcl_platform] && 
				$tcl_platform(platform) == "windows"} {	
		set tmpdir C:/temp
		# Create the directory if it doesn't exist.
		if {![file isdirectory $tmpdir]} {
			file mkdir $tmpdir
		}

	# Use /tmp
	} else {
		set tmpdir /tmp

	}

	# If on NT, substitute the '\' for a '/'
	if {[info exists tcl_platform] && $tcl_platform(platform) == "windows"} {
		regsub -all {\\} $tmpdir / tmpdir
	}

	# loop through temporary files until one doesn't exist.
	for {set ndx 0} {[file isfile $tmpdir/$prefix$ndx]} {incr ndx +1} {}

	return "$tmpdir/$prefix$ndx"
}

proc an_escquotes {str} {
        set len [string length $str]
        set newstr ""
        for {set n 0} {$n<$len} {incr n} {
                set c [string index $str $n]
                if {$c=="\"" || $c=="\\"} {
                        append newstr "\\"
                }
                append newstr $c
        }
        return $newstr
}

