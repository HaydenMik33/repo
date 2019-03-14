
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: sp.tcl,v 1.2 1997/12/02 19:31:28 karl Exp $
# $Log: sp.tcl,v $
# Revision 1.2  1997/12/02 19:31:28  karl
# Fixed stack trace caused by unmatched brackets in strex expressions.
#
# Revision 1.1  1996/08/27  16:18:12  karl
# Initial revision
#
# Assumes input is string expression (with surrounding parens)
proc strex_pretty {str} {
	set strlen [string length $str]
	set newstr ""
	set spacestr ""
	set inspace 0
	set indent 0
	set inbigop 0
	#puts "str=$str"
	while {$str!=""} {
	    set ch [string index $str 0]
	    set str [string range $str 1 end]
	    # If whitespace, just store it and go on
	    if {[string first $ch " \t\n"]>=0} {
		set inspace 1
		append spacestr $ch
	    # If non-whitespace ...
	    } else {
		# Are we coming out of whitespace or ending an expression?
		if {$inspace || $ch==")"} {
			#puts "newstr=$newstr inbigop=$inbigop indent=$indent"
			# If we're in a bigop and between operands of it
			if {$inbigop && $inbigop==$indent && $ch!=")"} {
				append newstr "\n"
				for {set cnt 0} {$cnt<$inbigop} {incr cnt} {
					append newstr "   "
				}
			} else {
				append newstr $spacestr
			}
			if {$ch==")"} {
				if {$indent==$inbigop} {
					incr inbigop -1
				}
				incr indent -1
			}
		}
		set inspace 0
		set spacestr ""
	    	switch -- $ch {
		{[} {
			while {$ch!="" && $ch!={]}} {
				append newstr $ch
				set ch [string index $str 0]
				set str [string range $str 1 end]
			}
			append newstr $ch
		}		
		{(} {
			incr indent
			append newstr $ch
			set str [string trimleft $str]
			set op [lindex [split $str] 0]	
			set str [string range $str [string length $op] end]
			set str [string trimleft $str]
			append newstr "$op"
			set spacestr " "
			set inspace 1
			switch -- $op {
			    {&} -
			    {|} {
				set inbigop $indent
			    }
			}
		}
		default {
			append newstr $ch
		}
	    	}
	    }
	}
	return $newstr
}

proc strex_ugly {string} {
	set lenstr [string length $string]
	set inbracket 0
	set newstr ""
	for {set i 0} {$i<$lenstr} {incr i} {
		set ch [string range $string $i $i]
		#puts "char: '$ch'"
		if {$ch=={[}} {
			incr inbracket
			append newstr $ch
		} elseif {$ch=={]}} {
			incr inbracket -1
			append newstr $ch
		} else {
			if {[string first $ch "\t\n "]>=0 && !$inbracket} {
				set newlen [expr [string length $newstr] - 1]
				set prevchar [string range $newstr $newlen \
					$newlen]
				#puts "whitespace outside bracket, prevchar='$prevchar'"
				if {[string first $prevchar "\t\n "]==-1} {
					#puts "needed"
					append newstr " "
				} else {
					#puts "unneeded"
				}
			} else {
				#puts "Normal char or whitespace in bracket"
				append newstr $ch
			}
		}
	} 
	return $newstr
}

#puts [strex_ugly "This  	 	 	is \[ a	\] test"]
#exit
