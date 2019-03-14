
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: np.tcl,v 1.13 2000/09/14 23:05:45 karl Exp $
# $Log: np.tcl,v $
# Revision 1.13  2000/09/14 23:05:45  karl
# Fixed bug where user would be asked to save changes when exiting
# during follow mode.
#
# Revision 1.12  2000/08/08  20:50:03  karl
# Added -tailfile option to allow tailing a file without using
# follow mode.
#
# Revision 1.11  1999/08/25  18:22:34  karl
# Took out some debugging output that could create a "/tmp/kjmjunk"
# stack trace.
#
# Revision 1.10  1999/08/24  15:00:09  karl
# Moved globals to an array to allow multiple nps in a single process.
# Added generic expandable -option loop for customization args.
# Changed explicit source statements to use auotload.
# Added -button option.
# Changed to use Supertext to allow unlimited undo.
# Changed window titles to use filename without path.
# Added "Save and Exit" to File menu.
# Added -save_cb and -ok_cb options.
# Took out script debugger specific code.
# Added -redonlyranges option
#
# Revision 1.9  1999/07/06  14:23:33  justin
# Added Follow File routines
#
# Revision 1.8  1999/06/04  20:46:49  justin
# Added Option to Change change character indent spaces
#
# Revision 1.7  1999/06/03  21:00:57  justin
# Made colorselection send in list format
# Fixed Print option, allowed user to define own print string
#
# Revision 1.6  1999/05/28  21:37:49  karl
# Added color configuration.
# Added "About" window.
# Added search/replace.
# Added highlighted text to paren match feature.
# Added Ctrl+M binding to do paren match.
#
# Revision 1.5  1999/02/22  20:00:13  karl
# Made text background white.
#
# Revision 1.4  1998/12/18  23:54:11  karl
# Added paren matching.
# Cleaned up cut & paste.
# Cleaned up goto line number and line number update.
#
# Revision 1.3  1998/08/05  21:58:15  karl
# Justin added Ctrl+X, Ctrl+C, and Ctrl+V bindings, and the file name in
# the title bar.
#
# Revision 1.2  1998/07/17  20:42:49  karl
# Fixed ANP to remember input file name and to ask about save at exit with X.
#
# Revision 1.1  1998/07/16  15:38:14  karl
# Initial revision
#
global np_version
set np_version 1

#option add *font -Adobe-Helvetica-Bold-R-Normal--*-120-*-*-*-*-*-* 
#option add *Entry.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*
#option add *Text.font -*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*

source $env(ASTK_DIR)/supertext.tcl
global ashlSupportEmail ashlSupportWeb ashlSupportFAQ
source $env(ASTK_DIR)/ashlSupportEmail.tcl
source $env(ASTK_DIR)/version.tcl


