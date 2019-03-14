
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: spectclsrv.tcl,v 1.11 2002/01/18 16:21:32 karl Exp $
#
dv_set docs>title { SpecTcl Server }
dv_set docs>author { Karl Minor, kmin@msg.ti.com }
dv_set docs>overview {
SpecTcl Server allows you to create true graphical AutoNet user interfaces
without learning TCL/TK.  

(Refer to spectcl.jpg screen dump)

Just use SpecTcl from Sun Labs to create each window of your OI, and the 
SpecTcl Server provides an AutoNet command front-end.  You can then invoke 
your OI windows from SFC, Script Language, C++, or TCL code.

(Refer to opinfo.jpg screen dump)
}
dv_set docs>target_user {
Anyone that wants to create good-looking operator interfaces without learning
TCL/TK or X-windows can use this approach to quickly create AutoNet-compliant
interfaces.

The SpecTcl documentation is pretty good, but of course
knows nothing about SpecTcl server.  You can get to to SpecTcl docs:

	http://sunscript.sun.com/spectcl/documentation/help.html

}
dv_set docs>usage {
1) Create your windows using SpecTcl, free from:
 
	http://sunscript.sun.com/TclTkCore
 
Make sure that each input widget defines a "textvariable" or "variable"
name.  These variable names will be used to pass data in or out of your
window.
 
For Text, Canvas, and Listbox widgets, define "item_name" instead.
 
For Buttons, enter "sts_sendreply %W" in the command field if you want
the button to generate the reply message, or "sts_senddata %W" if you
want it to send a data message.  Even if the button uses a bitmap or GIF,
enter a unique text string into the "text" field.  This will be returned
when the button is pressed. 
 
Use Commands/Build to generate the .tcl file that spectclsrv needs when
you issue "sts_show" commands.
 

2) Start a wishsrv or tcltksrv executable and load the spectclsrv.tcl file:

----------------------------------------------------------
	wishsrv -name myoi -file $ASTK_DIR/spectclsrv.tcl &
 
	--or--
 
	tcltksrv name=myoi tclstartup=$ASTK_DIR/spectclsrv.tcl &
----------------------------------------------------------

If you don't already have Tcl/Tk and the X Tools installed, consult
your AutoShell installation guide.  Starting with release 2.0.2, the
tools have been included in the AutoShell software distribution.

Make sure you have the environment variables $ASTK_DIR, TCL_LIBRARY,
and TK_LIBRARY set according to these instructions.

Uncompress and untar this file into your AutoShell home directory,
so it can place files into the astk directory.  For example:

	cd /home/ashl
	zcat spectclsrv.tar.Z | tar xvf -
 
3) Invoke your window by sending a "sts_show" command to the server:
 
----------------------------------------------------------
	COMMAND: myoi sts_show window=opdata
----------------------------------------------------------

4) You can use the windows as-is from and SFC or other AutoNet client.
If you know Tcl/Tk or are willing to learn, you can take advantage of
even more GUI capabilities by adding new bindings or commands to
widgets and buttons in your GUI.  The only limit is your imagination. 

To see some simple demos (these don't require SpecTcl to be installed),
cd to $ASTK_DIR/demos and execute the scripts "opdata", "opinfo", and
"sketchpad".
}

# beginning of code
################################################################################


proc tcl_quote {str} {
	regsub -all {\[} $str {\\[} str
	regsub -all {\]} $str {\\]} str
	regsub -all {\$} $str {\\$} str
	return $str
}


proc an_quote {str} {
	regsub -all {\\} $str {\\\\} str
	regsub -all {"} $str {\\"} str
	if [regexp "\[ \t\n\r\]" $str] {
		return \"$str\"
	} else {
		return $str
	}
}


proc suffsort {el1 el2} {
	set suff1 [lindex [split $el1 .] 1]
	set suff2 [lindex [split $el2 .] 1]
	if {$suff1>$suff2} {
		return 1
	} elseif {$suff1<$suff2} {
		return -1
	} else {
		return 0
	}
}


