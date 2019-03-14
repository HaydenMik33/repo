
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: lrev.tcl,v 1.1 1996/08/27 16:15:02 karl Exp $
# $Log: lrev.tcl,v $
# Revision 1.1  1996/08/27 16:15:02  karl
# Initial revision
#
###
### lrev.tcl 
###
### reverses the order of the elements in a list 
### and returns the reversed list
###
### input  : a list 
### output : a list
###
### Last edited:    02/28/96     14:15
###          by:    Guy M. Saenger
###
########
proc lrev {list} \
{
   set revlist ""
   foreach item $list { set revlist [linsert $revlist 0 $item] }
   return $revlist
}
########
