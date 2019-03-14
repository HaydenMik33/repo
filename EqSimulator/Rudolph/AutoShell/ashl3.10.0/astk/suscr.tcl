
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: suscr.tcl,v 1.31 2000/12/15 00:25:24 karl Exp $
# $Log: suscr.tcl,v $
# Revision 1.31  2000/12/15 00:25:24  karl
# Fixed the ON/OFF button to not make the lists misalign if the command is
# toward the end of a list longer than the listbox.
#
# Revision 1.30  2000/09/14 23:07:36  karl
# Added back the execution of OK button callbacks.
# Fixed to that closing the window via wm is like pressing cancel.
#
# Revision 1.29  2000/08/08  20:50:49  karl
# Added check to ingore error.log popups from exit command.
# Changed error.log popup to not use follow mode.
#
# Revision 1.28  2000/08/03  17:53:28  karl
# Took out leftover debugging puts "destroying ..."
#
# Revision 1.27  2000/07/07  22:11:44  karl
# Added warning when opening read-only files.
# Shrunk command edit buttons.
# Fixed non-graphical edit option.
#
# Revision 1.26  1999/09/20  19:54:42  karl
# Fixed to handle renaming the file or queue correctly, added the
# "Save As..." button.
#
# Revision 1.25  1999/08/24  15:34:12  karl
# Disabled raw edit mode until it can be fixed.
# Added command commenting feature.
# Added Cancel and OK callbacks.
#
# Revision 1.24  1999/03/17  21:55:09  karl
# Removed error window and added warning when two startups are opened
# that use the same script file (EQB & SFCE).
# Added code to check for child windows before closing a startup edit
# window.
# Changed synwin calls to synwin_sub to launch as children or parent
# window.  This allows check for children at window close.
#
# Revision 1.23  1999/02/22  20:05:03  karl
# Added continuous error.log/stdout watch to script edit code.
#
# Revision 1.22  1998/12/11  21:24:27  karl
# Fixed to allow paths to contain whitespace..
#
# Revision 1.21  1998/10/20  22:10:22  karl
# Fixed error pre/post checks to ignore new files of length 0.
#
# Revision 1.20  1998/09/01  21:51:58  karl
# Fixed "set errortime" bug introduced in previous revision.
#
# Revision 1.19  1998/09/01  19:18:08  karl
# Added diagfile_precheck, diagfile_postcheck for more generic file
# change checking.  Changed error_log_precheck/postcheck to use these
# new procs.
#
# Revision 1.18  1998/03/13  17:15:31  love
# Modified code to use join instead of manually creating an absolute path.
#
# Revision 1.17  1998/01/19  21:58:04  love
# Modified to use file join command instead of a set statement to create
# an absolute path when running on versions of Tcl later than 7.4.
#
# Revision 1.16  1998/01/08  22:57:02  karl
# Fixed file pointer leak caused when non-appl startup commands were edited.
#
# Revision 1.15  1997/11/07  19:47:45  karl
# Changed Add button at startup edit to add commands after current selection
# instead of before.
#
# Revision 1.14  1997/10/29  23:35:29  love
# Modified code to use tempfilename instead of creating temporary
# files by hand.  Enhanced code to use the file functions instead
# of exec'ing mv when running Tcl7.6 since this is more portable
#
# Revision 1.13  1997/08/26  18:25:01  karl
# Took explain out of defcmd internal edit window.
#
# Revision 1.12  1997/08/05  21:11:09  karl
# Fixed bug that caused error.log popup window to go haywire.
#
# Revision 1.11  1997/05/27  18:58:06  karl
# Added pop-up details window to view all command parameters.
#
# Revision 1.10  1997/04/14  18:13:05  karl
# Fixed bug introduced in previous checkin.  It would cause a stack trace
# anytime a command was double-clicked.
#
# Revision 1.9  1997/04/10  20:22:23  karl
# Added check for window already open for a given command.
#
# Revision 1.8  1997/01/20  22:01:09  karl
# Cleaned up handling of newline output at save.  Fixed default command
# format string to allow multiple %Ns.  Removed bindings that allowed
# widget traversal, since it was causing stack traces and is handled by
# TK already anyway.
#
# Revision 1.7  1997/01/07  23:32:48  karl
# Added edit_command_by_pos to allow external triggering of command edit.
#
# Revision 1.6  1996/11/14  23:29:21  karl
# Added storage of executable name in comments (like server name).
#
# Revision 1.5  1996/11/11  23:24:00  karl
# Fixed ODT-dumping "catch toplevel" statements.
# Added error_log_precheck and error_log_postcheck to notice and display
# changes to error.log.
#
# Revision 1.4  1996/11/04  21:57:41  karl
# Fixed bug with "restore" level parameter in edit window.
#
# Revision 1.3  1996/10/31  20:48:42  karl
# Fixed title in event that commands are edited from a string instead of file.
#
# Revision 1.2  1996/10/30  18:33:37  karl
# Removed leftover DV debugging dump.
#
# Revision 1.1  1996/08/27  16:18:34  karl
# Initial revision
#
# suscr.tcl
#
# this file contains most of the code used to edit 
# Autoshell startup files.  This includes reading
# data from a .su file, and editing all aspects of it
# except for commands.  Commands are handled by 
# cmdedit.tcl
#
# cmdedit.tcl, util.tcl, and viedit.tcl are required
# for the procedures in this file to work.
#

if {![info exists CT]} {
set CT(set) "set"
set CT(defcmdu) "defcmd"
set CT(defcmdi) "defcmd internal"
set CT(include) "include"
set CT(tclinclude) "tclinclude"
set CT(ldscript) "ldscript"
set CT(log) "log"
set CT(restore) "restore"
#set CT(set) "variable"
#set CT(defcmdu) "user cmd"
#set CT(defcmdi) "internal cmd"
#set CT(include) "include file"
#set CT(tclinclude) "tclinclude file"
#set CT(ldscript) "script file"
#set CT(log) "log settings"
#set CT(restore) "DV file"
}

set suscr_Usage_Notes {
}   

#rename file old_file
#proc file {args} {
#	puts "file $args"
#	return [eval old_file $args]
#}

# initialize the window counter to zero 
global win_num
set win_num 0
#set auto_path [linsert $auto_path 0 /home/jasonm/tk/libdir]

set edit_su_docs {

edit_su is used to graphically edit an AutoShell .su file.
Each command, variable, script file, and include file is 
put in a list.  Double-clicking on an item then lauches the
appropriate editing tool.  Other types of startup commands 
can be incorporated fairly easily.

filename - the name of the AutoShell startup file to be edited.
default_contents - Default contents of the startup file, in case
	it doesn't already exist.  For example: 
		"log name=all level=1
		 ldscript file=[file rootname $filename].scr"
buttons - Definitions for user-defined buttons to appear at the bottom of
	the edit window.  This is a list of buttons, where each button is 
	a list of the form {button_text callback_cmd}.  Each callback_cmd
	is a command to be executed when the button is pressed.  Each 
	callback_cmd will have two arguments, filename and appid, appended
	as arguments before being invoked, so the actual procedure must
	expect these arguments.  The filename identifies the file being
	edited, and the appid is a unique identifier for the edit window
	and its associated data. Example:
		"{{Trace Appl} {trace_sfc $sfcid {}}} 
		{{View DVs} {view_dvs $sfcid {} }}
		{{View Logs} {view_logs $sfcid {} }}"
		:
		proc trace_sfc {sfcid cctxt filename appid} { .... }
		proc view_dvs {sfcid ctxt filename appid} { ... }
 mode - If this is "graphical", the user will edit commands by selecting 
	them from an abbreviated listbox.  If it is "raw", the commands will
	be displayed in a big text edit window (defeating the purpose).

When in "graphical" mode, the available command types and their edit routines
are defined by the "cmdtable" structure, which should be defined by each 
application using edit_su.  The format for cmdtable is:
	{
	  {{cmd_type} {def_cmd_text} cmd_classify_proc cmd_edit_proc namespec}
	  {					 			     }
	  :
	  :
	}
cmd_type - short description of the command purpose
def_cmd_text - Default command text.  Starting values for a newly created cmd.
cmd_classify_proc - Proc to recognize commands of this type when reading the
	startup file.	
cmd_edit_proc - Proc to edit the values for this type of command.
namespec - Identifies how to extract command "name" from its text.
	"name" means  the value of the name= parameter contains the name.
	"1=" means that the left side of the first tagged parm is the name.

The do_any and edit_any procs are provided to make addition of new command
types easy.  For example the following cmdtable entry and procs allow 
editing of "restore" commands:

	{{DV file} {restore file=%N} do_restore edit_restore file}

Example of cmd_classify_proc:

	proc do_restore {firstword cmd winid} {
       		return [do_any $firstword $cmd $winid restore file "DV file"] 
	} 
Example of cmd_edit_proc:

	proc edit_restore {winid index} {
   		return [edit_any $winid $index 
			{restore file=%s [variable=%s] [parse [level=%d]]}]
	}
	
Note that the edit_any procedure uses the command's syntax string to define
the input window.  This string can be stolen from the AutoShell manual.

}

