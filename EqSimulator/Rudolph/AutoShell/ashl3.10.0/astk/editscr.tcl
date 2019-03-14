
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: editscr.tcl,v 1.22 2000/12/14 22:56:05 karl Exp $
# $Log: editscr.tcl,v $
# Revision 1.22  2000/12/14 22:56:05  karl
# Fixed find_configfile_names to see a top-level tclstartup file.  If
# there are both AS and Tcl startup files, it will still only see
# the AS startup file.
#
# Revision 1.21  2000/11/27 21:34:35  karl
# Added "movefile" option to delete_script2 to support orphan script save
# in SFCE.
#
# Revision 1.20  2000/09/11  21:59:37  karl
# Added "Abort" button on script rename warning window.
#
# Revision 1.19  2000/08/02  20:18:01  karl
# Added warnings when file struct file not readable or no startup file.
#
# Revision 1.18  2000/07/07  21:26:57  karl
# Changed an_file_structure to record file type in results.
# Changed methods to return error codes.
# Added "write" mode to pull_script2 to warn if file is not writable.
#
# Revision 1.17  1999/08/23  23:04:52  karl
# Fixed script pull/push to be generic.
#
# Revision 1.16  1999/06/02  17:35:07  karl
# Added find_configfile_names proc.
#
# Revision 1.15  1999/05/11  23:09:45  karl
# Fixed bug that caused duplicate scripts in .scr file if "endscript" w
# indented.
#
# Revision 1.14  1999/01/22  16:18:00  jasonm
# fixed bug which caused stack trace in pull_script2 when trying to
# save a script to a file that exists, but is empty (SCR si001955)
#
# Revision 1.13  1998/12/11  21:07:13  karl
# Fixed find_command_names to not assume all script lines are valid TCL
# lists.
#
# Revision 1.12  1998/12/08  21:06:37  karl
# Fixed file pointer leak that occurred when looking for existing scripts
# in a script file.
#
# Revision 1.11  1998/10/20  21:51:49  karl
# Added support for Java code.  Fixed bug where tclinclude was not
# recognized by find_all_names command.
#
# Revision 1.10  1998/05/26  15:18:53  karl
# Fixed file pointer leak that occurred when finding script names in a file.
#
# Revision 1.9  1997/12/09  23:08:42  jasonm
# commented out some puts's used for debuggin
#
# Revision 1.8  1997/12/09  16:16:41  jasonm
# whoops. missed a few lindex commands in rev. 1.7
#
# Revision 1.6  1997/10/29  20:06:44  love
# Modified push_script2 and delete_script2 to use a more portable
# method of manipulating files, the file command, when using
# tcl7.6 or newer.  Modified them to create temporary files with
# the tempfilename command instead of manually.
#
# Revision 1.5  1997/05/23  17:02:58  karl
# Added find_script_names command to search nested startups for
# script file loads.  Added pull_script_mult to consider multiple
# scripts when pulling a script from .scr files.  Fixed bugs in
# pull_script functions caused when lines were not valid TCL lists.
# Added push_script_mult,
#
# Changed sfce array name to astk, since this code is no longer specific
# to sfce.  Fixed push_script to allow new script text to have new
# script name.
#
# Revision 1.4  1997/05/13  17:11:05  karl
# Fixed bug that would cause stack traces if a script line had
# curly braces or unmatched quotes, caused by inappropriate lindex usage.
#
# Revision 1.3  1996/10/16  20:04:44  jasonm
# changed the default permissions passed to the tcl open command to those
# used by tcl (0666)
#
# Revision 1.2  1996/10/16  19:47:53  jasonm
# added ability to set the permissions of the script file that is created
#
# Revision 1.1  1996/08/27  16:13:01  karl
# Initial revision



