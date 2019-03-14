
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: wlb.tcl,v 1.1 1996/08/27 16:23:13 karl Exp $
# $Log: wlb.tcl,v $
# Revision 1.1  1996/08/27 16:23:13  karl
# Initial revision
#
#!/opt/misc/bin/wish4.0
### 
### wlb.tcl
###
### A widget-item listbox widget.
###
### input  : object name, item type, optional args
### output : modeled like listbox widget
###
### optional arguments:  (all must be prefixed by a hyphen, eg. -scrollable)
### scrollable - make the list box scrollablej
### mesg       - text message to show above box
### height     - height in widgets of the listbox
### width      - width  in widgets of the listbox
### font       - font to use for the text
### justify    - justification for the message
###
### NOTE:  widget created to be items in the listbox must be 
###        children of the "wlb widgetname".box.list item.
###
### example:
### widgetlistbox .wlb entry -scrollable
### .wlb configure -height 4 -width 2
### .wlb configure -font 6x13
### .wlb configure -mesg "hello there"
### set e1 "e1"; entry .wlb.box.list.entry1 -textvariable e1
### set e2 "e2"; entry .wlb.box.list.entry2 -textvariable e2
### set e3 "e3"; entry .wlb.box.list.entry3 -textvariable e3
### .wlb insert end .wlb.box.list.entry1
### .wlb insert end
### .wlb insert end .wlb.box.list.entry2 .wlb.box.list.entry3
### .wlb insert end
### pack .wlb
### puts [.wlb size]
### puts [.wlb get 0 end]
### puts [lindex [lindex [.wlb get 0 end] 2] 0]
### puts [lindex [.wlb get 2 2] 0]
###
### Last edited:    06/03/96     12:16
###          by:    Guy M. Saenger
###
########
proc wlb_type_height {w} \
{
   global tkPriv

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}

   return $tkPriv(wlb_type_height)
}
########
proc wlb_type_width {w} \
{
   global tkPriv

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}

   return $tkPriv(wlb_type_width)
}
########
proc wlb_type {w} \
{
   global tkPriv

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}

   return $tkPriv(wlb_type)
}
########
proc wlb_end {w} \
{
   global tkPriv

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}

   return $tkPriv(wlb_end)
}
########
proc wlb_size {w} \
{
   global tkPriv

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}

   return $tkPriv(wlb_size)
}
########
proc wlb_bind {w} \
{
   bind $w.box.list <1> \
   {+
   }

   bind $w.box.list <B1-Motion> \
   {+
   }
}
########
proc wlb_detstart {w idx} \
{
   if {$idx < 0} { set idx 0 }
   if {$idx > [wlb_end $w] || $idx == "end"} \
      { set idx [wlb_size $w] }
   return $idx
}
########
proc wlb_detend {w idx start} \
{
   if {$idx > [wlb_end $w] || $idx == "end"} \
      { set idx [wlb_end $w] }
   if {$idx == ""} { set idx $start }
   return $idx
}
########
proc wlb_newname {w} \
{
   set count 0
   while {[winfo exists $w.box.list.item$count]} { incr count }
   return $w.box.list.item$count
}
########
proc wlb_shiftlistup {w idx} \
{

   for {set i $idx} {$i <= [wlb_end $w]} {incr i} \
   {
      set x 1
      set y [expr $i * [wlb_type_height $w] + 1]
      set id [$w.box.list find closest $x $y]
      set y [expr [expr $i - 1] * [wlb_type_height $w]]
      $w.box.list coords $id 0 $y
   }
}
########
proc wlb_shiftlistdown {w idx} \
{

   for {set i [wlb_end $w]} {$i >= $idx} {incr i -1} \
   {
      set x 1
      set y [expr $i * [wlb_type_height $w] + 1]
      set id [$w.box.list find closest $x $y]
      set y [expr [expr $i + 1] * [wlb_type_height $w]]
      $w.box.list coords $id 0 $y
   }
}
########
proc wlb_configure {w args} \
{

   set args [lindex $args 0]

   set idx [lsearch $args "-scrollable"]
   if {$idx != -1} \
   {
      scrollbar $w.box.scroll -command "$w.box.list yview"
      pack $w.box.scroll -side left -fill y
      $w.box.list configure -yscrollcommand "$w.box.scroll set"
      $w.box.list configure -yscrollincrement [wlb_type_height $w]
      set args [lreplace $args $idx $idx]
   }

   set idx [lsearch $args "-font"]
   if {$idx != -1} \
   {
      set val [lindex $args [expr $idx + 1]]
      $w.mesg.label configure -font $val
      set args [lreplace $args $idx [expr $idx + 1]]
   }

   set idx [lsearch $args "-height"]
   if {$idx != -1} \
   {
      set val [lindex $args [expr $idx + 1]]
      set val [expr $val * [wlb_type_height $w]]
      set args [lreplace $args [expr $idx + 1] [expr $idx + 1] $val]
   }

   set idx [lsearch $args "-width"]
   if {$idx != -1} \
   {
      set val [lindex $args [expr $idx + 1]]
      set val [expr $val * [wlb_type_width $w]]
      set args [lreplace $args [expr $idx + 1] [expr $idx + 1] $val]
   }

   set idx [lsearch $args "-mesg"]
   if {$idx != -1} \
   {
      set val [lindex $args [expr $idx + 1]]
      $w.mesg.label configure -text $val
      pack $w.mesg.label
      set args [lreplace $args $idx [expr $idx + 1]]
   }

   set idx [lsearch $args "-justify"]
   if {$idx != -1} \
   {
      set val [lindex $args [expr $idx + 1]]
      $w.mesg.label configure -justify $val
      case $val \
      {
         left   { pack $w.mesg.label -anchor w }
         right  { pack $w.mesg.label -anchor e }
         center { pack $w.mesg.label -anchor c }
      }
      set args [lreplace $args $idx [expr $idx + 1]]
   }

   eval "$w.box.list configure $args"
  
   return ""
}
########
proc wlb_insert {w args} \
{
   global tkPriv

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}


   set args [lindex $args 0]
   if {$args == ""} { return }

   # get the starting index
   set start [wlb_detstart $w [lindex $args 0]]

   if {[lrange $args 1 end] == ""} \
   {
      wlb_shiftlistdown $w $start
      incr tkPriv(wlb_end)
      incr tkPriv(wlb_size)

      set y [expr $start * [wlb_type_height $w]]
      set name [wlb_newname $w]
      [wlb_type $w] $name
      $w.box.list create window 0 $y -window $name -anchor nw
   }

   foreach item [lrange $args 1 end] \
   {
      wlb_shiftlistdown $w $start
      incr tkPriv(wlb_end)
      incr tkPriv(wlb_size)

      set y [expr $start * [wlb_type_height $w]]
      set class [string tolower [winfo class $item]]
      if {$class != [wlb_type $w]} { continue }
      $w.box.list create window 0 $y -window $item -anchor nw
      incr start
   }

   set height [wlb_type_height $w]
   set tkPriv(wlb_ymaxscroll) [expr [wlb_size $w] * $height]
   $w.box.list configure -scrollregion "0 0 0 $tkPriv(wlb_ymaxscroll)"

   return ""
}
########
proc wlb_delete {w args} \
{
   global tkPriv

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}


   set args [lindex $args 0]
   if {$args == ""} { return }

   # get the starting index
   set start [wlb_detstart $w [lindex $args 0]]

   # determine the actual ending index
   set end [wlb_detend $w [lindex $args 1] $start]

   # make sure there are elements in there before attempting delete
   if {[$w.box.list find all] == ""} { return }

   # delete each index in the range specified
   for {set i $start} {$i <= $end} {incr i} \
   {
      set x 1
      set y [expr $i * [wlb_type_height $w] + 1]
      set id [$w.box.list find closest $x $y]
      $w.box.list delete $id

      wlb_shiftlistup $w [expr $i + 1]
      incr tkPriv(wlb_end)  -1
      incr tkPriv(wlb_size) -1
   }

   return ""
}
########
proc wlb_get {w args} \
{

   set args [lindex $args 0]
   if {$args == ""} { return }

   # get the starting index
   set start [wlb_detstart $w [lindex $args 0]]
 
   # determine the actual ending index
   set end [wlb_detend $w [lindex $args 1] $start]

   # get the widget names from the listbox
   set getlist ""
   for {set i $start} {$i <= $end} {incr i} \
   {
      set x 1
      set y [expr $i * [wlb_type_height $w] + 1]
      set id [$w.box.list find closest $x $y]
      lappend getlist [$w.box.list itemcget $id -window]
   }
   return $getlist
}
########
proc wlb_handler {w args} \
{
   set args [lindex $args 0]
   case [lindex $args 0] \
   {
      configure { return [wlb_configure $w [lrange $args 1 end]] }
      insert    { return [wlb_insert    $w [lrange $args 1 end]] }
      size      { return [wlb_size      $w] }
      delete    { return [wlb_delete    $w [lrange $args 1 end]] }
      get       { return [wlb_get       $w [lrange $args 1 end]] }
      default   {}
   }
}
########
proc widgetlistbox {w type args} \
{
   global tkPriv

	global tk_version
	if { $tk_version >= 8.4 } {
		tk::unsupported::ExposePrivateVariable tkPriv
	}


   set tkPriv(wlb_type) $type
   $type .x
   set tkPriv(wlb_type_height) [winfo reqheight .x]
   set tkPriv(wlb_type_width)  [winfo reqwidth  .x]
   destroy .x

   set tkPriv(wlb_end)        -1
   set tkPriv(wlb_size)        0
   set tkPriv(wlb_ymaxscroll)  0

   frame   $w
   frame   $w.mesg
   frame   $w.box

   label  $w.mesg.label

   canvas $w.box.list 
   pack   $w.box.list -side left

   pack $w.mesg -side top
   pack $w.box  -side bottom

   wlb_bind $w

   rename $w $w.old
   proc $w {args} "wlb_handler $w \$args"

   eval "wlb_configure $w \$args"
}
########
proc wlb_test {} \
{
   global e1 e2 e3 e4 e5

   widgetlistbox .wlb entry -scrollable
   .wlb configure -height 4 -width 2
   .wlb configure -font 6x13 
   .wlb configure -mesg "hello there" 
   set e1 "e1"; entry .wlb.box.list.entry1 -textvariable e1
   set e2 "e2"; entry .wlb.box.list.entry2 -textvariable e2
   set e3 "e3"; entry .wlb.box.list.entry3 -textvariable e3
   set e4 "e4"; entry .wlb.box.list.entry4 -textvariable e4
   set e5 "e5"; entry .wlb.box.list.entry5 -textvariable e5
   .wlb insert end .wlb.box.list.entry1
   .wlb insert end 
   .wlb insert end .wlb.box.list.entry2 .wlb.box.list.entry3
   .wlb insert 0 
   .wlb insert end 
   .wlb insert end 
   pack .wlb
   bind . <1> \
   {
      puts "size before [.wlb size]"
      puts [.wlb get 0 end]
      puts [.wlb.box.list find all]
      puts "deleting [.wlb delete 0]"
      puts [.wlb.box.list find all]
      puts [.wlb get 0 end]
      puts "size after [.wlb size]"
   }
   bind . <2> \
   {
      .wlb insert end .wlb.box.list.entry2 .wlb.box.list.entry3
      .wlb insert 0 
      .wlb insert 1  .wlb.box.list.entry1
      .wlb insert end .wlb.box.list.entry4 .wlb.box.list.entry5
   }
   bind . <3> \
   {
      .wlb insert 0 
      .wlb insert 0 .wlb.box.list.entry1
      .wlb insert 0 .wlb.box.list.entry2 
      .wlb insert 0 .wlb.box.list.entry3 
      .wlb insert 0 .wlb.box.list.entry4 
      .wlb insert 0 .wlb.box.list.entry5 
   }
}
########
#wlb_test