proc dumpvars {filename} {
	set fid [open $filename w]
	foreach varname [lsort [info globals]] {
		if {[string match "tkPriv*" $varname]} {
			continue
		}
		global $varname
		catch {
		if [array exists $varname] {
			foreach elname [lsort [array names $varname]] {
				eval set val \"\$$varname\($elname\)\"
				puts $fid "$varname\($elname\)=$val"
			}
		} else {
			eval set val \"\$$varname\"
			puts $fid "$varname=$val"
		}
		}
	}
	close $fid
}


proc sts_sendreply {window {menuopt ""}} {
	global widget_currenvs
	if {![info exists widget_currenvs([winfo parent $window])]} {
		tkerror "Button command must be \"sts_sendreply %W\""
		return
	}
	set currenv $widget_currenvs([winfo parent $window])
	if [catch {set res [sts_getdata [winfo parent $window]]}] {
		global sts_errorInfo errorInfo
		if {![info exists sts_errorInfo]} {
			set sts_errorInfo "sts_getdata failed - $errorInfo"
		}
		tk_dialog .tmp ERROR $sts_errorInfo error 0 OK
		return
	} else {
		an_write $currenv $res
		an_write $currenv window=[string range [winfo toplevel $window] 1 end]
	}
	if {![info exists \
		widget_currenvs([winfo parent $window],alreadyreplied)]} {
		if {$menuopt!=""} {
			set text $menuopt
		} else {
			if [catch {set text [$window cget -text]}] {
				set text [sts_getname $window]
			}
		}
		an_write $currenv pressed=[an_quote $text]
		destroy [winfo parent $window]
		an_return $currenv 0
	} else {
		if {$menuopt!=""} {
			set text $menuopt
		} else {
			if [catch {set text [$window cget -text]}] {
				set text [sts_getname $window]
			}
		}
		an_write $currenv pressed=[an_quote $text]
		an_senddata $currenv
		an_clearstdout $currenv
	}
}

proc sts_getdata {window} {
	set varlist {}
	set results ""
	foreach child [winfo children $window] {
		set class [winfo class $child]
		if {$class=="Frame"} {
			append results [sts_getdata $child]
			continue
		}
		if {$class!="Frame" && $class!="Label" 
				&& $class!="Button" 
				&& $class!="Canvas" 
				&& $class!="Scrollbar"} {
			if {$class=="Listbox"} {
				set sels [$child curselection]
				set wname [sts_getname $child]
				set count 1
				foreach sel $sels {
					set val [string trim [$child get $sel]]
					append results \
						${wname}.$count=[an_quote $val]\n
					incr count
				}
			} elseif {$class=="Text"} {
				set wname [sts_getname $child]
				set val [string trim [$child get 1.0 end]]
				if {[string compare $val ""]} {
					append results \
						${wname}=[an_quote $val]\n
				}
			} else {
				set var [sts_getname $child]
				set tl [winfo toplevel $window]
				if {[lsearch $varlist $var]==-1} {
					lappend varlist $var
					if {[string first "(" $var]>=0} {
						set temp2 [split $var "()"]
						set temp [lindex $temp2 0]
						set vartag [lindex $temp2 1]
						global $temp
					} else {
						set vartag $var
						global $var
					}
					if {![info exists $var]} {
						continue
					}
					eval set value \$$var
					set value [string trim $value]
					global sts_regexp sts_errorInfo sts_errormsg
					if {[info exists sts_regexp($tl,$vartag)] && \
						![regexp $sts_regexp($tl,$vartag) $value]} {
						if {[info exists sts_errormsg($tl,$vartag)]} {
							set sts_errorInfo "$value $sts_errormsg($tl,$vartag)"
						} else {
							set sts_errorInfo \
								"\"$value\" does not match \"$sts_regexp($tl,$vartag)\""
						}
						error "invalid data"
					}
					if {[string compare $value ""]} {
						append results \
							${vartag}=[an_quote $value]\n
					}
				}
			}
		}
	}
	return $results
}


