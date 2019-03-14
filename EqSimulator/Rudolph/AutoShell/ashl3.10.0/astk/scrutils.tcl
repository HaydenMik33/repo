
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: scrutils.tcl,v 1.4 1997/12/09 16:41:54 karl Exp $
# $Log: scrutils.tcl,v $
# Revision 1.4  1997/12/09 16:41:54  karl
# Fixed stack trace caused by treating script file lines as lists.
#
# Revision 1.3  1997/12/05  17:12:44  karl
# Fixed bug caused by treating script lines as TCL lists.
#
# Revision 1.2  1997/10/29  20:11:11  love
# Modified push_script to create temporary file names with the
# tempfilename command instead of manually.
# Modified push_script to use the file command to rename files instead
# of spawning mv when using tcl7.6 or newer.
#
# Revision 1.1  1996/08/27  16:17:08  karl
# Initial revision
#
##########
### pull_script
###
### Purpose
###   - get the text of a script command, as well as the preceding
###     comments, out of a file
###
### Parameters
###   - scrfilename is the name of the file.  It can be a list of files
###   - scriptname is the name of the command to be pulled.
##########

proc pull_script {scrfilename scriptname} {
    upvar 1 $scrfilename scrlist
    set currname {}
    set currbody {}
    foreach scr $scrfilename {
		set fid ""
		catch {set fid [open $scr r]}
		if {$fid==""} {
			continue
		}
		while {[gets $fid ln]>=0} {
			set firstword [lindex [split $ln " \t"] 0]
			if {$firstword=="startscript"} {
				set currname [lindex [split $ln " \t"] 1]
				append currbody $ln\n
			} elseif {$firstword=="endscript"} {
				append currbody $ln\n
				if {$currname==$scriptname} {
					close $fid
					lappend response $currbody 
					lappend response $scr
					return $response
				} else {
					set currname {}
					set currbody {}
				}
			} elseif {($currname != {}) || ([string index $ln 0] == "#")}  {
				append currbody $ln\n
			}
		}
    }
    return ""
}



##########
### get_script_names
###
### Purpose
###   - get a list of available scripts from a file
###
### Parameters
###   - scrfilename is the file to get the scriptnames from
##########

proc get_script_names { scrfilename }  {
	set fid ""
        set script_list {}
	catch {set fid [open $scrfilename r]}
	if {$fid == ""}  {
		return 
	}
	while {[gets $fid line] >= 0}  {
		set firsttoken [lindex [split $line {  }] 0]
		if {$firsttoken == "startscript" ||
			$firsttoken == "an_proc"}  {
			lappend script_list [lindex [split $line { 	}] 1]
		}
	}
	close $fid
	return $script_list
}
	


##########
### push_script
###
### Purpose
###   - to push the text text of a script back into a file
###
### Parameters
###   - scrfilename is the name of the file
###   - scriptname is the name of the script
###   - text is the data to be inserted into the file
##########

proc push_script {scrfilename scriptname text} {
	set tmpfile [tempfilename es[pid]]
    set fid ""
    set fido [open $tmpfile w]
    catch {set fid [open $scrfilename r]}
    set done 0
    while {$fid!="" && [gets $fid ln]>=0} {
	set firstword [lindex [split $ln " \t"] 0]
	if {$firstword=="startscript"} {
	    set currname [lindex [split $ln " \t"] 1]
	    append currbody $ln\n
	} elseif {$firstword=="endscript"} {
	    append currbody $ln\n
	    if {$currname==$scriptname} {
		puts $fido $text
		set done 1
		set currname {}
		set currbody {}
	    } else {
		puts $fido $currbody
		set currname {}
		set currbody {}
	    }
	} else {
	    append currbody $ln\n
	}
    }
    if {$fid!=""} {
	close $fid
    }
    if {$done==0} {
	puts -nonewline $fido "\n$text\n"
    }
    close $fido
	global options
	if {[info exists options] && [info exists options(backupfiles)] &&
			 $options(backupfiles) == 1} {
		catch {file rename -force $scrfilename $scrfilename~}
	}
    file rename -force $tmpfile $scrfilename
}

#
# deletes the named script from the specified file
# does error checking to make sure it can open file for reading, writing
# and that the script actually exists in the file
#
proc delete_script {filename script} {
 
   if {[catch {set file [open $filename]}]} {
      return -1
   }
   text .abc_xyz
   .abc_xyz insert end [read $file]
   close $file
 
   set begin [.abc_xyz search -regexp  "^startscript $script" 1.0]
   if {$begin == ""} { destroy .abc_xyz ; return -2 }
   set end   [.abc_xyz search -regexp "^end" $begin]
   if {$end   == ""} { destroy .abc_xyz ; return -2 }
 
   set beginline [lindex [split $begin .] 0]
   set endline   [lindex [split $end   .] 0]
   set prevline  [expr $beginline - 1]
 
   while {[string index [.abc_xyz get $prevline.0 $prevline.end] 0] == "#"} {
      incr prevline -1
   }
   set beginline [expr $prevline + 1]
   .abc_xyz delete "$beginline.0 linestart" "$endline.0 lineend"
 
   if {[catch {set file [open $filename w]}]} {
      destroy .abc_xyz
      return -1
   }
   puts $file "[.abc_xyz get 1.0 end]"
   close $file
 
   destroy .abc_xyz
   return 1
}
