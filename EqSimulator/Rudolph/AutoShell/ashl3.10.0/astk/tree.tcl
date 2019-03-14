
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: tree.tcl,v 1.3 2000/12/14 23:05:01 karl Exp $
# $Log: tree.tcl,v $
# Revision 1.3  2000/12/14 23:05:01  karl
# Removed leftover diagnostics variable dump (diag.tv).
#
# Revision 1.2  2000/07/07 22:40:38  karl
# Added -values and -valuecolors options to support DV drawing.
# Added openAll and closeAll procs.
#
# Revision 1.1  1999/06/04  20:33:22  karl
# Initial revision
#
#
# Copyright (C) 1997,1998 D. Richard Hipp
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
# 
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA  02111-1307, USA.
#
# Author contact information:
#   drh@acm.org
#   http://www.hwaci.com/drh/
#
# $Revision: 1.3 $
#
option add *highlightThickness 0

label .dummy
set Tree(font) [.dummy cget -font]
destroy .dummy

#switch $tcl_platform(platform) {
#  unix {
#    set Tree(font) \
#      -adobe-helvetica-medium-r-normal-*-11-80-100-100-p-56-iso8859-1
#  }
#  windows {
#    set Tree(font) \
#      -adobe-helvetica-medium-r-normal-*-14-100-100-100-p-76-iso8859-1
#  }
#}

proc Tree:dump {w fn} {
	global Tree
	set fid [open $fn w]
	foreach el [lsort [array names Tree "$w:*"]] {
		puts $fid "Tree($el)=$Tree($el)"
	}
	close $fid
}

#
# Create a new tree widget.  $args become the configuration arguments to
# the canvas widget from which the tree is constructed.
#
proc Tree:create {w delim args} {
  global Tree
  set Tree(dlm) $delim
  eval canvas $w -bg white $args
  bind $w <Destroy> "Tree:delitem $w $Tree(dlm)"
  Tree:dfltconfig $w $Tree(dlm)
  Tree:buildwhenidle $w
  set Tree($w:selection) {}
  set Tree($w:selidx) {}
}

# Initialize a element of the tree.
# Internal use only
#
proc Tree:dfltconfig {w v} {
  global Tree
  set Tree($w:$v:children) {}
  set Tree($w:$v:open) 0
  set Tree($w:$v:icon) {}
  set Tree($w:$v:tags) {}
  set Tree($w:$v:fill) {}
}

#
# Pass configuration options to the tree widget
#
proc Tree:config {w args} {
  eval $w config $args
}

#
# Insert a new element $v into the tree $w.
#
proc Tree:newitem {w v args} {
  global Tree
  set dir [tree_dirname $v $Tree(dlm)]
  set n [tree_tail $v $Tree(dlm)]
  if {![info exists Tree($w:$dir:open)]} {
    error "parent item \"$dir\" is missing"
  }
  set i [lsearch -exact $Tree($w:$dir:children) $n]
#  if {$i>=0} {
#    error "item \"$v\" already exists"
#  }
  lappend Tree($w:$dir:children) $n
  #set Tree($w:$dir:children) [lsort $Tree($w:$dir:children)]
  Tree:dfltconfig $w $v
  foreach {op arg} $args {
    switch -exact -- $op {
      -image {set Tree($w:$v:icon) $arg}
      -tags {set Tree($w:$v:tags) $arg}
      -fill {set Tree($w:$v:fill) $arg}
      -values {set Tree($w:$v:values) $arg}
      -valuecolors {set Tree($w:$v:valuecolors) $arg}
    }
  }
  Tree:buildwhenidle $w
}

proc Tree:getvalue {w v index} {
	global Tree
	set values $Tree($w:$v:values)
	return [lindex $values $index]
}

