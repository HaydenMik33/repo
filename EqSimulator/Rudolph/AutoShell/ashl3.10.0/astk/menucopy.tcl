
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: menucopy.tcl,v 1.1 1996/08/27 16:15:16 karl Exp $
# $Log: menucopy.tcl,v $
# Revision 1.1  1996/08/27 16:15:16  karl
# Initial revision
#
### 
### menucopy.tcl
###
### copies entries from one menu to another
###
### input  : from menu, to menu
### output : none
###
### example:
### menuCopy $frommenu $tomenu
###
### Last edited:    03/27/96     14:48
###          by:    Guy M. Saenger
###      action:    added ability to copy nested cascaded menus 
###
### Last edited:    02/28/96     14:15
###          by:    Guy M. Saenger
###
########
proc menuCopy {from to font} \
{
   menu $to -font $font -tearoff false

   set count [$from index end]
   if {$count == "none"} { return }
   for {set i 0} {$i <= $count} {incr i} \
   {
      set type    [$from type $i]
      set options [$from entryconfigure $i]
      $to add $type
      foreach optlist $options \
      {
         set opt [lindex $optlist 0]
         if {$opt == "-menu"} \
         {
            set menuname [winfo name [$from entrycget $i $opt]]
            menuCopy $from.$menuname $to.$menuname $font
            $to entryconfigure $i $opt $to.$menuname
         }
         if {$opt != "-menu"} \
         {
            set val [$from entrycget $i $opt]
            $to entryconfigure $i $opt $val
         }
      }
   }
}
########