proc open_note_pad {root args} {
	# These need to be placed in a base-based array.
	global np base

	if {$root == "."} {
            set base ""
        } else {
            set base $root
        }

	set inputname ""
	set np($base,readonlyranges) {}
	set np($base,save_cb) ""
	set np($base,ok_cb) ""
	set np($base,followflag) 0
	set np($base,tailfile) 0
	set np($base,embeddedflag) 0
	set np($base,buttonflag) 0
	set np($base,showfollowflag) 0
	#puts "args='$args'"		
	for {set argc 0} {$argc<[llength $args]} {incr argc} {
		set arg [lindex $args $argc]
		#puts "processing $arg"
		switch -- $arg {
			-showfollow {
                                set np($base,showfollowflag) 1
                        }
			-follow {
				#puts "setting followflag"
				set np($base,followflag) 1
			}
			-tailfile {
				set np($base,tailfile) 1
			}
			-buttons {
				set np($base,buttonflag) 1
			} 
			-embedded {
				set np($base,embeddedflag) 1
			} 
			-save_cb {
				incr argc
				set np($base,save_cb) [lindex $args $argc]
			} 
			-ok_cb {
				incr argc
				set np($base,ok_cb) [lindex $args $argc]
			} 
			-readonlyranges {
				incr argc
				set np($base,readonlyranges) \
					[split [lindex $args $argc] ,]
			}
			default {
				if {[string compare $inputname ""]==0} {
					set inputname $arg
				}
			}
		}
	}

         #bind -all <Up> "" 
         #bind -all <Down> "" 
         #bind -all <Prior> "" 
         #bind -all <Next> "" 

        set np(textcolors) "{foreground #000080} {background #fffafa}"
	set np($base,beaut) 0
        set np($base,printcmd) "lp -c"
	set np($base,filename) $inputname
	set np(tablist) ""
	if {[file exists ~/.anrc]} {
		if { [ catch {source ~/.anrc}] } {
			file delete ~/.anrc
		}
	}
#
# Menubar generation 
#
#
global env
#source $env(ASTK_DIR)/colorselect.tcl
#source $env(ASTK_DIR)/tailfile.tcl
lassign [winfo pointerxy .] x y
wm geometry . +[expr $x - 250]+[expr $y - 200]

frame $base.menubar
pack  $base.menubar -side top -fill x
if {$np($base,buttonflag)} {
	frame $base.buttons
	if {$np($base,showfollowflag)} {
                button $base.buttons.follow -text " Follow " \
                        -command "follow_file {$base}"
        }
	button $base.buttons.save -text " Save " \
		-command "save_text_quick {$base}"
	button $base.buttons.saveexit -text " OK " \
		-command "if {\$np($base,changed)} {save_text_quick {$base}}; exit_text {$base}"
	button $base.buttons.exit -text " Cancel " \
		-command "exit_text {$base}"
	if {$np($base,showfollowflag)} {
                pack $base.buttons.follow $base.buttons.save $base.buttons.saveexit $base.buttons.exit \
                -side left -pady 2 -padx 10
        } else {
                pack $base.buttons.save $base.buttons.saveexit $base.buttons.exit \
                -side left -pady 2 -padx 10
        }
	pack $base.buttons -side bottom
}

proc update_coords {base args} {
	global textpos np
	#puts "updating np($base,cursorpos)"
	set np($base,cursorpos) [$base.txt index insert]		
	#puts "updated np($base,cursorpos)"
}

proc mark_changed {base args} {
		global np
		#puts "marking change"
		set np($base,changed) 1
}

scrollbar $base.vscrl -orient vertical -command "$base.txt yview"
pack  $base.vscrl -side right -fill y 
Supertext::text $base.txt -yscrollcommand "$base.vscrl set" -xscrollcommand \
	"$base.hscrl set" -wrap none -background white \
	-postproc "[list mark_changed $base]"
pack $base.txt -expand 1 -fill both -side top
scrollbar $base.hscrl -orient horizontal -command "$base.txt xview"
pack  $base.hscrl -side top -fill x

$base.txt configure -tabs $np(tablist)


set_colors $base
#bind $base.txt <Destroy> "exit_text {$base}"
#puts " filename:$inputname base:$base root:$root"
set np($base,orgfilename) $inputname
if {$base==""} {
	wm protocol . WM_DELETE_WINDOW "exit_text {$base}"
	if {$inputname==""} {
		wm title . "untitled.txt"	
	} else {
		wm title . "[file tail $inputname]"	
	}
} else {
	wm protocol $base WM_DELETE_WINDOW "exit_text {$base}"
	wm title $base "**[file tail $inputname]"	
}

#
# Bindings List for Shortcuts and Menu Hot-Keys
#
#

#bind $base.txt <Control-Key-f> "find_text {$base}; break"
#bind $base.txt <Control-Key-n> "find_next_text {$base}; break" 
#bind $base.txt <Control-Key-e> "clear_text {$base}; break" 
#bind $base.txt <Control-Key-o> "read_text {$base}; break" 
#bind $base.txt <Control-Key-s> "save_text_quick {$base}; break" 
#bind $base.txt <Control-Key-a> "save_text_named {$base}; break" 
#bind $base.txt <Control-Key-z> "exit_text {$base}; break" 
bind $base.txt <Control-Key-p> "match_paren {$base}; break" 
bind $base.txt <Control-Key-z> "$base.txt undo"
#bind $base.txt <Control-Key-x> [bind Text <<Cut>>]
#bind $base.txt <Control-Key-v> "[bind Text <<Paste>>];break"
#bind $base.txt <Control-Key-c> [bind Text <<Copy>>]
bind $base.txt <ButtonRelease> "+update_coords {$base} " 
bind $base.txt <KeyRelease> "+update_coords {$base} " 
#bind $base.txt <Button-1> "+check_for_undo_save {$base}"
#rename tkTextButton1 orig_tkTextButton1
#
 
######## orig_tkTextButton & tk_SetCursor tended to cause infinite loops...
######## I believe the Update_coords binded to keyrelease takes care of it...

#proc tkTextButton1 {wn x y} "
#	orig_tkTextButton1 \$wn \$x \$y
##	puts {updating coords}
#	update_coords {$base}
##	puts {checking for undo save}
#	check_for_undo_save {$base}
#"

#rename tkTextSetCursor orig_tkTextSetCursor   
#proc tkTextSetCursor {wn offset} "
#	orig_tkTextSetCursor \$wn \$offset
##	puts {updating coords}
#	update_coords {$base}
#"

#
# The global Notepad Varibles used in most all procedures
#
#

global np 
set np($base,all) 0
set np($base,changed) 0
set np($base,typed) 0
set np($base,cutbuffer) {}
set np($base,undolist) {}
set np($base,direction) {-forwards}
set np($base,matchcase) {-nocase}
set np($base,allowregexp) {-exact}
set np($base,searchloc) {1.0}
set np($base,cursorpos) {1.0}
set np($base,currsearchfirstloc) ""


#
#  File Menu Generation and button references
#
global np 
menubutton $base.file -text File -underline 0 -menu $base.file.fmenu
pack $base.file -in $base.menubar -side left
menu $base.file.fmenu -tearoff 0

# Only new and open if not a slave process

if {!$np($base,embeddedflag)} {
  $base.file.fmenu add command -label New \
  	  -command "clear_text {$base}" \
	  -underline 1
  $base.file.fmenu add command -label Open... \
	  -command "read_text {$base}" \
	  -underline 0

}

$base.file.fmenu add command -label Save \
	-command "save_text_quick {$base}" \
	-underline 0

# Only allow save as if not an embedded process...

if {!$np($base,embeddedflag)} {
  $base.file.fmenu add command -label "Save As..." \
	-command "save_text_named {$base}" \
	-underline 5


$base.file.fmenu add separator
$base.file.fmenu add command -label "Follow Mode..." \
	  -command "follow_file {$base}" \
	  -underline 0

}
$base.file.fmenu add separator
$base.file.fmenu add command -label "Print" \
	-command "print_options {$base}" \
	-underline 0
$base.file.fmenu add separator
$base.file.fmenu add command -label "Options" \
	-underline 1  \
	-command {
   		    	optionsANP {$base}
	         } 
$base.file.fmenu add separator

$base.file.fmenu add command -label "Save and Exit" \
	-command "save_text_quick {$base}; exit_text {$base}" \
	-underline 1
$base.file.fmenu add command -label "Exit" \
	-command "exit_text {$base}" \
	-underline 1

if {[string compare $inputname ""]} {
	set np($base,filename) $inputname
} else {
	set np($base,filename) $inputname
}

#
# clear_text: This procedure is called to clear the textfield when the user  
#             has selected "New" from the file menu. It also makes sure the changes 
#	      in the current document are not lost
#

proc clear_text {base} {
	global np 
	wm title . "untitled.txt"	
	if {$np($base,changed) && $np($base,followflag)==0} {
		set rc [tk_dialog $base.warn WARNING \
			"Do you want to save changes to $np($base,filename)?" \
			warning 0 Yes No Cancel]
		if {$rc==0} {
			save_text_quick $base	
		} elseif {$rc==2} {
			return -1
		}
	}
	set np($base,filename) "untitled.txt"
	$base.txt delete 1.0 end
	set np($base,changed) 0
	return 0
}


#
# clear_text_for_load: This procedure is called to clear the textfield, only  
#             	       after the user has selected a new file to load.
#

proc clear_text_for_load {base} {
	global np
	wm title . " "	
	if {$np($base,changed)  && $np($base,followflag)==0} {
		set rc [tk_dialog $base.warn WARNING \
			"Do you want to save changes to $np($base,filename)?" \
			warning 0 Yes No Cancel]
		if {$rc==0} {
			save_text_quick $base	
		} elseif {$rc==2} {
			return -1
		}
	}
	set np($base,filename) ""
	$base.txt delete 1.0 end
	set np($base,changed) 0
	return 0
}


#
# read_text: After the text area is cleared, the file is readin and the title 
#            bar is updated to show the new filename.
#

proc read_text {base {fn ""}} {
	global np 
	#puts "in readtext fn $fn"
	#if [clear_text_for_load $base] {
	#	return
	#}
	if {[string compare $fn ""]==0} {
		set fn [tk_getOpenFile]		
	}
	if {$fn!=""} {
		clear_text_for_load $base
		set fid [open $fn r]
		if {$fid!=""} {
			set txt [string trimright [read $fid]]
			$base.txt insert 1.0 $txt
			$base.txt reset
			#puts " FN= $fn"	
			set np($base,filename) $fn
			
		}
		set np($base,filename) $fn
	}
 
	
	if {$base==""} {
		if {$fn!=""} {
			wm title . "[file tail $fn]"		
		}
	} else {
		wm title $base "!!$fn"		
	}
}

#
# save_text: This procedure will prompt the user to save the file and give them  
#            the file i/o screen, which allows the user to enter the file name. 
#


proc save_text {base filename} {
	global np 
	set fid [open $filename w]
	if {$np($base,save_cb)!=""} {
		eval $np($base,save_cb) $base.txt $fn
	} else {
		if {$fid!=""} {
			puts $fid [string trimright [$base.txt get 1.0 end]]
			close $fid
			wm title . "[file tail $fid]"	
			set np($base,changed) 0
		} else {
			tk_dialog .error ERROR \
				"Couldn't open $filename for writing!" \
				error 0 OK
		}
	}
}

#
# save_text_quick: This procedure will use the current file name to save the file  
#            overwriting the previous save. It doesn't pull up the file dialog box.
# 	     After checking the name, and making sure the file is not untitled, it will 
# 	     call save_text to write data to the file. 	
#

proc save_text_quick {base} {
	global np 
	if {$np($base,filename)=="untitled.txt"} {
		set fn [tk_getSaveFile -initialfile $np($base,filename)]		
	} else {
		set fn $np($base,filename)
		wm title . "[file tail $fn]"	
	}
	if {$fn!=""} {
		save_text $base $fn				
		set np($base,filename) $fn
		wm title . "[file tail $fn]"	
	}
}

#
# save_text_named: This procedure will prompt the user to save the file and give them  
#            the file i/o screen, which allows the user to enter the file name. 
#            Then the procedure calls save_text to save the file. 
#

proc save_text_named {base} {
	global np
	set fn [tk_getSaveFile -initialfile $np($base,filename)]		
	if {$fn!=""} {
		save_text $base $fn				
		set np($base,filename) $fn
		wm title . "[file tail $fn]"	
	}
}

#
# exit_text_named: This procedure will prompt the user to save the file, 
#		   if it was changed,before exiting.
#

proc exit_text {base} {
	global np winid currenv queue scrinfo 
        set_options $base
	if {$np($base,changed) && $np($base,followflag)==0} {
		set rc [tk_dialog $base.warn WARNING \
			"Do you want to save changes to $np($base,filename)?" \
			warning 0 Yes No Cancel]
		if {$rc==0} {
			save_text_quick $base	
		} elseif {$rc==2} {
			return
		}
	}

	# if a debug controlled edit return to debugger

        if {$np($base,embeddedflag)} {
		if {$np($base,ok_cb)!=""} {
			eval $np($base,ok_cb) $base.txt $fn
		  	 destroy $base.hscrl 
		         destroy $base.vscrl 
		         destroy $base.menubar 
			 destroy $base.txt
		 	 destroy $base.file
			 destroy $base.search
			 destroy $base.edit
		         destroy $base.coords
		}
	}

#	 rename	tkTextSetCursor ""
#	 rename tkTextButton1 ""
#         rename orig_tkTextButton1 tkTextButton1
#	 rename orig_tkTextSetCursor tkTextSetCursor
#         .mbar.edit configure -state normal
#  	 .mbar.edit configure -state normal
#         .mbar.file configure -state normal
#         .mbar.srch configure -state normal
#         .mbar.dbug configure -state normal
#         .mbar.win  configure -state normal
#	 destroy .mbar
#	
#	 setupGUI "notepad"
#  	 set filename $np($base,filename)
#         bind .f2.watch.button1 <ButtonRelease> "watchvar_list"  
#         bind .f2.watch.button2 <ButtonRelease> "remove_all_watch"     
#         bind .f4.leftpanel.button3 <ButtonRelease> "toggleBreakPoint \" \""     
#         bind .f4.leftpanel.button5 <ButtonRelease> "sendCommand"   
#         bind .f4.rightpanel.button2 <ButtonRelease> { showFindDLG }  
#         bind all <Control-F6> "toggleBreakPoint \" \""
# 	 bind . <Control-z> "destroy_win" 
#	catch {
#         bind .f1.text$winid <Up> ".f1.text$winid yview scroll  -1 units" 
#         bind .f1.text$winid <Down> ".f1.text$winid yview scroll  1 units" 
#         bind .f1.text$winid <Prior> ".f1.text$winid yview scroll  -1 pages" 
#         bind .f1.text$winid <Next> ".f1.text$winid yview scroll  1 pages" 
#	}
#         bind . <KeyPress-Delete> "remove_watch" 
#         #bind .f3.eval.label  <ButtonRelease> "blink"   
#         set minusd [string trimright $queue "d"]
#         bind . <Control-d> "destroy_win" 
#        an_msgsend $currenv $minusd "ldscript file=$orgfilename"  
#
#         an_msgsend 0 qsrv "list auto" -an_reply_cb "initFile filename=$filename"
#          return  
        

	
	if {$base==""} {
		destroy .
	} else {
		destroy $base
	}
       #rename $base.txtOld {}
}

#
#  Edit Menu Generation and button references
#
#

menubutton $base.edit -text Edit -underline 0 -menu $base.edit.emenu
pack $base.edit -in $base.menubar -side left
menu $base.edit.emenu -tearoff 0
$base.edit.emenu add command -label Undo \
	-accelerator Ctrl+Z \
	-command "$base.txt undo" \
	-underline 0
$base.edit.emenu add separator 
add_cutpaste $base.edit.emenu
#$base.edit.emenu add command -label "Cut"\
#	-accelerator Ctrl+X \
#	-command "tk_textCut {$base.txt}" \
#	-underline 2
#$base.edit.emenu add command -label "Copy"\
#	-accelerator Ctrl+C \
#	-command "tk_textCopy {$base.txt}" \
#	-underline 0
#$base.edit.emenu add command -label "Paste"\
#	-accelerator Ctrl+V \
#	-command "tk_textPaste {$base.txt}" \
#	-underline 0
$base.edit.emenu add separator 
$base.edit.emenu add command -label "Select All" \
	-command "selectall_text {$base}" \
	-underline 7
$base.edit.emenu add separator 
$base.edit.emenu add command -label "Match Brace/Bracket/Paren" \
	-accelerator Ctrl-P \
	-command "match_paren {$base}" \
	-underline 0
#if {$np($base,beaut)==1} {
#	$base.edit.emenu add command -label "Script Beautify" \
#	-state normal  -command "call_beaut"
#} else {
#	$base.edit.emenu add command -label "Script Beautify" \
#	-state disabled -command "call_beaut"
#}

proc match_paren {base} {
	global np
	set cpos [$base.txt index insert]
        set originalpos $cpos
	set schar [$base.txt get $cpos]
	switch $schar {
		"{" { set exp {[{}]}; 
			set dir -forwards; set si end }
		"}" { set exp {[{}]}; 
			set dir -backwards; set si 1.0 }
		"\[" { set exp {[\[\]]}; 
			set dir -forwards; set si end }
		"\]" { set exp {[\[\]]}; 
			set dir -backwards; set si 1.0 }
		"(" { set exp {[()]}; 
			set dir -forwards; set si end }
		")" { set exp {[()]}; 
			set dir -backwards; set si 1.0 }
		"default" {return}
	}
	set count 1
	while {$count>0} {
		#puts "cpos=$cpos schar=$schar exp=$exp dir=$dir si=$si"
		if {$dir=="-forwards"} {
			set nextchar "$cpos + 1 char"
		} else {
			set nextchar "$cpos - 1 char"
		}
		set mp [$base.txt search $dir -regexp $exp $nextchar $si]
		if {$mp==""} {
			tk_dialog .err ERROR "No match found" error 0 OK
			return
		}
		set mchar [$base.txt get $mp]
		#puts "found '$mchar' at $mp"
		if {$mchar==$schar} {
			incr count +1
			set cpos $mp
		} else {
			incr count -1
			set cpos $mp
		}
	}
        set rightpos2 [string range $originalpos [expr [string first "." $originalpos] + 1] end] 
        set rightpos2 [expr $rightpos2 +1]
        set leftpos2 [string range $originalpos 0 [expr [string first "." $originalpos] - 1]]
        set leftpos [string range $mp 0 [expr [string first "." $mp] - 1]]
        set rightpos [string range $mp [expr [string first "." $mp] + 1] end] 
        set rightpos [expr $rightpos +1]
        set mp $leftpos
	append mp "."
        append mp $rightpos
        catch {
          if {$leftpos2<$leftpos} {       
            $base.txt tag add sel $originalpos $mp
	  }	

          if {$leftpos2==$leftpos} { 
	   if {$rightpos2<$rightpos} {
            $base.txt tag add sel $originalpos $mp
           } 
	   if {$rightpos2>$rightpos} {	
	     $base.txt tag add sel $mp $originalpos 
	   }	  
  	  } 
	  if {$leftpos2>$leftpos} {
            $base.txt tag add sel $mp $originalpos
   	  }
	}
	$base.txt mark set insert $mp
	$base.txt see $mp
}

#
#  This procedure higlights all the text in the widget if Select all is chosen from the menu.
#    ( NOTE: Control / does the same thing)
#

proc selectall_text {base } {
	$base.txt tag add sel 1.0 end
}

#
#  Search Menu Generation and button references
#
#

menubutton $base.search -text Search -underline 0 -menu $base.search.smenu
pack $base.search -in $base.menubar -side left
menu $base.search.smenu -tearoff 0
$base.search.smenu add command -label "Find..." \
	-command "find_text {$base}" \
	-underline 0
$base.search.smenu add command -label "Replace..." \
	-command "replace_text {$base}" \
	-underline 0
$base.search.smenu add command -label "Find Next" \
	-command "find_next_text {$base}" \
	-state disabled \
	-underline 5




# this varible globally keeps track of the changes made to the search string.

trace variable np($base,searchstring) w "searchstring_changed {$base}"

trace variable np($base,replacestring) w "replacestring_changed {$base}"

#
#  searchstring_changed:  This procedure will note changes in the search string so 
#			  the program will find the right string in the widget
#

proc searchstring_changed {base name1 name2 op} {
	global np
	set np($base,searchloc) 1.0
        set np($base,currsearchfirstloc) ""

	if {[info exists np($base,searchstring)] && \
		[string compare $np($base,searchstring) ""]!=0} {
		$base.search.smenu entryconfigure "Find Next" -state normal
		if [winfo exists $base.ft] {
			$base.ft.findnext configure -state normal
		}
		if [winfo exists $base.rt] {
			$base.rt.findnext configure -state normal
		   if { [info exists np($base,searchstring)] && \
   		        [string compare $np($base,replacestring) ""]!=0} {
			$base.rt.replacenext configure -state normal
			$base.rt.replaceall  configure -state normal
		   }	                
		}


	} else {
		$base.search.smenu entryconfigure "Find Next" -state disabled
		if {[winfo exists $base.ft]} {
			$base.ft.findnext configure -state disabled                
		}
                if [winfo exists $base.rt] {
			$base.rt.findnext configure -state disabled
			$base.rt.replacenext configure -state disabled
			$base.rt.replaceall  configure -state disabled
		}

	}
        replacestring_changed {$base} 0 0 0
}

proc replacestring_changed {base name1 name2 op} {
	global np
	if { [info exists np($base,searchstring)] && \
		[string compare $np($base,replacestring) ""]!=0} {
                if {[info exists np($base,searchstring)] && [string compare $np($base,searchstring) ""]!=0} {
    		    if {[winfo exists $base.rt]} {
  			    $base.rt.replacenext configure -state normal
			    $base.rt.replaceall  configure -state normal
 		    }
                }   
	} else {
		if {[winfo exists $base.rt]} {
			$base.rt.replacenext configure -state disabled
			$base.rt.replaceall  configure -state disabled
		}
	}
}



#
#  find_text: This procedure will generate the find text window and prompt the user to select
#		criteria to narrow the search. 			  
#


proc find_text {base} {
	#puts "Inside find_text"
	if {[winfo exists $base.ft]} {
		#puts "window already shown"
		raise $base.ft
		return
	}
		#puts "creating new toplevel"

#    Main Find window generation
#
	toplevel $base.ft
        wm title $base.ft "Find Text"
	frame $base.ft.left 
	frame $base.ft.left.top
	frame $base.ft.left.top.entry1
	frame $base.ft.left.top.entry2

	label $base.ft.left.top.entry1.strlab -text "     Find What:"
	entry $base.ft.left.top.entry1.strent -textvariable np($base,searchstring)
	bind  $base.ft.left.top.entry1.strent <Return> "$base.ft.findnext invoke"
	
	pack $base.ft.left.top.entry1.strlab  -side left
	pack $base.ft.left.top.entry1.strent  -side left
        pack $base.ft.left.top.entry1 -in $base.ft.left.top -ipady 5
        pack $base.ft.left.top -in $base.ft.left -pady 15
	pack $base.ft.left -side left -in $base.ft

	frame $base.ft.left.bot
	frame $base.ft.left.bot.dir
	frame $base.ft.left.bot.match

	label $base.ft.left.bot.dirlab -text "Direction:"
	radiobutton $base.ft.left.bot.dir.dirup -text Up -variable np($base,direction) \
		-value "-backwards"
	radiobutton $base.ft.left.bot.dir.dirdown -text Down -variable np($base,direction) \
		-value "-forwards"
	checkbutton $base.ft.left.bot.matchcase -text "Match Case" \
		-variable np($base,matchcase) -onvalue "-exact" -offvalue "-nocase"
	checkbutton $base.ft.left.bot.allowregexp -text "Allow Regular Expressions" \
		-variable np($base,allowregexp) -onvalue "-regexp" \
		-offvalue "-exact"

	pack $base.ft.left.bot -in $base.ft.left
	pack $base.ft.left.bot.matchcase -anchor w -in $base.ft.left.bot
	pack $base.ft.left.bot.allowregexp -anchor w -in $base.ft.left.bot
                          
	pack $base.ft.left.bot.dirlab  -side left -anchor w -in $base.ft.left.bot
	pack $base.ft.left.bot.dir.dirup   -side left -in $base.ft.left.bot.dir
	pack $base.ft.left.bot.dir.dirdown -side left -in $base.ft.left.bot.dir
	pack $base.ft.left.bot.dir -in $base.ft.left.bot

	frame $base.ft.right

	button $base.ft.findnext -text " Find Next  " \
		-command "find_next_text {$base}" \
		-state disabled \
                -width 12

	button $base.ft.cancel -text "  Cancel    " \
                -command " destroy $base.ft " \
                -width 12

        set xoffset [expr [expr [winfo rootx $base.txt] +[winfo width $base.txt ] ] - 380]
	wm geometry $base.ft  +$xoffset+[expr [winfo rooty $base.txt]-[winfo height $base.ft]]
        bind $base.ft <Control-Key-n> "find_next_text {$base}; break" 

	searchstring_changed $base 0 0 0

	pack $base.ft.right       -side right -in $base.ft -padx 13
	pack $base.ft.findnext    -side top -anchor n -in $base.ft.right
	pack $base.ft.cancel      -side top -in $base.ft.right

	focus $base.ft.left.top.entry1.strent




}

#	This varible is used for globally updating the Location of the cursor 

#trace variable textpos($base.txt) w "update_coords {$base}"


#
#  find_next_text:  This procedure will continue searching the document for more matches 
#			to the specified string. It will also generate a window that tells 
#			the user is no match is found.
#				  

proc find_next_text {base} {
	global np firsttag tcl_platform

      if {$np($base,all)==0} { 
	set pos [$base.txt search \
		$np($base,matchcase) \
		$np($base,direction) \
		$np($base,allowregexp) \
		-- $np($base,searchstring) \
		$np($base,searchloc) \
		]

        # tke if out if you want search to stop at bottom     
        if {$pos==$np($base,currsearchfirstloc)} {
          set np($base,currsearchfirstloc) 0
        }

	set np($base,cursorpos) $pos

        if { $np($base,currsearchfirstloc)!=$pos } {
  	  if {$pos!=""} {
                set firsttag 0 
		$base.txt mark set insert $pos
		$base.txt tag remove sel 1.0 end

		# this if handles regexp unknown length error, just highlights first char
		# of a match if regular expression was done....otherwise just higlight as normal

		if {$np($base,allowregexp)=="-regexp"} {
                  set leftpos [string range $pos 0 [expr [string first "." $pos] - 1]]
	          set rightpos [string range $pos [expr [string first "." $pos] + 1] end] 
                  set rightpos [expr $rightpos +1]
                  set pos2 $leftpos
               	  append pos2 "."
                  append pos2 $rightpos
  		  $base.txt tag add sel $pos $pos2
                } else {
			#added code to handle windows problem of only showing highlighted text
			# only in the active window.  This is a custom highlight text in the text
			# window. 
			 if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
				eval {$base.txt tag delete jack}
	 	  		$base.txt tag configure jack -background [$base.txt cget -fg]	
	 	  		$base.txt tag configure jack -foreground [$base.txt cget -bg]	
		  	 	$base.txt tag add jack $pos \
					"$pos + [string length $np($base,searchstring)] chars"
				$base.txt tag add sel $pos \
					"$pos + [string length $np($base,searchstring)] chars"
		  	} else {
  		  		$base.txt tag add sel $pos \
					"$pos + [string length $np($base,searchstring)] chars"
		     	}		
		}

		$base.txt see $pos
		if {$np($base,direction)=="-forwards"} {
			set np($base,searchloc) \
				"$pos + [string length $np($base,searchstring)] chars"
		}  else {
			set np($base,searchloc) \
				"$pos - [string length $np($base,searchstring)] chars"
		}
	  }
	} 

        if {$np($base,currsearchfirstloc)==""} {
          set np($base,currsearchfirstloc) $pos
         set firsttag 1
        }



	  if {$pos==""} {
        	if {[winfo exists $base.nf]} {
			#puts "window already shown"
			raise $base.nf
			return
		}
	toplevel $base.nf
	wm title $base.nf "warning"	
	frame $base.nf.top 
	pack $base.nf.top -side top -in $base.nf	
	frame $base.nf.topleft
	pack $base.nf.topleft -side left -in $base.nf.top

 	label $base.nf.pic -bitmap warning -text " " -padx 10 -pady 10
	pack $base.nf.pic -side top -in $base.nf.topleft

	frame $base.nf.topright
	pack $base.nf.topright -side right -in $base.nf.top
	label $base.nf.snf -text "String Not Found" -padx 15 -pady 15
	pack $base.nf.snf -side top -in $base.nf.topright
	#frame $base.nf.bottom
	#pack $base.nf.bottom -side bottom -in $base.nf	
	button $base.nf.cancel -text "OK" -command "destroy $base.nf"
	pack $base.nf.cancel -side bottom -in $base.nf
	wm geometry $base.nf +[expr [winfo rootx .]+100]+[winfo rooty .]
        bind $base.nf <Return> "destroy $base.nf"
        return
     }		
    }

     # Incase of REPLACE ALL
       set firsttime 1
     if {$np($base,all)==1} {
        while {$np($base,all)==1}  {
 	  set pos [$base.txt search \
		$np($base,matchcase) \
		$np($base,direction) \
		$np($base,allowregexp) \
		-- $np($base,searchstring) \
		$np($base,searchloc) \
		]
          set rst [string length $np($base,replacestring)]
          set sst [string length $np($base,searchstring)]             
          if {$firsttime==1} {
            set leftpos [string range $pos 0 [expr [string first "." $pos] - 1]]
            set rightpos [string range $pos [expr [string first "." $pos] + 1] end]               
            set adjlen [string length $np($base,replacestring)]
            set rightpos  [expr $rightpos + $adjlen] 
            set testpos $leftpos
            append testpos $rightpos
          }
          set leftpos2 [string range $pos 0 [expr [string first "." $pos] - 1]]
          set rightpos2 [string range $pos [expr [string first "." $pos] + 1] end]                 
          if {$leftpos2<=$leftpos && $rightpos2<=$rightpos && $firsttime==0 } {
    	    set np($base,all) 0              
          }

	  if {$pos==""} {
            set np($base,all) 0
          }
          if { $np($base,currsearchfirstloc)!=$pos } {           
	    if {$pos!=""} {
	      $base.txt mark set insert $pos
	      $base.txt tag remove sel 1.0 end
	      $base.txt tag add sel $pos \
		"$pos + [string length $np($base,searchstring)] chars"
		$base.txt see $pos
		if {$np($base,direction)=="-forwards"} {
			set np($base,searchloc) \
				"$pos + [string length $np($base,searchstring)] chars"
		}  else {
			set np($base,searchloc) \
				"$pos - [string length $np($base,searchstring)] chars"
		}
	        $base.txt insert sel.first $np($base,replacestring)
  	        $base.txt delete sel.first sel.last
 	    } 
            if {$firsttime==1} {
  	       set np($base,currsearchfirstloc) $pos
               set firsttime 0
            }
          } else { 
	#last one in file
  
          }
          set firsttime 0
        }
      }
}


