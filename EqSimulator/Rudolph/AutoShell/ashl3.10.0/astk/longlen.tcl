
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: longlen.tcl,v 1.1 1996/08/27 16:14:47 karl Exp $
# $Log: longlen.tcl,v $
# Revision 1.1  1996/08/27 16:14:47  karl
# Initial revision
#
###
### longlen.tcl 
###
### finds the longest length string in a list of strings
### and returns the length of that string
###
### input  : a list of strings
### output : the length of the longest string in input
###
### Last edited:    02/28/96     14:15
###          by:    Guy M. Saenger
###
########
proc longestLength {strings} \
{
   set length 0
   foreach string $strings \
   {
      if {[string length $string] >  $length} \
         { set length [string length $string] }
   }
   return $length
}
########