#proc Tree:changeitem {w v newvalue} {
#	global Tree
#	puts "w=$w v=$v"
#	set tmp [split $v $Tree(dlm)]
#	set parent [join [lrange $tmp 0 [expr [llength $tmp]-2]] >]
#	set child [lindex $tmp end]
#	if {$parent==""} {
#		set parent $Tree(dlm)
#		set prefix ""
#	} else {
#		set prefix $parent
#	}
#	puts "parent=$parent child=$child"
#	set children $Tree($w:$parent:children)
#	
#	set clashpos [lsearch $children $newvalue]
#	if {$clashpos>=0} {
#		return -1
#	}
#
#	set tid [lindex $Tree($w:$v:tag) 0]
#	set newv $prefix>$child
#	set oldchild [lindex [split $v $Tree(dlm)] end]
#	set Tree($w:tag:$tid) $newv
#	$w itemconfigure $tid -text $newvalue
#	set childpos [lsearch $children $child]
#	set Tree($w:$parent:children) [lreplace $Tree($w:$parent:children) \
#		$childpos $childpos $newvalue]
#	foreach el [array names Tree "$w:*$Tree(dlm)$oldchild*:*"] {
#		puts "considering $el"
#		set tmp $Tree($el)
#		unset Tree($el)
#		set newel ""
#		puts -nonewline "	$Tree(dlm)$oldchild -> $Tree(dlm)$newvalue"
#		puts -nonewline "	[regsub -all "$Tree(dlm)$oldchild$Tree(dlm)" $el \
#			$Tree(dlm)$newvalue$Tree(dlm) newel] "
#		puts [regsub -all "$Tree(dlm)$oldchild:" $newel \
#			$Tree(dlm)$newvalue: newel]
#		puts "	changing $el to $newel"
#		set Tree($newel) $tmp
#	}
#	foreach el [array names Tree "*:tag:*"] {
#		if {[string match $Tree($el) "*>$oldchild"]} {
#			set Tree($el) [join [lreplace \
#				[split $Tree($el) $Tree(dlm)] end end $newvalue] $Tree(dlm)]
#		} elseif {[string match $Tree($el) "*>$oldchild"]} {
#		}
#	}
#	return 0	
#}

proc Tree:changevalue {w v index newvalue} {
	global Tree
	set values $Tree($w:$v:values)
	set valuecolors $Tree($w:$v:valuecolors)
	#puts "w=$w v=$v values={$values} valuecolors={$valuecolors}"
	set values [lreplace $values $index $index $newvalue]
	set Tree($w:$v:values) $values
	set tid [lindex $Tree($w:$v:tag) [expr $index+1]]
	#puts "tid=$tid"
	$w itemconfigure $tid -text $newvalue	
}

#
# Delete element $v from the tree $w.  If $v is $Tree(dlm), then the widget is
# deleted.
#
proc Tree:delitem {w v} {
  global Tree
  if {![info exists Tree($w:$v:open)]} return
  if {[string compare $v $Tree(dlm)]==0} {
    # delete the whole widget
    catch {destroy $w}
    foreach t [array names Tree $w:*] {
      unset Tree($t)
    }
  }
  if {[info exists Tree($w:$v:children)]} {
    foreach c $Tree($w:$v:children) {
      catch {Tree:delitem $w $v$Tree(dlm)$c}
    }
    unset Tree($w:$v:children)
    unset Tree($w:$v:open)
    unset Tree($w:$v:icon)
    set dir [tree_dirname $v $Tree(dlm)]
    set n [tree_tail $v $Tree(dlm)]
    set i [lsearch -exact $Tree($w:$dir:children) $n]
    if {$i>=0} {
      set Tree($w:$dir:children) [lreplace $Tree($w:$dir:children) $i $i]
    }
    Tree:buildwhenidle $w
  }
}

#
# Change the selection to the indicated item
#
proc Tree:setselection {w v} {
  global Tree
  set Tree($w:selection) $v
  return [Tree:drawselection $w]
}

# 
# Retrieve the current selection
#
proc Tree:getselection w {
  global Tree
  return $Tree($w:selection)
}

