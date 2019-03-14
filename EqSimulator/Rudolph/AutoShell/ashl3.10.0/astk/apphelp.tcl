
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: apphelp.tcl,v 1.6 1998/05/28 21:35:07 karl Exp $
# $Log: apphelp.tcl,v $
# Revision 1.6  1998/05/28 21:35:07  karl
# Added code to find figure out which menu item a user is interested in.
#
# Revision 1.5  1996/11/22  16:56:54  jasonm
# fixed bug where you could only shrink the window once
#
# Revision 1.4  1996/11/21  19:41:07  jasonm
# made window shrinking stuff force the toplevel to be the size of the
#   widget
#
# Revision 1.3  1996/11/20  20:52:21  jasonm
# added function to isolate certain parts of a widget to create screen
#   shots
#
# Revision 1.2  1996/11/07  16:15:00  jasonm
# modified so that an error window does not pop up if there is no entry
# for an item
#
# Revision 1.1  1996/08/27  16:07:39  karl
# Initial revision
#
#set buildindex 1
# Application Help Procedures
#
# Last edited:		03/06/96  12:58
#	   By:		Guy M. Saenger
#                       changed documentation for <F1> binding
#
# Last edited:		11/29/95  16:25
#	   By:		Dewayne McNair
#                       fixed a whole bunch 'o problems
#
#
# Last edited:		11/27/95  8:00
#	   By:		Dewayne McNair
#			made changes to documentation
#
# These functions allow your applications to provide context-sensitive and 
# browsable online help.  The procedures are initalized with the following code:
# 
# 	init_help application_name app-help.idx app-help.txt
# 
# Where  'application_name' is the unique name of your application,
# app-help.txt is a docfmt-style document describing the application, and
# app-help.idx is an index that associates widgets in your application with 
# sections of the document.  The init_help function initializes the arrays 
# necessary at runtime to provide access to the documentation.
# 
# To use the online help you application can provide browsable help with:
# 	help_browse application_name
# 
# To show information about how to use the online help:
# 	help_explain appname
# 
# To allow context sensitive help, use the following bindings.  Users will
# then be able to hold down the Ctrl key and click on any indexed widget to
# display help for the widget.
#
#    bind all <F1> {help_show_idx application_name [winfo containing %X %Y]}
#
# The format for each index entry is:
#
#	widget_name	heading_name
#
# Where widget_name is the full name of the widget.  Wildcard characters
# (*,?) can be used to match several widgets with a single heading.  The
# widget_name is separated by the heading_name by one or more TAB characters.
# The heading_name can contain spaces.

#============================================================================

# Procedure Name:   help_disp_error
#        Purpose:   display an error message
#         Inputs:   a string consisting of the message
#      Variables:   None
proc help_disp_error {error_message parent} {
        tk_messageBox -message $error_message -icon error \
            -type ok -parent $parent -title "Error!"

}

#Procedure Name:   help_init_help_array
#       Purpose:   reads a docfmt-type file into the array 
#                  help_txt(), indexed by heading name.
#        Inputs:   appname   - unique application name to which we want help
#                  help_file - file containing the help text
#     Variables:   help_txt - array indexed by 'topic' containing the help text
proc help_init_help_array {appname help_file} {
   global help_txt help_lev help_ord

   set text ""
   set section ""
   set prevline ""
   set index 0
   set file [open $help_file]
   foreach thisline [split [read $file] "\n"] {
      if {[regexp {^[-=\.]+$} $thisline]} {
	 #puts "checking $thisline '[string range $thisline 0 0]'"
	 switch -- [string range $thisline 0 0] {
		{=} { set prevlevel 0 }	
		{-} { set prevlevel 1 }	
		{.} { set prevlevel 2 }	
		default { set prevlevel 0 }
	 }
         set thislen [string length [string trim $thisline]]
         set prevlen [string length [string trim $prevline]]
         if {$prevlen == $thislen} {
            if {$text != "" && $section != ""} {
               set help_txt($appname,$section) [string trim $text]
               set help_lev($appname,$section) $level
	       set help_ord($appname,$index) $section
	       incr index
            }
            set section [string trim $prevline]
	    set level $prevlevel
            set text ""
            set thisline ""
         } else {
            append text "$prevline\n"
         }
      } else {
         append text "$prevline\n"
      }
      set prevline $thisline
   }
   set help_txt($appname,$section) [string trim $text]
   set help_lev($appname,$section) $level
   set help_ord($appname,$index) $section
   close $file
}