entry $base.coords -text 1.0 -textvariable np($base,cursorpos) -width 9
bind $base.coords <Return> "goto_text {$base} %W"
bind $base.coords <Button-1> "%W delete 0 end"

#
#   goto_text: This procedure will allow the user to enter a number in the position 
#              in the upper right entrybox and go to that posistion in the document.
#

proc goto_text {base wn} {
	global np
	if {[string first "." $np($base,cursorpos)]==-1} {
		append np($base,cursorpos) ".0"
	}
	catch {
		$base.txt mark set insert $np($base,cursorpos)
		$base.txt see $np($base,cursorpos)
		focus $base.txt
	}
}
pack $base.coords -in $base.menubar -side right 


menubutton $base.help -text "Help " -underline 0 -menu $base.help.hmenu
pack $base.help -in $base.menubar -side right
menu $base.help.hmenu -tearoff 0
$base.help.hmenu add command -label "About" \
	-command "aboutANP {$base}" \
	-underline 0

#trace variable textpos($base.txt) w "update_coords {$base}"
#
#   update_coords: This procedure will update the coordinates in the upper right of the 
#                  screen. 
#	

#rename $base.txt $base.txtOld
#proc $base.txt {cmd args} "
#	global textpos
#	if {\$cmd==\"mark\" && 
#		(\[llength \$args]>0 && \[lindex \$args 0]==\"set\") &&
#		(\[llength \$args]>1 && \[lindex \$args 1]==\"insert\") &&
#		\[llength \$args]>2 } {
#			set textpos($base.txt) \[lindex \$args 2]
#	}
#	return \[eval $base.txtOld \$cmd \$args]
#"

