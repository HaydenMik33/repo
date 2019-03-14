
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: colorselect.tcl,v 1.3 1999/06/04 18:58:59 justin Exp $
# $Log: colorselect.tcl,v $
# Revision 1.3  1999/06/04 18:58:59  justin
# Added recovery for user clicking cancel, sends original colors back now
#
# Revision 1.1  1996/08/27  16:10:27  karl
# Initial revision
#
#
# This command returns the color for use in tcl scripts
#
# It creates a toplevel window that contains the color selection
# mechanism. The name of the toplevel window is a required argument.
# the first item in the args list will be used as the title
# of the toplevel window if given.

proc colorselect { w args }  {
	
    set geometry "+[winfo pointerx .]+[winfo pointery .]"

	if {[catch {toplevel $w}]} { return }
	if {$args != ""}  {
		wm title $w [lindex $args 0]
	} else {
		wm title $w "Color Selection"
	}
    wm geometry $w $geometry

	set win [string range $w 1 end]
	global colorsel,$win
	set colorsel,$win 0
	
	set c [frame $w.colors -relief groove -bd 2]
	scale $c.red -label Red -from 0 -to 255 -length 10c \
		-orient horizontal -command "colorsel_newColor $win $c"
	scale $c.green -label Green -from 0 -to 255 -length 10c \
		-orient horizontal -command "colorsel_newColor $win $c"
	scale $c.blue -label Blue -from 0 -to 255 -length 10c \
		-orient horizontal -command "colorsel_newColor $win $c"
	frame $c.sample -height 1.5c -width 6c
	pack $c.red $c.green $c.blue -side top
	pack $c.sample -side top -pady 2m
	frame $w.butts -relief groove -bd 2
	set b [frame $w.butts.b]
	button $b.ok -text "OK" -command "set colorsel,$win 1; destroy $w"
	button $b.cancel -text "Cancel" -command "destroy $w"
	pack $b.ok $b.cancel -side left -padx 5 -pady 5
	pack $b
	pack $w.colors -side top -padx 4 -pady 2
	pack $w.butts -side top -padx 4 -pady 2 -fill x
	
	tkwait window $w

	if { [set colorsel,$win] }  {
		global color,$win
		return [set color,$win]
	}

}

proc colorsel_newColor { win f value }  {
	
	set color [format #%02x%02x%02x [$f.red get] [$f.green get] \
				   [$f.blue get]]
	$f.sample config -background $color

	global color,$win
	set color,$win $color
	
}


