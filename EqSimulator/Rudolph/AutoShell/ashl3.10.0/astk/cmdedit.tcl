
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Log: cmdedit.tcl,v $
# Revision 1.2  1999/03/17 21:28:29  karl
# Added a "return windowname" to the cmdedit proc, although it isn't
# actually used.
#
# Revision 1.1  1996/08/27  16:09:55  karl
# Initial revision
#
##########
##########
########## cmdedit.tcl
##########
########## this file contains code for the windows and dialog
########## boxes associated with editing an autoshell command.
########## 
########## the files util.tcl and viedit.tcl must have been sourced,
########## or the procedures in this file will fail.
##########
########## Last edited:     07/27/95      13:45
##########          By:     Jason Mechler
##########
##########

# At some point, I need to add code to tell if file is being edited
# by two different procedures at the same time.

#########################
#########################
###
### cmd_edit creates the main window used to edit a command.
### From this window, the replies, syntax, explain, level and 
### corresponding script can all be edited.
### 
### The window has two forms: one used to edit a user command,
### and one used to edit an internal command.  When editing
### an internal command, the syntax and replies are left off.
###
#########################
#########################

proc cmd_edit { winid num type }  {
    
    global winInfo
    global appInfo
    
    if {[catch {set w [toplevel .edit_cmd$winid,$num]}]} { return }
    #wm withdraw $w

    lappend appInfo($winid,toplevels) $w
    
    # first level: includes name of command and button to 
    # execute amazing VI-like text widget.
    frame $w.level1 -relief groove -bd 2
    frame $w.level1.filltop -height 7
    frame $w.level1.mid
    frame $w.level1.fillbot -height 3
    label $w.level1.mid.lname -text Name -width 8 -anchor e
    entry $w.level1.mid.ename -textvariable winInfo($winid,$num,command_name) \
	-width 35 -relief sunken -font {*-Courier-Medium-R-Normal-*-120-*}
    button $w.level1.mid.code -text Code -width 10 \
 	-command "edit_script $winid $num"
    
    pack $w.level1.filltop -side top -fill x
    pack $w.level1.mid.lname -fill x -side left -padx 10
    pack $w.level1.mid.ename -fill x -side left
    pack $w.level1.mid.code  -padx 10
    pack $w.level1.mid -side top -fill x
    pack $w.level1.fillbot -side top -fill x

    
    # second level: syntax of command (only for user commands)
    if {$type == "user"}  {
	frame $w.level2 -relief groove -bd 2
	frame $w.level2.filltop -height 10
	frame $w.level2.middle 
	frame $w.level2.midleft
	frame $w.level2.fillbot -height 10
	label $w.level2.lsyntax -text Syntax -width 8 -anchor e
	button $w.level2.fullsize -text {Full Size} -command " resize \
            $w.level2.fullsize $w.level2.tsyntax.text $winid $num syntax 20 5" 
	set winInfo($winid,$num,syntax_text) \
	    [viedit $w.level2.tsyntax -width 66 \
		 -height 5 -relief sunken -bd 2 -status no -fileops no].text
	# text widget defaults to normal Tk bindings
	do_normal $winInfo($winid,$num,syntax_text)
	
	pack $w.level2.filltop -side top -fill x
	pack $w.level2.lsyntax $w.level2.fullsize -side top -fill both \
	    -padx 5 -in $w.level2.midleft -padx 10
	pack $w.level2.midleft $w.level2.tsyntax -side left -fill both \
	    -in $w.level2.middle 
	pack $w.level2.middle -side top -fill both -expand yes
	pack $w.level2.fillbot -side bottom -fill x
	# defaults to small height
	set winInfo($winid,$num,big_small,syntax) 0
    }
    
    # third level: explanation of command
    frame $w.level3 -relief groove -bd 2
    frame $w.level3.filltop -height 10
    frame $w.level3.middle 
    frame $w.level3.midleft
    frame $w.level3.fillbot -height 10
    label $w.level3.lexplain -text Explain -width 8 -anchor e
    button $w.level3.fullsize -text {Full Size} -command " resize \
        $w.level3.fullsize $w.level3.texplain.text $winid $num explain 20 5" 
    set winInfo($winid,$num,explain_text) \
	[viedit $w.level3.texplain -width 66 \
	     -height 5 -relief sunken -bd 2 -status no -fileops no].text
    # text widget defaults to normal Tk bindings
    do_normal $winInfo($winid,$num,explain_text)
    pack $w.level3.filltop -side top -fill x
    pack $w.level3.lexplain $w.level3.fullsize -side top -fill both \
	-padx 5 -in $w.level3.midleft -padx 10
    pack $w.level3.midleft $w.level3.texplain -side left -fill both \
	-in $w.level3.middle
    pack $w.level3.middle -side top -fill x
    pack $w.level3.fillbot -side bottom -fill x
    # defaults to small height
    set winInfo($winid,$num,big_small,explain) 0

    # fourth level: replies and type (only for user commands)
    if {$type == "user"}  {
	frame $w.level4 -relief groove -bd 2
	frame $w.level4.filltop -height 5
	label $w.level4.lreply -text Replies;
	frame $w.level4.body
	frame $w.level4.body.left
	frame $w.level4.body.right
	frame $w.level4.body.right.replies -relief sunken -bd 2
	frame $w.level4.body.right.arrow
	frame $w.level4.fillbot -height 10
	
	button $w.level4.body.left.add -text Add -command \
	    "edit_reply $winid $num new" -width 7
	button $w.level4.body.left.del -text Delete -command \
	    "del_reply $winid $num" -width 7
	button $w.level4.body.left.edit -text Edit -command \
	    "edit_reply $winid $num old" -width 7

	# we can't use tabs or spaces effectively in listboxes,
	# so here two listboxes, linked to one scrollbar and with
	# bindings linked to both, were used.
	set winInfo($winid,$num,replynums) [listbox \
	    $w.level4.body.right.replies.replynums -selectmode browse \
	    -width 6 -height 5 -exportselection false -relief flat \
	    -yscrollcommand "$w.level4.body.right.scroll set" -bd 0];
	bindtags $w.level4.body.right.replies.replynums \
		"cmditems,$winid Listbox"
	set winInfo($winid,$num,replytext) [listbox \
	    $w.level4.body.right.replies.replytext -selectmode browse \
	    -width 49 -height 5 -exportselection false -relief flat \
	    -yscrollcommand "$w.level4.body.right.scroll set" -bd 0]
	bindtags $w.level4.body.right.replies.replytext \
		"cmditems,$winid Listbox"
	scrollbar $w.level4.body.right.scroll \
	    -command "scrollmult {$w.level4.body.right.replies.replynums \
	    $w.level4.body.right.replies.replytext}"

	proc b1c { w y }  {
	    selectmult "$w.level4.body.right.replies.replynums \
		    $w.level4.body.right.replies.replytext" $y
	}
	
	bind cmditems,$winid <1> "b1c $w %y ; break"
	bind cmditems,$winid <B1-Motion> "b1c $w %y ; break"
	bind cmditems,$winid <Double-Button-1>  \
		"edit_reply $winid $num old"

	button $w.level4.body.right.arrow.up -text "^" \
		-command "switch_list $winInfo($winid,$num,replynums) up ; \
		switch_list $winInfo($winid,$num,replytext) up"
	button $w.level4.body.right.arrow.down -text \
		"v" -command \
		"switch_list $winInfo($winid,$num,replynums) down ; \
		switch_list $winInfo($winid,$num,replytext) down"
	# now to pack all this in
	pack $w.level4.body.left.add $w.level4.body.left.del \
	    $w.level4.body.left.edit -side top -fill x -padx 15 -pady 5
	pack $w.level4.body.right.replies.replynums \
	    $w.level4.body.right.replies.replytext -side left -fill both
	pack $w.level4.body.right.arrow.up $w.level4.body.right.arrow.down \
		-side top -padx 6 -pady 2 -ipadx 1 -ipady 3 -expand yes
	pack $w.level4.body.right.replies -side left -fill both -expand yes
	pack $w.level4.body.right.scroll -side left -fill y -expand yes
	pack $w.level4.body.right.arrow -side left -fill x -expand yes
	
	pack $w.level4.body.left $w.level4.body.right -side left -ipadx 10
	pack $w.level4.filltop $w.level4.lreply $w.level4.body \
	    $w.level4.fillbot -side top -fill both

    }

    # level 5 - command level and quit buttons
    frame $w.level5 -relief flat -bd 2
    frame $w.level5.left -relief groove -bd 2
    frame $w.level5.right -relief groove -bd 2
    
    radiobutton $w.level5.left.butt1 -variable winInfo($winid,$num,level) \
	-anchor w -width 10 -relief flat
    radiobutton $w.level5.left.butt2 -variable winInfo($winid,$num,level) \
	-anchor w -width 10 -relief flat
    button $w.level5.right.ok -text OK -width 10 -command \
	"save_cmd $winid $num $type ; destroy $w"
    button $w.level5.right.save -text Save -width 10 -command \
	"save_cmd $winid $num $type"
    button $w.level5.right.cancel -text Cancel -width 10 \
	-command "destroy $w ; catch {destroy .script_edit$winid,$num}"
	
    if {$type == "user"}  {
	$w.level5.left.butt1 configure -text Normal -value 1
	$w.level5.left.butt2 configure -text Hidden -value 2
    } else {
	$w.level5.left.butt1 configure -text Normal -value 3
	$w.level5.left.butt2 configure -text Hook -value 6
    }  

    pack $w.level5.left.butt1 $w.level5.left.butt2 -side top -fill y \
	-padx 10 -pady 10
    pack $w.level5.right.ok $w.level5.right.save $w.level5.right.cancel \
	-side left -padx 25
    pack $w.level5.left $w.level5.right -side left -fill both  \
	-expand yes -padx 2
    
    # pack all the main frames
    if {$type == "user"}  {
	pack $w.level1 -fill both -side top -ipady 4 -ipadx 4 -pady 1 -padx 4
	pack $w.level2 -fill both -side top -pady 1 -padx 4
	pack $w.level3 -fill both -side top -ipady 4 -ipadx 4 -pady 1 -padx 4
	pack $w.level4 -side top -fill both -pady 1 -padx 4
	pack $w.level5 -side top -fill both
    } else {
	pack $w.level1 -fill both -side top -ipady 4 -ipadx 4 -pady 1 -padx 4
	pack $w.level3 -fill both -side top -ipady 4 -ipadx 4 -pady 1 -padx 4
	pack $w.level5 -side top -fill both 
    }	
    
    #after 500 wm deiconify $w

    return $w
}