if {[string compare $inputname ""]!=0 && [file exists $inputname]} {
	read_text $base $inputname
	
}
#puts "checking followflag"
if {$np($base,followflag)} {
	#puts "following file"
        follow_file $base
}

if {$np($base,readonlyranges)!=""} {
	#puts "configuring readonly tags $np($base,readonlyranges)"
	$base.txt tag config readonly -foreground red
	#set fid [open /tmp/kjmjunk w]
	#puts $fid "$base.txt tag add readonly $np($base,readonlyranges)"
	#close $fid
	eval $base.txt tag add readonly $np($base,readonlyranges)
}


set ignore {
	# Replace text widget command with one that screens out changes
	# to readonly text and records changes to the text.
	#puts "renaming $base.txt to .$base.txt"
	rename $base.txt .$base.txt
	proc $base.txt args {
		#puts "Inside replacement command"
		set currproc [lindex [info level 0] 0]
	        if {[string match ins* $args] &&
	                        [lsearch -exact [$currproc tag names \
	                        [lindex $args 1]] readonly]>-1} {
			#puts "Ignoring insert for $currproc $args"
	                return     
	        }
	        if [string match del* $args] {
			#puts "Calling delete for $currproc $args"
	                if [string comp {} [lindex $args 2]] {
				#puts "more than one arg"
				set s1 [lindex $args 1]
				set s2 [lindex $args 2]
				set ranges [$currproc tag ranges readonly]
				set num [llength $ranges]
				for {set r 0} {$r<$num} {incr r} {
					set r1 [lindex $ranges $r]
					incr r
					set r2 [lindex $ranges $r]
					if {([$currproc compare $r1 < $s1] && \
					    [$currproc compare $r2 > $s1]) || \
					    ([$currproc compare $r1 < $s2] && \
	                                           [$currproc compare $r2 > $s2]) } {
						return
					}
				}
				
	                } else {
				#puts "one arg"
				set item [$currproc tag names [lindex $args 1]]
				#puts "item=$item"
	                        if {[lsearch -exact $item readonly]>-1} {
					#puts "Ignoring delete"
	                                return 
	                        }
	                }
	        }
		#puts "Calling .$currproc"
	        uplevel .$currproc $args
		#puts "Called .$currproc"
	}
}