proc edit_su { filename default_contents {buttons {}} {mode graphical} 
	{vibindings 0} {parent .}}  {

	global appInfo
	global cmdInfo
	global win_num
	upvar 0 win_num winid

	# If there is no filename, we will assume that default_contents 
	# contains the name of a variable that contains the contents.
   
	# initialize command counter to 0
	set appInfo($winid,cmdnum) 0
	set appInfo($winid,commands) {}

	#puts "Inside edit_su for $filename"
	set existing 0
if {$filename!="" && [file extension $filename]!=".scr"} {
	#puts "Editing commands in a file"
	set w .edit_suf$winid	

	foreach id [array names appInfo "*,sufile"] {
		if {$appInfo($id)==$filename} {
			tk_dialog .tmp ERROR \
			"You Already have a window open for $filename." \
				error 0 OK
			return ""
		}
	}

		set appInfo($winid,mode) file
		# find out path of the main startup file
		set appInfo($winid,rootdir) [file dirname $filename]
		set appInfo($winid,sufile) $filename
		# set default scriptfile (foo.su ==> foo.scr)
		set appInfo($winid,scrfile) [file rootname $filename].scr
   	 
		# check to make sure .su file exists and is not empty
		# before trying to get data from it.
		if {[file exists $filename]}  {
			if {[file size $filename] == 0}  {
				set existing 0
			} else {
				if {[warn_read_only $filename]} {
					return ""
				}
				set fid [open $filename r]
				set existing 1
			}
		} else {
			set existing 0
		}
		set title "$filename - Startup Editor"
} else {
	#puts "Editing commands in a string"
	# Editing variable contents, not a file.
	set w .edit_sus$winid	
	foreach id [array names appInfo "*,scrfile"] {
		if {$appInfo($id)==$filename} {
			tk_dialog .tmp ERROR \
			"You already have a window open that may modify $filename. Be sure you don't edit the same command from both windows." \
				error 0 OK
			break
		}
	}
		set appInfo($winid,mode) string
		set appInfo($winid,scrfile) $filename
		set appInfo($winid,rootdir) [file dirname $filename]
		set title "Edit Startup Commands"
}

	set appInfo($winid,vibindings) $vibindings

	if {[winfo exists $w]} { return }
	set geometry "+[winfo x $parent]+[winfo y $parent]"
	toplevel $w
	wm geometry $w $geometry
	wm withdraw $w
	wm title $w $title
	if {[string length $filename]} {
		wm iconname $w $filename
	}
    # put window into list of startup files being edited.
    lappend appInfo(mainWindows) $w
    set appInfo($winid,mainwindow) $w

    
    #########################
    ### this is where the window is set up
    #########################

    ## menu bar
    #frame $w.mbar -relief groove  -bd 2
    ## file menu
    #menubutton $w.mbar.file -text File -menu $w.mbar.file.menu
    #menu $w.mbar.file.menu
    #$w.mbar.file.menu add command -label Quit -command "quit_edit_su $w $winid"
    ## pack the menus
    #pack $w.mbar.file -side left

    # command list and buttons
    frame $w.top -relief groove -bd 2

    if {$appInfo($winid,mode)=="file"} {
		#puts "Reading commands from a file"
	    # get information from .su file (vars, includes, defcmds, etc.)
    	if {$existing!=0} {
		#puts "REading existing app."
		read_app_def $fid $winid "FILE"
    	} else {
		#puts "Creating default app."
		set fid [open $filename w]
		puts $fid $default_contents
		close $fid
		set fid [open $filename r]
		#set fid $default_contents
		set existing 1
		read_app_def $fid $winid "FILE"
    	}
    } else {
		set existing 1
		#puts "Reading commands from a string"
		upvar #0 $default_contents su_contents
		read_app_def $su_contents $winid "STRING"
		set appInfo($winid,varname) $default_contents
    }

if {$mode=="graphical"} {
	#puts "Setting up graphical edit mode"
    frame $w.top.butt 
    frame $w.top.list
    # buttons
    button $w.top.butt.add -text "Add" \
	-padx 2 -pady 0 \
	-command "add_dialogue $winid" 
    button $w.top.butt.del -text "Cut" \
	-padx 2 -pady 0 \
	-command "del_command $winid $w.top.list.name $w.top.list.type 1"
    button $w.top.butt.copy -text "Copy" \
	-padx 2 -pady 0 \
	-command "del_command $winid $w.top.list.name $w.top.list.type 0"
    button $w.top.butt.paste -text "Paste" \
	-padx 2 -pady 0 \
	-command "paste_command $winid"
    button $w.top.butt.edit -text "Edit" \
	-padx 2 -pady 0 \
	-command "edit_command $winid $w.top.list.name \[$w.top.list.name curselection\]"
    button $w.top.butt.det -text "Details" \
	-padx 2 -pady 0 
    button $w.top.butt.cmt -text "On/Off"  \
	-command "disable_command $winid $w.top.list.type \
			\[$w.top.list.type curselection\]" \
	-padx 2 -pady 0 
    bind $w.top.butt.det <ButtonPress-1> "
	pop_command $winid $w.top.list.name \[$w.top.list.name curselection\]
	$w.top.butt.det configure -relief sunken
	break"
    bind $w.top.butt.det <ButtonRelease-1> "
	pop_info_hide 
	$w.top.butt.det configure -relief raised
	break"
    
    
    # list boxes
    frame $w.top.list.commands -relief sunken -bd 2
    pack $w.top -ipady 2 -padx 4 -expand yes -fill both  -pady 1
    # make the two listboxes act as one
    set appInfo($winid,namebox) [listbox $w.top.list.name  \
	-yscrollcommand "$w.top.list.scroll set" -exportselection false \
	-selectmode single -height 7 -relief flat -bd 0 \
	-highlightthickness 0]
    bindtags $w.top.list.name "suitems,$winid Listbox"
    set appInfo($winid,typebox) [listbox $w.top.list.type \
        -yscrollcommand "$w.top.list.scroll set" -exportselection false \
	-selectmode single -height 7 -relief flat -bd 0 \
	-highlightthickness 0]
    bindtags $w.top.list.type "suitems,$winid Listbox"
    scrollbar $w.top.list.scroll -highlightthickness 0 \
	-command "scrollmult {$w.top.list.name $w.top.list.type}"     

    proc b1s { w y winid }  {
	#puts "	b1s $w $y $winid"
	selectmult "$w.top.list.name $w.top.list.type" $y
	if {[$w.top.list.name size]}  {
	    set_comment $w.middle.comtext.text $winid \
		    [$w.top.list.name curselection]
	}
    }
	proc b1m { w y winid } {
		global appInfo
		# Get index of current selected entry
		set cursel [$w.top.list.name curselection] 
		if {$cursel==""} {
			return
		} 
		# Get index of mouse position
		set curpos [$w.top.list.name nearest $y]
		#puts "Dragging entry from $cursel to $curpos"
		# If mouse has moved away from selection
		if {$cursel!=$curpos} {
			#puts "cursel=$cursel curpos=$curpos"
		#$w.top.list.name see $curpos
		#$w.top.list.type see $curpos
			# Get data of current selection
			set moving_name [$w.top.list.name get $cursel]
			set moving_type [$w.top.list.type get $cursel]
			# Delete the selection from its current position
			set top [lindex [$w.top.list.name yview] 0]
			set top [expr round ($top)]
			if {$top!=0} {
				set top [expr round([$w.top.list.name size]*$top)]
			}
#	tk_dialog .tmp WAIT "About to delete, top=$top" {} {} OK
			$w.top.list.name delete $cursel
			$w.top.list.type delete $cursel
			# Insert it at the new position
#	tk_dialog .tmp WAIT "About to insert" {} {} OK
			$w.top.list.name insert $curpos $moving_name
			$w.top.list.type insert $curpos $moving_type
			# Readjust view to that of before ins/del
			$w.top.list.name yview $top
			$w.top.list.type yview $top

			# Get the command-list index
			set cmdlist $appInfo($winid,commands)
			# Find the old location in the index
			set moving_index [lindex $cmdlist $cursel]
			# Delete the old entry	
			set cmdlist [lreplace $cmdlist $cursel $cursel]	
			# And replace it in its new position
			set cmdlist [linsert $cmdlist $curpos $moving_index]
			set appInfo($winid,commands) $cmdlist
			# Update the selection to be at the current pos
			#puts "b1s $w $y $winid"
			selectmult "$w.top.list.name $w.top.list.type" $y
			#b1s $w $y $winid
		}
	}
    
    bind suitems,$winid <1> "b1s $w %y $winid; break"
    bind suitems,$winid <B1-Motion> "b1m $w %y $winid; break"
    bind suitems,$winid <B1-Leave> "break"
    bind suitems,$winid <Double-Button-1>  {
	set winid [string range [winfo toplevel %W] 9 end]
	if {[%W size]}  {edit_command $winid %W [%W curselection]}
    }
    bind suitems,$winid <ButtonPress-2> \
	"pop_command $winid %W \[%W nearest %y\]"
    bind suitems,$winid <ButtonRelease-2> "pop_info_hide"
    bind suitems,$winid <ButtonPress-3> \
	"pop_command $winid %W \[%W nearest %y\]"
    bind suitems,$winid <ButtonRelease-3> "pop_info_hide"
    

    # pack everything
    pack $w.top.list.type -side left \
	-in $w.top.list.commands -fill y
    pack $w.top.list.name -side left \
	-in $w.top.list.commands -expand yes -fill both
    pack $w.top.butt.add $w.top.butt.del $w.top.butt.copy $w.top.butt.paste \
		$w.top.butt.edit $w.top.butt.det \
		$w.top.butt.cmt \
		-side top -pady 1  -fill x
    pack $w.top.list.commands -side left -fill both -expand yes
    pack $w.top.list.scroll -side left -fill y 
    pack $w.top.butt -side left -padx 5
    pack $w.top.list -side left -expand 1 -fill both -padx 10


    # section to display and edit comments.  The comments associated
    # with the selected item are shown
    frame $w.middle -relief groove -bd 2
    pack $w.middle -side top -fill both -expand yes -ipady 2 -padx 4 -pady 1
    label $w.middle.comlabel -text "Comments:" -anchor w
    set comtext [viedit $w.middle.comtext -height 4 -width 80 \
		     -vibindings $appInfo($winid,vibindings) \
		     -relief sunken -bd 2 -status no -fileops no].text
    pack $w.middle.comlabel -side top -fill x  -padx 12
    pack $w.middle.comtext -side top -fill y -expand yes
    do_normal $comtext
    # fill list with items
	global su_comstr
    if {$existing && [info exists appInfo($winid,commands)]} {
	foreach command $appInfo($winid,commands)  {
		set commentflag [lindex $cmdInfo($winid,$command) 2]
		set cmdname [lindex [lindex $cmdInfo($winid,$command) 1] 2]
		if {$commentflag} {
			set cmdname "${su_comstr}$cmdname"
		}
	    $appInfo($winid,namebox) insert end \
		[lindex [lindex $cmdInfo($winid,$command) 1] 1]
	    $appInfo($winid,typebox) insert end $cmdname
	}
	# insert comment associated with first item in file
	if {[llength $appInfo($winid,commands)]>0} {
		$comtext insert 1.0 [lindex $cmdInfo($winid,0) 0]
	}
    }
    $comtext mark set insert 1.0
    # initially select the first item
    $appInfo($winid,namebox) selection set 0
    $appInfo($winid,typebox) selection set 0
    set appInfo($winid,oldindex) 0
} else {
	#puts "Setting up external editor edit mode"
	#puts "creating $w.edittext"
#    viedit $w.edittext -height 24 -width 80 \
#	     -vibindings $appInfo($winid,vibindings) \
#	     -relief sunken -bd 2 -status yes -fileops no
#    if {$appInfo($winid,mode)=="file"} {
#	    seek $fid 0
#	    $w.edittext.text insert 1.0 [read $fid]
#	    $w.edittext.text mark set insert 1.0
#    } else {
#	    upvar $default_contents su_contents
#	    $w.edittext.text insert 1.0 $su_contents
#	    $w.edittext.text mark set insert 1.0
#    }
	#set appInfo($winid,filecontents) [read $fid]
    global options
    if {[info exists options(texteditor)]}  {
        set editorcmd $options(texteditor)
    } elseif {[info exists options(vibindings)] && $options(vibindings)} {
        set editorcmd "xterm -e vi"
    } else {
        set editorcmd anp
    }
    if {$editorcmd=="anp" || [string match "*anp *" $editorcmd] || \
        [string match "*anp" $editorcmd]} {
        append editorcmd " -buttons"
    }

	# If editing var contents instead of file, button should
	# open an external editor with a callback to update the var.
	# If editing a file, the button just launches an editor.
	if {$filename!="" && [file extension $filename]!=".scr"} {
		button $w.edittext -text "Edit File" \
			-command "exec sh -c \"$editorcmd $filename\" &"
		#bind $w.edittext <Destroy> "puts {destroying $w.edittext}"
	} else {
		button $w.edittext -text "Edit File" \
			-command "su_execwait $winid {$editorcmd}"
		#bind $w.edittext <Destroy> "puts {destroying $w.edittext}"
	}

    pack $w.edittext -side top
    #do_normal $w.edittext.text
    set comtext ""
}

	if {$appInfo($winid,mode)=="file"} {
		close $fid
	}
    

	set buttnames ""
	set numbutts [llength $buttons]
	set maxbutts 6
	set numbuttframes [expr ($numbutts-1)/$maxbutts+1]
	#puts "numbutts=$numbutts numbuttframes=$numbuttframes"
	set fc 0
	

	# User-defined buttons and callbacks
	set bc 0
	foreach button $buttons {
		set buttontext [lindex $button 0]
		set buttoncb [lindex $button 1]
		if {$buttontext=="Cancel Callback"} {
			set appInfo($winid,cancelcb) $buttoncb
			continue
		}
		if {$buttontext=="Ok Callback"} {
			set appInfo($winid,okcb) $buttoncb
			continue
		}
		if {[expr $bc % $maxbutts]==0} {
			incr fc
			set frname $w.bottom$fc
			frame $frname -relief groove -bd 2
			pack $frname -side top -fill both \
				-ipady 4 -padx 4 -pady 1
		}
		incr bc
		button $frname.udb$bc -text $buttontext \
			-padx 4 -pady 1 \
			-command "global appInfo
				if {!\[su_save $winid {$comtext}\]} { 
					$buttoncb \$appInfo($winid,sufile) $winid
				}"
		pack $frname.udb$bc -side left -padx 2 -expand 1
		lappend buttnames $frname.udb$bc
	}

    frame $w.stdbutts -relief groove -bd 2
    pack $w.stdbutts -side top -fill both -ipady 4 -padx 4 -pady 1
    button $w.stdbutts.ok -text OK \
		-padx 4 -pady 1 \
		-command "ok_pressed $w $winid {$comtext} {$filename}"
    button $w.stdbutts.save -text Save \
		-padx 4 -pady 1 \
		-command "su_save $winid {$comtext}"
    button $w.stdbutts.cancel -text Cancel \
		-padx 4 -pady 1 \
		-command "[list cancel_pressed $w $winid $filename]" 
	wm protocol $w WM_DELETE_WINDOW "$w.stdbutts.cancel invoke"
    # pack 'em
    pack $w.stdbutts.ok  -side left -padx 10 -expand 1
	pack $w.stdbutts.save  -side left -padx 10 -expand 1
	if { $appInfo($winid,mode)=="file" } {
	    button $w.stdbutts.saveas -text "Save As..." \
			-padx 4 -pady 1 \
			-command "su_save_as $winid {$comtext} $w.stdbutts.saveas"
		pack $w.stdbutts.saveas -side left -padx 10 -expand 1
	}
	pack $w.stdbutts.cancel -side left -padx 10 -expand 1
    

    
    set appid $winid
    # increment the window counter
    incr winid

    #after 500 wm deiconify $w
    update idletasks; wm deiconify $w

	#wtree $w
    set appInfo($appid,buttnames) $buttnames
    return $appid
}

