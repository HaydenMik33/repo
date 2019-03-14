
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: xentry.tcl,v 1.1 1996/08/27 16:24:21 karl Exp $
# $Log: xentry.tcl,v $
# Revision 1.1  1996/08/27 16:24:21  karl
# Initial revision
#
###
### xentry.tcl (must also have entrybox.tcl sourced)
###
### shows an entry type widget with a button to pop open a larger 
### entrybox for editing large strings
###
### input  : name of widget and optional arguments
### output : none
###
### optional arguments:  (all must be prefixed by a hyphen, eg. -font, -fill)
### label    - text to show as a label
### font     - font to show text and button labels in
### variable - variable to use for expandable entry
### fill     - color to use for X on expandable entry button
### lwidth   - width  of the expandable entry label
### ewidth   - width  of the expandable entry field
### bwidth   - width  of the expandable entry button
### bheight  - heigth of the expandable entry button
###  
### example:
### xentry .xentry -label "Expandable Entry" -font 6x13 -ewidth 15 \
###   -variable xentryvar -lwidth 10
###
### Last edited:    02/28/96     14:15
###          by:    Guy M. Saenger
###
########
proc doXentryExpand {name xewidth} \
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
proc xentry {name args} \
{
   set    xentryopts "label font lwidth bwidth bheight"
   append xentryopts " variable ewidth fill xewidth" 

   # get option values
   foreach opt $xentryopts \
   {
      set index [lsearch $args "-$opt"]
      if {$index == -1} { set $opt $index }
      if {$index != -1} { set $opt [lindex $args [expr $index + 1]] }
   }

   # create xentry frame
   frame $name
   pack  $name -side left

   # create label
   label $name.label
   pack  $name.label -side left
   if {$lwidth != "-1"} { $name.label configure -width $lwidth }
   if {$label  != "-1"} { $name.label configure -text  $label  }
   if {$font   != "-1"} { $name.label configure -font  $font   }

   # create entry
   if {$variable == "-1"} { set variable [lindex [split $name .] end] }
   entry $name.entry -textvariable $variable
   pack  $name.entry -side left
   if {$ewidth   != "-1"} { $name.entry configure -width $ewidth }
   if {$font     != "-1"} { $name.entry configure -font  $font   }
   set value [$name.entry get]

   # create expand button
   if {$bwidth  == -1}  { set bwidth  10 }
   if {$bheight == -1}  { set bheight 10 }
   if {$fill    == -1}  { set fill    black }
   canvas $name.xeb -relief raised -bd 1 -width $bwidth -height $bheight \
      -highlightthickness 0
   pack   $name.xeb -side left
   $name.xeb create line 2 2 9 9 -fill $fill -width 2
   $name.xeb create line 2 9 9 2 -fill $fill -width 2

   bind $name.xeb <1> "doXentryExpand $name $xewidth"
}
########
