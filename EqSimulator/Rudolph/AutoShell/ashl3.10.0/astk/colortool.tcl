
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: colortool.tcl,v 1.1 1996/08/27 16:10:09 karl Exp $
# $Log: colortool.tcl,v $
# Revision 1.1  1996/08/27 16:10:09  karl
# Initial revision
#
#!/opt/misc/bin/wish
### 
### colortool.tcl
###
### A popup color chooser.
###
### input  : none
### output : none
###
### example:
### set color [colorTool]
###
### Last edited:    04/30/96     09:15
###          by:    Guy M. Saenger
###
########
proc colorTool {} \
{
   global color rgblist r g b __button__

   # create the toplevel window for the tool
   toplevel .t
   wm title .t "Color Tool"

   # set initial color shown to black
   set color black
   set r     0
   set g     0
   set b     0

   # create a left and right frame in the window
   frame .t.left
   pack  .t.left  -side left
   frame .t.right
   pack  .t.right -side right

   # pack the RGB scale for each value
   foreach rgb {r g b} \
   {
      # frame for slider
      frame .t.left.$rgb
      pack  .t.left.$rgb -padx 2m 

      # slider
      scale .t.left.$rgb.scale -from 0 -to 255 -font 6x13 -variable $rgb \
          -orient horizontal -sliderlength 10 -width 5 
      pack .t.left.$rgb.scale -side left

      # hex vals and label of slider
      label .t.left.$rgb.label -text [string toupper $rgb] -font 6x13
      pack  .t.left.$rgb.label -side left
      label .t.left.$rgb.hex   -text [format "0x%02x" [subst \$$rgb]] -font 6x13
      pack  .t.left.$rgb.hex   -side left

      # bind the motion of the scale to update text and box color
      bind .t.left.$rgb.scale <B1-Motion> \
      {
         set slider [winfo parent %W]
         set rgb    [lindex [split $slider .] 3]
         $slider.hex configure -text [format "0x%%02x" [subst \$$rgb]]
         .t.right.canvas configure -bg #[format "%%02x%%02x%%02x" $r $g $b]
      }

      # bind release of the scale to update text and color in box
      bind .t.left.$rgb.scale <ButtonRelease-1> \
      {
         # by default, set color to hex vals
         set slider [winfo parent %W]
         set rgb    [lindex [split $slider .] 3]
         $slider.hex configure -text [format "0x%%02x" [subst \$$rgb]]
         set match "#[format %%02x%%02x%%02x $r $g $b]"

         # see if there is a name for the color
         foreach clr [array names rgblist] \
         {
            if {$rgblist($clr) == "$r $g $b"} \
            { 
               set match $clr 
               if {![regexp {[0-9]} $clr]} { break }
            }
         }
         set color $match
      }
   }

   # show the buttons
   frame  .t.left.buttons
   pack   .t.left.buttons -pady 2m
   button .t.left.buttons.ok     -text OK     -font 6x13 \
      -command { set __button__ ok }
   pack   .t.left.buttons.ok     -side left -padx 1m
   button .t.left.buttons.cancel -text Cancel -font 6x13 \
      -command { set __button__ cancel }
   pack   .t.left.buttons.cancel -side left -padx 1m

   # show the canvas and its entry label
   canvas .t.right.canvas -bg $color -width 100 -height 100 -relief ridge -bd 4
   pack   .t.right.canvas -padx 2m -pady 1m 
   entry  .t.right.entry -font 6x13 -justify center -textvariable color
   pack   .t.right.entry  -padx 2m -pady 1m

   # bind the entry to update color based on input text
   bind .t.right.entry <Return> \
   { 
      if {[array names rgblist [%W get]] == {}} \
      {
         if {![winfo exists .t.listwin]} \
         {
            global list_okay

            toplevel .t.listwin 
            wm title .t.listwin "Color List"

            frame .t.listwin.list
            listbox .t.listwin.list.box -font 6x13 -selectmode single \
               -yscrollcommand ".t.listwin.list.bar set"
            scrollbar .t.listwin.list.bar -command ".t.listwin.list.box yview"
            pack .t.listwin.list
            pack .t.listwin.list.box -side left
            pack .t.listwin.list.bar -side right -fill y
            pack .t.listwin.okay

            button  .t.listwin.okay -text OK -font 6x13 -command \
            {
               set list_okay [.t.listwin.list.box get \
                  [.t.listwin.list.box curselection]]
               wm withdraw .t.listwin
            }

            foreach clr [lsort [array names rgblist]] \
            {
               .t.listwin.list.box insert end $clr
            }
         }

         set list_okay ""
         wm deiconify .t.listwin
         tkwait variable list_okay
         set color $list_okay
         unset list_okay
      }

      if {[%W get] != ""} \
      { 
         .t.right.canvas configure -bg $color
         set r [lindex $rgblist($color) 0]
         set g [lindex $rgblist($color) 1]
         set b [lindex $rgblist($color) 2]
         .t.left.r.hex configure -text [format "0x%%02x" $r]
         .t.left.g.hex configure -text [format "0x%%02x" $g]
         .t.left.b.hex configure -text [format "0x%%02x" $b]
      }
      break;
   }

   # update the window so that it shows up now
   update

   # read all color info from showrgb command
   set fd [open "|showrgb" "r"]
   set rgbvals [gets $fd]
   while {![eof $fd]} \
   {
      regsub -all " +" [lrange $rgbvals 0 2] " " rgb
      set rgblist([lrange $rgbvals 3 end]) [string trimleft $rgb]
      set rgbvals [gets $fd]
   }
   close $fd

   # wait for button press
   grab   .t
   focus  .t
   tkwait variable __button__

   # set return color value
   if {$__button__ == "ok"}     { set retval $color }
   if {$__button__ == "cancel"} { set retval "" }

   # clear globals, destroy toplevel, and return color chosen
   destroy .t
   unset r g b rgblist __button__ color
   return $retval
}
########
