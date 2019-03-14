
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: drop.tcl,v 1.2 1998/10/20 21:50:46 karl Exp $
# $Log: drop.tcl,v $
# Revision 1.2  1998/10/20 21:50:46  karl
# Fixed entry widget in drop-down to be stretchable.
#
# Revision 1.1  1996/08/27  16:12:10  karl
# Initial revision
#
###
### drop.tcl
###
### shows a dropdown type widget with an associated list of choices 
###
### input  : name of widget and optional arguments
### output : none
###
### optional arguments:  (all must be prefixed by a hyphen, eg. -font, -fill)
### label    - text to show as a label
### font     - font to show text and button labels in
### fill     - color to use for arrow on expandable dropdown button
### variable - variable to use for expandable dropdown entry
### choices  - choices for expandable dropdown list
### lwidth   - width  of the expandable dropdown label
### ewidth   - width  of the expandable dropdown entry
### bwidth   - width  of the expandable dropdown button
### bheight  - heigth of the expandable dropdown button
###  
### example:
### drop .drop -label "Drop" -font 6x13
###    -variable dropvar -lwidth 10 -edit 0
###    -choices "none choice1 choice2 default"
###
### Last edited:    02/28/96     14:15
###          by:    Guy M. Saenger
###
########
proc drop {name args} \
{
   set    dropopts "label font lwidth bwidth bheight"
   append dropopts " edit fill choices variable ewidth" 

   # get option values
   foreach opt $dropopts \
   {
      set index [lsearch $args "-$opt"]
      if {$index == -1} { set $opt $index }
      if {$index != -1} { set $opt [lindex $args [expr $index + 1]] }
   }

   # create expandable dropdown frame
   frame $name
   pack  $name -side left -expand 1 -fill x

   # create labels
   label $name.label
   pack  $name.label -side left
   if {$lwidth != "-1"} { $name.label configure -width $lwidth }
   if {$label  != "-1"} { $name.label configure -text  $label  }
   if {$font   != "-1"} { $name.label configure -font  $font   }

   # create entry
   if {$variable == "-1"} { set variable [lindex [split $name .] end] }
   entry $name.entry -textvariable $variable
   if {$edit == "0"} { bind $name.entry <KeyPress> { break } }
   pack  $name.entry -side left -expand 1 -fill x
   if {$ewidth   != "-1"} { $name.entry configure -width $ewidth }
   if {$font     != "-1"} { $name.entry configure -font  $font   }

   # create drop button
   if {$bwidth  == -1}  { set bwidth  10 }
   if {$bheight == -1}  { set bheight 10 }
   if {$fill    == -1}  { set fill    black }
   canvas $name.db -relief raised -bd 1 -width $bwidth -height $bheight \
      -highlightthickness 0
   pack   $name.db -side left
   $name.db create polygon 2 2 6 10 10 2 -fill $fill

   # build menu
   if {$choices != -1} \
   {
      set menu $name.db.menu
      if {[winfo exists $menu]} { destroy $menu }
      menu $menu -tearoff false
      if {$font != -1} { $menu configure -font $font }

      foreach choice $choices \
         { $menu add command -label $choice -command "set $variable $choice" }

      bind $name.db <1> \
         { tk_popup %W.menu [winfo pointerx .] [winfo pointery .] }
   }
}
########
