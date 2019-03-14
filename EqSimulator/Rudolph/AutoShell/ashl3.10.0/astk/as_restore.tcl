
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: as_restore.tcl,v 1.1 1996/08/27 16:07:53 karl Exp $
# $Log: as_restore.tcl,v $
# Revision 1.1  1996/08/27 16:07:53  karl
# Initial revision
#
# This function takes a pointer to an open DV-format file and returns a
# TCL list containing the contents of the file.  
#
# INPUT FILE:
#   a=1
#   b=2
#   { c 
#   	d=10
#   	e=20
#   }
#   { f
#   	g=30
#   	h=40
#   }
#  
# OUTPUT TCL LIST:
#   {a {1 2}}
#   {b 2}
#   {c
#   {d 10}
#   {e 20}
#   }
#   {f
#   {g 30}
#   {h 40}
#   }

# Takes a file pointer as input, to allow reading DVs embedded in file.
proc as_restore {fp} {
	set result ""
	# Read each line.
	while { [gets $fp line] >= 0} {
		# Trim leading and trailing whitespace.
		set line [string trimleft $line]
		# Slurp up continued lines into one line...
		set lastpos [expr [string length $line] - 1]
		while {[string index $line $lastpos] == "\\"} {
			set line [string trimright $line "\\"]
			gets $fp nextline
			set line "$line$nextline"
		}
		# If encountered list end...
		if { $line == "\}" } {
			# Force newline for readability, then copy bracket to
			# TCl list (TCL format is very similar to DVs).
			append result "\n$line"
		# If this line is a variable...
		} else {
			# get location of equal sign name/value separator.
			set equalpos [string first "=" $line]
			# If there was an equal sign (name and value)...
			if {$equalpos >= 0} {
				set name [string range $line 0 \
					[expr $equalpos - 1]] 
				# Delete any whitespace in the var name.
				regsub "\[ \t\n\]+" $name "" name
				set val  [string range $line \
					[expr $equalpos + 1] end]
				# Add the name and value to the TCL list.
				set sublist $name
				lappend sublist $val
				append result "\n{$sublist}"		
				#puts "oldlist={$name {$val}}"
				#puts "sublist={$sublist}"
				#append result "\n{$name {$val}}"		
			# If this was a "name only" DV...
			} else {
				# Delete any whitespace in the variable.
				regsub "\[ \t\n\]+" $line "" line
				append result "\n$line"
			}
		}

	}
	# Return the string we just created to the caller.  This string could
	# be quite large if the file was large. 
	return $result
}