proc sts_senddata {window {menuopt ""}} {
	global widget_currenvs
	if {![info exists widget_currenvs([winfo parent $window])]} {
		tkerror "Button command must be \"sts_senddata %W\""
		return
	}
	if {$menuopt!=""} {
		set text $menuopt
	} else {
		if [catch {set text [$window cget -text]}] {
			set text [sts_getname $window]
		}
	}
	set currenv $widget_currenvs([winfo parent $window])
	an_write $currenv [sts_getdata [winfo parent $window]]
	an_write $currenv pressed=[an_quote $text]
	an_senddata $currenv
	an_clearstdout $currenv
}


# Returns the unique variable name for this widget.
# 	textvariable if available, then
#	variable if available, then
#	item_name.
proc sts_getname {widget} {
	set opts [$widget configure]
	if {[lsearch $opts {-textvariable *}]>=0 &&
		[$widget cget -textvariable]!=""} {
		set widname [$widget cget -textvariable]
	} elseif {[lsearch $opts {-variable *}]>=0 &&
		[$widget cget -variable]!=""} {
		set widname [$widget cget -variable]
	} else {
		set widname [winfo name $widget]
	}
	return $widname
}


# Returns the unique widget name for this widget.
# 	textvariable if available, then
#	variable if available, then
#	item_name.
proc sts_getwidname {widget} {
	set opts [$widget configure]
	if {[lsearch $opts {-textvariable *}]>=0 &&
		[$widget cget -textvariable]!=""} {
		set widname [$widget cget -textvariable]
	} elseif {[lsearch $opts {-variable *}]>=0 &&
		[winfo class $widget]!="Radiobutton" &&
		[$widget cget -variable]!=""} {
		set widname [$widget cget -variable]
	} else {
		set widname [winfo name $widget]
	}
	return $widname
}



