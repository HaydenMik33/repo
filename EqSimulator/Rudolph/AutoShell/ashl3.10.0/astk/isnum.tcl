
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: isnum.tcl,v 1.1 1996/08/27 16:14:32 karl Exp $
# $Log: isnum.tcl,v $
# Revision 1.1  1996/08/27 16:14:32  karl
# Initial revision
#
###
### isnum.tcl 
###
### determines if a string is a number
### supports numbers preceded by + or -
### (supports only integers right now)
###
### input  : a string value
### output : 1 if string is a number, 0 if not
###
### examples:	
### puts [isNum "10"]   
### --> 1
### puts [isNum "hello"]
### --> 0
### puts [isNum "-5"]
### --> 1
###
### Last edited:    02/28/96     14:15
###          by:    Guy M. Saenger
###
########
proc isNum {value} \
{
   if {[regexp {^0$} $value]} { return 1 }
   if {[regexp {^[1-9][0-9]*$} $value]} { return 1 }
   if {[regexp {^\-[1-9][0-9]*$} $value]} { return 1 }
   if {[regexp {^\+[1-9][0-9]*$} $value]} { return 1 }
   return 0
}
########
