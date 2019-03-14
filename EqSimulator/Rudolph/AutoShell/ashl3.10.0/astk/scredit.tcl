
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: scredit.tcl,v 1.3 2000/07/07 21:47:56 karl Exp $
# $Log: scredit.tcl,v $
# Revision 1.3  2000/07/07 21:47:56  karl
# Added check for pullscript abort on readonly.
# Added readonlyranges to startscript/endscript lines.
#
# Revision 1.2  1999/10/06  18:33:13  karl
# Fixed big where "return to edit" on a script after errors were reported
# could result in the wrong lines being made readonly.
#
# Revision 1.1  1999/10/06  15:38:08  karl
# Initial revision
#

# Routines to extract, edit, and replace scripts in any language, with
# any editor.

# Counter used for temporary file names
set eas_count 0

proc eas_start {basename sucontents cmdname cmdtype defaultcode editorcmd
		cmdrenamecallback savecallback parentwin} {
	#puts "eas_start basename=$basename sucontents=$sucontents cmdname=$cmdname cmdtype=$cmdtype defaultcode=$defaultcode editorcmd=$editorcmd cmdrenamecallback=$cmdrenamecallback"
	#puts "pwd=[pwd]"
	global eas_count env eas_open eas_before tcl_platform
	if {[info exists eas_open($parentwin,$cmdname)]} {
		set msg "There is already a window open for $cmdname "
		append msg "under $parentwin."
		tk_dialog .err ERROR $msg error 0 OK
		return
	}
	set scriptfilename ""
	# Extract script from script files if it already exists.
	set script [string trim [pull_script_mult $basename \
			$sucontents $cmdname scriptfilename $cmdtype]]
	if {$script=="Pull_Script_Abort"} {
		return
	}
	# If the script didn't exist, assume it goes in the basename file.
	if {$script==""} {
		if {$cmdtype=="SL"} {
			#set scriptfilename [choose_script_file $cmdtype]
			set scriptfilename $basename.scr
			set script "startscript $cmdname\n"
			append script "$defaultcode\nendscript\n"
		} elseif {$cmdtype=="JAVA"} {
		} elseif {$cmdtype=="TCL"} {
			set scriptfilename $basename.tcl
			set script "an_proc $cmdname {} {} {} {\n$defaultcode\n}"
		} else {
			puts "INVALID SCRIPT TYPE: Contact AutoShell Support"
			return
		}
	} else {
		switch [file extension $scriptfilename] {
			.scr {set existtype SL}
			.tcl {set existtype TCL}
			.java {set existtype JAVA}
		}
		if {$existtype!=$cmdtype} {
			set msg "A $existtype script named $cmdname already "
			append msg "exists in $scriptfilename."
			tk_dialog .err ERROR $msg error 0 OK
			return 	
		}
	}
	#puts "script='$script'"
	set adjeditorcmd [adjusteditorcmd $editorcmd $script $cmdtype]
	if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
		set tfname "$env(TMP)/${cmdname}_[pid]_${eas_count}.eas"
	} else {
		set tfname "$env(HOME)/${cmdname}_[pid]_${eas_count}.eas"
	}

	set tfname [string map {\\ /} $tfname]
	incr eas_count
	set tfid [open $tfname w]
	if {$tfid==""} {
		tk_dialog .err ERROR "Couldn't open temporary file $tfname" \
			error 0 OK
		return
	}
	puts $tfid $script
	flush $tfid
	close $tfid
		
	#puts "editorcmd=$editorcmd"
	set eas_before($parentwin,$cmdname) $script
	exec_and_wait "$adjeditorcmd \"$tfname\" " \
		[list eas_done $basename $sucontents $cmdname $cmdtype \
			$defaultcode $editorcmd $cmdrenamecallback \
			$savecallback \
			$editorcmd $tfname $scriptfilename $parentwin]	 
	#puts "returned from exec_and_wait"
	set eas_open($parentwin,$cmdname) 1
}

proc adjusteditorcmd {editorcmd script cmdtype} {
###Paul K. 2005.03.29
   ### I could find no reason that we needed to continue restricting
   ### the users to only using ANP on Windows. Allow them to define the
   ### Editor to be used in the configuration defaults and avoid overriding
   ### that value here.
                # # Temporarily, I'm going to insist that they use anp.
                # # I can't do this in a .bat file because Win2000 acts funny.
                # # It works, but if you run it in foreground it ties up the
                # # UI and if you run it it background it doesn't send stdout to the pipe.
                # global tcl_platform env
                # if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
                #        set editorcmd "wish8.5 $env(ASTK_DIR)/anp.tcl"
                #        set readonly [eas_findboiler $script $cmdtype]
                #        append editorcmd " -buttons"
                #        append editorcmd " -readonlyranges $readonly "
                #
        ###} else
                                                                                

	if {$editorcmd=="anp" || \
		[string match "*anp *" $editorcmd] || \
		[string match "*anp" $editorcmd]} {
			set readonly [eas_findboiler $script $cmdtype]
			append editorcmd " -buttons"
			append editorcmd " -readonlyranges $readonly"
	}
	return $editorcmd
}