an_proc sts_show {sts_show window=%s [tagged_values] [replynow]
	[{parentwin=%s [{pack=%s, place=%s}], geometry=%s}] [takefocus]
	[globalgrab] [grab] [forcereload] [uidir=%s] [lockfor=%d] [clearall]} {
This command displays a window defined with the SpecTcl GUI builder.
The 'window' parameter specifies the base name (no extensions) of
a window that exists on disk in a 'xxxxxx.ui.tcl' file.  For example,
if SpecTcl created 'mywindow.ui.tcl', 'window=mywindow' should be
specified to display it.

When creating SpecTcl Server Windows, place the widget name in the
following widget fields.  This name will be used to pass data into
widgets, return data in reply or data messages, and will also serve
as the identifier for the widget in any sts_widcmd calls.

An exception is "radiobutton" widgets, which typically share a common
variable name.  For radiobuttons, enter a unique name in each radiobutton
"item_name" field, and enter the shared variable name in the "variable"
field.

Widget Type     field for name      field for variable
-----------     --------------      ------------------
label           item_name           N/A
checkbutton     variable            variable
radiobutton     item_name           variable
message         item_name           N/A
text            item_name           N/A
entry           textvariable        textvariable
scale           variable            variable
listbox         item_name           item_name
scrollbar       item_name           N/A
canvas          item_name           N/A

Note that for label, message, text, scrollbar, and canvas types, there
is no way to pass in data as command arguments or retrieve data in
reply or data messages.  These widgets are typically given values when
the window is defined or via commands or TCL code later.  The widget
commands (including configure) for these widgets provide powerful
capbilities, and can be accessed via sts_widcmd calls.

Note that when using sts_widcmd, the value of the "field for name"
item is used as the identifier for the widget.

To pass initialization data into a widget, pass the data in as a tagged
parameter, where the widget name is the tag.  For listbox widgets, each
listbox entry is an enumerated parameter with the listbox name as the prefix.

Any buttons defined in your window should invoke one of the following 
commands:

sts_sendreply %W - Sends a reply message to the client containing any data
	in the window, and destroys the window.

sts_senddata %W - Sends a data message to the client containing any data
	in the window, but does not destroy the window.

Data in reply and data messages will be tagged with the the widget's name.
Listbox selections will be returned as enumerated parameters.

The 'replynow' option can be used to force the sts_show command to generate
a reply to the client immediately after showing the window.  Such windows
can only contain 'sts_senddata' buttons.  If you use the 'replynow' option
and are using tcltksrv, be sure to get the latest version of tcltksrv 
(later than 4/15/1998).

EXAMPLE:
-------------------------------------------------------------------
COMMAND: ststest sts_show window=opinfo opnum=456456 lotnum=9801203
================= REPLY =================
fr=ststest to=tk11696
opnum=456456
lotnum=9801203
reply=0 command=sts_show comment="Success" 
=========================================
-------------------------------------------------------------------

By default, the window is created as a toplevel window positioned by
and managed by the window manager.  If the "parentwin" option is specified
and gives the name of an existing window ("." is the main window),
then the new window will be created inside the named window.  By default,
it will be packed at the top of the parent window, but the "pack"
or "place" options can be used to make placement of the window more
specific.  The values of "pack" or "place" should consist of valid
options to those commands, as documented in the TK documentation.

For example:
-------------------------------------------------------------------
... place="-x 50 -y 30" parentwin=.
-------------------------------------------------------------------
would place the upper left corner of the new window 50 pixel over and
30 pixel down inside the main window (which must have been "deiconify(ed)"
previously).
-------------------------------------------------------------------
... pack="-side right -expand 1 -fill both" parentwin=.
-------------------------------------------------------------------
will pack the new window against the right edge of the available space
in the main window, and will mark it to expand when the main window
is expanded by the user.

If the window is being displayed as a toplevel, the "geometry" parameter
can be used to control its size and position, as allowed by the window
manager.  For example, "geometry=+100+50" will place the upper left
corner of the window 100 pixels to the right of the upper left corner 
of the screen, and 50 pixels down from the upper left corner.
"geometry=400x400-10-10" will make the initial window size 400x400
and will place its lower right corner 10 pixels from the lower right
corner or the screen.

The "grab" option will cause all other windows to be locked until this
window is cleared.  

The "forcereload" option will cause the window definition to be reloaded
even if it already exists in memory.  By default, window definitions
will only be loaded the first time they are used and are kept in memory
for the life of the server.

The "uidir" option can be used to specify the directory in which the
window definition resides.  By default, window definitions are assumed
to be in the CWD.  Window names can be prefixed with paths, and a 
root DV named "uidir" can be created to indicate a server-wide path
to window files.

The "lockfor" parameter can be used to lock the window for N
seconds after it is created.  The window will remain on
the screen for N seconds, even if an sts_close is issued before
the time is up.  
} {
{0 Success}
{50 "Window already shown"}
{51 "Couldn't load window file"}} {


	global sts_lastfocus
	global sts_setfocus

	# trim any leading or trailing whitespace
	set window [string trim $window]

	# get the root name of the window
	# this handles the possibility of the 'window' parameter containing
	# file path info or mistakenly including the '.ui.tcl' extension
	set windowroot [file root [file tail $window]]

	#
	if {[info exists parentwin]} {
		if {$parentwin=="."} {
			set parentwin ""
		}
		set wn $parentwin.$windowroot
	} else {
		set wn .$windowroot
	}

	# check if the requested window is already displayed
	# if not, then proceed with the request to display the window
	# otherwise, return the appropriate error reply
	if {![winfo exists $wn]} {

		# check if the window definition file should be loaded
		# if so, then proceed to load the window definition
		# otherwise, proceed with the display of the designated window
		if {[info exists forcereload] || [info procs ${windowroot}_ui] == ""} {

			#------------------------------------------------------------------
			if {![info exists uidir]} {
				set uidir [dv_get uidir]
			}	
			set filepath ""
			if {[string index $window 0]!="/"} {
				foreach dir [split "$uidir:." :] {
					if [file readable \
						$dir/$windowroot.ui.tcl] {
						set filepath $dir/$windowroot
						break
					}
				}
				#if {$filepath==""} {
				#	an_return $currenv 51
				#	return
				#}
			} else {
				set filepath $window
			}
			#------------------------------------------------------------------

			# check if the window definition file can be read
			# if not, return the appropriate error reply
			# otherwise, load in the window definition and proceed
			# to display the designated window
			if {![file readable $filepath.ui.tcl]} {

				an_return $currenv 51
				return

			} else {

				source $filepath.ui.tcl
			}
		}

		#----------------------------------------------------------------------
		global widget_currenvs
		set widget_currenvs($wn) $currenv
		if {[info exists parentwin]} {
			frame $wn
			if {[info exists place]} {
				eval place $wn $place
			} elseif {[info exists pack]} {
				eval pack $wn $pack
			} else {
				pack $wn
			}
		} else {
			toplevel $wn
			if {[info exists geometry]} {
				wm geometry $wn $geometry
			}
		}
		${windowroot}_ui $wn 
		catch {unset inparms}
		foreach parm $anparms {
			set tag [lindex $parm 0]
			set val [lindex $parm 1]
			if {[lsearch "fr to do window currenv anparms an_data" $tag]==-1} {
				set inparms($tag) $val	
			}
		}
		foreach child [winfo children $wn] {
			set class [winfo class $child]
			if {$class!="Frame" && $class!="Button" && $class!="Scrollbar"} {
				if {$class=="Listbox"} {
					set wname [sts_getname $child]
					set els [array names inparms $wname.*]
					set idx $wname
					append idx .*
					set els [lsort -command suffsort [array names inparms $idx]]
					foreach el $els {
						$child insert end $inparms($el)
					}
				} elseif {$class=="Text"} {
					set wname [sts_getname $child]
					if [info exists inparms($wname)] {
						$child insert end $inparms($wname)
					}
				
				} elseif {$class=="Canvas"} {
					set wname [sts_getname $child]
					if [info exists inparms($wname)] {
						foreach cmd [split $inparms($wname) \n] {
							eval $child $cmd
						}
					}
				} else {
					set var [sts_getname $child]
					if {[string first "(" $var]>=0} {
						set temp2 [split $var "()"]
						set tempname [lindex $temp2 0]
						set vartag [lindex $temp2 1]
					} else {
						set tempname $var
						set vartag $var
					}
					if {[info exists clearall]} {
						catch {unset $var}
						global $tempname
						if {[catch {eval set $var \{\}}]} {
							eval set $var 0
						}
					}
					if {[info exists inparms($vartag)]} {
						catch {unset $var}
						global $tempname
						eval set $var \"$inparms($vartag)\"
					}
				}
			}
		}
		global sts_locked
		if {[info exists lockfor]} {
			set sts_locked($wn) ""
			after [expr $lockfor * 1000] "
				global sts_locked
				eval \$sts_locked($wn)
			"	
		} else {
			if {[info exists sts_locked($wn)]} {
				unset sts_locked($wn)
			}
		}
		if {[info exists grab]} {
			wm withdraw $wn
			wm deiconify $wn
			grab $wn	
		} elseif {[info exists globalgrab]} {
			wm withdraw $wn
			wm deiconify $wn
			grab -global $wn	
		}
		if {[info exists takefocus]} {
			set sts_lastfocus [focus -lastfor $wn]
			set sts_setfocus($wn) 1
		} else {
			set sts_setfocus($wn) 0
		}
		if {[info exists replynow]} {
			an_write $currenv "reply=0 comment=\"Window shown\""
			an_senddata $currenv
			an_clearstdout $currenv
			set widget_currenvs($wn,alreadyreplied) true
		}
		#----------------------------------------------------------------------

	} else {

		an_write $currenv [format "window=\"%s\"" $wn]

		an_return $currenv 50
	}
}




