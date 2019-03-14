
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: cutpaste.tcl,v 1.3 1999/08/23 23:03:37 karl Exp $
# $Log: cutpaste.tcl,v $
# Revision 1.3  1999/08/23 23:03:37  karl
# Fixed to take advantage ok TK's cut&paste handling.
#
# Revision 1.2  1999/03/31  15:01:06  jasonm
# added support for cutting text (i.e., text is deleted and placed into
# copy buffer). also, changed so that add_cutpaste can be called with
# no arguments to just setup the ctrl-c,v,x bindings
#
# Revision 1.1  1997/08/26  18:28:36  karl
# Initial revision
#

proc add_cutpaste { {menuname {}} } {

	bind Text <Control-Key-c> cp_copysel
	bind Text <Control-Key-x> cp_cutsel
	bind Text <Control-Key-v> cp_pastecopy

	bind Entry <Control-Key-c> cp_copysel
	bind Entry <Control-Key-x> cp_cutsel
	bind Entry <Control-Key-v> cp_pastecopy

	if {[string length $menuname]}  {
		bind $menuname <Visibility> "cp_enteredmenu $menuname"
		$menuname add command -label "Copy Text" \
			-accelerator "Ctrl-C" \
			-command cp_copysel
		$menuname add command -label "Cut Text" \
			-accelerator "Ctrl-X" \
			-command cp_cutsel
		$menuname add command -label "Paste Text" \
			-accelerator "Ctrl-V" \
			-command cp_pastecopy
	}
}

proc cp_enteredmenu {menuname} {
    if {[catch {selection get}]} {
        $menuname entryconfigure "Copy Text" -state disabled
        $menuname entryconfigure "Cut Text" -state disabled
    } else {
        $menuname entryconfigure "Copy Text" -state normal
        $menuname entryconfigure "Cut Text" -state normal
    }
    if {![catch {selection get -selection CLIPBOARD}]} {
        $menuname entryconfigure "Paste Text" -state normal
    } else {
        $menuname entryconfigure "Paste Text" -state disabled
    }
}


proc cp_copysel {} {
	#puts "inside cp_copysel"
	set selown [selection own]
	#puts "selown=$selown"
	if {$selown!=""} {
		event generate $selown <<Copy>>
	}
}

proc cp_cutsel {} {
	#puts "inside cp_cutsel"
	set selown [selection own]
	#puts "selown=$selown"
	if {$selown!=""} {
		event generate $selown <<Cut>>
	}
}

proc cp_pastecopy {} {
	#puts "inside cp_pastecopy"
	# The code below overrides the default TK behavior that keeps
	# Paste from replacing the current selection on UNIX.  We
	# want it to behave like Windows (replaces current selection 
	# with pasted text).
	set focown [focus]
	#puts "focown=$focown"
	if {$focown!=""} {
		set focclass [winfo class $focown]
		#puts "focclass=$focclass"
		switch $focclass {
		    Text {
			catch {
				catch {
				$focown delete sel.first sel.last
			}
			$focown insert insert [selection get -displayof \
				$focown -selection CLIPBOARD]
			}
		    }
		    Entry {
			catch {
				catch {
					$focown delete sel.first sel.last
				}
				$focown insert insert [selection get \
					-displayof $focown -selection CLIPBOARD]
				global tk_version
				if {$tk_version >= 8.4} {
					tk::unsupported::ExposePrivateCommand tkEntrySeeInsert
				}
				tkEntrySeeInsert $focown
			}
		    }
		}
	}
}

set ignoretest {
menubutton .menu -text Edit -menu .menu.m
pack .menu 
menu .menu.m
text .text 
pack .text
entry .entry
pack .entry
add_cutpaste .menu.m
}