proc colorsel_AcceptSelection { } {
   puts [format #%02x%02x%02x [.red get] [.green get] [.blue get]]
   exit
}


##############
#
#
#   Slider Color select
#   ver= 1.0
#   aut= Justin Tervooren
#   date= 05/14/99 
#
#   This TCL will take a  procedure call in the form of "colorselect $args" where arg0
#	it the title for the color selection window, and args1-X are colors to be set
#	for each arg it will make a selection window and place the correspoiding R-G-B
# 	values into a global variable with the name coloroptions($argname,R), coloroptions($argname,G)
#	coloroptions($argname,B), and coloroptions($argname,NAME) for any name value the user inputted
#################


#################
#
#  proc sli_colorselect
#
#  DESC: This proc will generate a color selection subwindow for each argument
#
#################
proc sli_colorselect { w args }  {
	global coloroptions btn

    set geometry "+[winfo pointerx .]+[winfo pointery .]"
	if {[catch {toplevel $w}]} { return }
	if {$args != ""}  {
		wm title $w [lindex $args 0]
	} else {
		wm title $w "Color Selection"
	}
    wm geometry $w $geometry

	set win [string range $w 1 end]
	global colorsel,$win
	set colorsel,$win 0
        set scales [lrange $args 1 end]
  	set scales [lindex $scales 0]
        set scalesbak $scales
        foreach item $scales {
         # If default values exist set them 

          set element [lindex $item 0]
          set colors [lindex $item 1]
          set coloroptions($element,Name) $colors
  	  if {[string range $colors 0 0]!="#"} {						
			       set win2 "."
                 	       append win2 $win
		               set rgbcolors [winfo rgb $win2 $coloroptions($element,Name)]
			       set R [string range $rgbcolors 0 [expr [string first " " $rgbcolors] -1]]
			       set rgbcolors [string range $rgbcolors [expr [string first " " $rgbcolors] +1] end]
			       set G [string range $rgbcolors 0 [expr [string first " " $rgbcolors] -1]]
			       set rgbcolors [string range $rgbcolors [expr [string first " " $rgbcolors] +1] end]
			       set B [string trim $rgbcolors]
   			       # Configure colors to 255 level mode.  
   			       set R [expr $R / 256]
		  	       set G [expr $G / 256]
			       set B [expr $B / 256]
			       set R [format %02x $R]
			       set G [format %02x $G]
			       set B [format %02x $B]
			       set colors "#"
			       append colors $R	 
			       append colors $G
			       append colors $B 
          }
	 		
          set colors [string trimleft $colors "#"]
          set coloroptions($element,R) "0x"
  	  append coloroptions($element,R) [string range $colors 0 1]
          set coloroptions($element,G) "0x"
    	  append coloroptions($element,G) [string range $colors 2 3]
          set coloroptions($element,B) "0x"
          append coloroptions($element,B) [string range $colors 4 5]
          set coloroptions($element,R) [format %i $coloroptions($element,R)]
          set coloroptions($element,G) [format %i $coloroptions($element,G)]
          set coloroptions($element,B) [format %i $coloroptions($element,B)]
	         
	  set c [frame $w.$element -relief groove -bd 2]          
	  label $c.title  -text "$element\n"
          frame $c.scl1
          frame $c.scl2
          frame $c.scl3
	  label $c.scl1.entry -text "R"
   	  scale $c.scl1.red -from 0 -to 255 -length 2c -orient vertical -variable coloroptions($element,R) -command "sli_colorsel_newColor $win $c"					     
	  label $c.scl2.entry -text "G"							     
	  scale $c.scl2.green -from 0 -to 255 -length 2c -orient vertical -command "sli_colorsel_newColor $win $c" -variable coloroptions($element,G)
	  label $c.scl3.entry -text "B"
	  scale $c.scl3.blue -from 0 -to 255 -length 2c -orient vertical -command "sli_colorsel_newColor $win $c" -variable coloroptions($element,B)
          frame $c.right
          entry $c.right.entry  -width 9 -textvariable coloroptions($element,NAME)
	  frame $c.right.sample -height 1.5c -width 2c
          label $c.right.title  -text ""
          pack $c.right.sample -side top
 	  pack $c.right.title  $c.right.entry -side left
	  pack $c.title -side top
	  pack $c.scl1.entry $c.scl1.red
	  pack $c.scl2.entry $c.scl2.green
	  pack $c.scl3.entry $c.scl3.blue
	  pack $c.scl1 $c.scl2 $c.scl3 -side left
	  pack $c.right  -side top -pady 2m
	  pack $w.$element -side top -padx 4 -pady 2

          bind $c.right.entry <Return> {
				 global coloroptions
				 set inwin %W
			 	 set element2 [string trimright %W ".right.entry"]
				 set element2 [string trimleft $element2 ".color."]
				 set coloroptions($element2,NAME) [%W get]
				 update_sliders $element2 $inwin 
			}
          }
          bind .color <Return> {
			         set me [%W get]
 	  }
 	  frame $w.butts -relief groove -bd 2
	  set b [frame $w.butts.b]
          set btn "" 
  	  button $b.ok -text "OK" -command " destroy $w; set btn \"ok\""
	  button $b.cancel -text "Cancel" -command "destroy $w; set btn \"cancel\""
	  pack $b.ok $b.cancel -side left -padx 5 -pady 5
	  pack $b	
 	  pack $w.butts -side top -padx 4 -pady 2 -fill x
          tkwait variable btn

  	  if {$btn=="ok"}  {
		set colorlist [color_return $scales] 
		return $colorlist
  	  } else {
		return $scalesbak
	  }
}

#################
#
#  proc sli_colorsel_newColor
#
#  DESC: This proc will update the demo color widget
#
#################

proc sli_colorsel_newColor { win f value }  {
	
	set color [format #%02x%02x%02x [$f.scl1.red get] [$f.scl2.green get] \
				   [$f.scl3.blue get]]
	$f.right.sample config -background $color
        $f.right.entry delete 0 end
        $f.right.entry insert 0 $color
	global coloroptions
        set var [string trimleft $f ".color."]
	set coloroptions($var,name) $color

}

proc sli_colorsel_AcceptSelection { } {
   puts [format #%02x%02x%02x [.scl1.red get] [.scl2.green get] [.scl3.blue get]]
   exit
}

#################
#
#  proc update_sliders
#
#  DESC: This proc will update the sliders when a user enters a name
#
#################

proc update_sliders {element win} {
   global coloroptions

   # Catch incase of invalid color name
     catch {
       set rgbcolors [winfo rgb $win $coloroptions($element,NAME)]     
       set highwin [string trimright $win "entry"] 	
       set R [string range $rgbcolors 0 [expr [string first " " $rgbcolors] -1]]
       set rgbcolors [string range $rgbcolors [expr [string first " " $rgbcolors] +1] end]
       set G [string range $rgbcolors 0 [expr [string first " " $rgbcolors] -1]]
       set rgbcolors [string range $rgbcolors [expr [string first " " $rgbcolors] +1] end]
       set B [string trim $rgbcolors]
       # Configure colors to 255 level mode.  
       set R [expr $R / 256]
       set G [expr $G / 256]
       set B [expr $B / 256]
       set coloroptions($element,R) $R 
       set coloroptions($element,G) $G
       set coloroptions($element,B) $B
       set coloroptions($element,L) [list $R $G $B]        
       append highwin "sample"
       $highwin config -background $coloroptions($element,NAME)
     }	
}

#################
#
#  proc color_return
#
#  DESC: This proc will return a list of selected colors
#
#################

proc color_return {scales} {
       global coloroptions
       set colorlist ""
       foreach item $scales {
         set element [lindex $item 0]          
         set colors [lindex $item 1]
	 set colors $coloroptions($element,NAME)
         set element_list [list $element $colors]
         append colorlist [list $element_list]
         append colorlist " "
       }
       return $colorlist
}