#########################
#########################
###
### input_cmd takes as input a command in tcl list format, as 
### well as it's type, winid, and number.  It then inputs this
### into the corresponding cmd_edit window for editing.
###
#########################
#########################

proc input_cmd { cmd_data winid num type }  { 

    global winInfo
    global appInfo

    #########################
    ### first, we'll get the data out of the tcl list and into 
    ### local variables to input into the window.
    #########################

    # set up list to eliminate name, help, explain, and level
    # Only replies should be left.  These can then be cycled through
    set num_args [llength $cmd_data]
    for {set i 0} {$i < $num_args} {incr i}  {
	append arg_list "$i "
    }

    set pos [lsearch $cmd_data "name *"]
    set delete [lsearch $arg_list $pos]
    if {$delete >= 0}  {
	set arg_list [lreplace $arg_list $delete $delete]
	set name [lindex $cmd_data $pos] 
    }
    
    set pos [lsearch $cmd_data "explain *"]
    set delete [lsearch $arg_list $pos]
    if {$delete >= 0}  {
	set arg_list [lreplace $arg_list $delete $delete]
	set explain [lindex $cmd_data $pos]
    } else {set explain {explain {}}}

    set pos [lsearch $cmd_data "level *"]
    set delete [lsearch $arg_list $pos]
    if {$delete >= 0}  {
	set arg_list [lreplace $arg_list $delete $delete]
	set level [lindex $cmd_data $pos]
    } else {set level ""}

    if {$type == "user"}  {    
	set pos [lsearch $cmd_data "help *"]
	set delete [lsearch $arg_list $pos]
	if {$delete >= 0}  {
	    set arg_list [lreplace $arg_list $delete $delete]
	    set help [lindex $cmd_data $pos]
	} else {set help {help {}}}
	
	# only replies should be left.  We can now cycle through
	# and input these into their own list.
	foreach pos $arg_list {
	    set reply [lindex $cmd_data $pos]
	    if {[string first {reply} [lindex $reply 0]] >= 0}  {
		lappend reply_list "{[lindex $reply 0]} {[lindex $reply 1]}"
	    }
	}
    }
    
    #########################
    ### now it's time to start putting this stuff into the window.
    #########################
    
    # set command name
    set winInfo($winid,$num,command_name) [lindex $name 1]

    # if level is already defined, use that.  Otherwise default
    # to 1 for user commands and 3 for internal commands.
    if {$level != ""}  {
	set winInfo($winid,$num,level) [lindex $level 1]
    } else {
	if {$type == "user"}  {
	    set winInfo($winid,$num,level) 1
	} else {
	    set winInfo($winid,$num,level) 3
	}
    }

    # set the title of the window appropriately.
    if {$type == "user"}  {
	wm title .edit_cmd$winid,$num \
	    "Edit User Command - $winInfo($winid,$num,command_name)"
    } else {
	wm title .edit_cmd$winid,$num \
	    "Edit Internal Command - $winInfo($winid,$num,command_name)"
    }

    # enter command explain string
    $winInfo($winid,$num,explain_text) insert 1.0 [lindex $explain 1]

    if {$type == "user"}  {
	# enter command syntax
	$winInfo($winid,$num,syntax_text) insert 1.0 [lindex $help 1]
	
	# get replies into listbox
	if {[info exists reply_list]}  {
	    foreach reply $reply_list {
		if {[string first reply [lindex $reply 0]] >= 0}  {
		    set replynum [lindex [split [lindex $reply 0] .] 1]
		    $winInfo($winid,$num,replynums) insert end $replynum
		    $winInfo($winid,$num,replytext) insert end [lindex $reply 1]
		}
	    }
	} else {
	    # if no replies are defined, at least include "reply.0=success"
	    $winInfo($winid,$num,replynums) insert end "0"
	    $winInfo($winid,$num,replytext) insert end "success"
	}
	# initially select the first reply
	$winInfo($winid,$num,replynums) selection set 0
	$winInfo($winid,$num,replytext) selection set 0
    }

    # get script
    if {[info exists appInfo($winid,scrfile)]}  {
	set script_info [pull_script appInfo($winid,scrfile) \
			     $winInfo($winid,$num,command_name)]
    } else {set script_info ""}
    if {$script_info != ""}  {
	# put script text and filename into local variables
	set winInfo($winid,$num,script) [lindex $script_info 0]
	set winInfo($winid,$num,scriptfile) [lindex $script_info 1]
    } else {
	set winInfo($winid,$num,script) {}
	# if new script, put into default scriptfile (foo.su --> foo.scr)
	set winInfo($winid,$num,scriptfile) $appInfo($winid,scrfile)
    }
    
}
    