proc su_execwait {winid editorcmd} {
	global appInfo
	set tmpfile [tempfilename su[pid]]
	set outfile [open $tmpfile w]
	upvar #0 $appInfo($winid,varname) su_contents
	#eval set su_contents \$$appInfo($winid,varname)
	set su_contents [string trim $su_contents]
	puts $outfile $su_contents
	close $outfile
	exec_and_wait "sh -c \"$editorcmd $tmpfile\"" \
		"su_execwait_handler $winid $tmpfile"
}

proc su_execwait_handler {winid tmpfile} {
		global appInfo
		#global $appInfo($winid,varname) 
		upvar #0 $appInfo($winid,varname) su_contents
		set infile [open $tmpfile r]
		set tmpstr [string trim [read $infile]]
		set su_contents $tmpstr
		close $infile
		file delete $tmpfile
}

proc copy_handler {x y} {
	if {![catch {set rc [selection get -selection CLIPBOARD]}]} {
		return $rc
	} else {
		return ""
	}
}

proc su_save_as {winid comtext w} {
	global appInfo
	set initialfile $appInfo($winid,sufile)
	set fn [tk_getSaveFile -defaultextension .su \
		-initialfile [file tail $initialfile] -parent $w]
	if {$fn!=""} {
		set appInfo($winid,sufile) $fn
		set rc [su_save $winid $comtext $fn]
		if {!$rc} {
			set title "$fn - Startup Editor"
			wm title .edit_suf$winid $title
			if {[string length $fn]} {
				wm iconname .edit_suf$winid $fn
			}
		}
		return $rc
	} else {
		return -5
	}
}


proc ok_pressed {w winid comtext filename} {
	global appInfo
	if {[info exists appInfo($winid,okcb)]} {
		eval $appInfo($winid,okcb) $filename $winid
	}
	#puts "su_save $winid $comtext"
	if {![su_save $winid $comtext]} {
		quit_edit_su $w $winid
	}
}

proc cancel_pressed {w winid filename} {
	global appInfo
	if {[info exists appInfo($winid,cancelcb)]} {
		eval $appInfo($winid,cancelcb) $filename $winid
	}
	quit_edit_su $w $winid
}

proc pop_command {winid listbox list_index} {
    global cmdInfo
    global appInfo
    if {$list_index != ""}  {
	set cmd_index [lindex $appInfo($winid,commands) $list_index]
	if {$cmd_index==""} {
		return
	}
	set parmlist [lindex [lindex $cmdInfo($winid,$cmd_index) 1] 0]
	foreach parm $parmlist {
		if {[llength $parm]>1} {
			append cmdtext "[lindex $parm 0]="
			if {[regexp {[ 	]} [lindex $parm 1]]} {
				set val [lindex $parm 1]
				regsub -all "\n" $val "\n\t\t" val
				append cmdtext "\"$val\"\n\t"
			} else {
				append cmdtext "[lindex $parm 1]\n\t"
			}
		} else {
			if {[regexp {[ 	]} $parm]} {
				append cmdtext "\"$parm\"\n\t"
			} else {
				append cmdtext "$parm\n\t"
			}
		}
	}
	pop_info_show [string trim $cmdtext]
    } else {
	#puts "no current selection"
    }
}

proc change_butt_state {winid buttname buttstate} {
	global appInfo
	#puts "Trying to change '$buttname' to $buttstate for $winid"
	if {![info exists appInfo($winid,buttnames)]} {
		return 
	}
	foreach button $appInfo($winid,buttnames) {
		set text [$button cget -text]
		#puts "Looking at $text"
		if {$text==$buttname} {
			#puts "$button configure -state $buttstate"
			$button configure -state $buttstate
			break
		}
	}
}


proc cleanup_edit_su {winid} {
    global appInfo cmdInfo
    set names [array names appInfo "$winid,*"]
    foreach name $names {
    	unset appInfo($name)
    }
    set names [array names cmdInfo "$winid,*"]
    foreach name $names {
    	unset cmdInfo($name)
    }
}

proc quit_edit_su { w winid }  {

    global appInfo cmdInfo
	foreach child [winfo children $w] {
		if {[winfo toplevel $child]==$child} {
			tk_dialog .tmp Warning "Please close all subwindows before closing this window." warning 0 OK
			raise $child
			wm deiconify $child
			return
		}
	}
    set pos [lsearch $appInfo(mainWindows) $w]
    set appInfo(mainWindows) \
	[lreplace $appInfo(mainWindows) $pos $pos]
    cleanup_edit_su $winid
    if {[llength $appInfo(mainWindows)] == 0}  {
	destroy $w
    } else {
	if {[info exists appInfo($winid,toplevel)]}  {
	    foreach window $appInfo($winid,toplevels) {destroy $window}
	}
	destroy $w
    }
}