#
# Bitmaps used to show which parts of the tree can be opened.
#
set maskdata "#define solid_width 9\n#define solid_height 9"
append maskdata {
  static unsigned char solid_bits[] = {
   0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01, 0xff, 0x01,
   0xff, 0x01, 0xff, 0x01, 0xff, 0x01
  };
}
set data "#define open_width 9\n#define open_height 9"
append data {
  static unsigned char open_bits[] = {
   0xff, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x7d, 0x01, 0x01, 0x01,
   0x01, 0x01, 0x01, 0x01, 0xff, 0x01
  };
}
image create bitmap Tree:openbm -data $data -maskdata $maskdata \
  -foreground black -background white
set data "#define closed_width 9\n#define closed_height 9"
append data {
  static unsigned char closed_bits[] = {
   0xff, 0x01, 0x01, 0x01, 0x11, 0x01, 0x11, 0x01, 0x7d, 0x01, 0x11, 0x01,
   0x11, 0x01, 0x01, 0x01, 0xff, 0x01
  };
}
image create bitmap Tree:closedbm -data $data -maskdata $maskdata \
  -foreground black -background white

# Internal use only.
# Draw the tree on the canvas
proc Tree:build w {
  global Tree
  $w delete all
  catch {unset Tree($w:buildpending)}
  set Tree($w:y) 30
  Tree:buildlayer $w $Tree(dlm) 10
  $w config -scrollregion [$w bbox all]
  Tree:drawselection $w
}

# Internal use only.
# Build a single layer of the tree on the canvas.  Indent by $in pixels
proc Tree:buildlayer {w v in} {
  global Tree
  if {$v=="$Tree(dlm)"} {
    set vx {}
  } else {
    set vx $v
  }
  set start [expr $Tree($w:y)-10]
  foreach c $Tree($w:$v:children) {
    set y $Tree($w:y)
    incr Tree($w:y) 17
    $w create line $in $y [expr $in+10] $y -fill gray50 
    set icon $Tree($w:$vx$Tree(dlm)$c:icon)
    set taglist label
    foreach tag $Tree($w:$vx$Tree(dlm)$c:tags) {
      lappend taglist $tag
    }
    set x [expr $in+12]
    if {[string length $icon]>0} {
      set k [$w create image $x $y -image $icon -anchor w -tags $taglist]
      incr x 20
      set Tree($w:tag:$k) $vx$Tree(dlm)$c
    }
#    if {[info exists Tree($w:$vx$Tree(dlm)$c:value)]} {
#		set txt "$c$Tree($w:$vx$Tree(dlm)$c:value)"
#	} else {
#		set txt "$c"
#	}
	set txt $c
    set fill $Tree($w:$vx$Tree(dlm)$c:fill)
    if {$fill!={}} {
	    set j [$w create text $x $y -text $txt -font $Tree(font) \
       	                         -anchor w -tags $taglist -fill $fill]
    } else {
	    set j [$w create text $x $y -text $txt -font $Tree(font) \
	                          -anchor w -tags $taglist] 
    }
    set Tree($w:tag:$j) $vx$Tree(dlm)$c
    set Tree($w:$vx$Tree(dlm)$c:tag) $j
	set prev $j
	set vcount 0
    if {[info exists Tree($w:$vx$Tree(dlm)$c:values)]} {
		foreach value $Tree($w:$vx$Tree(dlm)$c:values) {	
			#set bbox [$w bbox $prev]
			#set wid [expr [lindex $bbox 2] - [lindex $bbox 0]]
			if {[info exists Tree($w:$vx$Tree(dlm)$c:valuecolors)] && \
				[llength $Tree($w:$vx$Tree(dlm)$c:valuecolors)]>$vcount} {
				set color [lindex $Tree($w:$vx$Tree(dlm)$c:valuecolors) \
					$vcount]
			} else {
				set color black
			}
			regsub -all "\n" $value {\\n} value
		    set j [$w create text [expr [lindex [$w bbox $prev] 2]+1] $y \
				-text $value -font $Tree(font) \
				-anchor w -tags value$vcount -fill $color]
   		 	set Tree($w:tag:$j) $vx$Tree(dlm)$c
		    lappend Tree($w:$vx$Tree(dlm)$c:tag) $j
			set prev $j
			incr vcount
		}
	}
    if {[string length $Tree($w:$vx$Tree(dlm)$c:children)]} {
	   	# This protects whitespace in variable names with spaces in them
		set varname "Tree($w:$vx$Tree(dlm)$c:open)"

      	if {$Tree($w:$vx$Tree(dlm)$c:open)} {
         	set j [$w create image $in $y -image Tree:openbm]
        	$w bind $j <1> "set \"$varname\" 0; Tree:build $w"
         	Tree:buildlayer $w $vx$Tree(dlm)$c [expr $in+18]
      	} else {
         	set j [$w create image $in $y -image Tree:closedbm]
         	$w bind $j <1> "set \"$varname\" 1; Tree:build $w"
      	}
    }
  }
  if {[info exists y]} {
	  set j [$w create line $in $start $in [expr $y+1] -fill gray50 ]
	  $w lower $j
  }
}