proc eas_findboiler {script cmdtype} {
	set linecount 1
	set ranges ""
	set ssfound 0
	set esfound 0
	foreach line [split $script "\n"] {
		switch -- $cmdtype {
		    SL {
			if {([string match \
			     {startscript[ \t]*} [string trim $line]] && $ssfound==0)} {
				if {[string compare $ranges ""]} {
					append ranges "," 
				}
				append ranges "$linecount.0,$linecount.0+1lines"	
				set ssfound 1
			} elseif {([string match \
			     {endscript} [string trim $line]] && $esfound==0) ||
			    ([string match \
			     {endscript[ \t]*} [string trim $line]] && $esfound==0)} {
				if {[string compare $ranges ""]} {
					append ranges "," 
				}
				append ranges "$linecount.0,$linecount.0+1lines"	
				set esfound 1
			}
		    }
		    TCL {
			if {[string match \
			     {an_proc[ \t]*} [string trim $line]]} {
				if {[string compare $ranges ""]} {
					append ranges "," 
				}
				append ranges "$linecount.0,$linecount.0+1lines"	
			}
		    }
		    JAVA {
		    }
		}
		incr linecount
	}
	return $ranges
}

proc eas_done {basename sucontents cmdname cmdtype defaultcode editorcmd \
	cmdrenamecallback savecallback editorcmd tfname scriptfilename \
	parentwin} {
	global eas_open eas_before env tcl_platform options
	#puts "entering eas_done"
	# If SL, run chkscr
	# if TCL, check for complete body
	# if Java, compile it.
	set tfid [open $tfname r]
	if {$tfid==""} {
		tk_dialog .err ERROR "Couldn't open temporary file $tfname" \
			error 0 OK
		return
	}
	set script [read $tfid]
	close $tfid
	
	set contentsbefore $eas_before($parentwin,$cmdname)
	if {[string compare [string trim $contentsbefore] \
		[string trim $script]]==0} {
		unset eas_before($parentwin,$cmdname)
		if {[info exists eas_open($parentwin,$cmdname)]} {
			unset eas_open($parentwin,$cmdname)
		}
		file delete $tfname
		return
	}

	#puts "cmdtype=$cmdtype"
	if {$cmdtype=="SL"} {
		set warnings "WARNING: Couldn't find chkscr executable "
		append warnings "to check script syntax."
		catch {set warnings [exec chkscr $tfname]}
	} elseif {$cmdtype=="TCL"} {
		set warnings ""
		if { [info exists options(procheck)] && $options(procheck) == 1} { 

            set fp [open $tfname r]
            fconfigure $fp -buffering line
 			if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
				append tempFile $env(TEMP) "\\edit" [pid]
			} else {
				append tempFile "/tmp/edit" [pid]
			}
                
                file delete $tempFile
                if [catch {set fileId [open $tempFile a+ 0666]} warnings ] {
			set warnings "Could not open temporary file for syntax checking; $warnings"
		} else {
      	        	set counter 1
                	while {[gets $fp data] >= 0} {
                        	set str_array($counter) $data
                        	set counter [expr $counter + 1]
                	}
                	for {set i 2} {$i < [array size str_array]} { incr i 1} {
                        	puts $fileId $str_array($i)
                	}
                	close $fileId
                	close $fp
				
				set warnings "WARNING: Couldn't find procheck executable"
				
	                	if { [info exists tcl_platform] && \
						$tcl_platform(os)=="Linux"} {
   	                     		catch {exec $env(ASTK_DIR)/../procheck/linux-ix86/bin/procheck -W2 $tempFile} warnings
   		        	} elseif { [info exists tcl_platform] && \
							$tcl_platform(platform) == "windows" } {
					catch {exec $env(ASTK_DIR)/../procheck/win32-ix86/bin/procheck.exe -nologo -W2 $tempFile} warnings

   		        	} elseif { [info exists tcl_platform] && \
							$tcl_platform(os) == "SunOS" } {
   	                     		catch {exec $env(ASTK_DIR)/../procheck/solaris-sparc/bin/procheck -nologo -W2 $tempFile} warnings
				} else {
					set warnings ""
				}

                		file delete $tempFile
                		if {[regexp {^[^\n]*\n[^\n]*$} $warnings]} {
                        		set warnings ""
                        		set procheck_error_flag 0
                		} else {
                        		regsub ".*?\n.*?\n" $warnings {} warnings
                        		set procheck_error_flag 1
                		}
                		if {$procheck_error_flag == 0}  {
					if {![info complete $script]} {
						set warnings "0 TCL Script not complete.  Check for "
						append warnings "mismatched braces, brackets, or quotes."
					} else {
						set warnings ""
					}
				}
			}
		}
	} elseif {$cmdtype=="JAVA"} {
		# Add Java compile step here.
		set warnings ""
	}
	#puts "warnings=$warnings"
	if {[string compare $warnings ""]} {
		set lines [split $warnings "\n"]
		foreach line $lines {
			set tmp [split $line " 	"]
			append warnings2 [join [lrange $tmp 1 end]] "\n"
		}
		if {$cmdtype=="SL"} {
			set rc [scrl_dialog  .warning Warning \
				$warnings2 warning 0 \
				"Return to Edit" "Save Anyway" "-width 60"]
		} else {
			set rc [scrl_dialog  .warning Warning \
				$warnings2 warning 0 \
				"Return to Edit" "Cancel" "-width 60"]
		}
		if {$cmdtype=="TCL" && $rc==1} {
			if {[info exists eas_open($parentwin,$cmdname)]} {
				unset eas_open($parentwin,$cmdname)
			}
			file delete $tfname	
			return
		}
		if {$rc==0} {
			# Code to reopen edit window.
			exec_and_wait "[adjusteditorcmd $editorcmd $script $cmdtype] $tfname" \
				[list eas_done $basename $sucontents \
				$cmdname $cmdtype $defaultcode $editorcmd \
				$cmdrenamecallback $savecallback $editorcmd \
				$tfname $scriptfilename $parentwin]	 
			#puts "returned from exec_and_wait"
			return
		}
	}
	set nameafteredit [script_name [string trim $script] $cmdtype]
	if {[string compare $nameafteredit $cmdname]} {
		set dummyfilevar ""
		set exist [pull_script_mult $basename $sucontents \
			$nameafteredit dummyfilevar]
		if {$exist==""} {
			set msg "You changed the name of the command from "
			append msg "$cmdname to $nameafteredit.  This may "
			append msg "confuse the application if command names "
			append msg "are defined in other windows."
			set rc [tk_dialog .warn WARNING $msg warning 0 \
				"Return to Edit" "Save Anyway"]
			if {$rc==0} {
				exec_and_wait "[adjusteditorcmd $editorcmd $script $cmdtype] $tfname" \
					[list eas_done $basename $sucontents \
						$cmdname $cmdtype \
						$defaultcode $editorcmd \
						$cmdrenamecallback \
						$savecallback $editorcmd \
						$tfname $scriptfilename \
						$parentwin]	 
				#puts "returned from exec_and_wait"
				return
			}
		} else {
			set msg "You changed the name of the command from "
			append msg "$cmdname to $nameafteredit.  There is "
			append msg "already a command named $nameafteredit. "
			append msg "Please choose a different name. "
			set rc [tk_dialog .warn WARNING $msg warning 0 \
				"Return to Edit"]
			exec_and_wait "[adjusteditorcmd $editorcmd $script $cmdtype] $tfname" \
				[list eas_done $basename $sucontents \
					$cmdname $cmdtype \
					$defaultcode $editorcmd \
					$cmdrenamecallback \
					$savecallback $editorcmd \
					$tfname $scriptfilename \
					$parentwin]	 
			#puts "returned from exec_and_wait"
			return
		}
	}
	if {$nameafteredit!=$cmdname} {
		if {$cmdrenamecallback!=""} {
			eval $cmdrenamecallback $cmdname $nameafteredit
		}
	}
	set cmdnameafter [push_script2 $scriptfilename $nameafteredit \
		[string trim $script] $cmdtype]
	#puts "cmdnameafter=$cmdnameafter"
	if {[string compare $cmdnameafter ""]==0} {
		set msg "Couldn't store changes to $scriptfilename. "
		append msg "Check permissions on the file and the "
		append msg "directory it is in."
		set rc [tk_dialog .err ERROR $msg error 0 "Discard Changes" \
			"Return to Edit"]
		if {$rc==1} {
			exec_and_wait "[adjusteditorcmd $editorcmd $script $cmdtype] $tfname" \
				[list eas_done $basename $sucontents \
					$cmdname $cmdtype \
					$defaultcode $editorcmd \
					$cmdrenamecallback \
					$savecallback $editorcmd \
					$tfname $scriptfilename \
					$parentwin]	 
			return
		}
	}	
	#puts "cmdnameafter=$cmdnameafter"
	if {$savecallback!=""} {
		eval $savecallback $cmdname $cmdtype {$script} 
	}
	if {[info exists eas_open($parentwin,$cmdname)]} {
		unset eas_open($parentwin,$cmdname)
	}
	file delete $tfname
}

