
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: xdrop.tcl,v 1.1 1996/08/27 16:24:05 karl Exp $
# $Log: xdrop.tcl,v $
# Revision 1.1  1996/08/27 16:24:05  karl
# Initial revision
#
###
### xdrop.tcl (must also have entrybox.tcl sourced)
###
### shows a dropdown type widget with an associated list of choices and a
### menu choice to pop open a larger entrybox for editing large strings
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
### xewidth  - width  of the expanded dropdown entry
### bwidth   - width  of the expandable dropdown button
### bheight  - heigth of the expandable dropdown button
###  
### example:
### xdrop .xdrop -label "Drop" -font 6x13 -variable xdropvar -lwidth 10 \
###    -ewidth 13 -choices "none choice1 choice2 default"
###
### Last edited:    02/28/96     14:15
###          by:    Guy M. Saenger
###
########
proc doXdropExpand {name xewidth} \
{
   set value [$name.entry get]
   set label [$name.label cget -text]
   if {$xewidth == "-1"} { set xewidth 30 }
   set value [entryBox .entry -x [winfo pointerx .] -y [winfo pointery .] \
      -title {Expanded Entry} -wrap 3i -mesg "Please enter $label" \
      -ewidth $xewidth -value $value]
   if {$value != "-1"} \
   {
      $name.entry delete 0 end
      $name.entry insert 0 $value
   }
}
########
proc xdrop {name args} \
{
   set    xdropopts "label font lwidth bwidth bheight fill"
   append xdropopts " choices variable ewidth xewidth edit" 

   # get option values
   foreach opt $xdropopts \
   {
      set index [lsearch $args "-$opt"]
      if {$index == -1} { set $opt $index }
      if {$index != -1} { set $opt [lindex $args [expr $index + 1]] }
   }

   # create expandable dropdown frame
   frame $name
   pack  $name -side left

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
   pack  $name.entry -side left
   if {$ewidth   != "-1"} { $name.entry configure -width $ewidth }
   if {$font     != "-1"} { $name.entry configure -font  $font   }

   # create drop button
   if {$bwidth  == -1}  { set bwidth  10 }
   if {$bheight == -1}  { set bheight 10 }
   if {$fill    == -1}  { set fill    black }
   canvas $name.xdb -relief raised -bd 1 -width $bwidth -height $bheight \
      -highlightthickness 0
   pack   $name.xdb -side left
   $name.xdb create polygon 2 2 6 10 10 2 -fill $fill

   # build menu
   if {$choices != -1} \
   {
      set menu $name.xdb.menu
      if {[winfo exists $menu]} { destroy $menu }
      menu $menu -tearoff false
      if {$font != -1} { $menu configure -font $font }

      $menu add command -label expand -command "doXdropExpand $name $xewidth"
      $menu add separator

      foreach choice $choices \
         { $menu add command -label $choice -command "set $variable $choice" }

      bind $name.xdb <1> \
         { tk_popup %W.menu [winfo pointerx .] [winfo pointery .] }
   }
}
########