proc Tree:openAll {w v {except {}}} {
  global Tree
  if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==0
      && [info exists Tree($w:$v:children)] 
      && [string length $Tree($w:$v:children)]>0} {
	#puts "opening $v$Tree(dlm)$child"
	foreach exception $except {
		if {[string compare "[string trim $exception >]" \
				[string trim $v >]]==0} {
			return
		}
	}
    set Tree($w:$v:open) 1
  }
  foreach child $Tree($w:$v:children) {
	if {$v==">"} {
		set v ""
	}
	Tree:openAll $w $v$Tree(dlm)$child $except
  }
  Tree:buildwhenidle $w
}

# Open a branch of a tree
#
proc Tree:open {w v} {
  global Tree
  if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==0
      && [info exists Tree($w:$v:children)] 
      && [string length $Tree($w:$v:children)]>0} {
    set Tree($w:$v:open) 1
    Tree:buildwhenidle $w
  }
}

proc Tree:closeAll {w v} {
  global Tree
  if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==1} {
    set Tree($w:$v:open) 0
  }
  foreach child $Tree($w:$v:children) {
	if {$v==">"} {
		set v ""
	}
	Tree:closeAll $w $v$Tree(dlm)$child
  }
  Tree:buildwhenidle $w
}

proc Tree:close {w v} {
  global Tree
  if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==1} {
    set Tree($w:$v:open) 0
    Tree:buildwhenidle $w
  }
}

# Internal use only.
# Draw the selection highlight
proc Tree:drawselection w {
  global Tree
  if {[string length $Tree($w:selidx)]} {
    $w delete $Tree($w:selidx)
  }
  set v $Tree($w:selection)
  if {[string length $v]==0} {return -1}
	#puts "w=$w v=$v"
	#Tree:dump $w diag.tv
  if {![info exists Tree($w:$v:tag)]} {return -2}
  set bbox [$w bbox [lindex $Tree($w:$v:tag) 0]]
  if {[llength $bbox]==4} {
    set i [eval $w create rectangle $bbox -fill skyblue -outline {{}}]
    set Tree($w:selidx) $i
    $w lower $i
	return 0
  } else {
    set Tree($w:selidx) {}
	return -3
  }
}

# Internal use only
# Call Tree:build then next time we're idle
proc Tree:buildwhenidle w {
  global Tree
  if {![info exists Tree($w:buildpending)]} {
    set Tree($w:buildpending) 1
    after idle "Tree:build $w"
  }
}

#
# Return the full pathname of the label for widget $w that is located
# at real coordinates $x, $y
#
proc Tree:labelat {w x y} {
  set x [$w canvasx $x]
  set y [$w canvasy $y]
  global Tree
  foreach m [$w find overlapping $x $y $x $y] {
    if {[info exists Tree($w:tag:$m)]} {
		#puts "labelat returning $Tree($w:tag:$m)"
      return $Tree($w:tag:$m)
    }
  }
		#puts "labelat returning \"\""
  return ""
}

