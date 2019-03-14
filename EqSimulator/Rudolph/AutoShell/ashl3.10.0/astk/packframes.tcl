
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: packframes.tcl,v 1.1 1996/08/27 16:16:17 karl Exp $
# $Log: packframes.tcl,v $
# Revision 1.1  1996/08/27 16:16:17  karl
# Initial revision
#
###
### packframes.tcl
###
### procedure thats takes a list of items and a specified number of items
### to be placed on each row in a parent frame and creates all the frames
### needed to pack the items accordingly
###
### input  : the parent frame to create, a list of objects to be placed inside
###          the parent frame, and the number of items per row in the parent
###          frame
### output : a list of frames created that allow for packing the items into
###          the parent frame with "cols" items per row
###
### example:
### set frames [getPackFrames .checkbuttons "a b c d" 2]
### puts $frames
### --> .checkbuttons.frame1 .checkbuttons.frame2
###
### items can now be packed as follows:
### ____________________________
### |         a     b          | <-- frame1
### |         c     d          | <-- frame2
### ----------------------------
###
### Last edited:    02/28/96     14:15
###          by:    Guy M. Saenger
###
########
proc getPackFrames {parent items cols} \
{
   # initialize frames list
   set frames ""

   # pack the parent frame
   frame $parent
   pack  $parent -padx 4m -pady 4m

   # figure out how many frames are needed
   set numframes [expr ceil([expr [llength $items].0 / $cols.0])]

   # pack all frames needed
   for {set count 0} {$count < $numframes} {incr count} \
   {
      frame $parent.frame$count
      pack  $parent.frame$count -anchor w
      set   frames [linsert $frames end $parent.frame$count]
   }

   # return all frames created
   return $frames
}