#########################
#########################
###
### save_cmd writes all of the local variables used in the cmd_edit
### window out to the main list of commands.  It also puts the 
### updated script back into it's scriptfile.  
###
### The script is saved immediately.  However, if the user cancels
### the main window, instead of using save or OK, the changes to the
### defcmd statement are not saved in the .su file.
###
#########################
#########################

proc save_cmd { winid index type }  {

    global winInfo
    global appInfo
    global cmdInfo


    #########################
    ### here we are going to build a new command in the
    ### tcl list format
    #########################
    
    lappend cmd "defcmd"
    
    # set the name
    lappend name {name}
    lappend name $winInfo($winid,$index,command_name)
    lappend cmd $name

    # if this is a user command, set the syntax string
    if {$type == "user"}  {
	lappend syntax {help}
	set syntax_text \
	    [string trim [$winInfo($winid,$index,syntax_text) get 1.0 end]]
	# only include if there is a syntax string
	if {$syntax_text != ""}  {
	    lappend syntax $syntax_text
	    lappend cmd $syntax
	}
    }

    # set the explain string
    lappend explain {explain}
    set explain_text \
	[string trim [$winInfo($winid,$index,explain_text) get 1.0 end]]
    if {$explain_text != ""}  {
	# only include if there is an explain string
	lappend explain $explain_text
	lappend cmd $explain
    }

    # set the level
    lappend level {level}
    lappend level $winInfo($winid,$index,level)
    lappend cmd $level

    # if this is a user command, add the replies, else 
    # add internal flag
    ### *** Sometime, I need to add code to sort these *** ###
    if {$type == "user"}  {
	set numlist $winInfo($winid,$index,replynums)
	set textlist $winInfo($winid,$index,replytext)
	
	for {set i 0} {$i < [$numlist size]} {incr i}  {
	    lappend reply "reply.[$numlist get $i]"
	    lappend reply "[$textlist get $i]"
	    lappend cmd $reply
	    set reply ""
	}
    } else {
	lappend cmd "internal"
    }
    
    set winInfo($winid,$index,script) \
	[string trim $winInfo($winid,$index,script)]
    # write the script out to its scriptfile
    push_script $winInfo($winid,$index,scriptfile) \
	$winInfo($winid,$index,command_name) \
	$winInfo($winid,$index,script)
    
    
    #########################
    ### now we have to put this command back into the 
    ### main array
    #########################

    # get the old command (including comments)
    set cmd_info [lindex $cmdInfo($winid,$index) 1]
    # replace the actual command list with our new one
    set cmd_info [lreplace $cmd_info 0 0 $cmd]
    # puts this back into the main array of commands
    set cmdInfo($winid,$index) \
	[lreplace $cmdInfo($winid,$index) 1 1 $cmd_info]

}