# Procedure Name:   help_show_help
#        Purpose:   displays a help window based on the help_txt() array 
#                   and the heading.
#         Inputs:   appname  - unique application name to which we want help
#                   heading  - heading about which to show help
#      Variables:   help_txt - array indexed by 'topic' containing the help text
proc help_show_help {appname heading} {
   global help_txt

   set cnt 0
   set MAX_ROWS 24

   #puts "heading=$heading"
   if {[string trim $heading]==""} {
	return
   }
   while {[winfo exists .hlp$cnt]} {
      incr cnt
   }
   set wn .hlp$cnt
   if {[info exists help_txt($appname,$heading)] == 0} {
      help_disp_error "No help defined for $heading" $wn
      return
   }
   toplevel $wn
   wm geometry $wn "+[expr [winfo pointerx .] - 500]+[expr [winfo pointery .] - 15]"
   wm resizable $wn 0 0
   wm title $wn "$heading"

   set text "\n[string trim $help_txt($appname,$heading)]\n"
   set tmp [split $text "\n"]
   set textheight [llength $tmp]
   if {$textheight < 5} {
      set textheight 5
   }
   if {$textheight > $MAX_ROWS} {
      set textheight $MAX_ROWS
   }
   set textwidth 40
   foreach el $tmp {
      set linelen [string length $el]
      if {$linelen > $textwidth} {
         set textwidth $linelen
      }
   }
   incr textwidth
   incr textheight

   frame $wn.f1 

   text $wn.f1.text -yscrollcommand "$wn.f1.scroll set" -bd 2 -relief groove \
                    -width $textwidth -height $textheight -bg lightblue
   scrollbar $wn.f1.scroll -command "$wn.f1.text yview"
   button $wn.ok -text OK -width 10 -command "destroy $wn"

   $wn.f1.text insert 1.0 "$heading\n"
   $wn.f1.text insert 2.0 $text
   $wn.f1.text tag add heading 1.0 2.0
   $wn.f1.text tag configure heading -foreground blue

   pack $wn.f1.text -side left
   if {$textheight > $MAX_ROWS} {
      pack $wn.f1.scroll -side right -fill y
   }
   pack $wn.f1 -side top
   pack $wn.ok -side top
}


# Procedure Name:   help_show_idx
#        Purpose:   decode which topic we want to show and call
#                   help_show_help with that topic
#         Inputs:   appname  - unique application name to which we want help 
#                   widget   - widget about which we are asking for help
#      Variables:   sh_idx   - array indexed by 'topic' containing the help text
proc help_show_idx {appname widget} {
   global sh_idx help_debugging

   set match ""
   set index [array names sh_idx $appname,*]
   foreach pattern $index {
      regsub -all {\.} [string trimleft $pattern $appname,] {\\.} fixed_pattern
      if {[regexp "^$fixed_pattern\$" "$widget"]} {
         set match [string trimleft $pattern "$appname,"]
         break
      }
   }
   if {$match != ""} {
      if {[info exists sh_idx($appname,$match)] == 0} {
         tkerror "Match but no entry for $match"
         return
      } 
      help_show_help $appname $sh_idx($appname,$match)
   } else {
	global buildindex
	if {[info exists buildindex]} {
		set label ""
		catch {set label [$widget cget -text]}
		set class [winfo class $widget]
		if {$class=="Menu"} {
			set label [$widget entrycget active -label]
		}
		puts "$widget		$label"
		flush stdout
	} else {
		if {$help_debugging}  {
			help_disp_error "Sorry, no help for this item ($widget). Check other items." .
		}
	}
   }
}