proc eas_check {parentwin} {
	global eas_open
	if {[llength [array names eas_open "$parentwin,*"]]} {
		set msg "You still have edit windows open for "
		append msg "the following scripts: "
		append msg "[array names eas_open "$parentwin,*"]."
		tk_dialog .warn WARNING $msg warning 0 OK
		return 0
	}
	return 1
}

proc choose_text_editor {} {
	global options tcl_platform 
	set geometry "+[winfo pointerx .]+[winfo pointery .]"
	toplevel .cte
	wm geometry .cte $geometry

	button .cte.ok -text "  OK  " -command "destroy .cte"
	pack .cte.ok -side bottom
	
	label .cte.lab -text "Choose Text Editor"
	pack .cte.lab -side top

	radiobutton .cte.anp -text "Anp" -value anp \
		-variable options(texteditor) \
		-command {.cte.ent configure -state disabled}

	pack .cte.anp -side left

	if { [info exists tcl_platform] && $tcl_platform(platform) != "windows" } {
		radiobutton .cte.vi -text "VI" -value "xterm -e vi" \
			-variable options(texteditor) \
			-command {.cte.ent configure -state disabled}
		pack .cte.vi -side left
	   } 

	radiobutton .cte.userlab -text "User Defined" \
		-variable options(texteditor) \
		-command {.cte.ent configure -state normal}

	pack .cte.userlab -side left

	entry .cte.ent \
		-textvariable options(texteditor) 
	pack .cte.ent -side left

	
	grab .cte
}