#########################
#########################
###
### edit_script creates a window to edit the script associated
### with the given command.
###
#########################
#########################

proc edit_script { winid num }  {

    global winInfo
    global appInfo

    if {[catch {set w [toplevel .script_edit$winid,$num]}]} { return }
    #wm withdraw $w
    # add this window to the list that will be destroyed when
    # the command edit window is destoyed.
    lappend appInfo($winid,toplevels) $w
    wm title $w "Edit Script - $winInfo($winid,$num,command_name)"
    
    viedit $w.text -savecommand \
	"global winInfo ; set winInfo($winid,$num,script) " 
    
    # put script into the text widget and give it the focus
    $w.text.text insert 1.0 $winInfo($winid,$num,script)
    focus $w.text.text
    $w.text.text mark set insert {1.0}
    do_normal $w.text.text
    $w.text configure -relief groove -bd 2

    # create buttons to duplicate vi's :wq, :w, :q! commands
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
    pack $w.buttons -side top -fill both -expand yes \
	-padx 4 -pady 2 -ipady 10 -ipadx 150

    #after 500 wm deiconify $w
}


#########################
#########################
### 
### edit_reply will either edit an existing reply, or add
### a new one, depending on the value of the parameter "new".
###
### When adding, the new reply always goes above whatever
### reply was previously selected.  
###    ****** I need to make some way to change this ******
###
#########################
#########################