focus $base.txt
set np($base,changed) 0
if {$np($base,tailfile)} {
	$base.txt see end
}
return $base.txt
}

#
#  replace_text: This procedure will generate the replace text window and prompt the user to select
#		criteria to narrow the search. 			  
#


proc replace_text {base} {
	#puts "Inside find_text"
	if {[winfo exists $base.rt]} {
		#puts "window already shown"
		raise $base.rt
		return
	}
		#puts "creating new toplevel"

#    Main replace window generation
#
	toplevel $base.rt
        wm title $base.rt "Replace Text"
	frame $base.rt.left 
	frame $base.rt.left.top
	frame $base.rt.left.top.entry1
	frame $base.rt.left.top.entry2


	label $base.rt.left.top.entry1.strlab -text "     Find What:"
	entry $base.rt.left.top.entry1.strent -textvariable np($base,searchstring)
	bind  $base.rt.left.top.entry1.strent <Return> "$base.rt.findnext invoke"

	label $base.rt.left.top.entry2.strlab2 -text "Replace With:"
	entry $base.rt.left.top.entry2.strent2 -textvariable np($base,replacestring)
	bind  $base.rt.left.top.entry2.strent2 <Return> "$base.rt.findnext invoke"
	
	pack $base.rt.left.top.entry1.strlab  -side left
	pack $base.rt.left.top.entry1.strent  -side left
        pack $base.rt.left.top.entry1 -in $base.rt.left.top -ipady 5
	pack $base.rt.left.top.entry2.strlab2 -side left
	pack $base.rt.left.top.entry2.strent2 -side left
        pack $base.rt.left.top.entry2 -in $base.rt.left.top 
        pack $base.rt.left.top -in $base.rt.left -pady 15
	pack $base.rt.left -side left -in $base.rt

	frame $base.rt.left.bot
	frame $base.rt.left.bot.dir
	frame $base.rt.left.bot.match

	label $base.rt.left.bot.dirlab -text "Direction:"
	radiobutton $base.rt.left.bot.dir.dirup -text Up -variable np($base,direction) \
		-value "-backwards"
	radiobutton $base.rt.left.bot.dir.dirdown -text Down -variable np($base,direction) \
		-value "-forwards"
	checkbutton $base.rt.left.bot.matchcase -text "Match Case" \
		-variable np($base,matchcase) -onvalue "-exact" -offvalue "-nocase"
	checkbutton $base.rt.left.bot.allowregexp -text "Allow Regular Expressions" \
		-variable np($base,allowregexp) -onvalue "-regexp" \
		-offvalue "-exact"

	pack $base.rt.left.bot -in $base.rt.left
	pack $base.rt.left.bot.matchcase -anchor w -in $base.rt.left.bot
	pack $base.rt.left.bot.allowregexp -anchor w -in $base.rt.left.bot
                          
	pack $base.rt.left.bot.dirlab  -side left -anchor w -in $base.rt.left.bot
	pack $base.rt.left.bot.dir.dirup   -side left -in $base.rt.left.bot.dir
	pack $base.rt.left.bot.dir.dirdown -side left -in $base.rt.left.bot.dir
	pack $base.rt.left.bot.dir -in $base.rt.left.bot

	frame $base.rt.right

	button $base.rt.findnext -text " Find Next  " \
		-command "find_next_text {$base}" \
		-state disabled \
                -width 12

	button $base.rt.replacenext -text "  Replace   " \
		-command "replace_next {$base};find_next_text {$base}" \
		-state disabled \
                -width 12

	button $base.rt.replaceall -text "Replace All" \
		-command " destroy $base.rt; set np($base,all) 1;  find_next_text {$base}
 " \
		-state disabled \
                -width 12

	button $base.rt.cancel -text "  Cancel    " \
                -command " destroy $base.rt " \
                -width 12


        set xoffset [expr [expr [winfo rootx $base.txt] +[winfo width $base.txt ] ] - 380]
	wm geometry $base.rt  +$xoffset+[expr [winfo rooty $base.txt]-[winfo height $base.rt]]
 


#	wm geometry $base.rt +[winfo rootx .]+[winfo rooty .]
        bind $base.rt <Control-Key-n> "find_next_text {$base}; break" 

	searchstring_changed $base 0 0 0
 	replacestring_changed $base 0 0 0       

	pack $base.rt.right       -side right -in $base.rt -padx 13
	pack $base.rt.findnext    -side top -anchor n -in $base.rt.right
	pack $base.rt.replacenext -side top -anchor n -in $base.rt.right
	pack $base.rt.replaceall  -side top -anchor n -in $base.rt.right
	pack $base.rt.cancel      -side top -in $base.rt.right

	focus $base.rt.left.top.entry1.strent
}