proc start_xclipboard {} {
	global env
	set env(XENVIRONMENT) $env(ASTK_DIR)/XClipboard
    if [catch {exec xclipboard -iconic >& /dev/null &}] {

        if {[file exists "/usr/X11R6/bin/xclipboard"]} {
            if [catch {exec /usr/X11R6/bin/xclipboard -iconic >& /dev/null &}] {
            	tk_dialog .tmp WARNING "The xclipboard found at /usr/X11R6/bin could not be executed.  Please put a valid xclipboard in your path" warning 0 OK
			}	

        } elseif {[file exists "/usr/openwin/bin/xclipboard"]} {
          if [catch {exec /usr/openwin/bin/xclipboard -iconic >& /dev/null &}] {
            	tk_dialog .tmp WARNING "The xclipboard found at /usr/openwin/bin could not be executed.  Please put a valid xclipboard in your path" warning 0 OK
			}	

        } elseif {[file exists "/usr/contrib/bin/xclipboard"]} {
          if [catch {exec /usr/contrib/bin/xclipboard -iconic >& /dev/null &}] {
            	tk_dialog .tmp WARNING "The xclipboard found at /usr/contrib/bin could not be executed.  Please put a valid xclipboard in your path" warning 0 OK
			}	

        } else {
           	tk_dialog .tmp WARNING "The xclipboard found in your path could not be executed.  Please put a valid xclipboard in your path" warning 0 OK
		}
    }

}



#Things to test:
#	Renaming script while in editor (tcl,scr,java)
#	Deleting script while in editor (tcl,scr,java)
#	Errors in script
#	Abnormal editor termination
#	Quit without save
#	Edit while already editing.
#	Close parent while edit window open
#	New script when multiple script files
#	Scripts in secondary files
#	Add -buttons option to anp OK
#	Change script name to exist, in parent, rename, replace OK
#	Change script name to exist, in parent, rename, use exist ERR
#	Change script type in parent 
#	Change script name in text
# 	New script of existing name, same type
#	New script of existing name, different type.
#	Close appl/parent window while edit windows open.
#	Edit file in synwin needs to use anp

# Test cases

# Script Language edited with VI
#eas_start easjunk "ldscript file=easjunk2.scr" testscript1 SL \
#	"	# Testing" "xterm -e vi" ""

# Script Language edited with anp
#eas_start easjunk "ldscript file=easjunk2.scr" testscript1 SL \
#	"	# Testing" "anp" ""

# TCL edited with VI
#eas_start easjunk "tclinclude file=easjunk2.tcl" testtclscript1 TCL \
#	"	# Testing" "xterm -e vi" ""

# TCL edited with anp
#eas_start easjunk "ldscript file=easjunk2.scr" testtclscript1 TCL \
#	"	# Testing" "anp" ""

