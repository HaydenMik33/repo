
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: entrybox.tcl,v 1.1 1996/08/27 16:13:16 karl Exp $
# $Log: entrybox.tcl,v $
# Revision 1.1  1996/08/27 16:13:16  karl
# Initial revision
#
###
### entrybox.tcl 
###
### shows a popup box with a message, entry field, and button choices
### window can be accepted  by pressing <RETURN> key or "OK" button
### window can be cancelled by pressing <ESCAPE> key or "Cancel" button
###
### globals: (all unset before return)
### __button__ - used for catching the button pressed
### __entry__  - text typed into entry field
###
### input  : name of window and optional arguments
### output : text in entry field, or -1 if cancel
###
### optional arguments:  (all must be prefixed by a hyphen, eg. -x, -y)
### x	    - horizontal screen location to put box
### y       - vertical screen location to put box
### mesg    - text message to display in box
### title   - title of the dialog box window
### font    - font to show text and button labels in
### value   - initial text placed in entry
### wrap    - distance at which the text message should wrap
### justify - way the text message should be justified
### ewidth  - width of the entry widget
###  
### example:
### set entrytext [entryBox .entry -x 10 -y 100 \
###    -title "Entry Box Example" -wrap 3i -justify left -font 6x13 \
###    -mesg "This is a just a entry box example"]
###
### Last edited:    04/08/96     15:25
###          by:    Guy M. Saenger
###      action:    fixed tabbing among widgets
###                 made bindings only on entry
###
###
### Last edited:    02/28/96     14:15
###          by:    Guy M. Saenger
###
########
proc entryBox {name args} \
{
   global __button__ __entry__

   set entryboxopts "x y mesg title font value wrap justify ewidth"

   # get the options passed to box
   foreach opt $entryboxopts \
   {
      set index [lsearch $args "-$opt"]
      if {$index == -1} { set $opt $index }
      if {$index != -1} { set $opt [lindex $args [expr $index + 1]] }
   }

   # create the window
   set geometry "+[winfo pointerx .]+[winfo pointery .]"
   toplevel $name
   wm geometry $name $geometry
   wm resizable $name false false
   if {$title != "-1"} { wm title $name $title }
 
   # put the message and entry blank into the window
   label $name.label
   entry $name.entry -textvariable __entry__
   pack  $name.label -side top -padx 2m -pady 1m
   pack  $name.entry -side top -padx 2m -pady 1m
   if {$wrap    != "-1"} { $name.label configure -wrap $wrap }
   if {$justify != "-1"} { $name.label configure -justify $justify }
   if {$mesg    != "-1"} { $name.label configure -text $mesg }
   if {$font    != "-1"} { $name.label configure -font $font }
   if {$font    != "-1"} { $name.entry configure -font $font }
   if {$ewidth  != "-1"} { $name.entry configure -width $ewidth }
   if {$value   != "-1"} { set __entry__ $value }

   # pack the buttons into the window   
   frame $name.buttons
   pack  $name.buttons
   frame $name.buttons.def -relief sunken -bd 1
   button $name.buttons.okay   -text "OK" -command "set __button__ okay"
   frame $name.buttons.other
   button $name.buttons.cancel -text "Cancel" -command "set __button__ cancel"
   if {$font != "-1"} { $name.buttons.okay   configure -font $font }
   if {$font != "-1"} { $name.buttons.cancel configure -font $font }
   pack  $name.buttons.def -side left -expand 1 -padx 1m -pady 1m
   pack  $name.buttons.okay -in $name.buttons.def -padx 1m -pady 1m
   pack  $name.buttons.other -side left -expand 1 -padx 1m -pady 1m
   pack  $name.buttons.cancel -in $name.buttons.other -padx 1m -pady 1m
   raise $name.buttons.okay $name.buttons.def

   # set positioning of window
   wm withdraw $name
   update idletasks
   if {$x == -1 && $y != -1} { set x 0 }
   if {$x != -1 && $y == -1} { set y 0 }
   if {$x == "center"} \
   {
      set x [expr [winfo screenwidth $name]/2 - \
            [winfo reqwidth $name]/2 - \
            [winfo vrootx [winfo parent $name]]]
   }
   if {$y == "center"} \
   {
      set y [expr [winfo screenheight $name]/2 - \
            [winfo reqheight $name]/2 - \
            [winfo vrooty [winfo parent $name]]]
   }
   if {$x != -1 && $y != -1} { wm geometry $name +$x+$y }
   wm deiconify $name

   # make some key bindings
   bind $name.entry <Return> { set __button__ okay }
   bind $name.entry <Escape> { set __button__ cancel }

   # wait for button or key bindings
   grab   $name
   focus  $name.entry
   tkwait variable __button__

   # set entry value
   if {$__button__ == "okay"}   { set entryval $__entry__ }
   if {$__button__ == "cancel"} { set entryval "-1" }

   # clear globals, destroy toplevel, and return entry value
   destroy $name
   unset __button__ __entry__
   return $entryval
}
########