proc replace_next {base} {
global np
  catch {
    $base.txt insert sel.first $np($base,replacestring)
    $base.txt delete sel.first sel.last
  }
}

proc optionsANP {base} {
   global np 
   toplevel .opt
   wm title .opt "options"
   wm resizable .opt false false
   label .opt.name  -text "\nAutoShell Notepad Options"
   label .opt.space  -text " "

   button .opt.ok -text OK -command "destroy .opt; set_options {$base}" -width 10


   button .opt.indent  -text "Set Indent Characters" -command {	destroy .opt; set_indent $base }

   button .opt.color  -text "  Set Notepad Colors  " -command {			 
   				       destroy .opt
			               set np(textcolors) [sli_colorselect .color "Select your Colors" $np(textcolors)]
  	  	   	  	       set_colors $base
 	  	   	         }

   pack .opt.name
   pack .opt.space
   pack .opt.indent
   pack .opt.color 

   wm geometry .opt +[expr [winfo rootx .]+130]+[expr [winfo rooty .] + 50]
    
   pack .opt.ok -side top -ipadx 3 -ipady 3 -padx 3 -pady 3
   catch {grab .opt}
   tkwait window .opt
}

proc set_indent {$base} {
   global btn np
   set msg "Enter number of spaces to indent:\n"
   toplevel .indent
   wm resizable .indent false false
   frame .indent.f0
   frame .indent.f1
   frame .indent.f2
   label .indent.f0.label -text "Spaces:\n"
   entry .indent.f0.entry -width 30
   bind .indent.f0.entry <Return> {  
     set num [%W get]		
     if {$num!=""} { 
       set ct 2
       set num1 [expr $num * 8.8]
       set num1 [expr $num1 / 4]
       set tab $num1
       set tablist [list]
       set tabm $tab
       # Dependent upon spaces chosen generate tab stops.....	
       while {$tabm<80 && $ct<80} {
          append tabm "m"
          set tablist [lappend tablist $tabm]
          set tabm [expr $num1 * $ct]
          set ct [expr $ct + 1] 
         }
         set np(tablist) $tablist
         $base.txt configure -tabs $np(tablist)
     } 
   }
   label .indent.f1.label -text $msg
   button .indent.f2.btnOK     -text "Ok"     -width 6 -command "set btn ok; event generate .indent <Return>"
   button .indent.f2.btnCancel -text "Cancel" -width 6 -command "set btn cancel"
   pack .indent.f0.label -side left -anchor w
   pack .indent.f0.entry
   pack .indent.f0
   pack .indent.f1.label
   pack .indent.f1 -pady 5
   pack .indent.f2.btnOK -side left
   pack .indent.f2.btnCancel
   pack .indent.f2 -pady 5 
   bind .indent <Escape> { set btn cancel }
   # wait for button or key bindings
   grab .indent
   focus .indent.f0.entry
   wm geometry .indent +[expr [winfo rootx .]+130]+[expr [winfo rooty .] + 50]
  
   tkwait variable btn  
   if {$btn=="ok"} {
    
   } 
   # destroy this dialog and return focus to previous window
   destroy .indent
}