# Procedure Name:   help_init_help_idx
#        Purpose:   read the given index file and store contents in an array
#         Inputs:   appname - unique application name to which we want help
#      Variables:   sh_idx - array indexed by topic containing the help text
proc help_init_help_idx {appname idxfile} {
   global sh_idx 

   set file [open $idxfile]
   foreach line [split [read $file] "\n"] {
      set line [string trim $line]		
      set widget [lindex $line 0]
      regsub -all {\*} $widget {[^\.]+} widget
      set section [lrange $line 1 end]	
      set sh_idx($appname,$widget) $section
   }
   close $file
}


# Procedure Name:   help_explain
#        Purpose:   tell the user how to use the help system
#         Inputs:   appname - unique application name to which we want help
#      Variables:   None
proc help_explain {appname} {
   help_show_help $appname "HELP" 	
}

# Procedure Name:   help_browse
#        Purpose:   display all available help topics in a browser
#         Inputs:   appname  - the unique application name to which we want help
#      Variables:   help_txt - array indexed by 'topic' containing the help text
#                   tagname - the current tag value.  used to obtain the
#                             appropriate help entry

proc help_browse {appname} {
	global help_lev help_txt help_ord

	set wn .browse
	if {[winfo exists $wn]} {
		help_disp_error "Browse window already open." .
		return
	}
    toplevel $wn
   wm geometry $wn "+[expr [winfo pointerx .] - 460]+[expr [winfo pointery .] - 5]"

	frame $wn.index
	frame $wn.text
	frame $wn.butts

	# Setup the buttons
	button $wn.butts.text -text Text -width 10 -command "
		help_browse2_text $wn
	"
	button $wn.butts.index -text Index -width 10 -command "
		help_browse2_index $wn
	"
	button $wn.butts.cancel -text Cancel -width 10 \
		-command "destroy $wn"
	pack $wn.butts.text $wn.butts.index $wn.butts.cancel \
		-side left -expand 1
	pack $wn.butts -side bottom -expand 1 -fill x

	# Setup the index.
	listbox $wn.index.list -yscrollcommand "$wn.index.scrl set"  \
		-width 65 -height 20
	scrollbar $wn.index.scrl -command "$wn.index.list yview"
	bind $wn.index.list <Double-Button-1> "
		help_browse2_text $wn
	"
	pack $wn.index.list -side left -fill both -expand 1
	pack $wn.index.scrl -side left -fill y -expand 1

	# Setup the text
	text $wn.text.content -yscrollcommand "$wn.text.scrl set"\
		-width 80 -height 30 -background lightblue
	label .dummy 
	set regfont [.dummy cget -font]
	destroy .dummy
	$wn.text.content tag configure heading -foreground blue -font $regfont
	scrollbar $wn.text.scrl -command "$wn.text.content yview"
	pack $wn.text.content -side left -fill both -expand 1
	pack $wn.text.scrl -side left -fill y -expand 1

	# Put data into the index and the text.
	for {set index 0} {[info exists help_ord($appname,$index)]} \
			{incr index} {
		set section $help_ord($appname,$index)
		set level $help_lev($appname,$section)

		set entry ""
		for {set ic 0} {$ic<$level} {incr ic} {
			append entry "        "
		}
		append entry $section
		$wn.index.list insert end $entry

		$wn.text.content insert end "$section\n\n" heading 
		$wn.text.content insert end \
			"$help_txt($appname,$section)\n\n\n" text
	}
	$wn.text.content configure -state disabled

	pack $wn.index -side bottom -fill both -expand 1
	$wn.butts.index configure -state disabled
	
}

proc help_browse2_text {wn} {
	pack forget $wn.index
	pack $wn.text -side bottom -fill both -expand 1
	$wn.butts.text configure -state disabled
	$wn.butts.index configure -state normal
	set sel [$wn.index.list curselection]
	if {$sel!=""} {
		set section [string trim [$wn.index.list get $sel]]
		set loc [$wn.text.content search -regexp "^$section\$" 1.0]
		$wn.text.content yview $loc
	} else {
		$wn.text.content yview 0
	}
}