an_proc sts_widcmd {sts_widcmd window=%s [widget=%s] cmd=%s [parentwin=%s]} {
Executes a widget command for a window shown with sts_show. 

For example, if your window named 'mywin' contains a canvas 
(drawing area) widget with item_name 'sketchpad', you can draw 
a circle on the canvas with the command:
----------------------------------------------------------
	sts_widcmd window=mywin widget=sketchpad \ 
		cmd="create oval 10 10 100 100"
----------------------------------------------------------

The widget commands supported by each widget are documented
in the TK man pages for the widgets.

To change the attributes of most widgets at runtime, you can use the
"configure" widget command:
----------------------------------------------------------
sts_widcmd window=testframe parentwin=. \
	cmd="configure -relief groove -borderwidth 4 -bg red"
----------------------------------------------------------

The "parentwin" option is used only when the sts_show that displayed
the window placed it inside an existing window. 

To execute commands that are not widget commands, use the "tclexec"
command:
----------------------------------------------------------
tclexec cmds="wm minsize . 400 300"
----------------------------------------------------------
Sets the main window (normally hidden) to a minimum size.

----------------------------------------------------------
tclexec cmds="wm deiconify ."
----------------------------------------------------------
Unhides the main window (named .)  You can then use the "parentwin"
option of sts_show to place windows inside the main window, instead
of creating them as separately managed windows.

By default, any command or variable substitutions in "cmd" will not
be expanded.  If the "subst" option is specified, dollar signs and
left brackets will result in variable and command substitutions,
respectively.
} {
{0 Success}
{1 "No such Window"}
{2 "No such Widget"}
{3 "Widget Command Failed"}
{4 "Command Garbled"}
} {
	global errorInfo
	if {[info exists parentwin]} {
		if {$parentwin=="."} {
			set parentwin ""
		}
		set wn $parentwin.$window
	} else {
		set wn .$window
	}
	set w $wn
	if {![winfo exists $wn]} {
		an_write $currenv "widget=$w\ncmd=[an_quote $cmd]"
		an_return $currenv 1
		return
	}
	if {![info complete $cmd]} {
		an_write $currenv "widget=$w\ncmd=[an_quote $cmd]"
		an_return $currenv 4
		return
	}
	if [info exists widget] {
		foreach child [winfo children $wn] {
			set widname [sts_getwidname $child]
			if {$widname==$widget} {
				set w $child
				break
			}
		}
		if {[string compare $w $wn]==0} {
			an_write $currenv "widget=$w\ncmd=[an_quote $cmd]"
			an_return $currenv 2
			return
		}
	} else {
		set w $wn
	}

	if {[info exists subst]} {
		set rc [catch {eval $w $cmd}]
	} else {
		set rc [catch {eval $w [tcl_quote $cmd]}]
	}

	update idletasks
	if {$rc} {
		an_write $currenv error=[an_quote [lindex [split $errorInfo \n] 0]]
		an_write $currenv "widget=$w\ncmd=[an_quote $cmd]"
		an_return $currenv 3
		return
	} else {
		an_return $currenv 0
		return
	}
}