proc edit_reply { winid num new }  {

    global winInfo
    global appInfo

    set numlist $winInfo($winid,$num,replynums)
    set textlist $winInfo($winid,$num,replytext)

    set index [$numlist curselection]
    
    if {[catch {set w \
	[toplevel .edit_reply$winid,$num,[$numlist curselection]]}]} { return }
    #wm withdraw $w
    lappend appInfo($winid,toplevels) $w
    
    # set the title and initial values appropriately
    if {$new == "new"}  {
	wm title $w "Add Reply"
	set winInfo($winid,$num,newnum) ""
	set winInfo($winid,$num,newtext) ""
    } else {
	wm title $w "Edit Reply"
	set winInfo($winid,$num,newnum) [$numlist get $index]
	set winInfo($winid,$num,newtext) [$textlist get $index]
    }
    
    frame $w.text -relief groove -bd 2
    # reply number
    frame $w.text.num
    label $w.text.num.l -text Number -width 7 -anchor e
    entry $w.text.num.e -textvariable winInfo($winid,$num,newnum) \
	-width 30 -relief sunken -bd 2
    bindtags $w.text.num.e "$w.text.num.e Entry firstEntry . all"
    pack $w.text.num.l $w.text.num.e -side left -pady 3 -fill both
    pack $w.text.num -fill both
    # reply text
    frame $w.text.value
    label $w.text.value.l -text Text -width 7 -anchor e
    entry $w.text.value.e -textvariable winInfo($winid,$num,newtext) \
	-width 30 -relief sunken -bd 2
    bindtags $w.text.value.e "$w.text.value.e Entry lastEntry . all"
    pack $w.text.value.l $w.text.value.e -side left -pady 3 -fill both
    pack $w.text.value -fill both

    # buttons
    frame $w.buttons -relief groove -bd 2
    if {$new == "new"}  {
	button $w.buttons.ok -text OK -width 8 -command \
	    "$numlist insert $index \$winInfo($winid,$num,newnum) ; \
             $textlist insert $index \$winInfo($winid,$num,newtext) ; \
             destroy $w"
    } else {
	button $w.buttons.ok -text OK -width 8 -command \
	    "$numlist delete $index ; $textlist delete $index ; \
             $numlist insert $index \$winInfo($winid,$num,newnum) ; \
             $textlist insert $index \$winInfo($winid,$num,newtext) ; \
             $numlist selection anchor $index ; $textlist selection anchor $index ; \
             destroy $w"
    }
    bindtags $w.buttons.ok "$w.buttons.ok Button firstButton . all"
    button $w.buttons.cancel -text Cancel -command "destroy $w" -width 8
    bindtags $w.buttons.cancel "$w.buttons.cancel Button lastButton . all"
    pack $w.buttons.ok $w.buttons.cancel -side left -padx 5 -pady 5 \
	-expand yes
    
    pack $w.text -ipadx 10 -padx 4 -pady 2 -fill x
    pack $w.buttons -ipady 5 -padx 4 -pady 2 -fill both -expand yes

    #after 500 wm deiconify $w
    focus $w.text.num.e 

}
    

#########################
#########################
###
### del_reply deletes the currently selected reply
###
#########################
#########################

proc del_reply { winid num }  {

    global winInfo

    set numlist $winInfo($winid,$num,replynums)
    set typelist $winInfo($winid,$num,replytext)

    if {[$numlist size]}  {
	set index [$numlist curselection]
	$numlist delete $index
	$typelist delete $index
    }
    
    $numlist selection anchor $index
    $typelist selection anchor $index

}