proc set_options {base} {
  global np
  catch {
        set fid [open ~/.anrc w]
	  puts $fid "global np"
 	  puts $fid "set np($base,printcmd) \"$np($base,printcmd)\""
          puts $fid "set np(textcolors) \"$np(textcolors)\""
#         puts $fid "set np($base,beaut) $np($base,beaut)"
          catch {       
            puts $fid "set np(tablist) [list $np(tablist)]"
          }  

	close $fid
  } 

}

proc print_options {base} {
	global np tmpbase
	set tmpbase $base
	toplevel .po
 	wm title .po "Print Options"
	frame .po.prtcmd -relief groove -bd 2
	label .po.prompt -text "Print Command:"
	entry .po.entry -textvariable np($base,printcmd)
	pack .po.prompt .po.entry -side left -in .po.prtcmd
	pack .po.prtcmd -fill x -padx 2 -pady 2
	button .po.print -text Print -command \
		{
                  destroy .po
		  global tmpbase
                  print_current_doc $tmpbase		
                  }               
	button .po.cancel -text Cancel -command "destroy .po; "	
	pack .po.print .po.cancel -expand 1 -side left
}

proc print_current_doc {base} {
		  global np
		  set fid [open "anptmp[pid].txt" w]
		  set fn "anptmp[pid].txt"
 		  set currenttxt [$base.txt get 1.0 end]		 
		  puts $fid $currenttxt
       	          close $fid
  		  if {[catch { exec sh -c "$np($base,printcmd) $fn"}]==0} {
                  } 
                #  catch { exec -- rm [glob anptmp*] }	
}