proc ignore {} {
#################
#
# The remainder is code that demonstrates the use of the Tree
# widget.  
#
. config -bd 3 -relief flat
frame .f -bg white
pack .f -fill both -expand 1
image create photo idir -data {
    R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4APj4+P///wAAAAAAACwAAAAAEAAQAAADPVi63P4w
    LkKCtTTnUsXwQqBtAfh910UU4ugGAEucpgnLNY3Gop7folwNOBOeiEYQ0acDpp6pGAFArVqt
    hQQAO///
}
image create photo ifile -data {
    R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4+P///wAAAAAAAAAAACwAAAAAEAAQAAADPkixzPOD
    yADrWE8qC8WN0+BZAmBq1GMOqwigXFXCrGk/cxjjr27fLtout6n9eMIYMTXsFZsogXRKJf6u
    P0kCADv/
}
frame .f.mb -bd 2 -relief raised
pack .f.mb -side top -fill x
menubutton .f.mb.file -text File -menu .mb.file.menu
catch {
  menu .f.mb.file.menu
  .f.mb.file.menu add command -label Quit -command exit
}
menubutton .f.mb.edit -text Edit
menubutton .f.mb.view -text View
menubutton .f.mb.help -text Help
pack .f.mb.file .f.mb.edit .f.mb.view .f.mb.help -side left -padx 10
Tree:create .f.w -width 150 -height 400 -yscrollcommand {.f.sb set}
scrollbar .f.sb -orient vertical -command {.f.w yview}
pack .f.w -side left -fill both -expand 1 -padx 5 -pady 5
pack .f.sb -side left -fill y
frame .f.c -height 400 -width 400 -bg white
pack .f.c -side left -fill both -expand 1
label .f.c.l -width 40 -text {} -bg [.f.c cget -bg]
pack .f.c.l -expand 1
foreach z {1 2 3} {
  Tree:newitem .f.w $Tree(dlm)dir$z -image idir
  foreach x {1 2 3 4 5 6} {
    Tree:newitem .f.w $Tree(dlm)dir$z$Tree(dlm)file$x -image ifile
  }
  Tree:newitem .f.w $Tree(dlm)dir$z$Tree(dlm)subdir -image idir
  foreach y {1 2} {
    Tree:newitem .f.w $Tree(dlm)dir$z$Tree(dlm)subdir$Tree(dlm)file$y -image ifile
  }
  foreach zz {1 2 3 4} {
    Tree:newitem .f.w $Tree(dlm)dir$z$Tree(dlm)subdir$Tree(dlm)ssdir$zz -image idir
    Tree:newitem .f.w $Tree(dlm)dir$z$Tree(dlm)subdir$Tree(dlm)ssdir$zz$Tree(dlm)file1  ;# No icon!
    Tree:newitem .f.w $Tree(dlm)dir$z$Tree(dlm)subdir$Tree(dlm)ssdir$zz$Tree(dlm)file2 -image ifile
  }
}
.f.w bind x <1> {
  set lbl [Tree:labelat %W %x %y]
  Tree:setselection %W $lbl
  .f.c.l config -text $lbl
}
.f.w bind x <Double-1> {
  Tree:open %W [Tree:labelat %W %x %y]
}
update
}

proc tree_dirname {path delim} {
	set list [split [string trimright $path $delim] $delim]	
	set length [llength $list]
	if {$length==0} {
		return $delim
	} elseif {$length<3} {
		if {[string index $path 0]==$delim} {
			return $delim
		} else {
			return "."
		}
	} else {
		return [join [lrange $list 0 [expr $length-2]] $delim]
	}
}

proc tree_tail {path delim} {
	set list [split $path $delim]	
	if {[llength $list]==1} {
		return $path
	} else {
		return [lindex $list end]
	}
}