an_proc sts_close {sts_close window=%s [parentwin=%s]} {
Closes a window previously opened with sts_show.  A reply to the original
sts_show command will be sent to the original client, and will contain 
any data in the widgets.  
} {
{0 Success }
{1 "No Such Window"}} {

	global sts_lastfocus
	global sts_setfocus

	if {[info exists parentwin]} {
		if {$parentwin=="."} {
			set parentwin ""
		}
		set wn $parentwin.$window
	} else {
		set wn .$window
	}
	set w $wn
	if {![winfo exists $wn]} {
		an_return $currenv 1
		return
	}
	global widget_currenvs
	set oldcurrenv $widget_currenvs($wn)
	an_write $oldcurrenv [sts_getdata $wn]		
	if {$sts_setfocus($wn)} {
		set sts_lastfocus [focus -lastfor $wn]
		if {[winfo exists $sts_lastfocus]} {
			focus $sts_lastfocus
		}
		set sts_setfocus($wn) 0
	}
	global sts_locked
	# If window is locked, record action to take when unlocked.
	if {[info exists sts_locked($wn)]} {
		set sts_locked($wn) "destroy $wn"	
	} else {
		destroy $wn
	}
	an_return $oldcurrenv 0
	an_return $currenv 0
}




an_proc sts_load {sts_load window=%s [filepath=%s]} {
Loads into memory the window definition file designated by the 'window'
parameter, and whose location on disk can be further defined by a path
specified with the optional 'filepath' parameter.
The 'window' parameter specifies the base name (no extensions) of
a window definition that exists on disk as a 'xxxxxxxx.ui.tcl' file.
For example, if the desired window definition is contained in a file
named: 'mywindow.ui.tcl', 'window=mywindow' should be used in this command
to specify it.
The 'filepath' parameter can be used to specify path to the desired file
within the file system directory structure.  This can be an absolute file
path or a path relative to the current working directory.  For example:
/opt/apps/clients/windowdefs, or ../clients/windowdefs.
A file system path may be included as part of the window name specified
by the 'window' parameter.  For example: 'window=../windowdefs/mywindow'.
If the 'filepath' parameter is also included, then the specified path is
prepended to that which is specified with the 'window' parameter.
For example:
with 'window=../windowdefs/mywindow' and 'filepath=/opt/apps/clients/bin'
the result would be the loading of the windows definition file designated
by '/opt/apps/clients/bin/../windowdefs/mywindow.ui.tcl'.
} {
{0 Success}
{51 "Couldn't load window file"}} {

	set replycode 0

	# trim any leading or trailing whitespace
	set window [string trim $window]

	# get the root name of the window
	# this handles the possibility of the 'window' parameter containing
	# file path info or mistakenly including the '.ui.tcl' extension
	set windowroot [file root [file tail $window]]

	# check if the window definition has already been loaded
	# if not, then prepare to load in the window definition
	# otherwise, do nothing and return good reply
	if {[info procs ${windowroot}_ui] == ""} {

		# check if 'filepath' parameter included in the call
		# if not, then initialize a filepath variable to an empty string
		# otherwise, trim any leading or trailing whitespace
		if {![info exists filepath]} {

			set filepath ""

		} else {

			set filepath [string trim $filepath]
		}

		# build a fully qualified path to the window definition file
		set window [format "%s.ui.tcl" [file rootname $window]]
		set filepath [file join $filepath $window]

		# check if the window definition file can be read
		# if not, set an error reply code
		# otherwise, load in the window definition
		if {![file readable $filepath]} {

			set replycode 51

		} else {

			source $filepath
		}
	}

	an_write $currenv [format "file=\"%s\"" $filepath]

	an_return $currenv $replycode
}