set LB "{"
set RB "}"
proc find_command_names {filename type} {

	#puts "find_command_names filename=$filename type=$type"
	if {![file exists $filename]}  {
		return
	}
	
	set command_names ""
	set if [open $filename r]
	
	if {![string compare $type SL]}  {
		set exp {^startscript [a-zA-Z1-9]*}
		# puts $exp
	} elseif {![string compare $type JAVA]}  {
		set exp {^new Command\("[a-zA-Z1-9]*}
	} elseif {![string compare $type TCL]}  {
		set exp {^an_proc [a-zA-Z1-9]*}
		# puts $exp
	}
		
	while {[gets $if line] >= 0}  {
		if {[regexp $exp $line]}  {
			if {$type=="JAVA"} {
				lappend command_names [lindex \
					[split $line {"}] \ 1]
			} else {
				set words [split $line "\n\t "]
				set words2 {}
				foreach word $words {
					lappend words2 $word
				}
				#puts "appending '[lindex $words2 1]'"
				lappend command_names [lindex $words2 1]
			}
		}
	}
	
	close $if
	return $command_names 
	#puts "command_names=$command_names"
}

# Look through startup commands for names of scripts of all types. 
proc find_configfile_names {server callback} {
	#puts "sending get CWD"
	an_msgsend 0 $server "get CWD" -an_reply_cb \
		"find_configfile_names2 callback=\"$callback\""
}

an_proc find_configfile_names2 {} {} {} {
	# Fix these to work with tag-enclosed get results.
	#puts "sending get startup"
	an_msgsend 0 $fr "get startup" -an_reply_cb \
		"find_configfile_names3 CWD=$CWD callback=\"$callback\""
}

an_proc find_configfile_names3 {} {} {} {
	#puts "sending get tclstartup"
	an_msgsend 0 $fr "get tclstartup" -an_reply_cb \
		"find_configfile_names4 CWD=$CWD startup=$startup \
		callback=\"$callback\""
}

an_proc find_configfile_names4 {} {} {} {
	if {$startup=="none" && [info exists tclstartup]} {
		set startup $tclstartup
	}
	if {[string index $startup 0]!="/"} {
		global env
		if { [info exists tcl_platform] && \
			$tcl_platform(platform)=="windows" && \
			[string index $startup 1] != ":" } {
			set startup $CWD/$startup
		}
	}
	an_delete_cb $currenv
	if {[file tail $startup]=="none"} {
		tk_dialog .err WARNING "No startup files." \
			warning 0 OK
		return
	}
	eval $callback "{[an_file_structure $startup]}"
}

proc an_file_structure {filetoscan {type {}}} {
	global tcl_platform
	#puts "an_file_structure called for $filetoscan"
	set directory [file dirname $filetoscan]
#	if {[file tail $filetoscan]=="none"} {
#		tk_dialog .err WARNING "No startup files." \
#			warning 0 OK
#		return
#	}
	if {![file readable $filetoscan]} {
		tk_dialog .err ERROR "Couldn't open $filetoscan for reading!" \
			error 0 OK
		return
	}
	set fid [open $filetoscan r]
	set contents [read $fid]	
	close $fid
	set subfiles {}
	foreach cmd [split $contents "\n"] {
		if {[string trim $cmd]==""} {
			continue
		}
		#puts "Checking $cmd..."
		# Grab first three words
		scan $cmd "%s%s%s" cmdname arg1 arg2

		# If it is an include command, recurse
		if {[info exists cmdname] && $cmdname=="include" && \
		    [info exists arg1]} {
			#puts "Checking inside $arg1"
			set filename [string trim [lindex [split $arg1 =] 1] \"]
			regsub {\(rel\)} $filename "" filename
			if {[string index $filename 0]!="/"} {
				set filename $directory/$filename
			}
			if {[file readable $filename]} {
				#set sf [open $filename r]
				#set subcontents [read $sf]
				#close $sf
				#puts "looking in $filename"
				if {$type!=""} {
					set temp [an_file_structure $filename su]
				} else {
					set temp [an_file_structure $filename]
				}
				#puts "an_file_structure returned $temp"
				lappend subfiles "$temp" 
			}
		}
		# If it is a ldscript command, record script name.
		if {[info exists cmdname] && $cmdname=="ldscript" && \
		    [info exists arg1]} {
			#puts "recording $arg1"
			set value [string trim [lindex [split $arg1 =] 1] \"]
			regsub -all {\(rel\)} $value "" value
			if { [info exists tcl_platform] && \
					$tcl_platform(platform)=="windows" && \
					[string index $value 1] != ":" } {
				set value $directory/$value
			} else { if {[string index $value 0]!="/"} {
				set value $directory/$value
			}
			}
			
			if {$type!=""} {
				lappend subfiles scr:$value
			} else {
				lappend subfiles $value
			}
		}
		# If it is a restore command, record file name.
		if {[info exists cmdname] && $cmdname=="restore" && \
		    [info exists arg1]} {
			#puts "recording $arg1"
			set value [string trim [lindex [split $arg1 =] 1] \"]
			regsub -all {\(rel\)} $value "" value
			if {[string index $value 0]!="/"} {
				set value $directory/$value
			}
			if {$type!=""} {
				lappend subfiles dv:$value
			} else {
				lappend subfiles $value
			}
		}
		# If it is a tclinclude command, record script name.
		if {[info exists cmdname] && $cmdname=="tclinclude" && \
		    [info exists arg1]} {
			#puts "recording $arg1"
			set value [string trim [lindex [split $arg1 =] 1] \"]
			regsub -all {\(rel\)} $value "" value
			if { [info exists tcl_platform] && \
					$tcl_platform(platform)=="windows" && \
					[string index $value 1] != ":" } {
				set value $directory/$value
			} else { if {[string index $value 0]!="/"} {
				set value $directory/$value
			}
			}
			if {$type!=""} {
				lappend subfiles tcl:$value
			} else {
				lappend subfiles $value
			}
		}
		# If it is a loadcmdset command, record script name.
		if {[info exists cmdname] && $cmdname=="loadcmdset" && \
		    [info exists arg1]} {
			#puts "recording $arg1"
			set value [string trim [lindex [split $arg1 =] 1] \"]
			regsub -all {\(rel\)} $value "" value
			if {$type!=""} {
				lappend subfiles class:$value
			} else {
				lappend subfiles $value
			}
		}
	}
	if {$type!=""} {
		return "$type:$filetoscan {$subfiles}"
	} else {
		return "$filetoscan {$subfiles}"
	}
}

proc print_configfile_names {list indent} {
	set string ""
	for {set n 0} {$n<[expr $indent*5]} {incr n} { append string " "} 
	set dir [file dirname [lindex $list 0]]
	set nam [file tail [lindex $list 0]]
	append string "`-$nam {$dir}\n"
	foreach item [lindex $list 1] {
		append string [print_configfile_names $item [expr $indent+1]]
	}
	return $string
}
 

# Look through startup commands for names of scripts of all types. 
proc find_script_names {sucontents} {
	set scrnames {}
	foreach cmd [split $sucontents "\n"] {
		if {[string trim $cmd]==""} {
			continue
		}
		#puts "Checking $cmd..."
		# Grab first three words
		scan $cmd "%s%s%s" cmdname arg1 arg2

		# If it is an include command, recurse
		if {[info exists cmdname] && $cmdname=="include" && \
		    [info exists arg1]} {
			#puts "Checking inside $arg1"
			set filename [string trim [lindex [split $arg1 =] 1] \"]
			#puts "filename=$filename"
			regsub {\(rel\)} $filename "" filename
			#puts "filename=$filename"
			if {[file readable $filename]} {
				set sf [open $filename r]
				set subcontents [read $sf]
				close $sf
				#puts "looking in $filename"
				append scrnames " [find_script_names \
					$subcontents]"
			}
		}
		# If it is a ldscript command, record script name.
		if {[info exists cmdname] && $cmdname=="ldscript" && \
		    [info exists arg1]} {
			#puts "recording $arg1"
			set value [string trim [lindex [split $arg1 =] 1] \"]
			regsub -all {\(rel\)} $value "" value
			append scrnames " $value"
		}
		# If it is a tclinclude command, record script name.
		if {[info exists cmdname] && $cmdname=="tclinclude" && \
		    [info exists arg1]} {
			#puts "recording $arg1"
			set value [string trim [lindex [split $arg1 =] 1] \"]
			regsub -all {\(rel\)} $value "" value
			append scrnames " $value"
		}
		# If it is a loadcmdset command, record script name.
		if {[info exists cmdname] && $cmdname=="loadcmdset" && \
		    [info exists arg1]} {
			#puts "recording $arg1"
			set value [string trim [lindex [split $arg1 =] 1] \"]
			regsub -all {\(rel\)} $value "" value
			append scrnames " $value"
		}
	}
	#puts "find_script_names returning '$scrnames'"
	return $scrnames
}

# Checks for conflicts when the name of a script reference is changed.
proc check_script_conflict {newname newtype oldname oldtype basename 
		sucontents} {
	# If the name changed to something other than none.
	if {$newname!="" && $oldname!="" && \
			($oldname!=$newname || $oldtype!=$newtype)} {
		set scrfile ""
		# Look for an existing script of the old name in all files.
		set oldtext [pull_script_mult $basename \
			$sucontents $oldname scrfile]
		# If there was a script by the old name, ask whether
		# to rename it to the new name.
		if {$oldtext!=""} {
		    switch [file extension $scrfile] {
			    .scr {set existtype SL}
			    .tcl {set existtype TCL}
			    .java {set existtype JAVA}
		    }
		    # If user changed the command name
		    if {$oldname!=$newname} {
			set    msg "Do you want to rename command "
			append msg "\"$oldname\" to \"$newname\", "
			append msg "or just change the reference to "
			append msg "\"$newname\"?"
			set rc [tk_dialog .tmp "Script Name Change" \
				$msg questhead 0 \
				"Rename Command" "Change Reference" "Abort"]
			# If user chose to rename
			if {$rc==2} {
				return -1
			} elseif {$rc==0} {
				# Look for existing script by new name. 
				set existtext [pull_script_mult \
					$basename $sucontents $newname \
					scrfile]
				# If new name already in use, ask whether
				# to overwrite it or use it.
				if {$existtext!=""} {
					set    msg "There is already a command"
					append msg " named \"$newname\""
					append msg " in \"$scrfile\"."
					set rc [tk_dialog .tmp \
						"Script Name Conflict" \
						$msg questhead 0 \
						"Replace It" "Use Existing"]
					if {$rc==1} {
						return -1
					} else {
						return [delete_script2 $scrfile \
							$newname $existtype]
					}
				}	
				# New name is OK.
				# Change name in script code.
				set newtext [rename_script_mult $oldname \
					$oldtext $newname $newtype]
				# Delete the old script.
				delete_script2 $scrfile $oldname $oldtype
				# Write the new script
				push_script2 $scrfile $newname $newtext \
					$newtype 
			}
		    # If command of same name but diff type existed.
		    } elseif {$existtype!=$newtype} {
			set    msg "Do you want to delete the existing "
			append msg "\"$existtype\" script in \"$scrfile\"?"
			set rc [tk_dialog .tmp "Script Type Change" \
				$msg questhead 0 \
				"Delete Existing" "Cancel"]
			if {$rc==0} {
				# Delete the old script.
				return [delete_script2 $scrfile $oldname $existtype]
				# Write the new script
			} else {
				return -1
			}
		    }
		}
	}
	return 0
}

# Searches all scripts for a particular command
proc pull_script_mult {suname sucontents scriptname filevarname 
		{cmdtype ALL}} {
	#puts "pull_script_mult cmdtype=$cmdtype"
	upvar $filevarname filevar
	# Get names of all command files.
#	switch $cmdtype {
#		SL {set ext scr}
#		TCL {set ext tcl}
#		JAVA {set ext java}
#	}
	set scriptfiles "[file tail [file rootname $suname]].scr \
		[file tail [file rootname $suname]].tcl \
		[file tail [file rootname $suname]].java \
		[find_script_names $sucontents]"
	foreach scriptfile $scriptfiles {
		switch [file extension $scriptfile] {
			.scr { set filetype SL	}
			.tcl { set filetype TCL	}
			.java { set filetype JAVA }
		}
		set scripttext [pull_script2 $scriptfile $scriptname \
			$filetype]
			#puts "Scripttext returned is $scripttext "

		if {$scripttext!=""} {
			set filevar $scriptfile
			#puts "found $scriptname in $scriptfile"
			return $scripttext
		}
	}

}

# Pulls a specific command out of a specific script file or list of files
proc pull_script2 {scrfile scriptname {cmdtype SL} {accesstype write}} {
	#puts $df1 "pull_script2 cmdtype=$cmdtype scrfile=$scrfile scriptname=$scriptname"
	global LB RB
	set currname {}
	set currbody {}
	foreach scr $scrfile {
		set fid ""
		catch {set fid [open $scr r]}
		if {$fid==""} {
			#puts "Couldn't open $scr"
			continue
		}
		if {$cmdtype=="SL"} {
			while {[gets $fid ln]>=0} {
				#set firstword [lindex [split \
					[string trim $ln] " "] 0]
				set nw [scan $ln "%s%s" firstword \
					secondword]
				if {$nw>1 && $firstword=="startscript"} {
				#puts "startscript: currname=$currname"
					set currname $secondword
					append currbody $ln\n
				} elseif {$nw>0 && \
						$firstword=="endscript"} {
					append currbody $ln\n
					#puts "endscript: currname=$currname"
					if {$currname==$scriptname} {
						close $fid
						if {$accesstype=="write" && [warn_read_only $scr]} {
							return "Pull_Script_Abort"
						}
						set scrlist $scr
						#puts "pull_script2 returning: $currbody"
						return $currbody
					} else {
						set currname {}
						set currbody {}
					}
				} else {
					append currbody $ln\n
				}
			}
		} elseif {$cmdtype=="TCL"} {
			while {[gets $fid ln]>=0} {
				set currbody "$ln\n"
			        while {[regexp {^\s*(#.*)?$} $currbody] && \
                                       [gets $fid ln]>=0} {
					        set currbody "$ln\n"
				        }		
			        while {![info complete $currbody] && \
                                        [gets $fid ln]>=0} {
					        append currbody "$ln\n"
				        }		

					#puts "line: $ln"
                                
				if {[info complete $currbody] && \
					[lindex $currbody 1]==$scriptname} {
					close $fid
					if {$accesstype=="write" && [warn_read_only $scr]} {
						return "Pull_Script_Abort"
					}
					set scrlist $scr
					#puts "pull_script2 returning: $currbody"
					return $currbody
				} else {
					set currname {}
					set currbody {}
				}
			}
		} elseif {$cmdtype=="JAVA"} {
			while {[gets $fid ln]>=0} {
				set words [split [string trim $ln] " \t"]
				#puts "words='$words'"
				if {[llength $words]==4 && \
						[lindex $words 1]=="StartCmd"} {
					set currname [lindex $words 2]
					#puts "StartCmd: currname=$currname"
					set currbody ""
				} elseif {[llength $words]==3 && \
						[lindex $words 1]=="EndCmd"} {
					#puts "EndCmd: currname=$currname"
					#append currbody $ln\n
					if {$currname==$scriptname} {
						close $fid
						if {$accesstype=="write" && [warn_read_only $scr]} {
							return "Pull_Script_Abort"
						}
						set scrlist $scr
						#puts "pull_script2 returning: $currbody"
						return $currbody
					} else {
						set currname {}
						set currbody {}
					}
				} else {
					append currbody $ln\n
				}
			}
		}
		close $fid
	}
	return ""
}

proc push_script_mult {filenames scriptname text {cmdtype SL} {perms 0666}} {
	#puts "push_script_mult filenames={$filenames} scriptname=$scriptname text={$text} cmdtype=$cmdtype perms=$perms"
	if {[llength $filenames]>1} {
		toplevel .choose
		wm title .choose ""
		label .choose.l -text "Which File?"
		pack .choose.l
		set buttcount 1
		foreach filename $filenames {
			button .choose.b$buttcount -text $filename -command \
				"destroy .choose
				push_script2 $filename $scriptname {$text} \
					$cmdtype $perms"	
			pack .choose.b$buttcount
		}
		button .choose.cancel -text "Cancel" -command "destroy .choose"
		pack .choose.cancel -pady 10
	}
}

proc push_script2 {filename scriptname text {cmdtype SL} {perms 0666}} {
	#puts "push_script2 filename=$filename scriptname=$scriptname text={$text} cmdtype=$cmdtype perms=$perms"
	global LB RB
	set tmpfile [tempfilename edscr[pid]]
	set fid ""
	set fido [open $tmpfile w $perms]
	catch {set fid [open $filename r]}
	set done 0
	set currbody ""
	set newscriptname $scriptname
	if {$cmdtype=="SL"} {
		# Get name out of script text.
		set newscriptname [script_name $text $cmdtype]
		while {$fid!="" && [gets $fid ln]>=0} {
			set firstword [lindex [split [string trim $ln] \
				 "\t "] 0]
			if {$firstword=="startscript"} {
				set currname [lindex [split $ln "\t "] 1]
				append currbody $ln\n
			} elseif {$firstword=="endscript"} {
				append currbody $ln\n
				if {$currname==$scriptname} {
					puts $fido "[string trim $text]"
					set done 1
					set currname {}
					set currbody {}
				} else {
					puts $fido "[string trim $currbody]"
					set currname {}
					set currbody {}
				}
			} else {
				append currbody $ln\n
			}
		}
	} elseif {$cmdtype=="TCL"} {
		# Get name out of script text.
		set newscriptname [script_name $text $cmdtype]
		while {$fid!="" && [gets $fid ln]>=0} {
			if {$ln!=""} {
				set currbody "$ln\n"
			        while {[regexp {^\s*(#.*)?$} $currbody] && \
                                       [gets $fid ln]>=0} {
					        set currbody "$ln\n"
				        }		
				while {![info complete $currbody] && \
					[gets $fid ln]>=0} {
					append currbody "$ln\n"
				}		
				if {$ln!="" && [info complete $currbody] && \
					[lindex $currbody 1]==$scriptname} {
					puts $fido "[string trim $text]"
					set done 1
					set currname {}
					set currbody {}
				} else {
					puts $fido "[string trim $currbody]"
					set currname {}
					set currbody {}
				}
			} else {
					puts $fido ""
					set currname {}
					set currbody {}
			}
		}
	} elseif {$cmdtype=="JAVA"} {
		set currbody ""
		# Get name out of script text in case it has changed.
		set newscriptname [script_name $text $cmdtype]
		# Assume Java commands are surrounded by /* StartCmd cmdname */
		# /* EndCmd */ markers.
		# Find and replace it if it already exists.
		while {$fid!="" && [gets $fid ln]>=0} {
			set words [split [string trim $ln] " \t"]
			if {[llength $words]==4 && \
					[lindex $words 1]=="StartCmd"} {
				set currname [lindex $words 2]
				#puts "Dumping '$currbody' to output."
				puts $fido [string trim $currbody]
				#puts "Accumulating '$ln'"
				set currbody $ln\n
			} elseif {[llength $words]==3 && \
                                        [lindex $words 1]=="EndCmd"} {
				#puts "Accumulating '$ln'"
				append currbody $ln\n
				if {$currname==$scriptname} {
					#puts "Replacing:\n$currbody\nwith:\n$text"
					puts $fido "/* StartCmd $scriptname */
[string trim $text]
/* EndCmd */\n"
					set done 1
					set currname {}
					set currbody {}
				} else {
					#puts "Dumping:\n$currbody"
					puts $fido "[string trim $currbody]"
					set currname {}
					set currbody {}
				}
			} else {
				#puts "Accumulating '$ln'"
				append currbody $ln\n
			}
		}
	}
	# If this is a new file and the command was not found.
	if {$fid==""} {
		if {$cmdtype=="JAVA"} {
			#puts "Creating new java file header."
			puts $fido "import com.ti.mtc.ashl.*;
				import java.util.*;
				import java.io.*;
 
				public class [file tail [file rootname \
					$filename]] $LB
				public [file tail [file rootname  \
					$filename]]() $LB"
		}
	}
 	if {$done==0} {
		#puts "Creating new command: $text."
		if {$cmdtype=="JAVA"} {
			puts $fido "/* StartCmd $scriptname */"
		}
		puts -nonewline $fido "\n[string trim $text]\n"
		if {$cmdtype=="JAVA"} {
			puts $fido "/* EndCmd */"
		}
	}
	if {$fid!=""} {
		#puts "Flushing:\n$currbody"
		puts $fido [string trim $currbody]
	}
	if {$fid==""} {
		if {$cmdtype=="JAVA"} {
			#puts "Creating new java file trailer."
			puts $fido "\n$RB\n$RB"
		}
	}
	if {$fid!=""} {
		close $fid
	} 
	close $fido
	if {[file exists $filename] && ![file writable $filename]} {
		tk_dialog .err ERROR "File $filename is read-only" error 0 OK
		return ""
	} 
	global options
	if {[info exists options] && [info exists options(backupfiles)] &&
			$options(backupfiles) == 1} {
		catch {file rename -force $filename $filename~}
	}
	if [catch {file rename -force $tmpfile $filename}] {
		tkerror "Can't open $filename"
		return ""
	}
	return $newscriptname
}

proc script_name {text scripttype} {
	set scriptname "iNVALID_cOMMAND_tEXT"
	if {$scripttype=="SL"} {
		# Get name out of script text.
		foreach line [split $text "\n"] {
			set words [scan $line "%s%s" firstword secondword]
			if {$words>1 && $firstword=="startscript"} {
				set scriptname $secondword
				break
			}
		}
	} elseif {$scripttype=="TCL"} {
		# Get name out of script text.
		foreach line [split $text "\n"] {
			set words [scan $line "%s%s" firstword secondword]
			if {$words>1 && $firstword=="an_proc"} {
				set scriptname $secondword
				break
			}
		}
	} elseif {$scripttype=="JAVA"} {
		set currbody ""
		# Get name out of script text in case it has changed.
		foreach line [split $text "\n"] {
			set words [split [string trim $line] "\""]
			if {[llength $words]>1 && \
					[lindex $words 0]=="new Command("} {
				set scriptname [lindex $words 1]
				break
			}
		}
	}
	return $scriptname
}

proc delete_script2 {filename scriptname {cmdtype SL} {perms 0666} \
		{movefile {}}} {
	#puts "delete_script2 filename=$filename scriptname=$scriptname cmdtype=$cmdtype perms=$perms filename=$filename"
	global LB RB
	set accesstype write
	set tmpfile [tempfilename edscr[pid]]
	set fid ""
	set fido [open $tmpfile w $perms]
	catch {set fid [open $filename r]}
	set done 0
	if {$cmdtype=="SL"} {
		while {$fid!="" && [gets $fid ln]>=0} {
			set firstword [lindex [split [string trim $ln] \
				"\t "] 0]
			if {$firstword=="startscript"} {
				set currname [lindex [split $ln "\t "] 1]
				append currbody $ln\n
			} elseif {$firstword=="endscript"} {
				append currbody $ln\n
				if {$currname==$scriptname} {
					# puts $fido "[string trim $text]\n"
					if {$accesstype=="write" && [warn_read_only $filename]} {
						close $fido
						catch {file delete -force $tmpfile}
						return -1
					}
					if {$movefile!=""} {
						set mfid [open $movefile w]
						puts $mfid "[string trim $currbody]"
						close $mfid
					}
					set done 1
					set currname {}
					set currbody {}
				} else {
					puts $fido "[string trim $currbody]"
					set currname {}
					set currbody {}
				}
			} else {
				append currbody $ln\n
			}
		}
	} elseif {$cmdtype=="TCL"} {
		while {$fid!="" && [gets $fid ln]>=0} {
			if {$ln!=""} {
				set currbody "$ln\n"
			        while {[regexp {^\s*(#.*)?$} $currbody] && \
                                       [gets $fid ln]>=0} {
					        set currbody "$ln\n"
				        }		
				while {![info complete $currbody] && \
					[gets $fid ln]>=0} {
					append currbody "$ln\n"
				}		
				if {$ln!="" && [info complete $currbody] && \
					[lindex $currbody 1]==$scriptname} {
					# puts $fido "[string trim $text]"
					if {$accesstype=="write" && [warn_read_only $filename]} {
						close $fido
						catch {file delete -force $tmpfile}
						return -1
					}
					if {$movefile!=""} {
						set mfid [open $movefile w]
						puts $mfid "[string trim $currbody]"
						close $mfid
					}
					set done 1
					set currname {}
					set currbody {}
				} else {
					puts $fido "[string trim $currbody]"
					set currname {}
					set currbody {}
				}
			} else {
					puts $fido ""
					set currname {}
					set currbody {}
			}
		}
	} elseif {$cmdtype=="JAVA"} {
		while {$fid!="" && [gets $fid ln]>=0} {
			set words [split [string trim $ln] " \t"]
			if {[llength $words]==4 && \
					[lindex $words 1]=="StartCmd"} {
				set currname [lindex $words 2]
				append currbody $ln\n
			} elseif {[llength $words]==3 && \
					[lindex $words 1]=="EndCmd"} {
				append currbody $ln\n
				if {$currname==$scriptname} {
					# puts $fido "[string trim $text]\n"
					if {$accesstype=="write" && [warn_read_only $filename]} {
						close $fido
						catch {file delete -force $tmpfile}
						return -1
					}
					if {$movefile!=""} {
						set mfid [open $movefile w]
						puts $mfid "[string trim $currbody]"
						close $mfid
					}
					set done 1
					set currname {}
					set currbody {}
				} else {
					puts $fido "[string trim $currbody]"
					set currname {}
					set currbody {}
				}
			} else {
				append currbody $ln\n
			}
		}
	}
	if {$fid!=""} {
		close $fid
	}
	# if {$done==0} {
		# puts -nonewline $fido "\n[string trim $text]\n"
	# }
	close $fido

	catch {file rename -force $filename $filename~}
	file rename -force $tmpfile $filename
	return 0
}

proc rename_script_mult {oldscript oldtext currscript cmdtype} {
	set newtext ""
	#puts "Replacing $cmdtype '$oldscript' in '$oldtext' with '$currscript'"
	switch $cmdtype {
		"SL" {
			regsub "startscript\[ 	\]\[ 	\]*$oldscript" \
				$oldtext "startscript $currscript" newtext
			return $newtext
		}
		"TCL" {
			regsub "an_proc\[ 	\]\[ 	\]*$oldscript" \
				$oldtext "an_proc $currscript" newtext
			return $newtext
		}
		"JAVA" {
		}
	}

}

proc java_complete {chunk} {
	set parencount 0
	set bracketcount 0
	set bracecount 0
	set quotecount 0
	global LB RB
	set len [string length $chunk]
	for {set p 0} {$p<$len} {incr p} {
		set c [string index $chunk $p] 
		switch $c {
		    "(" { incr parencount +1 }
		    ")" { incr parencount -1 }
		    "\[" { incr bracketcount +1 }
		    "\]" { incr bracketcount -1 }
		    "{" { incr bracecount +1 }
		    "}" { incr bracecount -1 }
		    "\"" { 
				if {$quotecount>0} {
					set quotecount 0
				} else {
					set quotecount 1
				}
			}
		}
	}
	#puts "parencount=$parencount bracketcount=$bracketcount bracecount=$bracecount quotecount=$quotecount"
	if {$parencount!=0 || $bracketcount!=0 || $bracecount!=0 || 
		$quotecount!=0} {
		#puts "$chunk\n not complete"
		return 0
	} else {
		return 1
	}
}

#rename while old_while
#proc while {cond code} {
#	puts "Entering while for $cond"
#	uplevel "old_while {$cond} {$code}"
#}