proc list_msg_to_an {command indentflag} {
	set outstr "[lindex $command 0] "
	for {set i 1} {$i < [llength $command]} {incr i}  {
	    if {[llength [lindex $command $i]] == 1}  {
		# Positional parameters.
		append outstr "[lindex $command $i] "
	    } else {
		# Tagged parameters.
		append outstr "[lindex [lindex $command $i] 0]="
		set value [lindex [lindex $command $i] 1]
		regsub -all "\n" $value {\n} value
		# Escape all escapes
		regsub -all {\\} $value "\\\\" value
		# Escape all embedded quotes.
		regsub -all {\"} $value "\\\"" value
		set value [string trim $value]
		append outstr "\"$value\""
	    }
	    if {$indentflag} {
	      # If output goes to a file.
  	      if {$i < [expr [llength $command] -1] } {
		# Indent all the command parameters.
	  	append outstr " \\\n\t"
	      } else  {
	  	append outstr "\n"
	      }
	    } else {
	      # If output is a string.
		append outstr " "
	    }
	}
	return $outstr
}

proc su_save { winid comtext {filename {}}}  {
	#puts "winid=$winid comtext=$comtext filename=$filename"
    global cmdInfo appInfo options

	#puts "Inside su_save"
    
	#puts "appInfo($winid,mode)=$appInfo($winid,mode)"
    # If editing a file, warn if it is read-only, then copy to backup.
    if {$appInfo($winid,mode)=="file"} {
		if {$filename==""} {
			set filename $appInfo($winid,sufile)
		}
		if {[file exists $filename] && ![file writable $filename]} {
			tk_dialog .err ERROR "File $filename is read-only!" error 0 OK
			return -1
		}
		# If we are using the graphical edit mode to edit a file, move
		# the file to a backup location.
		if {![winfo exists .edit_suf$winid.edittext] &&
			![winfo exists .edit_sus$winid.edittext]} {
			if {[info exists options] && [info exists options(backupfiles)] &&
					 $options(backupfiles) == 1} {
				catch {file rename -force $filename $filename~}
			}
		}
    }

    # If editing a file in graphical mode, 
    # create a temporary file name and open it.
    if {$appInfo($winid,mode)=="file" && 
		(![winfo exists .edit_suf$winid.edittext] &&
		![winfo exists .edit_sus$winid.edittext])} {
	set tmpfile [tempfilename su[pid]]
	set outfile [open $tmpfile w]
    }
	#puts "looking for .edit_su?$winid.edittext"

# Graphical Edit Mode - extract info from data structures
#puts "looking for .edit_su?$winid.edittext"
if {![winfo exists .edit_suf$winid.edittext] &&
	![winfo exists .edit_sus$winid.edittext]} {
	#puts "Getting outstr from data structure"
    set outstr ""
    if {$comtext!="" && $appInfo($winid,cmdnum)>$appInfo($winid,oldindex)} {
	set cmdInfo($winid,$appInfo($winid,oldindex)) \
		[lreplace $cmdInfo($winid,$appInfo($winid,oldindex)) 0 0 \
		[$comtext get 1.0 end]]
    }

	if {[info exists appInfo($winid,srvname)] &&
			$appInfo($winid,srvname)!=""} {
		append outstr "# $appInfo($winid,sufile), Loaded by: $appInfo($winid,srvname)"
	}
	if {[info exists appInfo($winid,exename)] &&
			$appInfo($winid,exename)!=""} {
		append outstr " Executable: $appInfo($winid,exename)"
		#puts "pushed exename='$appInfo($winid,exename)'"
	}
	append outstr "\n"
    foreach cmdnum $appInfo($winid,commands) {
	set cmd $cmdInfo($winid,$cmdnum)
	#puts $cmd
	set comment [string trim [lindex $cmd 0]]
	if {$comment!=""} {
	set comment "\# $comment"
	regsub -all "\n" $comment "\n\# " comment
	#set comment [string range $comment 0 [expr [string length $comment]-3]]
	append outstr "$comment\n"
	}
	
	set command [lindex [lindex $cmd 1] 0]
	global su_comstr
	if {[llength $cmd]>2} {
		set commentflag [lindex $cmd 2]
	} else {
		set commentflag 0
	}
	if {$commentflag} {
		append outstr $su_comstr
	}
	#puts "command=$command"
	if {$appInfo($winid,mode)=="file"} {
		set fileflag 1
	} else {
		set fileflag 0
	}
	append outstr [list_msg_to_an $command $fileflag]
#	append outstr "[lindex $command 0] "
#	# Loop through parameters
#	for {set i 1} {$i < [llength $command]} {incr i}  {
#	    if {[llength [lindex $command $i]] == 1}  {
#		# Positional parameters.
#		append outstr "[lindex $command $i] "
#	    } else {
#		# Tagged parameters.
#		append outstr "[lindex [lindex $command $i] 0]="
#		set value [lindex [lindex $command $i] 1]
#
##              if {$appInfo($winid,mode)=="file"} {
##		# Replace newlines with \n.
##		regsub -all "\n" $value "\\\n" value
##	      } else {
#		regsub -all "\n" $value {\n} value
##	      }
#		# Escape all escapes
#		regsub -all {\\} $value "\\\\" value
#		# Escape all embedded quotes.
#		regsub -all {\"} $value "\\\"" value
#		set value [string trim $value]
#		append outstr "\"$value\""
#	    }
#	    if {$appInfo($winid,mode)=="file"} {
#	      # If output goes to a file.
#  	      if {$i < [expr [llength $command] -1] } {
#		# Indent all the command parameters.
#	  	append outstr " \\\n\t"
#	      } else  {
#	  	append outstr "\n"
#	      }
#	    } else {
#	      # If output is a string.
#		append outstr " "
#	    }
#	}

#	# Last command argument
#	if {[llength [lindex $command $i]] == 1}  {
#	    # Non-tagged parm
#	    append outstr "[lindex $command $i] \n"
#	} else {
#	    # Tagged parm
#	    append outstr "[lindex [lindex $command $i] 0]="	
#	    regsub -all "\n" [lindex [lindex $command $i] 1] {\n} value
#	    regsub -all {\\} $value "\\\\" value
#	    regsub -all {\"} $value "\\\"" value
#	    set value [string trim $value]
#	    append outstr "\"$value\"\n"
#	}
	append outstr "\n"
	
    }
    # If editing a file (in graphical mode) store edited contents to disk.
    if {$appInfo($winid,mode)=="file" } {
	puts -nonewline $outfile $outstr
    close $outfile
	file rename -force $tmpfile $filename
    # If editing an in-memory string, update the string with edited contents.
    } else {
	upvar #0 $appInfo($winid,varname) su_contents
	set su_contents $outstr
    }
# External Edit Mode 
} else {
	# Add code to update exename and srvname if necessary.
	set tfid [open $filename r]
	set contents [read $tfid]
	close $tfid
	set lines [split $contents "\n"]
	set newlines {}
	foreach line $lines {
		if {[string index $line 0]=="#" && 
			[string first "Loaded by:" $line]>0} {
			set newline "# $appInfo($winid,sufile)"
			if {[info exists appInfo($winid,srvname)]} {
				append newline ", Loaded by: $appInfo($winid,srvname)"
			} 
			if {[info exists appInfo($winid,exename)]} {
				append newline " Executable: $appInfo($winid,exename)"
			} 
			lappend newlines $newline
			
		} else {
			lappend newlines $line
		}
	}
	set tfid [open $filename w]
	puts $tfid [join $newlines "\n"]
	close $tfid

	#puts "Getting outstr from text widget"
	#set outstr [.edit_suf$winid.edittext.text get 1.0 end]
	#set outstr $appInfo($winid,filecontents)
	# If editing file (external editor) edited contents already on disk.
	# If editing an in-memory string, string should have been updated by
	# callback
	#if {$appInfo($winid,mode)!="file" } {
	#	upvar #0 $appInfo($winid,varname) su_contents
	#	set su_contents $outstr
    	#}
}
	#puts "outstr=$outstr"
	
	return 0
}

proc paste_command { winid}  {
	#puts "paste_command winid=$winid"

    global appInfo winInfo cmdtable
	if {[catch {set cmdtopaste [selection get -selection PRIMARY]}]} {
		tk_dialog .tmp ERROR \
			"Clipboard is empty" \
			error 0 OK
	}
	if {[catch {an_msg_to_tcl $cmdtopaste}]} {
		tk_dialog .tmp ERROR \
			"Clipboard contents not in valid AutoNet command format" \
			error 0 OK
	}
	scan $cmdtopaste "%s" showtype
	set name [find_name $winid $cmdtopaste]

    set namelist $appInfo($winid,namebox)
    set typelist $appInfo($winid,typebox)
    set cmdnum $appInfo($winid,cmdnum)
    #puts "namelist=$namelist typelist=$typelist cmdnum=$cmdnum"
    if {[info exists appInfo($winid,commands)]}  {
	#puts "appInfo($winid,commands)=$appInfo($winid,commands)"
    }
  
    set list_index [$namelist curselection]
    if {$list_index == ""} {
	set list_index [$namelist size]
    } else {
	set list_index [expr $list_index + 1]
    }
    $namelist insert $list_index $name
    $typelist insert $list_index $showtype
    $namelist selection clear 0 end
    $typelist selection clear 0 end
    $namelist selection set $list_index
    $typelist selection set $list_index
    if {[info exists appInfo($winid,commands)]}  {
	set appInfo($winid,commands) \
	    [linsert $appInfo($winid,commands) $list_index $cmdnum]
    } else {
	lappend appInfo($winid,commands) $cmdnum
    }
    set appInfo($winid,cmdnum) \
	[classify $winid $cmdtopaste {} $cmdnum]
    set cmdInfo($winid,$cmdnum) ""

    #edit_command $winid $namelist $list_index
}    
	
proc add_command { winid name type }  {
	#puts "add_command winid=$winid name=$name type=$type"

    global appInfo winInfo cmdtable

    set namelist $appInfo($winid,namebox)
    set typelist $appInfo($winid,typebox)
    set cmdnum $appInfo($winid,cmdnum)
  
    # Look for command type in table
    set tblpos [lsearch $cmdtable "{$type} *"]
    if {$tblpos<0} {
	set line $name
	set showtype {}
	#return -1	
    } else {
	# Get entry describing this command type
	set entry [lindex $cmdtable $tblpos]
	# Insert the new name into the default line for this command.
	regsub -all %N [lindex $entry 1] $name line
	set showtype $type
    }
    
    set list_index [$namelist curselection]
    if {$list_index == ""} {
	set list_index [$namelist size]
    } else {
	set list_index [expr $list_index + 1]
    }
    $namelist insert $list_index $name
    $typelist insert $list_index $showtype
    $namelist selection clear 0 end
    $typelist selection clear 0 end
    $namelist selection set $list_index
    $typelist selection set $list_index
    if {[info exists appInfo($winid,commands)]}  {
	set appInfo($winid,commands) \
	    [linsert $appInfo($winid,commands) $list_index $cmdnum]
    } else {
	lappend appInfo($winid,commands) $cmdnum
    }
    set appInfo($winid,cmdnum) \
	[classify $winid $line {} $cmdnum]
    set cmdInfo($winid,$cmdnum) ""

    edit_command $winid $namelist $list_index
}    

set su_comstr "#OFF#"
proc disable_command { winid listbox list_index}  {
	global cmdInfo
	global appInfo
	global su_comstr
	#print_array appInfo
	#print_array cmdInfo
	if {$list_index != ""}  {
		set cmd_index [lindex $appInfo($winid,commands) $list_index]
		#puts "cmd_index=$cmd_index"
		set cmd_info $cmdInfo($winid,$cmd_index)
		#puts "cmd_info=$cmd_info"
		if {[llength $cmd_info]<3} {
			set commentflag 0
			lappend cmd_info 0
		} else {
			set commentflag [lindex $cmd_info 2]
		}
		#puts "commentflag=$commentflag"
		set cmd_str [lindex $cmd_info 1]
		#puts "cmd_str=$cmd_str"
		set cmd_name [lindex [lindex $cmd_str 0] 0]
		#puts "cmd_name=$cmd_name"
		if {$commentflag==1} {
			set cmdInfo($winid,$cmd_index) \
				[lreplace $cmd_info 2 2 0]
			set tmp [$listbox get $list_index]
			$listbox delete $list_index
			$listbox insert $list_index \
				[string range $tmp \
					[string length $su_comstr] end]
			[winfo parent $listbox].name yview moveto \
				[lindex [$listbox yview] 0]
				
		} else {
			set cmdInfo($winid,$cmd_index) \
				[lreplace $cmd_info 2 2 1]
			set tmp [$listbox get $list_index]
			$listbox delete $list_index
			$listbox insert $list_index "$su_comstr$tmp"
			[winfo parent $listbox].name yview moveto \
				[lindex [$listbox yview] 0]
		}
		$listbox selection set $list_index
    	}
}

proc edit_command { winid listbox list_index}  {

	#puts "edit_command $winid $listbox $list_index"
    global cmdInfo
    global appInfo
    #set list_index [$listbox curselection]
    if {$list_index != ""}  {
	set cmd_index [lindex $appInfo($winid,commands) $list_index]
	set edit_com [lindex [lindex $cmdInfo($winid,$cmd_index) 1] 3]
	#puts "eval $edit_com $winid $cmd_index"
	eval $edit_com $winid $cmd_index

    } else {
	#puts "no current selection"
    }

}

proc edit_command_by_pos {winid index} {
	global cmdInfo
	set edit_com [lindex [lindex $cmdInfo($winid,$index) 1] 3]
	eval $edit_com $winid $index
}


proc del_command { winid listbox1 listbox2 {delflag 0}}  {
    
    global cmdInfo
    global appInfo
    set index [$listbox1 curselection]
    if {$index != ""}  {
	if {$delflag} {
		$listbox1 delete $index
		$listbox2 delete $index
		$listbox1 selection anchor $index
		$listbox2 selection anchor $index
	}
	set deletedcmd [lindex $appInfo($winid,commands) $index ]
	set parmlist [lindex [lindex $cmdInfo($winid,$deletedcmd) 1] 0]

	clipboard clear -displayof $listbox1
	clipboard append -displayof $listbox1 [list_msg_to_an $parmlist 0] 
    	selection handle -selection PRIMARY $listbox1 copy_handler
	selection own $listbox1

	#puts "put on clipboard: [selection get -selection CLIPBOARD]"
	if {$delflag} {
		set appInfo($winid,commands) \
			[lreplace $appInfo($winid,commands) $index $index]
	}
    }
}

	
#proc clipboard_paster {offset maxbytes} {
#	puts "offset=$offset maxbytes=$maxbytes"
#	return [selection get -selection CLIPBOARD]
#}


proc add_dialogue { winid }  {

    global appInfo cmdtable

    if {[winfo exists .additem$winid]} { return }
    lassign [winfo pointerxy .] x y
    set w [toplevel .additem$winid]
    wm geometry $w +[expr $x - 40]+[expr $y - 30]
    #wm withdraw $w
    wm title $w "Add Item"

    # name of new command 
    frame $w.name -relief groove -bd 2
#    label $w.name.lname -text Name -anchor e 
#    entry $w.name.ename -textvariable appInfo($winid,newname) \
#	    -width 25 -relief sunken \
#	    -font {*-Courier-Medium-R-Normal-*-120-*}
#    bind $w.name.ename <Return>  \
#	    "add_command $winid \$appInfo($winid,newname) \
#	    \[$w.type get\]; destroy $w ; break"
    
#    pack $w.name.lname -fill x -side left -padx 10
#    pack $w.name.ename -fill x -side left

    # type of new command 
    frame $w.type -relief groove -bd 2
    listbox $w.type.list -height 7 -yscrollcommand "$w.type.scrl set"
    scrollbar $w.type.scrl -command "$w.type.list yview"
    pack $w.type.list -side left -fill both -expand 1
    pack $w.type.scrl -side left -fill y -expand 1
    $w.type.list insert end "(User-defined Command)"
    foreach type $cmdtable {
	$w.type.list insert end [lindex $type 0]
    }
    $w.type.list selection set 0 0
    
bind $w.type.list <Double-Button-1> "add_command \
	$winid XXXXXX \[$w.type.list get \[lindex \[$w.type.list curselection\] 0\]\]; destroy $w; break" 

    
    # buttons to accept or cancel
    frame $w.buttons -relief groove -bd 2
    button $w.buttons.ok -text OK -command "add_command \
	$winid XXXXXX \[$w.type.list get \[lindex \[$w.type.list curselection\] 0\]\]; destroy $w" \
	-width 8
    button $w.buttons.cancel -text Cancel -command "destroy $w" \
	-width 8
    pack $w.buttons.ok $w.buttons.cancel -side left -expand yes \
	-padx 15

    # pack all the frames
    pack $w.name -fill both -side top -padx 4 -pady 1 -ipady 3 -ipadx 10
    pack $w.type -fill both -padx 4 -pady 1
    pack $w.buttons -fill both -side top -padx 4 -pady 1 -ipady 3

    #after 500 wm deiconify $w
#    focus $w.name.ename
    
}

proc set_comment { comtext winid index }  {

    global cmdInfo
    global appInfo
    
    set newcomment [string trim [$comtext get 1.0 end]]
    if {$newcomment != ""}  {append newcomment "\n"}
    
    set cmdInfo($winid,$appInfo($winid,oldindex)) \
	[lreplace $cmdInfo($winid,$appInfo($winid,oldindex)) 0 0 \
	     $newcomment]
    $comtext delete 1.0 end
    $comtext insert 1.0 [lindex $cmdInfo($winid,$index) 0]
    $comtext mark set insert 1.0
    set appInfo($winid,oldindex) $index

}

proc edit_defcmd { winid index }  {
    
    global cmdInfo appInfo
    set cmd [lindex [lindex $cmdInfo($winid,$index) 1] 0]
#puts "cmd=$cmd"
    if {[lsearch $cmd internal] < 0}  {
	set w [cmd_edit $winid $index user]
	#puts "appending $w to appInfo($winid,toplevels)"
        lappend appInfo($winid,toplevels) $w
	input_cmd $cmd $winid $index user
    } else {
	set w [cmd_edit $winid $index internal]
	#puts "appending $w to appInfo($winid,toplevels)"
        lappend appInfo($winid,toplevels) $w
	input_cmd $cmd $winid $index internal
    }

}

proc edit_unknown { winid index }  {

    global appInfo
    global cmdInfo
    
    set cmd [lindex [lindex $cmdInfo($winid,$index) 1] 0]

    set cmdname [lindex $cmd 0]
    set appInfo($winid,$index,cmdname) $cmdname
    set origcmdname $appInfo($winid,$index,cmdname)

    if {[winfo exists .unk$winid,$index]} { return }
    lassign [winfo pointerxy .] x y
    set w [toplevel .unk$winid,$index]
    wm geometry $w +[expr $x - 40]+[expr $y - 30]
    wm withdraw $w
    lappend appInfo($winid,toplevels) $w
    wm title $w "$cmdname Edit"
    
    # text part
    frame $w.text -relief groove -bd 2
    # variable name
    frame $w.text.name
    label $w.text.name.l -text Command -width 10 -anchor e
    entry $w.text.name.e -textvariable appInfo($winid,$index,cmdname) \
	    -width 30 -relief sunken -bd 2
    #bindtags $w.text.name.e "$w.text.name.e Entry firstEntry . all"
    pack $w.text.name.l -side left -pady 3 -fill both
    pack $w.text.name.e -side left -pady 3 -fill x -expand 1
    pack $w.text.name -fill both 

	# Tag entries
	frame $w.text.tags
	label $w.text.tags.l -text "Parms" -width 10 -anchor e
	entry .dummy
	set eh [winfo reqheight .dummy ]
	#puts "eh=$eh"
	destroy .dummy
	text $w.text.tags.txt -yscrollcommand "$w.text.tags.scrl set"  \
		-width 44 -height 5
	#set lh [lindex [$w.text.tags.txt dlineinfo 1.0] 3]
	#puts "lh=$lh"
	#$w.text.tags.txt configure -spacing3 [expr $eh - $lh]	
	scrollbar $w.text.tags.scrl -command "$w.text.tags.txt yview"
	pack $w.text.tags.l $w.text.tags.txt $w.text.tags.scrl \
		-side left -fill both
	button $w.text.tags.add -text Add -command "
		eu_add_tag $winid $index \$cmdInfo($winid,$index,tnum) 2
	"	
	pack $w.text.tags.add -side top

	# Flag entries
	frame $w.text.flags
	label $w.text.flags.l -text "Parms" -width 10 -anchor e
	text $w.text.flags.txt -yscrollcommand "$w.text.flags.scrl set"  \
		-width 44 -height 4
	scrollbar $w.text.flags.scrl -command "$w.text.flags.txt yview"
	pack $w.text.flags.l $w.text.flags.txt $w.text.flags.scrl \
		-side left -fill both
	button $w.text.flags.add -text Add -command "
		eu_add_flag $winid $index \$cmdInfo($winid,$index,fnum) 2
	"	
	pack $w.text.flags.add -side top

	# Transfer existing parms into arrays and count them.
	set tn 1
	set fn 1
	if {[llength $cmd]>1} {
		set parms [lrange $cmd 1 end]
		foreach item $parms {
			set tag [lindex $item 0]
			if {[llength $item]>1} {
				set val [lindex $item 1]
				set cmdInfo($winid,$index,tag,$tn) $tag
				set cmdInfo($winid,$index,val,$tn) $val
				incr tn
			} else {
				set cmdInfo($winid,$index,flag,$fn) $tag
				incr fn
			}
		}
	}
	incr tn -1
	incr fn -1
	
	set numtags 5
	set numflags 2
	if {$tn>$numtags} {
		set numtags $tn
	}
	if {$fn>$numflags} {
		set numflags $fn
	}

	eu_add_tag $winid $index 0 $numtags
	eu_add_flag $winid $index 0 $numflags
	
#    label $w.text.value.l -text Parameters -width 10 -anchor e
#    viedit $w.text.value.e -status no -fileops no -width 30 -height 4 \
#	-vibindings $appInfo($winid,vibindings) \
#	-relief sunken -bd 2
#    $w.text.value.e.text insert 1.0 $appInfo($winid,$index,parms)
#    bindtags $w.text.value.e "$w.text.value.e Entry lastEntry . all"
#    pack $w.text.value.l -side left -pady 3 -fill both
#    pack $w.text.value.e -side left -pady 3 -fill both -expand 1
    pack $w.text.tags -fill both -expand 1
    pack $w.text.flags -fill both -expand 1
    
    # buttons
    frame $w.buttons -relief groove -bd 2
    button $w.buttons.ok -text OK -width 8 -command \
	    "if {\[eu_save_parms $winid $index\]} {destroy $w}"
    #bindtags $w.buttons.ok "$w.buttons.ok Button firstButton . all"
    button $w.buttons.cancel -text Cancel -command "destroy $w" -width 8
    #bindtags $w.buttons.cancel "$w.buttons.cancel Button lastButton . all"
    pack $w.buttons.ok $w.buttons.cancel -side left -padx 5 \
	    -pady 2 -expand 1
    pack $w.text -ipadx 10 -padx 4 -pady 2 -fill both -expand 1
    pack $w.buttons -ipady 2 -padx 4 -pady 2 -fill both 
    
    update idletasks; wm deiconify $w
    focus $w.text.name.e

}

proc eu_add_tag {winid index currnum num} {
	global cmdInfo
	set w .unk$winid,$index
	$w.text.tags.txt configure -state normal
	for {set n [expr $currnum + 1] } \
			{ $n <= [expr $currnum + $num]} \
			{incr n} {
		$w.text.tags.txt insert end "\n"
		$w.text.tags.txt window create $n.0 \
			-create "entry $w.text.tags.txt.tag$n \
				-textvariable cmdInfo($winid,$index,tag,$n) \
				-width 15"
		$w.text.tags.txt window create $n.end \
			-create "entry $w.text.tags.txt.val$n \
				-textvariable cmdInfo($winid,$index,val,$n) \
				-width 25"
		
	}
	set cmdInfo($winid,$index,tnum) [expr $currnum + $num]
	$w.text.tags.txt configure -state disabled
}

proc eu_add_flag {winid index currnum num} {
	global cmdInfo
	set w .unk$winid,$index
	$w.text.flags.txt configure -state normal
	for {set n [expr $currnum + 1] } \
			{ $n <= [expr $currnum + $num]} \
			{incr n} {
		$w.text.flags.txt insert end "\n"
		$w.text.flags.txt window create $n.0 \
			-create "entry $w.text.flags.txt.tag$n -textvariable \
				cmdInfo($winid,$index,flag,$n) -width 15"
	}
	set cmdInfo($winid,$index,fnum) [expr $currnum + $num]
	$w.text.flags.txt configure -state disabled
}

proc eu_save_parms { winid index }  {

	global appInfo cmdInfo
	set w .unk$winid,$index

	set cmdname [string trim $appInfo($winid,$index,cmdname)]
	if {$cmdname==""} {
		tk_dialog .error ERROR "Command name can't be blank." {} 0 OK
		return 0
	}
	if {![regexp {^[a-zA-Z0-9_\-]+$} $cmdname]} {
		tk_dialog .error ERROR "Command name can only contain alphanumerics, dashes, and underlines." {} 0 OK
		return 0
	}

	set parms $cmdname
	set flags {}
	set tnum $cmdInfo($winid,$index,tnum)
	for {set n 1} {$n<=$tnum} {incr n} {
		if {![info exists cmdInfo($winid,$index,tag,$n)]} {
			continue
		}
		set parm {}
		set tag [string trim $cmdInfo($winid,$index,tag,$n)] 
		if {$tag!=""} {
			set val $cmdInfo($winid,$index,val,$n)
			if {$val!=""} {
				lappend parm $tag $val
				lappend parms $parm
			} else {
				lappend flags $tag
			}
		}
	}
	set fnum $cmdInfo($winid,$index,fnum)
	#puts "fnum=$fnum"
	for {set n 1} {$n<=$fnum} {incr n} {
		if {![info exists cmdInfo($winid,$index,flag,$n)]} {
			continue
		}
		set flag [string trim $cmdInfo($winid,$index,flag,$n)] 
		if {$flag!=""} {
			lappend flags $flag
		}
	}
	#puts "flags=$flags"

	# Get new var name and value and put in list form.
	#set var $appInfo($winid,$index,var)
	#set value [string trim [$w.text.value.e.text get 1.0 end]]
	#set level1 [lindex $cmdInfo($winid,$index) 1]
	#set level2 [lindex $level1 0]
	#lappend level3 $var
	#lappend level3 $value

	# Go get existing command info
	set cmdinfo $cmdInfo($winid,$index)
	#puts "old cmdinfo=$cmdinfo"
	# Get existing command parms
	set cmddata [lindex $cmdinfo 1]
	#puts "old cmddata=$cmddata"
	# Replace old parms with new parms.
	#set cmddata $parms
	set parms "$parms $flags"
	set cmddata [lreplace $cmddata 0 0 $parms]
	set cmddata [lreplace $cmddata 2 2 $cmdname]

	# Replace new command info with updated command info.
	set cmdinfo [lreplace $cmdinfo 1 1 $cmddata]
	#puts "new cmdinfo=$cmdinfo"
	#set cmdinfo [lchange $cmdinfo $level3 3 "1 0 $pos"]
	#puts "new cmdinfo=$cmdinfo"
	set cmdInfo($winid,$index) $cmdinfo

	#puts "index=$index commands=$appInfo($winid,commands)"
	# Get position of this item in the listbox.
	set listindex [lsearch $appInfo($winid,commands) $index]
	# Delete the old entry
	$appInfo($winid,namebox) delete $listindex
	# Insert the new entry.
	$appInfo($winid,namebox) insert $listindex \
		[lindex [lindex $cmdInfo($winid,$index) 1] 1]
	# Repeat for second listbox.
	$appInfo($winid,typebox) delete $listindex
	$appInfo($winid,typebox) insert $listindex \
		[lindex [lindex $cmdInfo($winid,$index) 1] 2] 
	return 1	
}

proc edit_set { winid index }  {

    global appInfo
    global cmdInfo
    
    set cmd [lindex [lindex $cmdInfo($winid,$index) 1] 0]
    set var [set appInfo($winid,$index,var) \
		 [lindex [lindex $cmd 1] 0]]
    set origvar $appInfo($winid,$index,var)
    set pos [lsearch $cmd "$var *"]
    set appInfo($winid,$index,value)  [lindex [lindex $cmd $pos] 1]
    set origval $appInfo($winid,$index,value)

    if {[winfo exists .var$winid,$index]} { return }
    lassign [winfo pointerxy .] x y
    set w [toplevel .var$winid,$index]
    wm geometry $w +[expr $x - 40]+[expr $y - 30]
    wm withdraw $w
    lappend appInfo($winid,toplevels) $w
    wm title $w "Edit Variable - $var"
    
    # text part
    frame $w.text -relief groove -bd 2
    # variable name
    frame $w.text.name
    label $w.text.name.l -text Variable -width 7 -anchor e
    entry $w.text.name.e -textvariable appInfo($winid,$index,var) \
	    -width 30 -relief sunken -bd 2
    bind $w.text.name.e <space> {break}
    bind $w.text.name.e <Tab> {break}
    #bindtags $w.text.name.e "$w.text.name.e Entry firstEntry . all"
    pack $w.text.name.l -side left -pady 3 -fill both
    pack $w.text.name.e -side left -pady 3 -fill x -expand 1
    pack $w.text.name -fill both 
    # variable value
    frame $w.text.value
    label $w.text.value.l -text Value -width 7 -anchor e
    viedit $w.text.value.e -status no -fileops no -width 30 -height 4 \
	-vibindings $appInfo($winid,vibindings) \
	-relief sunken -bd 2
    $w.text.value.e.text insert 1.0 $appInfo($winid,$index,value)
    #bindtags $w.text.value.e "$w.text.value.e Entry lastEntry . all"
    pack $w.text.value.l -side left -pady 3 -fill both
    pack $w.text.value.e -side left -pady 3 -fill both -expand 1
    pack $w.text.value -fill both -expand 1
    
    # buttons
    frame $w.buttons -relief groove -bd 2
    button $w.buttons.ok -text OK -width 8 -command \
	    "save_var $winid $index $pos $w; destroy $w"
    #bindtags $w.buttons.ok "$w.buttons.ok Button firstButton . all"
    button $w.buttons.cancel -text Cancel -command "destroy $w" -width 8
    #bindtags $w.buttons.cancel "$w.buttons.cancel Button lastButton . all"
    pack $w.buttons.ok $w.buttons.cancel -side left -padx 5 \
	    -pady 2 -expand 1
    pack $w.text -ipadx 10 -padx 4 -pady 2 -fill both -expand 1
    pack $w.buttons -ipady 2 -padx 4 -pady 2 -fill both 
    
    update idletasks; wm deiconify $w
    focus $w.text.name.e

}

proc save_var { winid index pos w}  {

    global appInfo
    global cmdInfo

    set var $appInfo($winid,$index,var)
    set value [string trim [$w.text.value.e.text get 1.0 end]]
    set level1 [lindex $cmdInfo($winid,$index) 1]
    set level2 [lindex $level1 0]
    lappend level3 $var
    lappend level3 $value
	set cmdinfo $cmdInfo($winid,$index)
	#puts "old cmdinfo=$cmdinfo"
	set cmddata [lindex $cmdinfo 1]
	#puts "old cmddata=$cmddata"
	set cmddata [lreplace $cmddata 1 1 $var]
	#puts "new cmddata=$cmddata"

	set cmdinfo [lreplace $cmdinfo 1 1 $cmddata]
	#puts "new cmdinfo=$cmdinfo"
	set cmdinfo [lchange $cmdinfo $level3 3 "1 0 $pos"]
	#puts "new cmdinfo=$cmdinfo"
	set cmdInfo($winid,$index) $cmdinfo
#    set cmdInfo($winid,$index) \
#	[lchange $cmdInfo($winid,$index) $level3 3 "1 0 $pos"]

#		set cmddata [lreplace $cmddata 0 0 $newlist]
#		set cmddata [lreplace $cmddata 1 1 $newname]
#		set cmdinfo [lreplace $cmdinfo 1 1 $cmddata]
#		set cmdInfo($winid,$index) $cmdinfo

	#puts "index=$index commands=$appInfo($winid,commands)"
	if {![winfo exists .edit_suf$winid.edittext] &&
		![winfo exists .edit_sus$winid.edittext]} {
		set listindex [lsearch $appInfo($winid,commands) $index]
            $appInfo($winid,namebox) delete $listindex
            $appInfo($winid,namebox) insert $listindex \
                [lindex [lindex $cmdInfo($winid,$index) 1] 1]
            $appInfo($winid,typebox) delete $listindex
            $appInfo($winid,typebox) insert $listindex \
                [lindex [lindex $cmdInfo($winid,$index) 1] 2] 
	}
}

proc edit_include { winid index }  {
	return [edit_any $winid $index {include file=%s [results]}]

#    global appInfo
#    global cmdInfo
#    
#    set cmd [lindex [lindex $cmdInfo($winid,$index) 1] 0]
#    set pos [lsearch $cmd "file *"]
#    set file [lindex [lindex $cmd $pos] 1]
#
#    if {[string range $file 0 4] == "(rel)"}  {
#	edit_su $appInfo($winid,rootdir)/[string range $file 5 end]
#    } else {
#	edit_su $file
#    }
#
}
proc edit_tclinclude { winid index }  {
        return [edit_any $winid $index {tclinclude file=%s [results]}]
}



# No longer used.
proc edit_ldscript { winid index }  {

    global appInfo
    global cmdInfo
	global tcl_version

    set cmd [lindex [lindex $cmdInfo($winid,$index) 1] 0]
    set pos [lsearch $cmd "file *"]
    set file [lindex [lindex $cmd $pos] 1]
	if {[string range $file 0 4] == "(rel)"}  {
		if { $tcl_version > "7.4" } {
			set file [file join $appInfo($winid,rootdir) \
				[string range $file 5 end]]
		} else {
			set file $appInfo($winid,rootdir)/[string range $file 5 end]
		}
	}

    
    if {[catch {set f [open $file r]}]}  {
	if {[winfo exists .error$winid,$index]} { return }
	set w [toplevel .error$winid,$index]
 	#wm withdraw $w
	lappend appInfo($winid,toplevels) $w
	#wm title $w Error
	message $w.msg -text "$file does not exist.  You may need to \
             prepend `(rel)' to it." -width 150
	button $w.button -text "OK" -command "destroy $w"
	pack $w.msg $w.button -side top -fill x
	#after 500 wm deiconify $w
    } else {
	if {[winfo exists .scriptfile$winid,$index]} { return }
    	lassign [winfo pointerxy .] x y
	set w [toplevel .scriptfile$winid,$index]
    	wm geometry $w +[expr $x - 40]+[expr $y - 30]
	#wm withdraw $w
	lappend appInfo($winid,toplevels) $w
	#wm title $w "Edit Scriptfile - $file"
	viedit $w.text -savecommand "save_scriptfile $w.text.text $file" \
		-vibindings $appInfo($winid,vibindings)
	$w.text configure -relief groove -bd 2
	frame $w.buttons -relief groove -bd 2
	button $w.buttons.ok -text OK -width 8 \
	    -command "vi_save $w.text.text; vi_quit $w.text.text"
	button $w.buttons.save -text Save -width 8 \
	    -command "vi_save $w.text.text"
	button $w.buttons.cancel -text Cancel -width 8 \
	    -command "set viInfo($w.text.text,modified) 0; vi_quit $w.text.text"
       	pack $w.buttons.ok $w.buttons.save $w.buttons.cancel \
	    -side left -padx 10 -expand yes
	pack $w.text -fill both -expand yes -padx 4 -pady 2
	pack $w.buttons -fill both -expand yes -padx 4 -pady 2 \
	    -ipadx 150 -ipady 3
	#after 500 wm deiconify $w
	while {![eof $f]}  {
	    $w.text.text insert 1.0 [read $f 1000]
	}
	close $f
	focus $w.text.text
	$w.text.text mark set insert {1.0}
	do_normal $w.text.text
    }
    
}

proc save_scriptfile { t file script }  {

	catch {file rename -force $file $file~}
	set f [open $file w]
	puts $f $script
	close $f

}

proc do_defchart {firstword cmd winid} {
	global appInfo CT
	if { $firstword == "defchart" } {
		set name [lindex [lindex $cmd [lsearch $cmd "chart *"]] 1]
		lappend result $cmd $name "$CT(defchart)"
		lappend appInfo($winid,"$CT(defchart)") $name
		return $result
	} else {
		return 0
	}
}

proc edit_defchart { winid index } {
	global cmdInfo appInfo
	set mainwin $appInfo($winid,mainwindow)
	set cmdinfo $cmdInfo($winid,$index)
	#puts "cmdinfo=$cmdinfo"
	set cmddata [lindex $cmdinfo 1]
	set cmdparms [lindex $cmddata 0]
	#puts "cmddata=$cmddata"
	set ret [synwin_sub $mainwin {defchart chart=%s cctxt.<n>=%s 
		[parentchart=%s parentstep=%s]
	   	 [chartdef=%s] [parenthome=%s]} $cmdparms {} {} \
		 $appInfo($winid,vibindings)]
	if {$ret != ""} {
		#puts "old cmdinfo=$cmdinfo"
		#puts "ret=$ret"
		set cmddata [lreplace $cmddata 0 0 [an_msg_to_tcl $ret]]
		set cmdinfo [lreplace $cmdinfo 1 1 $cmddata]
		#puts "new cmdinfo=$cmdinfo"
		set cmdInfo($winid,$index) $cmdinfo
	}
}

proc do_defcmdu {firstword cmd winid} {
	global CT
	return [do_any $firstword $cmd $winid defcmd name "$CT(defcmdu)"]
}

proc edit_defcmdu {winid index} {
	return [edit_any $winid $index {defcmd name=%s help=%s explain=%s reply.<code>=%s cmd=%s}]
}

proc do_defcmdi {firstword cmd winid} {
	global CT
	return [do_any $firstword $cmd $winid "defcmd internal" name "$CT(defcmdi)"]
}

proc edit_defcmdi {winid index} {
	return [edit_any $winid $index {defcmd name=%s [internal]}]
}

proc do_ldscript2 {firstword cmd winid} {
	global CT
	return [do_any $firstword $cmd $winid ldscript file "$CT(ldscript)"]
}

proc edit_ldscript2 {winid index} {
	return [edit_any $winid $index {ldscript file=%s [path=%s] [-bin]}]
}

proc read_app_def {fid winid source}  {

    global appInfo
    global cmdInfo
    
	#puts "Inside read_app_def, fid=$fid"
    set appInfo($winid,comment_buff) {}
    set oldcmdnum 0

	if {"$source" == "FILE"} {
		set contents [read $fid]
	} else {
		set contents $fid
	}
    
    set contents [split $contents "\n"]
    set linetotal [llength $contents]
    for {set lc 0} {$lc<$linetotal} {incr lc} {
	set line [lindex $contents $lc]	
	# Trim leading whitespace
	set line [string trimleft $line]
	if {[string range $line 0 2]=="do="} {
		set line [string range $line 3 end]
	}
	if {[string length $line] > 0}  {
	    
	    # `Slurp up' continued lines onto one line
	    set lastpos [expr [string length $line] - 1]
	    while {[string index $line $lastpos] == "\\"}  {
		set line [string trimright $line "\\"]
		#gets $fid nextline
		incr lc
		set nextline [lindex $contents $lc]
		#set nextline [string trim $nextline]
		append line "\n$nextline"
		set lastpos [expr [string length $line] - 1]
	    }
	    
		global su_comstr
	    # check to see if it's a comment or a command
	    if {[string index $line 0] == "#" && \
		![string match "${su_comstr}*" $line]}  {
		set line [string range $line 1 end]
		if {[string index $line 0] == " "}  {
		    set line [string range $line 1 end]
		}
		set startpos 0
		# Is there a server name embedded in the comment?
		if {![info exists appInfo($winid,srvname)] &&
				[string first "Loaded by:" $line]>=0} {
			set startpos [string first "Loaded by:" $line]
			incr startpos [string length "Loaded by:"]
			set str [lindex [string range $line \
				$startpos end] 0]
			if {$str!=""} {
				set appInfo($winid,srvname) $str
			} 
		}
		# Is there a server name embedded in the comment?
		if {![info exists appInfo($winid,exename)] &&
				[string first "Executable:" $line]>=0} {
			set startpos [string first "Executable:" $line]
			incr startpos [string length "Executable:"]
			set str [string trim [string range $line \
				$startpos end]]
			if {$str!=""} {
				set appInfo($winid,exename) $str
			} 
			#puts "pulled exename='$str'"
		}
		if {$startpos==0} {
			append appInfo($winid,comment_buff) "$line\n"
		}
	    } else {
		if {[string match "${su_comstr}*" $line]} {
			set commentflag 1
			set line [string range $line \
				[string length $su_comstr] end]
		} else {
			set commentflag 0
		}
		#puts $line
		set currcmdnum $appInfo($winid,cmdnum)
		set appInfo($winid,cmdnum) \
		    [classify $winid $line $appInfo($winid,comment_buff) \
			 $currcmdnum]
		lappend cmdInfo($winid,$currcmdnum) $commentflag
		if {$oldcmdnum != $appInfo($winid,cmdnum)}  {
		    lappend appInfo($winid,commands) $oldcmdnum
		}
		set oldcmdnum $appInfo($winid,cmdnum)
		#puts $appInfo($winid,comment_buff)
		set appInfo($winid,comment_buff) {}
	    }
	}
    }
}

proc find_name {winid line} {
    global cmdtable
    set cmd [an_msg_to_tcl $line]
    set firstword [lindex $cmd 0]
	foreach type $cmdtable {
		# Execute do_ proc to extract name & type.
		set result [eval [lindex $type 2] {$firstword $cmd $winid}]
		#puts "result=$result"
		# The do_ proc, if it applied, returns "cmd name type"
		if {[lindex $result 0] != 0}  {
			# Add editcmd to cmdInfo data.
			return [lindex $result 1]
		}
	}
	# If none of the known types match, treat it as an unknown type.
	return ""
}

proc classify { winid line comment cmdnum}  {

    global appInfo
    global cmdInfo
    global cmdtable

#puts "Inside classify, line=$line"
    set cmd [an_msg_to_tcl $line]
    set firstword [lindex $cmd 0]

#puts "classify $winid $line $comment $cmdnum"
	foreach type $cmdtable {
		#puts "Looking at $type"
		#puts "Executing eval [lindex $type 2] {$firstword $cmd $winid}"
		# Execute do_ proc to extract name & type.
		# puts "type=$type\nfirstword=$firstword\ncmd=$cmd"
		set result [eval [lindex $type 2] {$firstword $cmd $winid}]
		#puts "result=$result"
		# The do_ proc, if it applied, returns "cmd name type"
		if {[lindex $result 0] != 0}  {
			# Add editcmd to cmdInfo data.
			lappend result "[lindex $type 3]"
			lappend cmdInfo($winid,$cmdnum) $comment
 			lappend cmdInfo($winid,$cmdnum)  $result
			#puts "Adding $cmdInfo($winid,$cmdnum)"
			#puts "comment=$comment"
			#puts "result=$result"
			return [expr $cmdnum + 1]
		}
	}
	# If none of the known types match, treat it as an unknown type.
	set result "{$cmd} {} [lindex $cmd 0] edit_unknown"
	lappend cmdInfo($winid,$cmdnum) $comment
	lappend cmdInfo($winid,$cmdnum)  $result
		#puts "comment=$comment"
		#puts "result=$result"
	return [expr $cmdnum + 1]
}

# table to classify commands
if {[info exists cmdtable]==0} {
set cmdtable "
    {{$CT(set)} {set %N=VALUE} do_set edit_set 1=}
    {{$CT(defcmdi)} {defcmd name=%N internal} do_defcmdi edit_defcmdi name}
    {{$CT(defcmdu)} {defcmd name=%N reply.0=Success} do_defcmdu edit_defcmdu name}
    {{$CT(include)} {include file=%N} do_include edit_include file}
    {{$CT(tclinclude)} {tclinclude file=%N} do_tclinclude edit_tclinclude file}
    {{$CT(ldscript)} {ldscript file=%N} do_ldscript2 edit_ldscript2 file}
    {{$CT(restore)} {restore file=%N} do_restore edit_restore file}
    {{$CT(log)} {log name=%N} do_log edit_log name}
"

}

proc getpath { winid name }  {
    
	if {[string range $name 0 4] == "(rel)"}  {
		global appInfo
		return "[file join $appInfo($winid,rootdir) \
				[string range $name 5 end]]"
	} else {
		return $name
	}
    
}


# The do_ procedures return the list "an_cmd_list name type"

proc do_set { firstword cmd winid }  {

    global appInfo CT
     if {$firstword == "set"}  {
	 set name [lindex [lindex $cmd 1] 0]
	 lappend result $cmd $name "$CT(set)"
	 lappend appInfo($winid,variables) $name
	 return $result
    } else {
	return 0
    }
    
}

proc do_defcmd { firstword cmd winid }  {
    
    global appInfo CT
    if {$firstword == "defcmd"}  {
	set pos [lsearch $cmd "name *"]
	if {$pos >= 0}  {
	    set name [lindex [lindex $cmd $pos] 1]
	}
	if {[lsearch $cmd internal] < 0}  {
	    set type "$CT(defcmdu)"
	    lappend appInfo($winid,$type) $name
	} else {
	    set type "$CT(defcmdi)"
	    lappend appInfo($winid,$type) $name
	}
	lappend result $cmd $name $type
	return $result
    } else {
	return 0
    }
    
}

proc do_include { firstword cmd winid }  {

    global appInfo CT
    if {$firstword == "include"}  {
	set name [lindex [lindex $cmd 1] 1]
	lappend result $cmd $name "$CT(include)"
	set filename [getpath $winid $name]
	lappend appInfo($winid,includes) $filename
	return $result
    } else {
	return 0
    }

}

proc do_tclinclude { firstword cmd winid }  {

    global appInfo CT
    if {$firstword == "tclinclude"}  {
        set name [lindex [lindex $cmd 1] 1]
        lappend result $cmd $name "$CT(tclinclude)"
        set filename [getpath $winid $name]
        lappend appInfo($winid,tclincludes) $filename
        return $result
    } else {
        return 0
    }

}


proc do_ldscript { firstword cmd winid }  {

    global appInfo CT
    if {$firstword == "ldscript"}  {
	set name [lindex [lindex $cmd 1] 1]
	lappend result $cmd $name "$CT(ldscript)"
	set filename [getpath $winid $name]
	lappend appInfo($winid,scripts) $filename
	return $result
    } else {
	return 0
    }

}

proc do_restore {firstword cmd winid} {
        global CT
        return [do_any $firstword $cmd $winid restore file "$CT(restore)"]
}

proc edit_restore {winid index} {
        return [edit_any $winid $index {restore file=%s [variable=%s] [parse [level=%d]]}]
}

proc do_log {firstword cmd winid} {
        global CT
        return [do_any $firstword $cmd $winid log name "$CT(log)"]
}

proc edit_log {winid index} {
        return [edit_any $winid $index {log [ name=%s [file=%s]
               [{ create, ( level=%d, size=%d [keep=%2d],
                            weeklylog=0|1, namestamp=0|1,
                            datestamp=0|1, timestamp=0|1,
                            closelogs=0|1 )}]] } ]
}

#proc pull_script {scrfile scriptname} {
#    set currname {}
#    set currbody {}
#    puts "scrfile=$scrfile"
#    foreach scr $scrfile {
#    	puts "scr=$scr"
#	set fid ""
#	catch {set fid [open $scr r]}
#	if {$fid==""} {
#	    continue
#	}
#	while {[gets $fid ln]>=0} {
#	    set firstword [lindex $ln 0]
#	    if {$firstword=="startscript"} {
#		set currname [lindex $ln 1]
#		append currbody $ln\n
#	    } elseif {$firstword=="endscript"} {
#		append currbody $ln\n
#		if {$currname==$scriptname} {
#		    close $fid
#		    lappend response $currbody 
#		    lappend response $scr
#		    return $response
#		} else {
#		    set currname {}
#		    set currbody {}
#		}
#	    } elseif {($currname != {}) || ([string index $ln 0] == "#")}  {
#		append currbody $ln\n
#	    }
#	}
#    }
#    return ""
#}
#
#proc push_script {filename scriptname text} {
#    set fid ""
#    set fido [open /tmp/editscript[pid] w]
#    catch {set fid [open $filename r]}
#    set done 0
#    while {$fid!="" && [gets $fid ln]>=0} {
#	set firstword [lindex $ln 0]
#	if {$firstword=="startscript"} {
#	    set currname [lindex $ln 1]
#	    append currbody $ln\n
#	} elseif {$firstword=="endscript"} {
#	    append currbody $ln\n
#	    if {$currname==$scriptname} {
#		puts $fido $text
#		set done 1
#		set currname {}
#		set currbody {}
#	    } else {
#		puts $fido $currbody
#		set currname {}
#		set currbody {}
#	    }
#	} else {
#	    append currbody $ln\n
#	}
#    }
#    if {$fid!=""} {
#	close $fid
#    }
#    if {$done==0} {
#	puts -nonewline $fido "\n$text\n"
#    }
#    close $fido
#    # XXXXXXXXXXX Not DOS portable.
#    catch {exec mv -f $filename $filename~}
#    exec mv -f /tmp/editscript[pid] $filename
#}


proc do_any {firstword cmd winid matchcmd nameid type } {
	global appInfo
	set matchlen [llength $matchcmd]
	#puts "matchcmd=$matchcmd matchlen=$matchlen"
	if { ($matchlen==1 && $firstword==$matchcmd) ||
	     ($matchlen>1 && $firstword==[lindex $matchcmd 0] && 
	     [string match "*\[ 	\n\][lindex $matchcmd 1]*" $cmd])} {
		if {[string match {[0-9]*} $nameid]} {
			set pc 0
			foreach item $cmd {
				if {[llength $item]>1} {
					incr pc
				} else {
					if {$pc==$nameid} {
						set name $item
						break
					} else {
						incr pc
					}
				}
			}	
		} else {
			set name [lindex [lindex $cmd \
				[lsearch $cmd "$nameid *"]] 1]
		}
		lappend result $cmd $name $type
		lappend appInfo($winid,$type) $name
		return $result
	} else {
		return 0
	}
}

proc edit_any { winid index synstr} {
	#puts "edit_any $winid $index $synstr"
	global cmdInfo appInfo cmdtable
	set mainwin $appInfo($winid,mainwindow)
	set cmdinfo $cmdInfo($winid,$index)
        set cmddata [lindex $cmdinfo 1]
        set cmdparms [lindex $cmddata 0]
	#puts "cmdparms=$cmdparms"
	#puts "winid=$winid"
	set wn [synwin_sub $mainwin $synstr $cmdparms "edit_any_cb $winid $index" $appInfo($winid,scrfile) $appInfo($winid,vibindings)]
	#lappend appInfo($winid,children) "$index $wn"
}

proc edit_any_cb {winid index msgstr} {
	global cmdInfo appInfo cmdtable
	#set childloc [lsearch $appInfo($winid,children) "$index *"]
	#if {$childloc>=0} {
	#	set appInfo($winid,children) [lreplace \
	#		$appInfo($winid,children) $childloc $childloc]
	#}
	#puts "winid=$winid index=$index msgstr={$msgstr}"
	set cmdinfo $cmdInfo($winid,$index)
        set cmddata [lindex $cmdinfo 1]
        set cmdparms [lindex $cmddata 0]
	#puts "msgstr=$msgstr"
	if {$msgstr != ""} {
		#GET TYPE OF COMMAND
		set ctype [lindex $cmddata 2]
		#puts "ctype=$ctype"
		set typepos [lsearch $cmdtable 	"{$ctype} *"]
		#puts "typepos=$typepos"
		if {$typepos==-1} {
			tkerror "Invalid command type"
		}
		set typeinfo [lindex $cmdtable $typepos]
		#puts "typeinfo=$typeinfo"
		#GET NAME LOC FROM CMDTABLE
		set nameloc [lindex $typeinfo 4]
		#puts "nameloc=$nameloc"
		set newlist [an_msg_to_tcl $msgstr]
		#puts "newlist=$newlist"
		#FIND NAME FROM DATA
		if {[string match {[0-9]*} $nameloc]} {
			set newname [lindex $newlist $nameloc]
		} else {
			set namepos [lsearch $newlist "$nameloc *"]
			set newname [lindex [lindex $newlist $namepos] 1]
		}
		#puts "newname=$newname"
		set cmddata [lreplace $cmddata 0 0 $newlist]
		set cmddata [lreplace $cmddata 1 1 $newname]
		set cmdinfo [lreplace $cmdinfo 1 1 $cmddata]
		#puts "old cmdinfo: $cmdInfo($winid,$index)"
		set cmdInfo($winid,$index) $cmdinfo
		#puts "new cmdinfo: $cmdInfo($winid,$index)"
	#puts "index=$index commands=$appInfo($winid,commands)"
		set listindex [lsearch $appInfo($winid,commands) $index]
            $appInfo($winid,namebox) delete $listindex
            $appInfo($winid,namebox) insert $listindex \
                [lindex [lindex $cmdInfo($winid,$index) 1] 1]
            $appInfo($winid,typebox) delete $listindex
            $appInfo($winid,typebox) insert $listindex \
                [lindex [lindex $cmdInfo($winid,$index) 1] 2] 
	}
} 

proc error_log_precheck {} {
	diagfile_precheck error.log
}

proc error_log_postcheck {} {
	return [diagfile_postcheck error.log]
}

proc diagfile_precheck {filename} {
	global errortime
	diagfile_cancel $filename
	# Store the mtime of the file for later check with diagfile_postcheck.
	if {[file exists $filename]} {
		set errortime($filename) [file mtime $filename]
	} else {
		set errortime($filename) 0
	}
}

proc diagfile_postcheck {filename {mode once}} {
	global errortime errorwatch
	if {![info exists errortime($filename)]} {
		return 0
	}
	if {[file exists $filename]} {
		set errortime2($filename) [file mtime $filename]
	} else {
		set errortime2($filename) 0
	}
	#puts "errortime=$errortime errortime2=$errortime2"
	set fsize 0
	catch {set fsize [file size $filename]}
	if {$errortime2($filename)>$errortime($filename) &&
		$fsize>0} {
		set fid [open $filename r]
		set lastline ""
		while {![eof $fid]} {
			set line [gets $fid]
			if {[string trim $line]!=""} {
				set lastline $line
			}
		}
		close $fid
		diagfile_cancel $filename
		if {[string match "*User invoked exit command*" $lastline]} {
			if {$mode=="continuous"} {
				set errorwatch($filename) [after 2000 \
					"diagfile_postcheck $filename continuous"]
			} 
			return 0
		}
		tailfile $filename "" 0 0
		set errortime($filename) errortime2($filename)
		return 1
	} else {
		if {$mode=="continuous"} {
			set errorwatch($filename) [after 2000 \
				"diagfile_postcheck $filename continuous"]
		} 
		return 0
	}
}

proc diagfile_cancel {filename} {
	global errorwatch errortime
	if {[info exists errorwatch($filename)]} {
		after cancel $errorwatch($filename)
		unset errorwatch($filename)
	}
	if {[info exists errortime($filename)]} {
		unset errortime($filename)
	}
}

proc print_array {arrayname} {
	upvar $arrayname x
	foreach el [array names x] {
		puts "$arrayname\($el\)=$x($el)"
	}
}