wm withdraw .


# end of code
################################################################################
#
# $Log: spectclsrv.tcl,v $
# Revision 1.11  2002/01/18 16:21:32  karl
# Fixed bug that had broken listbox initialization.
# Fixed so that widget variables can be array elements.
# Fixed bug where listbox init values could be in wrong order.
#
# Revision 1.10  2000/12/14 23:02:25  karl
# Took out leftover debugging Tcl var dump.
# ,
#
# Revision 1.9  2000/12/14 22:58:22  karl
# Added the "clearall" option to clear field values from previous calls.
# Fixed the "forcereload" feature.
# Allowed textvariables for Labels.
# Added window=xxxx tag to sts_show reply messages.
# Fixed problems with underscores in variable names.
#
# Revision 1.8  2000/09/11 22:08:52  karl
# Added globalgrab, forcereload, uidir, lockfor options to sts_show.
# Added "subst" option to sts_widcmd.  Fixed bug where quotes were
# corrupting messages.
#
# Revision 1.7  2000/07/07  21:55:58  karl
# Added better docs in explain strings.
# Added parentwin option to create new window inside an existing one.
# Added place and pack options to allow freer window placement.
# Added geometry option to allow window size and position customization.
# Added grab option.
# Changed an_clear to an_clearstdout.
# Added error window if window data collection fails.
# Fixed problem with Frames in windows.
# Added sts_regexp() field verification ability.
#
# Revision 1.6  1999/08/24  15:31:15  karl
# Fixed listboxes to retain order of numerically suffixed input data.
#
# Revision 1.5  1999/03/31  22:57:19  karl
# Took out auto-load of *.gif, which can be dangerous in dir with lots of gifs.
#
# Revision 1.4  1998/10/20  21:57:25  karl
# Fixed bug related to field names containing dots.  Fixed bug related
# to tagged values containing unprotected spaces.  Fixed bug that
# kept menu option selection messages from containing other field
# data.  Fixed bug that caused all values containing t, n, or r to
# be quoted even if unnecessary.
# Added code to import all *.gif and images/*.gif files at startup.
#
# Revision 1.3  1998/07/21  21:19:20  karl
# Added conversion of underscores in field names to periods for easier
# access.
#
# Revision 1.2  1998/07/20  18:45:53  karl
# Took out "wm withdraw" and leftover debugging "puts"
#
# Revision 1.1  1998/07/16  15:34:43  karl
# Initial revision
