
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

######
###### docutils.tcl
######
###### this file contains functions to automate the process of
###### generating docfmt compatible help files.
######

# $Id: docutils.tcl,v 1.1 1996/11/06 16:07:14 jasonm Exp $
# $Log: docutils.tcl,v $
# Revision 1.1  1996/11/06 16:07:14  jasonm
# Initial revision
#

proc doc_heading { text }  {
	set text [string trim $text]
	set length [string length $text]
	append text "\n"
	for {set i 0} {$i < $length} {incr i}  {
		append text "="
	}
	append text "\n"
	return $text
}

proc doc_subheading { text }  {
	set text [string trim $text]
	set length [string length $text]
	append text "\n"
	for {set i 0} {$i < $length} {incr i}  {
		append text "-"
	}
	append text "\n"
	return $text
}

proc doc_subsubheading { text }  {
	set text [string trim $text]
	set length [string length $text]
	append text "\n"
	for {set i 0} {$i < $length} {incr i}  {
		append text "."
	}
	append text "\n"
	return $text
}


proc doc_pagebreak { }  {
	set text ""
	for {set i 0} {$i < 45} {incr i}  {
		append text "="
	}
	append text "\n"
	return $text
}

proc doc_ignore { text }  {
	set ignore ""
	for {set i 0} {$i < 45} {incr i}  {
		append ignore "-"
	}
	return "$ignore\n$text\n$ignore\n"
}
