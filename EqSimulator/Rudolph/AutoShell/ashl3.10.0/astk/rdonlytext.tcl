
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: rdonlytext.tcl,v 1.1 1996/08/27 16:16:53 karl Exp $
# $Log: rdonlytext.tcl,v $
# Revision 1.1  1996/08/27 16:16:53  karl
# Initial revision
#



#########################################################################
# This procedure modifies the Text class bindings so that all text marked
# with the tag "readonly" will not be modifiable.
# It should be invoked only once at the beginning of the Tk script. 
#########################################################################

##########
###
### To actually make text readonly, it should be given the tag readonly
### in the text widget.
###
##########

proc initReadonlyTextTag {} {

  # modify class bindings that insert or delete text.
  foreach binding [bind Text] {
    
    set bindproc [bind Text $binding]
    
    # disable insertion
    regsub -all "(\[ \t\]*)%W insert (\[^ \]*)" $bindproc {\
\1if {[lsearch [%W tag names \2   ] readonly] >= 0 \&\&
\1    [lsearch [%W tag names \2-1c] readonly] >= 0 \&\&
\1    [%W index \2] != 1.0} break
\0} bindproc
    
    # disable deletion
    regsub -all "(\[ \t\]*)%W delete (\[^\n\]*)" $bindproc {\
\1if {[llength {\2}] == 1} {
\1  if {[lsearch [%W tag names \2] readonly] >= 0} break
\1} else {
\1  if {[%W tag nextrange readonly \2] != {} ||
\1      [lsearch [%W tag names [lindex {\2} 0]] readonly] >= 0} break
\1}
\0} bindproc
    
    # set new binding
    bind Text $binding $bindproc
  }
  
  # modify the procedure tkTextInsert that inserts or deletes text.
	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateCommand tkTextInsert
	}
  set args [info args tkTextInsert]
  set body [info body tkTextInsert]
  
  # disable insertion
  regsub -all "(\[ \t\]*)(\[^ \]*) insert (\[^ \]*)" $body {\
\1if {[lsearch [\2 tag names \3   ] readonly] >= 0 \&\&
\1    [lsearch [\2 tag names \3-1c] readonly] >= 0 \&\&
\1    [\2 index \3] != 1.0} return
\0} body
  
  # disable deletion
  regsub -all "(\[ \t\]*)(\[^ \]*) delete (\[^\n\]*)" $body {\
\1if {[llength {\3}] == 1} {
\1  if {[lsearch [\2 tag names \3] readonly] >= 0} return
\1} else {
\1  if {[\2 tag nextrange readonly \3] != {} ||
\1      [lsearch [\2 tag names [lindex {\3} 0]] readonly] >= 0} return
\1}
\0} body
  
  # replace the procedure with the modified one
  #proc tkTextInsert $args $body
}