proc help_browse2_index {wn} {
	pack forget $wn.text
	pack $wn.index -side bottom -fill both -expand 1
	$wn.butts.text configure -state normal
	$wn.butts.index configure -state disabled
}


proc help_browse_old {appname {sort 1}} {
   global help_txt tagname help_lev

   set wn .browse
   if {[winfo exists $wn]} {
      help_disp_error "Browse window already open." .
      return
   }
   toplevel $wn
   wm geometry $wn "+[expr [winfo pointerx .] - 460]+[expr [winfo pointery .] - 5]"

   set topics [array names help_txt $appname,*]
   set numtopics [llength $topics]
   for {set index 0} {$index<$numtopics} {incr index} {
		set topic [lindex $topics $index]
		set tmp [string range $topic [string length $appname,] end]
		set topics [lreplace $topics $index $index $tmp]
   }
	#puts "topics=$topics"
   if {$sort} {
	   set topics [lsort $topics]
   }
   set tagname ""

   # create a dummy widget so we can grab the default font
   label .h__elp_d_u_m_m_y
   set font [.h__elp_d_u_m_m_y cget -font]
   destroy .h__elp_d_u_m_m_y

   frame $wn.f1
   frame $wn.f2
   text $wn.f1.text -yscrollcommand "$wn.f1.scroll set" -bd 2 -relief groove \
                    -width 80 -height 24 -bg lightblue -state disabled

   text $wn.f2.text -yscrollcommand "$wn.f2.scroll set" -bd 2 -relief groove \
                    -width 80 -height 12 -font $font

   bind $wn.f2.text <1>         {break}
   bind $wn.f2.text <Double-1>  {break}
   bind $wn.f2.text <Triple-1>  {break}
   bind $wn.f2.text <B1-Leave>  {
      break
   }
   bind $wn.f2.text <B1-Motion> {
      set newtag [%W tag names @%x,%y]
      if {$newtag != $tagname && $newtag != ""} { 
         help_update_browse [winfo toplevel %W] %x %y
      }
      break
   }

   scrollbar $wn.f1.scroll -command "$wn.f1.text yview"
   scrollbar $wn.f2.scroll -command "$wn.f2.text yview"
   button $wn.ok -text OK -width 10 -command "destroy $wn"

   set linecnt 0
   $wn.f2.text configure -tabs {1c 8c}
   for {set i 0} {$i < [llength $topics]} {} {
      set topic [lindex $topics $i]
      for {set ic 0; set line1 ""} {$ic<$help_lev($appname,$topic)} {incr ic} {
      	append line1 "   "
      }
      append line1 $topic
      #set line1 [string trimleft $topic "$appname,"]
      regsub -all " +" $topic "___" tag1
      set tag1 "$appname,$tag1"

      if {$line1 != ""} {
         $wn.f2.text insert end "\t" "" "$line1" "$tag1"
         $wn.f2.text tag bind $tag1 <1> {
            help_update_browse [winfo toplevel %W] %x %y
         }
         $wn.f2.text tag bind $tag1 <Double-1> "
            help_activate_browse \[winfo toplevel %W\] $appname
         "
         # $wn.f2.text tag configure $tag1 -borderwidth 2 -relief raised
         incr i
      }
      set curpos [lindex [split [$wn.f2.text index insert] .] 1]
      if {$curpos <= 35} {
         set topic [lindex $topics $i]
      for {set ic 0; set line2 ""} {$ic<$help_lev($appname,$topic)} {incr ic} {
      	append line2 "   "
      }
      append line2 $topic
         #set line2 [string trimleft $topic "$appname,"]
         regsub -all " +" $topic "___" tag2
	 set tag2 "$appname,$tag2"
         if {$line2 != ""} {
            $wn.f2.text insert end "\t" "" "$line2" "$tag2" "\n"
            $wn.f2.text tag bind $tag2 <1> {
               help_update_browse [winfo toplevel %W] %x %y
            }
            $wn.f2.text tag bind $tag2 <Double-1> "
               help_activate_browse \[winfo toplevel %W\] $appname
            "
            incr i
         }
         # $wn.f2.text tag configure $tag2 -borderwidth 2 -relief raised
      } else {
         $wn.f2.text insert end "\n"
      }
      incr linecnt
   }
   # remove the extra \n at the bottom of the screen
   $wn.f2.text delete insert
   $wn.f2.text configure -state disabled
   incr linecnt -1

   pack $wn.ok        -side bottom -padx 4 -pady 4
   pack $wn.f1.text   -side left
   pack $wn.f2.text   -side left
   # pack $wn.f1.scroll -side left -fill y
   if {$linecnt > 12} {
      pack $wn.f2.scroll -side left -fill y
   }
   pack $wn.f1        -side top -anchor nw
   pack $wn.f2        -side top -anchor nw
}