proc call_beaut {} {
	global np base env
        if {$np($base,filename)!=""} {
		set fn $np($base,filename)
		clear_text $base
		exec sh -c "$env(ASTK_DIR)/scrbeaut.tcl  $fn"
		set fid [open $fn r]
		if {$fid!=""} {
			set txt [string trimright [read $fid]]
			$base.txt insert 1.0 $txt
			
		}
		set np($base,filename) $fn
		wm title . "[file tail $np($base,filename)]"
	}
}

proc set_colors {base} {
   global np
      catch {
      	set colorf [lindex $np(textcolors) 0]
	set colorf [lindex $colorf 1]
	set colorb [lindex $np(textcolors) 1]
	set colorb [lindex $colorb 1]	        
        $base.txt configure -foreground $colorf
        $base.txt configure -background $colorb
       } 
}

proc follow_file {base} {
        global np
	set np($base,followflag) 1
 	start_np_tail $base $np($base,filename)
       	$base.txt configure -state normal      
}

set tf_f(0) 0

proc np_tailfile {base filepath {buttonName ""} {vibindings 0} {followmode 0}} {
      global  tf_f tf_p tf_searchstr tf_sd tf_sp filepath2 f2

	if {[info exists tf_p($filepath)]} {
		return
	}
	set tf_p($filepath) 1
	# If file doesn't exist...
	if {[catch "open $filepath r" f]} {
		# Try to create it.
		if {[set f [ open $filepath w]]==""} {
			# Abort if can't create
			return 1
		}
		# If could create, close the file, then reopen for reading.
		close $f
		if {[set f [ open $filepath r]]==""} {
			return 2
		}
	}
	if {![file exists $filepath]} {
		return 3
	}
	file stat $filepath finfo
	set inode $finfo(ino)
        set filepath2 $filepath
        set f2 $f
	set tf_searchstr ""
	set tf_sd +
	set tf_sp 1.0
	set tf_f($base.txt) 0
	frame $base.butts



	global tf_f
	set tf_f($base.txt) 1
	button $base.butts.follow -text "Turn Off Follow Mode" \
		-command "np_tailfile_stop {$base} $filepath2 $f2"

        np_tailfile_update {$base} $filepath $f $inode $base.txt

	pack $base.butts -side top -fill x 
	pack $base.butts.follow \
		-in $base.butts \
		-side left -fill x  -expand 1
	$base.txt delete 1.0 end

	while {[gets $f linebuf]> -1} {
          $base.txt insert end "$linebuf\n"
	}

	$base.txt see end
	$base.txt configure -state disabled

	if {$followmode} {
		$base.txt.follow invoke
	}
}

proc np_tailfile_stop {base filepath f} {
	close $f
	global tf_p
	unset tf_p($filepath)
        destroy $base.butts
	$base.txt configure -state normal

	$base.file.fmenu entryconfigure "New" -state normal
	$base.file.fmenu entryconfigure "Open..." -state normal
	$base.file.fmenu entryconfigure "Save" -state normal
	$base.file.fmenu entryconfigure "Save and Exit" -state normal
	$base.file.fmenu entryconfigure "Save As..." -state normal
	$base.file.fmenu entryconfigure "Follow Mode..." -state normal


}

proc np_tailfile_update {base filepath f inode tfwin} {
	global junkflag tf_f

        # If Follow mode has been set, then read rest of file and insert into
	#  text widget
	if { $tf_f($tfwin) } {
	  if {![winfo exists $tfwin]} {
		return 5
	  }
	$tfwin configure -state normal
	# The catch will handle delayed tailfile update calls once file has been eliminated
          if {[catch {
  	    while {[gets $f linebuf]> -1 } {
		$tfwin insert end "$linebuf\n"
	    }
	  	if {$tf_f($tfwin)} {
			$tfwin yview end
	  	}
	    $tfwin configure -state disabled
          }]!=0} { 
            return
          }
	  if [catch {file stat $filepath finfo}] {
		tk_dialog .tmptf ERROR "File $filepath disappeared." error 0 OK
		return
	  }
	  if {![file exists $filepath]} {
		after 500 "np_tailfile_update {$base} $filepath $f $inode $tfwin"
	  }
	  if {$inode != $finfo(ino)} {
		close $f
		if {[set f [ open $filepath r]]==""} {
			return 4
		} 
		file stat $filepath finfo
		set inode $finfo(ino)
	  }
	  after 500 "np_tailfile_update {$base} $filepath $f $inode $tfwin"
	  set wh [lindex [$tfwin configure -height] 4]
	  # Check to see if follow mode has been set
	}
}

proc start_np_tail {base fn} {
global env  tf_f np

$base.file.fmenu entryconfigure "New" -state disabled
$base.file.fmenu entryconfigure "Open..." -state disabled
$base.file.fmenu entryconfigure "Save" -state disabled
$base.file.fmenu entryconfigure "Save and Exit" -state disabled

$base.file.fmenu entryconfigure "Save As..." -state disabled
$base.file.fmenu entryconfigure "Follow Mode..." -state disabled


# Array of "follow" flags.
set tf_f(0) 0
# Array of "follow" flags.

#bind all <Enter> {global help_currwin;set help_currwin %W}
#bind all <F1> {global help_currwin;puts "$help_currwin fired"; break}

#source $env(ASTK_DIR)/viedit.tcl
#source $env(ASTK_DIR)/util.tcl
$base.txt delete 0.0 end
np_tailfile $base $fn
#tkwait visibility $base.txt
#tkwait window $base.txt
#exit
}



proc aboutANP {base} {
   global ashlSupportWeb ashlSupportEmail copyright release_version

   toplevel .about
   wm title .about "About AutoShell Notepad"
   wm resizable .about false false
   label .about.name  -text "\nAutoShell Notepad"
   label .about.ver -text "Version $release_version"
   label .about.copyright -text $copyright
   label .about.support -text " For support and maintence contact:\n"
   label .about.email -text "$ashlSupportEmail\n"
   label .about.auth  -text "Original author: Karl Minor 07/17/1998\nWith Assorted Routines by Justin Tervooren"

   pack  .about.name
   pack  .about.ver
   pack  .about.copyright
   pack  .about.support
   pack  .about.email
   pack  .about.auth
   wm geometry .about +[expr [winfo rootx .]+130]+[expr [winfo rooty .] + 50]
 
   button .about.ok -text OK -command "destroy .about" -width 10
   pack .about.ok -side top -ipadx 3 -ipady 3 -padx 3 -pady 3
   catch {grab .about}
   tkwait window .about
}
