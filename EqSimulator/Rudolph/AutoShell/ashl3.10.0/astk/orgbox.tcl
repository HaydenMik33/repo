
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: orgbox.tcl,v 1.1 1996/08/27 16:15:53 karl Exp $
# $Log: orgbox.tcl,v $
# Revision 1.1  1996/08/27 16:15:53  karl
# Initial revision
#
###
### orgbox.tcl 
###
### shows a popup box with a list of items that can be reorganized by
### drag and drop of the items.  Window list can be returned by pressing
### <RETURN> key; window can be cancelled by pressing <ESCAPE> key
###
### globals: (all unset before return)
### __button__ - used for catching the button pressed
###
### input  : name of window, list choices
### output : reorganized list choices
###
### optional arguments:  (all must be prefixed by a hyphen, eg. -x, -y)
### x	       - horizontal screen location to put box (value can be "center")
### y          - vertical   screen location to put box (value can be "center")
### mesg       - text message to display in box
### width      - the width of the list box
### height     - the height of the list box
### scrollable - whether the box is scrollable
### title      - title of the choice box window
### font       - font to show text and button labels in
### justify    - way the text message should be justified
###  
### example:
### set list [orgBox .org $list -mesg "Org List" \
###    -title "Org Listbox Example" -justify left -font 6x13]
###
### Last edited:    03/28/96     13:22
###          by:    Guy M. Saenger
###
########
proc orgBox {name items args} \
{
   global __button__

   set orgboxopts "x y mesg title font justify height width scrollable"
 
   # get the options passed to box
   foreach opt $orgboxopts \
   {
      set index [lsearch $args "-$opt"]
      if {$index == -1} { set $opt $index }
      if {$index != -1} { set $opt [lindex $args [expr $index + 1]] }
   }
 
   # create the window
   set win $name; if {$name == "."} { set name "" }
   if {! [winfo exists $win]} { toplevel $win }
   wm resizable $win false false
   if {$title != "-1"} { wm title $win $title }
   
   # put the message into the window
   label $name.mesg 
   pack  $name.mesg -padx 2m -pady 1m
   if {$justify != "-1"} { $name.mesg configure -justify $justify }
   if {$mesg    != "-1"} { $name.mesg configure -text $mesg }
   if {$font    != "-1"} { $name.mesg configure -font $font }

   # put the listbox of choice in window 
   frame $name.box
   pack  $name.box -padx 2m -pady 1m
   listbox $name.box.list -yscrollcommand "$name.box.scroll set"
   scrollbar $name.box.scroll -command "$name.box.list yview"
   if {$font   != "-1"} { $name.box.list configure -font $font     }
   if {$height != "-1"} { $name.box.list configure -height $height }
   if {$width  != "-1"} { $name.box.list configure -width $width   }
   pack $name.box.list   -side left
   if {$scrollable != "-1"} { pack $name.box.scroll -side left -fill y }
   foreach item $items { $name.box.list insert end $item }

   # create the buttons used in the dialog window
   frame $name.buttons
   pack  $name.buttons
   button $name.buttons.okay   -text "OK"     -width 6 \
      -command "set __button__ okay"
   button $name.buttons.cancel -text "Cancel" -width 6 \
      -command "set __button__ cancel"
   pack   $name.buttons.okay   -side left
   pack   $name.buttons.cancel -side left
   if {$font != "-1"} { $name.buttons.okay   configure -font $font }
   if {$font != "-1"} { $name.buttons.cancel configure -font $font }

   # set positioning of window
   wm withdraw $win
   update idletasks
   if {$x == -1 && $y != -1} { set x 0 }
   if {$x != -1 && $y == -1} { set y 0 }
   if {$x == "center"} \
   {
      set x [expr [winfo screenwidth $win]/2 - \
            [winfo reqwidth $win]/2 - \
            [winfo vrootx [winfo parent $win]]]
   }
   if {$y == "center"} \
   {
      set y [expr [winfo screenheight $win]/2 - \
            [winfo reqheight $win]/2 - \
            [winfo vrooty [winfo parent $win]]]
   }
   if {$x != -1 && $y != -1} { wm geometry $win +$x+$y }
   wm deiconify $win

   # make some key bindings
   bind $win <Return> { set __button__ okay   }
   bind $win <Escape> { set __button__ cancel }

   # make listbox bindings
   bind $name.box.list <1> \
   {
      set oldidx [%W index @%x,%y]
   }
   bind $name.box.list <B1-Motion> \
   {
      set newidx [%W index @%x,%y]
      if {$newidx == $oldidx} { break }
      set text  [%W get $oldidx]
      %W delete $oldidx $oldidx
      %W insert $newidx $text
      set oldidx $newidx
   }

   # wait for button or key bindings
   grab   $win
   tkwait variable __button__

   # get organized items
   if {$__button__ == "okay"} \
      { set items [$name.box.list get 0 end] }
 
   # unset global, destroy orgbox, and return the item list
   unset __button__
   destroy $win
   return $items
}
########