# Procedure Name:   help_update_browse
#        Purpose:   obtain the tag value under the cursor and display
#                   update the help text in the browser window
#         Inputs:   the current window
#                   current x position
#                   current y position
#      Variables:   help_txt - array indexed by 'topic' containing the help text
#                   tagname - the current tag value.  used to obtain the
#                             appropriate help entry
proc help_update_browse {win x y} {
   global help_txt tagname

   set text2 $win.f2.text

   selection clear -displayof $win

   # grab the default background color
   set bgcolor [$text2 cget -background]

   $text2 tag configure $tagname -backgr $bgcolor -relief flat
   set tagname [$text2 tag names @$x,$y]
   $text2 tag configure $tagname -backgr grey75 -relief raised -borderwidth 1
}

proc help_activate_browse {win appname} {
   global help_txt tagname

   set text1 $win.f1.text
   set text2 $win.f2.text
   set appname [lindex [split $tagname ,] 0]
   set item [string trim [$text2 get $tagname.first $tagname.last]]

   if {$item != ""} {
      $text1 configure -state normal
      $text1 delete 1.0 end
      $text1 insert 1.0 "$item\n"
      $text1 insert 2.0 "\n[string trim $help_txt($appname,$item)]\n"
      $text1 tag add heading 1.0 2.0
      $text1 tag configure heading -foreground blue
      $text1 configure -state disabled
      if {[lindex [split [$text1 index insert] .] 0] > 24} {
         pack .browse.f1.scroll -side left -fill y
      } else {
         pack forget .browse.f1.scroll
      }
   }
}

# Procedure Name:   init_help
#        Purpose:   initialize global variables, build index list
#         Inputs:   appname   - unique application name to which we want help
#                   help file - index listing
#                   help file - text
#                   NOTE: these need to be full paths to the files!
#      Variables:   help_txt - array indexed by 'topic' containing the help text
proc init_help {appname idxfile txtfile {debug 0} } {
   global help_txt help_lev help_debugging

   help_init_help_idx   $appname $idxfile
   help_init_help_array $appname $txtfile
   set help_debugging $debug

   set help_txt($appname,HELP) "
You can get online context-sensitive help for any widget, menu, button,
or field by placing the cursor on top of the widget and pressing F1.
This will display a help window for the item.

You can browse the online help by choosing the \"Browse Help\" item from
the Help menu.  This will display a list of help entries and allow you to
view the text associated with the entries."
	set help_lev($appname,HELP) 0
}


proc isolate_widget { w {level 0} }   {

	global isolation

	if {!$level}  {
		if {[info exists isolation]}  {
			foreach widget $isolation  {
				pack $widget
			}
			unset isolation
			return
		} else {
			wm minsize [winfo toplevel $w] [winfo width $w] [winfo height $w]
		}
	}

	if {[winfo toplevel $w] == $w}  { return }

	set parent [winfo parent $w]

	foreach child [winfo children $parent]  {
		if {[string compare $child $w]}  {
			pack forget $child
			lappend isolation $child
		}
	}

	incr level
	isolate_widget $parent $level

}
