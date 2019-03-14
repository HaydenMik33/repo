#
#
global nItem 1
global changed 0
global treeName
global sysFileName
global OSName
global null
global duplicate
global slash
global backslash
global nullTmp
global dupTmp
global slashTmp
global backslashTmp
global checkdup
option add *highlightThickness 0
global release_version
if {[catch {source $env(ASTK_DIR)/version.tcl}] || \
    ![info exists release_version]} {
        set release_version "1.0"
}


# Copyright (c) 1998-2002, Bryan Oakley
# All Rights Reservered
#
# Bryan Oakley
# oakley@bardo.clearlight.com
#
# combobox v2.2.1 September 22, 2002
#
# a combobox / dropdown listbox (pick your favorite name) widget 
# written in pure tcl
#
# this code is freely distributable without restriction, but is 
# provided as-is with no warranty expressed or implied. 
#
# thanks to the following people who provided beta test support or
# patches to the code (in no particular order):
#
# Scott Beasley     Alexandre Ferrieux      Todd Helfter
# Matt Gushee       Laurent Duperval        John Jackson
# Fred Rapp         Christopher Nelson
# Eric Galluzzo     Jean-Francois Moine
#
# A special thanks to Martin M. Hunt who provided several good ideas, 
# and always with a patch to implement them. Jean-Francois Moine, 
# Todd Helfter and John Jackson were also kind enough to send in some 
# code patches.
#
# ... and many others over the years.

package require Tk 8.0
package provide combobox 2.2.1

namespace eval ::combobox {

    # this is the public interface
    namespace export combobox

    # these contain references to available options
    variable widgetOptions

    # these contain references to available commands and subcommands
    variable widgetCommands
    variable scanCommands
    variable listCommands
}

# ::combobox::combobox --
#
#     This is the command that gets exported. It creates a new
#     combobox widget.
#
# Arguments:
#
#     w        path of new widget to create
#     args     additional option/value pairs (eg: -background white, etc.)
#
# Results:
#
#     It creates the widget and sets up all of the default bindings
#
# Returns:
#
#     The name of the newly create widget

proc ::combobox::combobox {w args} {
    variable widgetOptions
    variable widgetCommands
    variable scanCommands
    variable listCommands

    # perform a one time initialization
    if {![info exists widgetOptions]} {
	Init
    }

    # build it...
    eval Build $w $args

    # set some bindings...
    SetBindings $w

    # and we are done!
    return $w
}


# ::combobox::Init --
#
#     Initialize the namespace variables. This should only be called
#     once, immediately prior to creating the first instance of the
#     widget
#
# Arguments:
#
#    none
#
# Results:
#
#     All state variables are set to their default values; all of 
#     the option database entries will exist.
#
# Returns:
# 
#     empty string

proc ::combobox::Init {} {
    variable widgetOptions
    variable widgetCommands
    variable scanCommands
    variable listCommands
    variable defaultEntryCursor

    array set widgetOptions [list \
	    -background          {background          Background} \
	    -bd                  -borderwidth \
	    -bg                  -background \
	    -borderwidth         {borderWidth         BorderWidth} \
	    -command             {command             Command} \
	    -commandstate        {commandState        State} \
	    -cursor              {cursor              Cursor} \
	    -disabledbackground  {disabledBackground  DisabledBackground} \
	    -disabledforeground  {disabledForeground  DisabledForeground} \
            -dropdownwidth       {dropdownWidth       DropdownWidth} \
	    -editable            {editable            Editable} \
	    -fg                  -foreground \
	    -font                {font                Font} \
	    -foreground          {foreground          Foreground} \
	    -height              {height              Height} \
	    -highlightbackground {highlightBackground HighlightBackground} \
	    -highlightcolor      {highlightColor      HighlightColor} \
	    -highlightthickness  {highlightThickness  HighlightThickness} \
	    -image               {image               Image} \
	    -maxheight           {maxHeight           Height} \
	    -opencommand         {opencommand         Command} \
	    -relief              {relief              Relief} \
	    -selectbackground    {selectBackground    Foreground} \
	    -selectborderwidth   {selectBorderWidth   BorderWidth} \
	    -selectforeground    {selectForeground    Background} \
	    -state               {state               State} \
	    -takefocus           {takeFocus           TakeFocus} \
	    -textvariable        {textVariable        Variable} \
	    -value               {value               Value} \
	    -width               {width               Width} \
	    -xscrollcommand      {xScrollCommand      ScrollCommand} \
    ]


    set widgetCommands [list \
	    bbox      cget     configure    curselection \
	    delete    get      icursor      index        \
	    insert    list     scan         selection    \
	    xview     select   toggle       open         \
            close     \
    ]

    set listCommands [list \
	    delete       get      \
            index        insert       size \
    ]

    set scanCommands [list mark dragto]

    # why check for the Tk package? This lets us be sourced into 
    # an interpreter that doesn't have Tk loaded, such as the slave
    # interpreter used by pkg_mkIndex. In theory it should have no
    # side effects when run 
    if {[lsearch -exact [package names] "Tk"] != -1} {

	##################################################################
	#- this initializes the option database. Kinda gross, but it works
	#- (I think). 
	##################################################################

	# the image used for the button...
	if {$::tcl_platform(platform) == "windows"} {
	    image create bitmap ::combobox::bimage -data {
		#define down_arrow_width 12
		#define down_arrow_height 12
		static char down_arrow_bits[] = {
		    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
		    0xfc,0xf1,0xf8,0xf0,0x70,0xf0,0x20,0xf0,
		    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
		}
	    }
	} else {
	    image create bitmap ::combobox::bimage -data  {
		#define down_arrow_width 15
		#define down_arrow_height 15
		static char down_arrow_bits[] = {
		    0x00,0x80,0x00,0x80,0x00,0x80,0x00,0x80,
		    0x00,0x80,0xf8,0x8f,0xf0,0x87,0xe0,0x83,
		    0xc0,0x81,0x80,0x80,0x00,0x80,0x00,0x80,
		    0x00,0x80,0x00,0x80,0x00,0x80
		}
	    }
	}

	# compute a widget name we can use to create a temporary widget
	set tmpWidget ".__tmp__"
	set count 0
	while {[winfo exists $tmpWidget] == 1} {
	    set tmpWidget ".__tmp__$count"
	    incr count
	}

	# get the scrollbar width. Because we try to be clever and draw our
	# own button instead of using a tk widget, we need to know what size
	# button to create. This little hack tells us the width of a scroll
	# bar.
	#
	# NB: we need to be sure and pick a window  that doesn't already
	# exist... 
	scrollbar $tmpWidget
	set sb_width [winfo reqwidth $tmpWidget]
	destroy $tmpWidget

	# steal options from the entry widget
	# we want darn near all options, so we'll go ahead and do
	# them all. No harm done in adding the one or two that we
	# don't use.
	entry $tmpWidget 
	foreach foo [$tmpWidget configure] {
	    # the cursor option is special, so we'll save it in
	    # a special way
	    if {[lindex $foo 0] == "-cursor"} {
		set defaultEntryCursor [lindex $foo 4]
	    }
	    if {[llength $foo] == 5} {
		set option [lindex $foo 1]
		set value [lindex $foo 4]
		option add *Combobox.$option $value widgetDefault

		# these options also apply to the dropdown listbox
		if {[string compare $option "foreground"] == 0 \
			|| [string compare $option "background"] == 0 \
			|| [string compare $option "font"] == 0} {
		    option add *Combobox*ComboboxListbox.$option $value \
			    widgetDefault
		}
	    }
	}
	destroy $tmpWidget

	# these are unique to us...
	option add *Combobox.dropdownWidth       {}     widgetDefault
	option add *Combobox.openCommand         {}     widgetDefault
	option add *Combobox.cursor              {}     widgetDefault
	option add *Combobox.commandState        normal widgetDefault
	option add *Combobox.editable            1      widgetDefault
	option add *Combobox.maxHeight           10     widgetDefault
	option add *Combobox.height              0
    }

    # set class bindings
    SetClassBindings
}

# ::combobox::SetClassBindings --
#
#    Sets up the default bindings for the widget class
#
#    this proc exists since it's The Right Thing To Do, but
#    I haven't had the time to figure out how to do all the
#    binding stuff on a class level. The main problem is that
#    the entry widget must have focus for the insertion cursor
#    to be visible. So, I either have to have the entry widget
#    have the Combobox bindtag, or do some fancy juggling of
#    events or some such. What a pain.
#
# Arguments:
#
#    none
#
# Returns:
#
#    empty string

proc ::combobox::SetClassBindings {} {

    # make sure we clean up after ourselves...
    bind Combobox <Destroy> [list ::combobox::DestroyHandler %W]

    # this will (hopefully) close (and lose the grab on) the
    # listbox if the user clicks anywhere outside of it. Note
    # that on Windows, you can click on some other app and
    # the listbox will still be there, because tcl won't see
    # that button click
    set this {[::combobox::convert %W -W]}
    bind Combobox <Any-ButtonPress>   "$this close"
    bind Combobox <Any-ButtonRelease> "$this close"

    # this helps (but doesn't fully solve) focus issues. The general
    # idea is, whenever the frame gets focus it gets passed on to
    # the entry widget
    bind Combobox <FocusIn> {::combobox::tkTabToWindow [::combobox::convert %W -W].entry}

    # this closes the listbox if we get hidden
    bind Combobox <Unmap> {[::combobox::convert %W -W] close}

    return ""
}

# ::combobox::SetBindings --
#
#    here's where we do most of the binding foo. I think there's probably
#    a few bindings I ought to add that I just haven't thought
#    about...
#
#    I'm not convinced these are the proper bindings. Ideally all
#    bindings should be on "Combobox", but because of my juggling of
#    bindtags I'm not convinced thats what I want to do. But, it all
#    seems to work, its just not as robust as it could be.
#
# Arguments:
#
#    w    widget pathname
#
# Returns:
#
#    empty string

proc ::combobox::SetBindings {w} {
    upvar ::combobox::${w}::widgets  widgets
    upvar ::combobox::${w}::options  options

    # juggle the bindtags. The basic idea here is to associate the
    # widget name with the entry widget, so if a user does a bind
    # on the combobox it will get handled properly since it is
    # the entry widget that has keyboard focus.
    bindtags $widgets(entry) \
	    [concat $widgets(this) [bindtags $widgets(entry)]]

    bindtags $widgets(button) \
	    [concat $widgets(this) [bindtags $widgets(button)]]

    # override the default bindings for tab and shift-tab. The
    # focus procs take a widget as their only parameter and we
    # want to make sure the right window gets used (for shift-
    # tab we want it to appear as if the event was generated
    # on the frame rather than the entry. 
    bind $widgets(entry) <Tab> \
	    "::combobox::tkTabToWindow \[tk_focusNext $widgets(entry)\]; break"
    bind $widgets(entry) <Shift-Tab> \
	    "::combobox::tkTabToWindow \[tk_focusPrev $widgets(this)\]; break"
    
    # this makes our "button" (which is actually a label)
    # do the right thing
    bind $widgets(button) <ButtonPress-1> [list $widgets(this) toggle]

    # this lets the autoscan of the listbox work, even if they
    # move the cursor over the entry widget.
    bind $widgets(entry) <B1-Enter> "break"

    bind $widgets(listbox) <ButtonRelease-1> \
        "::combobox::Select [list $widgets(this)] \
         \[$widgets(listbox) nearest %y\]; break"

    bind $widgets(vsb) <ButtonPress-1>   {continue}
    bind $widgets(vsb) <ButtonRelease-1> {continue}

    bind $widgets(listbox) <Any-Motion> {
	%W selection clear 0 end
	%W activate @%x,%y
	%W selection anchor @%x,%y
	%W selection set @%x,%y @%x,%y
	# need to do a yview if the cursor goes off the top
	# or bottom of the window... (or do we?)
    }

    # these events need to be passed from the entry widget
    # to the listbox, or otherwise need some sort of special
    # handling. 
    foreach event [list <Up> <Down> <Tab> <Return> <Escape> \
	    <Next> <Prior> <Double-1> <1> <Any-KeyPress> \
	    <FocusIn> <FocusOut>] {
	bind $widgets(entry) $event \
            [list ::combobox::HandleEvent $widgets(this) $event]
    }

    # like the other events, <MouseWheel> needs to be passed from
    # the entry widget to the listbox. However, in this case we
    # need to add an additional parameter
    catch {
	bind $widgets(entry) <MouseWheel> \
	    [list ::combobox::HandleEvent $widgets(this) <MouseWheel> %D]
    }
}

# ::combobox::Build --
#
#    This does all of the work necessary to create the basic
#    combobox. 
#
# Arguments:
#
#    w        widget name
#    args     additional option/value pairs
#
# Results:
#
#    Creates a new widget with the given name. Also creates a new
#    namespace patterened after the widget name, as a child namespace
#    to ::combobox
#
# Returns:
#
#    the name of the widget

proc ::combobox::Build {w args } {
    variable widgetOptions

    if {[winfo exists $w]} {
	error "window name \"$w\" already exists"
    }

    # create the namespace for this instance, and define a few
    # variables
    namespace eval ::combobox::$w {

	variable ignoreTrace 0
	variable oldFocus    {}
	variable oldGrab     {}
	variable oldValue    {}
	variable options
	variable this
	variable widgets

	set widgets(foo) foo  ;# coerce into an array
	set options(foo) foo  ;# coerce into an array

	unset widgets(foo)
	unset options(foo)
    }

    # import the widgets and options arrays into this proc so
    # we don't have to use fully qualified names, which is a
    # pain.
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    # this is our widget -- a frame of class Combobox. Naturally,
    # it will contain other widgets. We create it here because
    # we need it in order to set some default options.
    set widgets(this)   [frame  $w -class Combobox -takefocus 0]
    set widgets(entry)  [entry  $w.entry -takefocus 1]
    set widgets(button) [label  $w.button -takefocus 0] 

    # this defines all of the default options. We get the
    # values from the option database. Note that if an array
    # value is a list of length one it is an alias to another
    # option, so we just ignore it
    foreach name [array names widgetOptions] {
	if {[llength $widgetOptions($name)] == 1} continue

	set optName  [lindex $widgetOptions($name) 0]
	set optClass [lindex $widgetOptions($name) 1]

	set value [option get $w $optName $optClass]
	set options($name) $value
    }

    # a couple options aren't available in earlier versions of
    # tcl, so we'll set them to sane values. For that matter, if
    # they exist but are empty, set them to sane values.
    if {[string length $options(-disabledforeground)] == 0} {
        set options(-disabledforeground) $options(-foreground)
    }
    if {[string length $options(-disabledbackground)] == 0} {
        set options(-disabledbackground) $options(-background)
    }

    # if -value is set to null, we'll remove it from our
    # local array. The assumption is, if the user sets it from
    # the option database, they will set it to something other
    # than null (since it's impossible to determine the difference
    # between a null value and no value at all).
    if {[info exists options(-value)] \
	    && [string length $options(-value)] == 0} {
	unset options(-value)
    }

    # we will later rename the frame's widget proc to be our
    # own custom widget proc. We need to keep track of this
    # new name, so we'll define and store it here...
    set widgets(frame) ::combobox::${w}::$w

    # gotta do this sooner or later. Might as well do it now
    pack $widgets(entry)  -side left  -fill both -expand yes
    pack $widgets(button) -side right -fill y    -expand no

    # I should probably do this in a catch, but for now it's
    # good enough... What it does, obviously, is put all of
    # the option/values pairs into an array. Make them easier
    # to handle later on...
    array set options $args

    # now, the dropdown list... the same renaming nonsense
    # must go on here as well...
    set widgets(dropdown)   [toplevel  $w.top]
    set widgets(listbox) [listbox   $w.top.list]
    set widgets(vsb)     [scrollbar $w.top.vsb]

    pack $widgets(listbox) -side left -fill both -expand y

    # fine tune the widgets based on the options (and a few
    # arbitrary values...)

    # NB: we are going to use the frame to handle the relief
    # of the widget as a whole, so the entry widget will be 
    # flat. This makes the button which drops down the list
    # to appear "inside" the entry widget.

    $widgets(vsb) configure \
	    -command "$widgets(listbox) yview" \
	    -highlightthickness 0

    $widgets(button) configure \
	    -highlightthickness 0 \
	    -borderwidth 1 \
	    -relief raised \
	    -width [expr {[winfo reqwidth $widgets(vsb)] - 2}]

    $widgets(entry) configure \
	    -borderwidth 0 \
	    -relief flat \
	    -highlightthickness 0 

    $widgets(dropdown) configure \
	    -borderwidth 1 \
	    -relief sunken

    $widgets(listbox) configure \
	    -selectmode browse \
	    -background [$widgets(entry) cget -bg] \
	    -yscrollcommand "$widgets(vsb) set" \
	    -exportselection false \
	    -borderwidth 0


#    trace variable ::combobox::${w}::entryTextVariable w \
#	    [list ::combobox::EntryTrace $w]
	
    # do some window management foo on the dropdown window
    wm overrideredirect $widgets(dropdown) 1
    wm transient        $widgets(dropdown) [winfo toplevel $w]
    wm group            $widgets(dropdown) [winfo parent $w]
    wm resizable        $widgets(dropdown) 0 0
    wm withdraw         $widgets(dropdown)
    
    # this moves the original frame widget proc into our
    # namespace and gives it a handy name
    rename ::$w $widgets(frame)

    # now, create our widget proc. Obviously (?) it goes in
    # the global namespace. All combobox widgets will actually
    # share the same widget proc to cut down on the amount of
    # bloat. 
    proc ::$w {command args} \
        "eval ::combobox::WidgetProc $w \$command \$args"


    # ok, the thing exists... let's do a bit more configuration. 
    if {[catch "::combobox::Configure [list $widgets(this)] [array get options]" error]} {
	catch {destroy $w}
	error "internal error: $error"
    }

    return ""

}

# ::combobox::HandleEvent --
#
#    this proc handles events from the entry widget that we want
#    handled specially (typically, to allow navigation of the list
#    even though the focus is in the entry widget)
#
# Arguments:
#
#    w       widget pathname
#    event   a string representing the event (not necessarily an
#            actual event)
#    args    additional arguments required by particular events

proc ::combobox::HandleEvent {w event args} {
    upvar ::combobox::${w}::widgets  widgets
    upvar ::combobox::${w}::options  options
    upvar ::combobox::${w}::oldValue oldValue

    # for all of these events, if we have a special action we'll
    # do that and do a "return -code break" to keep additional 
    # bindings from firing. Otherwise we'll let the event fall
    # on through. 
    switch $event {

        "<MouseWheel>" {
	    if {[winfo ismapped $widgets(dropdown)]} {
                set D [lindex $args 0]
                # the '120' number in the following expression has
                # it's genesis in the tk bind manpage, which suggests
                # that the smallest value of %D for mousewheel events
                # will be 120. The intent is to scroll one line at a time.
                $widgets(listbox) yview scroll [expr {-($D/120)}] units
            }
        } 

	"<Any-KeyPress>" {
	    # if the widget is editable, clear the selection. 
	    # this makes it more obvious what will happen if the 
	    # user presses <Return> (and helps our code know what
	    # to do if the user presses return)
	    if {$options(-editable)} {
		$widgets(listbox) see 0
		$widgets(listbox) selection clear 0 end
		$widgets(listbox) selection anchor 0
		$widgets(listbox) activate 0
	    }
	}

	"<FocusIn>" {
	    set oldValue [$widgets(entry) get]
	}

	"<FocusOut>" {
	    if {![winfo ismapped $widgets(dropdown)]} {
		# did the value change?
		set newValue [$widgets(entry) get]
		if {$oldValue != $newValue} {
		    CallCommand $widgets(this) $newValue
		}
	    }
	}

	"<1>" {
	    set editable [::combobox::GetBoolean $options(-editable)]
	    if {!$editable} {
		if {[winfo ismapped $widgets(dropdown)]} {
		    $widgets(this) close
		    return -code break;

		} else {
		    if {$options(-state) != "disabled"} {
			$widgets(this) open
			return -code break;
		    }
		}
	    }
	}

	"<Double-1>" {
	    if {$options(-state) != "disabled"} {
		$widgets(this) toggle
		return -code break;
	    }
	}

	"<Tab>" {
	    if {[winfo ismapped $widgets(dropdown)]} {
		::combobox::Find $widgets(this) 0
		return -code break;
	    } else {
		::combobox::SetValue $widgets(this) [$widgets(this) get]
	    }
	}

	"<Escape>" {
#	    $widgets(entry) delete 0 end
#	    $widgets(entry) insert 0 $oldValue
	    if {[winfo ismapped $widgets(dropdown)]} {
		$widgets(this) close
		return -code break;
	    }
	}

	"<Return>" {
	    # did the value change?
	    set newValue [$widgets(entry) get]
	    if {$oldValue != $newValue} {
		CallCommand $widgets(this) $newValue
	    }

	    if {[winfo ismapped $widgets(dropdown)]} {
		::combobox::Select $widgets(this) \
			[$widgets(listbox) curselection]
		return -code break;
	    } 

	}

	"<Next>" {
	    $widgets(listbox) yview scroll 1 pages
	    set index [$widgets(listbox) index @0,0]
	    $widgets(listbox) see $index
	    $widgets(listbox) activate $index
	    $widgets(listbox) selection clear 0 end
	    $widgets(listbox) selection anchor $index
	    $widgets(listbox) selection set $index

	}

	"<Prior>" {
	    $widgets(listbox) yview scroll -1 pages
	    set index [$widgets(listbox) index @0,0]
	    $widgets(listbox) activate $index
	    $widgets(listbox) see $index
	    $widgets(listbox) selection clear 0 end
	    $widgets(listbox) selection anchor $index
	    $widgets(listbox) selection set $index
	}

	"<Down>" {
	    if {[winfo ismapped $widgets(dropdown)]} {
		::combobox::tkListboxUpDown $widgets(listbox) 1
		return -code break;

	    } else {
		if {$options(-state) != "disabled"} {
		    $widgets(this) open
		    return -code break;
		}
	    }
	}
	"<Up>" {
	    if {[winfo ismapped $widgets(dropdown)]} {
		::combobox::tkListboxUpDown $widgets(listbox) -1
		return -code break;

	    } else {
		if {$options(-state) != "disabled"} {
		    $widgets(this) open
		    return -code break;
		}
	    }
	}
    }

    return ""
}

# ::combobox::DestroyHandler {w} --
# 
#    Cleans up after a combobox widget is destroyed
#
# Arguments:
#
#    w    widget pathname
#
# Results:
#
#    The namespace that was created for the widget is deleted,
#    and the widget proc is removed.

proc ::combobox::DestroyHandler {w} {

    # if the widget actually being destroyed is of class Combobox,
    # crush the namespace and kill the proc. Get it? Crush. Kill. 
    # Destroy. Heh. Danger Will Robinson! Oh, man! I'm so funny it
    # brings tears to my eyes.
    if {[string compare [winfo class $w] "Combobox"] == 0} {
	upvar ::combobox::${w}::widgets  widgets
	upvar ::combobox::${w}::options  options

	# delete the namespace and the proc which represents
	# our widget
	namespace delete ::combobox::$w
	rename $w {}
    }   

    return ""
}

# ::combobox::Find
#
#    finds something in the listbox that matches the pattern in the
#    entry widget and selects it
#
#    N.B. I'm not convinced this is working the way it ought to. It
#    works, but is the behavior what is expected? I've also got a gut
#    feeling that there's a better way to do this, but I'm too lazy to
#    figure it out...
#
# Arguments:
#
#    w      widget pathname
#    exact  boolean; if true an exact match is desired
#
# Returns:
#
#    Empty string

proc ::combobox::Find {w {exact 0}} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    ## *sigh* this logic is rather gross and convoluted. Surely
    ## there is a more simple, straight-forward way to implement
    ## all this. As the saying goes, I lack the time to make it
    ## shorter...

    # use what is already in the entry widget as a pattern
    set pattern [$widgets(entry) get]

    if {[string length $pattern] == 0} {
	# clear the current selection
	$widgets(listbox) see 0
	$widgets(listbox) selection clear 0 end
	$widgets(listbox) selection anchor 0
	$widgets(listbox) activate 0
	return
    }

    # we're going to be searching this list...
    set list [$widgets(listbox) get 0 end]

    # if we are doing an exact match, try to find,
    # well, an exact match
    set exactMatch -1
    if {$exact} {
	set exactMatch [lsearch -exact $list $pattern]
    }

    # search for it. We'll try to be clever and not only
    # search for a match for what they typed, but a match for
    # something close to what they typed. We'll keep removing one
    # character at a time from the pattern until we find a match
    # of some sort.
    set index -1
    while {$index == -1 && [string length $pattern]} {
	set index [lsearch -glob $list "$pattern*"]
	if {$index == -1} {
	    regsub {.$} $pattern {} pattern
	}
    }

    # this is the item that most closely matches...
    set thisItem [lindex $list $index]

    # did we find a match? If so, do some additional munging...
    if {$index != -1} {

	# we need to find the part of the first item that is 
	# unique WRT the second... I know there's probably a
	# simpler way to do this... 

	set nextIndex [expr {$index + 1}]
	set nextItem [lindex $list $nextIndex]

	# we don't really need to do much if the next
	# item doesn't match our pattern...
	if {[string match $pattern* $nextItem]} {
	    # ok, the next item matches our pattern, too
	    # now the trick is to find the first character
	    # where they *don't* match...
	    set marker [string length $pattern]
	    while {$marker <= [string length $pattern]} {
		set a [string index $thisItem $marker]
		set b [string index $nextItem $marker]
		if {[string compare $a $b] == 0} {
		    append pattern $a
		    incr marker
		} else {
		    break
		}
	    }
	} else {
	    set marker [string length $pattern]
	}
	
    } else {
	set marker end
	set index 0
    }

    # ok, we know the pattern and what part is unique;
    # update the entry widget and listbox appropriately
    if {$exact && $exactMatch == -1} {
	# this means we didn't find an exact match
	$widgets(listbox) selection clear 0 end
	$widgets(listbox) see $index

    } elseif {!$exact}  {
	# this means we found something, but it isn't an exact
	# match. If we find something that *is* an exact match we
	# don't need to do the following, since it would merely 
	# be replacing the data in the entry widget with itself
	set oldstate [$widgets(entry) cget -state]
	$widgets(entry) configure -state normal
	$widgets(entry) delete 0 end
	$widgets(entry) insert end $thisItem
	$widgets(entry) selection clear
	$widgets(entry) selection range $marker end
	$widgets(listbox) activate $index
	$widgets(listbox) selection clear 0 end
	$widgets(listbox) selection anchor $index
	$widgets(listbox) selection set $index
	$widgets(listbox) see $index
	$widgets(entry) configure -state $oldstate
    }
}

# ::combobox::Select --
#
#    selects an item from the list and sets the value of the combobox
#    to that value
#
# Arguments:
#
#    w      widget pathname
#    index  listbox index of item to be selected
#
# Returns:
#
#    empty string

proc ::combobox::Select {w index} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    # the catch is because I'm sloppy -- presumably, the only time
    # an error will be caught is if there is no selection. 
    if {![catch {set data [$widgets(listbox) get [lindex $index 0]]}]} {
	::combobox::SetValue $widgets(this) $data

	$widgets(listbox) selection clear 0 end
	$widgets(listbox) selection anchor $index
	$widgets(listbox) selection set $index

    }
    $widgets(entry) selection range 0 end

    $widgets(this) close

    return ""
}

# ::combobox::HandleScrollbar --
# 
#    causes the scrollbar of the dropdown list to appear or disappear
#    based on the contents of the dropdown listbox
#
# Arguments:
#
#    w       widget pathname
#    action  the action to perform on the scrollbar
#
# Returns:
#
#    an empty string

proc ::combobox::HandleScrollbar {w {action "unknown"}} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    if {$options(-height) == 0} {
	set hlimit $options(-maxheight)
    } else {
	set hlimit $options(-height)
    }		    

    switch $action {
	"grow" {
	    if {$hlimit > 0 && [$widgets(listbox) size] > $hlimit} {
		pack $widgets(vsb) -side right -fill y -expand n
	    }
	}

	"shrink" {
	    if {$hlimit > 0 && [$widgets(listbox) size] <= $hlimit} {
		pack forget $widgets(vsb)
	    }
	}

	"crop" {
	    # this means the window was cropped and we definitely 
	    # need a scrollbar no matter what the user wants
	    pack $widgets(vsb) -side right -fill y -expand n
	}

	default {
	    if {$hlimit > 0 && [$widgets(listbox) size] > $hlimit} {
		pack $widgets(vsb) -side right -fill y -expand n
	    } else {
		pack forget $widgets(vsb)
	    }
	}
    }

    return ""
}

# ::combobox::ComputeGeometry --
#
#    computes the geometry of the dropdown list based on the size of the
#    combobox...
#
# Arguments:
#
#    w     widget pathname
#
# Returns:
#
#    the desired geometry of the listbox

proc ::combobox::ComputeGeometry {w} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options
    
    if {$options(-height) == 0 && $options(-maxheight) != "0"} {
	# if this is the case, count the items and see if
	# it exceeds our maxheight. If so, set the listbox
	# size to maxheight...
	set nitems [$widgets(listbox) size]
	if {$nitems > $options(-maxheight)} {
	    # tweak the height of the listbox
	    $widgets(listbox) configure -height $options(-maxheight)
	} else {
	    # un-tweak the height of the listbox
	    $widgets(listbox) configure -height 0
	}
	update idletasks
    }

    # compute height and width of the dropdown list
    set bd [$widgets(dropdown) cget -borderwidth]
    set height [expr {[winfo reqheight $widgets(dropdown)] + $bd + $bd}]
    if {[string length $options(-dropdownwidth)] == 0 || 
        $options(-dropdownwidth) == 0} {
        set width [winfo width $widgets(this)]
    } else {
        set m [font measure [$widgets(listbox) cget -font] "m"]
        set width [expr {$options(-dropdownwidth) * $m}]
    }

    # figure out where to place it on the screen, trying to take into
    # account we may be running under some virtual window manager
    set screenWidth  [winfo screenwidth $widgets(this)]
    set screenHeight [winfo screenheight $widgets(this)]
    set rootx        [winfo rootx $widgets(this)]
    set rooty        [winfo rooty $widgets(this)]
    set vrootx       [winfo vrootx $widgets(this)]
    set vrooty       [winfo vrooty $widgets(this)]

    # the x coordinate is simply the rootx of our widget, adjusted for
    # the virtual window. We won't worry about whether the window will
    # be offscreen to the left or right -- we want the illusion that it
    # is part of the entry widget, so if part of the entry widget is off-
    # screen, so will the list. If you want to change the behavior,
    # simply change the if statement... (and be sure to update this
    # comment!)
    set x  [expr {$rootx + $vrootx}]
    if {0} { 
	set rightEdge [expr {$x + $width}]
	if {$rightEdge > $screenWidth} {
	    set x [expr {$screenWidth - $width}]
	}
	if {$x < 0} {set x 0}
    }

    # the y coordinate is the rooty plus vrooty offset plus 
    # the height of the static part of the widget plus 1 for a 
    # tiny bit of visual separation...
    set y [expr {$rooty + $vrooty + [winfo reqheight $widgets(this)] + 1}]
    set bottomEdge [expr {$y + $height}]

    if {$bottomEdge >= $screenHeight} {
	# ok. Fine. Pop it up above the entry widget isntead of
	# below.
	set y [expr {($rooty - $height - 1) + $vrooty}]

	if {$y < 0} {
	    # this means it extends beyond our screen. How annoying.
	    # Now we'll try to be real clever and either pop it up or
	    # down, depending on which way gives us the biggest list. 
	    # then, we'll trim the list to fit and force the use of
	    # a scrollbar

	    # (sadly, for windows users this measurement doesn't
	    # take into consideration the height of the taskbar,
	    # but don't blame me -- there isn't any way to detect
	    # it or figure out its dimensions. The same probably
	    # applies to any window manager with some magic windows
	    # glued to the top or bottom of the screen)

	    if {$rooty > [expr {$screenHeight / 2}]} {
		# we are in the lower half of the screen -- 
		# pop it up. Y is zero; that parts easy. The height
		# is simply the y coordinate of our widget, minus
		# a pixel for some visual separation. The y coordinate
		# will be the topof the screen.
		set y 1
		set height [expr {$rooty - 1 - $y}]

	    } else {
		# we are in the upper half of the screen --
		# pop it down
		set y [expr {$rooty + $vrooty + \
			[winfo reqheight $widgets(this)] + 1}]
		set height [expr {$screenHeight - $y}]

	    }

	    # force a scrollbar
	    HandleScrollbar $widgets(this) crop
	}	   
    }

    if {$y < 0} {
	# hmmm. Bummer.
	set y 0
	set height $screenheight
    }

    set geometry [format "=%dx%d+%d+%d" $width $height $x $y]

    return $geometry
}

# ::combobox::DoInternalWidgetCommand --
#
#    perform an internal widget command, then mung any error results
#    to look like it came from our megawidget. A lot of work just to
#    give the illusion that our megawidget is an atomic widget
#
# Arguments:
#
#    w           widget pathname
#    subwidget   pathname of the subwidget 
#    command     subwidget command to be executed
#    args        arguments to the command
#
# Returns:
#
#    The result of the subwidget command, or an error

proc ::combobox::DoInternalWidgetCommand {w subwidget command args} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    set subcommand $command
    set command [concat $widgets($subwidget) $command $args]
    if {[catch $command result]} {
	# replace the subwidget name with the megawidget name
	regsub $widgets($subwidget) $result $widgets(this) result

	# replace specific instances of the subwidget command
	# with out megawidget command
	switch $subwidget,$subcommand {
	    listbox,index  {regsub "index"  $result "list index"  result}
	    listbox,insert {regsub "insert" $result "list insert" result}
	    listbox,delete {regsub "delete" $result "list delete" result}
	    listbox,get    {regsub "get"    $result "list get"    result}
	    listbox,size   {regsub "size"   $result "list size"   result}
	}
	error $result

    } else {
	return $result
    }
}


# ::combobox::WidgetProc --
#
#    This gets uses as the widgetproc for an combobox widget. 
#    Notice where the widget is created and you'll see that the
#    actual widget proc merely evals this proc with all of the
#    arguments intact.
#
#    Note that some widget commands are defined "inline" (ie:
#    within this proc), and some do most of their work in 
#    separate procs. This is merely because sometimes it was
#    easier to do it one way or the other.
#
# Arguments:
#
#    w         widget pathname
#    command   widget subcommand
#    args      additional arguments; varies with the subcommand
#
# Results:
#
#    Performs the requested widget command

proc ::combobox::WidgetProc {w command args} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options
    upvar ::combobox::${w}::oldFocus oldFocus
    upvar ::combobox::${w}::oldFocus oldGrab

    set command [::combobox::Canonize $w command $command]

    # this is just shorthand notation...
    set doWidgetCommand \
	    [list ::combobox::DoInternalWidgetCommand $widgets(this)]

    if {$command == "list"} {
	# ok, the next argument is a list command; we'll 
	# rip it from args and append it to command to
	# create a unique internal command
	#
	# NB: because of the sloppy way we are doing this,
	# we'll also let the user enter our secret command
	# directly (eg: listinsert, listdelete), but we
	# won't document that fact
	set command "list-[lindex $args 0]"
	set args [lrange $args 1 end]
    }

    set result ""

    # many of these commands are just synonyms for specific
    # commands in one of the subwidgets. We'll get them out
    # of the way first, then do the custom commands.
    switch $command {
	bbox -
	delete -
	get -
	icursor -
	index -
	insert -
	scan -
	selection -
	xview {
	    set result [eval $doWidgetCommand entry $command $args]
	}
	list-get 	{set result [eval $doWidgetCommand listbox get $args]}
	list-index 	{set result [eval $doWidgetCommand listbox index $args]}
	list-size 	{set result [eval $doWidgetCommand listbox size $args]}

	select {
	    if {[llength $args] == 1} {
		set index [lindex $args 0]
		set result [Select $widgets(this) $index]
	    } else {
		error "usage: $w select index"
	    }
	}

	subwidget {
	    set knownWidgets [list button entry listbox dropdown vsb]
	    if {[llength $args] == 0} {
		return $knownWidgets
	    }

	    set name [lindex $args 0]
	    if {[lsearch $knownWidgets $name] != -1} {
		set result $widgets($name)
	    } else {
		error "unknown subwidget $name"
	    }
	}

	curselection {
	    set result [eval $doWidgetCommand listbox curselection]
	}

	list-insert {
	    eval $doWidgetCommand listbox insert $args
	    set result [HandleScrollbar $w "grow"]
	}

	list-delete {
	    eval $doWidgetCommand listbox delete $args
	    set result [HandleScrollbar $w "shrink"]
	}

	toggle {
	    # ignore this command if the widget is disabled...
	    if {$options(-state) == "disabled"} return

	    # pops down the list if it is not, hides it
	    # if it is...
	    if {[winfo ismapped $widgets(dropdown)]} {
		set result [$widgets(this) close]
	    } else {
		set result [$widgets(this) open]
	    }
	}

	open {

	    # if this is an editable combobox, the focus should
	    # be set to the entry widget
	    if {$options(-editable)} {
		focus $widgets(entry)
		$widgets(entry) select range 0 end
		$widgets(entry) icur end
	    }

	    # if we are disabled, we won't allow this to happen
	    if {$options(-state) == "disabled"} {
		return 0
	    }

	    # if there is a -opencommand, execute it now
	    if {[string length $options(-opencommand)] > 0} {
		# hmmm... should I do a catch, or just let the normal
		# error handling handle any errors? For now, the latter...
		uplevel \#0 $options(-opencommand)
	    }

	    # compute the geometry of the window to pop up, and set
	    # it, and force the window manager to take notice
	    # (even if it is not presently visible).
	    #
	    # this isn't strictly necessary if the window is already
	    # mapped, but we'll go ahead and set the geometry here
	    # since its harmless and *may* actually reset the geometry
	    # to something better in some weird case.
	    set geometry [::combobox::ComputeGeometry $widgets(this)]
	    wm geometry $widgets(dropdown) $geometry
	    update idletasks

	    # if we are already open, there's nothing else to do
	    if {[winfo ismapped $widgets(dropdown)]} {
		return 0
	    }

	    # save the widget that currently has the focus; we'll restore
	    # the focus there when we're done
	    set oldFocus [focus]

	    # ok, tweak the visual appearance of things and 
	    # make the list pop up
	    $widgets(button) configure -relief sunken
	    raise $widgets(dropdown) [winfo parent $widgets(this)]
	    wm deiconify $widgets(dropdown) 

	    # force focus to the entry widget so we can handle keypress
	    # events for traversal
	    focus -force $widgets(entry)

	    # select something by default, but only if its an
	    # exact match...
	    ::combobox::Find $widgets(this) 1

	    # save the current grab state for the display containing
	    # this widget. We'll restore it when we close the dropdown
	    # list
	    set status "none"
	    set grab [grab current $widgets(this)]
	    if {$grab != ""} {set status [grab status $grab]}
	    set oldGrab [list $grab $status]
	    unset grab status

	    # *gasp* do a global grab!!! Mom always told me not to
	    # do things like this, but sometimes a man's gotta do
	    # what a man's gotta do.
	    grab -global $widgets(this)

	    # fake the listbox into thinking it has focus. This is 
	    # necessary to get scanning initialized properly in the
	    # listbox.
	    event generate $widgets(listbox) <B1-Enter>

	    return 1
	}

	close {
	    # if we are already closed, don't do anything...
	    if {![winfo ismapped $widgets(dropdown)]} {
		return 0
	    }

	    # restore the focus and grab, but ignore any errors...
	    # we're going to be paranoid and release the grab before
	    # trying to set any other grab because we really really
	    # really want to make sure the grab is released.
	    catch {focus $oldFocus} result
	    catch {grab release $widgets(this)}
	    catch {
		set status [lindex $oldGrab 1]
		if {$status == "global"} {
		    grab -global [lindex $oldGrab 0]
		} elseif {$status == "local"} {
		    grab [lindex $oldGrab 0]
		}
		unset status
	    }

	    # hides the listbox
	    $widgets(button) configure -relief raised
	    wm withdraw $widgets(dropdown) 

	    # select the data in the entry widget. Not sure
	    # why, other than observation seems to suggest that's
	    # what windows widgets do.
	    set editable [::combobox::GetBoolean $options(-editable)]
	    if {$editable} {
		$widgets(entry) selection range 0 end
		$widgets(button) configure -relief raised
	    }


	    # magic tcl stuff (see tk.tcl in the distribution 
	    # lib directory)
	    ::combobox::tkCancelRepeat

	    return 1
	}

	cget {
	    if {[llength $args] != 1} {
		error "wrong # args: should be $w cget option"
	    }
	    set opt [::combobox::Canonize $w option [lindex $args 0]]

	    if {$opt == "-value"} {
		set result [$widgets(entry) get]
	    } else {
		set result $options($opt)
	    }
	}

	configure {
	    set result [eval ::combobox::Configure {$w} $args]
	}

	default {
	    error "bad option \"$command\""
	}
    }

    return $result
}

# ::combobox::Configure --
#
#    Implements the "configure" widget subcommand
#
# Arguments:
#
#    w      widget pathname
#    args   zero or more option/value pairs (or a single option)
#
# Results:
#    
#    Performs typcial "configure" type requests on the widget

proc ::combobox::Configure {w args} {
    variable widgetOptions
    variable defaultEntryCursor

    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    if {[llength $args] == 0} {
	# hmmm. User must be wanting all configuration information
	# note that if the value of an array element is of length
	# one it is an alias, which needs to be handled slightly
	# differently
	set results {}
	foreach opt [lsort [array names widgetOptions]] {
	    if {[llength $widgetOptions($opt)] == 1} {
		set alias $widgetOptions($opt)
		set optName $widgetOptions($alias)
		lappend results [list $opt $optName]
	    } else {
		set optName  [lindex $widgetOptions($opt) 0]
		set optClass [lindex $widgetOptions($opt) 1]
		set default [option get $w $optName $optClass]
		if {[info exists options($opt)]} {
		    lappend results [list $opt $optName $optClass \
			    $default $options($opt)]
		} else {
		    lappend results [list $opt $optName $optClass \
			    $default ""]
		}
	    }
	}

	return $results
    }
    
    # one argument means we are looking for configuration
    # information on a single option
    if {[llength $args] == 1} {
	set opt [::combobox::Canonize $w option [lindex $args 0]]

	set optName  [lindex $widgetOptions($opt) 0]
	set optClass [lindex $widgetOptions($opt) 1]
	set default [option get $w $optName $optClass]
	set results [list $opt $optName $optClass \
		$default $options($opt)]
	return $results
    }

    # if we have an odd number of values, bail. 
    if {[expr {[llength $args]%2}] == 1} {
	# hmmm. An odd number of elements in args
	error "value for \"[lindex $args end]\" missing"
    }
    
    # Great. An even number of options. Let's make sure they 
    # are all valid before we do anything. Note that Canonize
    # will generate an error if it finds a bogus option; otherwise
    # it returns the canonical option name
    foreach {name value} $args {
	set name [::combobox::Canonize $w option $name]
	set opts($name) $value
    }

    # process all of the configuration options
    # some (actually, most) options require us to
    # do something, like change the attributes of
    # a widget or two. Here's where we do that...
    #
    # note that the handling of disabledforeground and
    # disabledbackground is a little wonky. First, we have
    # to deal with backwards compatibility (ie: tk 8.3 and below
    # didn't have such options for the entry widget), and
    # we have to deal with the fact we might want to disable
    # the entry widget but use the normal foreground/background
    # for when the combobox is not disabled, but not editable either.

    set updateVisual 0
    foreach option [array names opts] {
	set newValue $opts($option)
	if {[info exists options($option)]} {
	    set oldValue $options($option)
	}

	switch -- $option {
	    -background {
		set updateVisual 1
		set options($option) $newValue
	    }

	    -borderwidth {
		$widgets(frame) configure -borderwidth $newValue
		set options($option) $newValue
	    }

	    -command {
		# nothing else to do...
		set options($option) $newValue
	    }

	    -commandstate {
		# do some value checking...
		if {$newValue != "normal" && $newValue != "disabled"} {
		    set options($option) $oldValue
		    set message "bad state value \"$newValue\";"
		    append message " must be normal or disabled"
		    error $message
		}
		set options($option) $newValue
	    }

	    -cursor {
		$widgets(frame) configure -cursor $newValue
		$widgets(entry) configure -cursor $newValue
		$widgets(listbox) configure -cursor $newValue
		set options($option) $newValue
	    }

	    -disabledforeground {
		set updateVisual 1
		set options($option) $newValue
	    }

	    -disabledbackground {
		set updateVisual 1
		set options($option) $newValue
	    }

            -dropdownwidth {
                set options($option) $newValue
            }

	    -editable {
		set updateVisual 1
		if {$newValue} {
		    # it's editable...
		    $widgets(entry) configure \
			    -state normal \
			    -cursor $defaultEntryCursor
		} else {
		    $widgets(entry) configure \
			    -state disabled \
			    -cursor $options(-cursor)
		}
		set options($option) $newValue
	    }

	    -font {
		$widgets(entry) configure -font $newValue
		$widgets(listbox) configure -font $newValue
		set options($option) $newValue
	    }

	    -foreground {
		set updateVisual 1
		set options($option) $newValue
	    }

	    -height {
		$widgets(listbox) configure -height $newValue
		HandleScrollbar $w
		set options($option) $newValue
	    }

	    -highlightbackground {
		$widgets(frame) configure -highlightbackground $newValue
		set options($option) $newValue
	    }

	    -highlightcolor {
		$widgets(frame) configure -highlightcolor $newValue
		set options($option) $newValue
	    }

	    -highlightthickness {
		$widgets(frame) configure -highlightthickness $newValue
		set options($option) $newValue
	    }
	    
	    -image {
		if {[string length $newValue] > 0} {
		    $widgets(button) configure -image $newValue
		} else {
		    $widgets(button) configure -image ::combobox::bimage
		}
		set options($option) $newValue
	    }

	    -maxheight {
		# ComputeGeometry may dork with the actual height
		# of the listbox, so let's undork it
		$widgets(listbox) configure -height $options(-height)
		HandleScrollbar $w
		set options($option) $newValue
	    }

	    -opencommand {
		# nothing else to do...
		set options($option) $newValue
	    }

	    -relief {
		$widgets(frame) configure -relief $newValue
		set options($option) $newValue
	    }

	    -selectbackground {
		$widgets(entry) configure -selectbackground $newValue
		$widgets(listbox) configure -selectbackground $newValue
		set options($option) $newValue
	    }

	    -selectborderwidth {
		$widgets(entry) configure -selectborderwidth $newValue
		$widgets(listbox) configure -selectborderwidth $newValue
		set options($option) $newValue
	    }

	    -selectforeground {
		$widgets(entry) configure -selectforeground $newValue
		$widgets(listbox) configure -selectforeground $newValue
		set options($option) $newValue
	    }

	    -state {
		if {$newValue == "normal"} {
		    set updateVisual 1
		    # it's enabled

		    set editable [::combobox::GetBoolean \
			    $options(-editable)]
		    if {$editable} {
			$widgets(entry) configure -state normal
			$widgets(entry) configure -takefocus 1
		    }

                    # note that $widgets(button) is actually a label,
                    # not a button. And being able to disable labels
                    # wasn't possible until tk 8.3. (makes me wonder
		    # why I chose to use a label, but that answer is
		    # lost to antiquity)
                    if {[info patchlevel] >= 8.3} {
                        $widgets(button) configure -state normal
                    }

		} elseif {$newValue == "disabled"}  {
		    set updateVisual 1
		    # it's disabled
		    $widgets(entry) configure -state disabled
		    $widgets(entry) configure -takefocus 0
                    # note that $widgets(button) is actually a label,
                    # not a button. And being able to disable labels
                    # wasn't possible until tk 8.3. (makes me wonder
		    # why I chose to use a label, but that answer is
		    # lost to antiquity)
                    if {$::tcl_version >= 8.3} {
                        $widgets(button) configure -state disabled 
                    }

		} else {
		    set options($option) $oldValue
		    set message "bad state value \"$newValue\";"
		    append message " must be normal or disabled"
		    error $message
		}

		set options($option) $newValue
	    }

	    -takefocus {
		$widgets(entry) configure -takefocus $newValue
		set options($option) $newValue
	    }

	    -textvariable {
		$widgets(entry) configure -textvariable $newValue
		set options($option) $newValue
	    }

	    -value {
		::combobox::SetValue $widgets(this) $newValue
		set options($option) $newValue
	    }

	    -width {
		$widgets(entry) configure -width $newValue
		$widgets(listbox) configure -width $newValue
		set options($option) $newValue
	    }

	    -xscrollcommand {
		$widgets(entry) configure -xscrollcommand $newValue
		set options($option) $newValue
	    }
	}	    

	if {$updateVisual} {UpdateVisualAttributes $w}
    }
}

# ::combobox::UpdateVisualAttributes --
#
# sets the visual attributes (foreground, background mostly) 
# based on the current state of the widget (normal/disabled, 
# editable/non-editable)
#
# why a proc for such a simple thing? Well, in addition to the
# various states of the widget, we also have to consider the 
# version of tk being used -- versions from 8.4 and beyond have
# the notion of disabled foreground/background options for various
# widgets. All of the permutations can get nasty, so we encapsulate
# it all in one spot.
#
# note also that we don't handle all visual attributes here; just
# the ones that depend on the state of the widget. The rest are 
# handled on a case by case basis
#
# Arguments:
#    w		widget pathname
#
# Returns:
#    empty string

proc ::combobox::UpdateVisualAttributes {w} {

    upvar ::combobox::${w}::widgets     widgets
    upvar ::combobox::${w}::options     options

    if {$options(-state) == "normal"} {

	set foreground $options(-foreground)
	set background $options(-background)
	
    } elseif {$options(-state) == "disabled"} {

	set foreground $options(-disabledforeground)
	set background $options(-disabledbackground)
    }

    $widgets(entry)   configure -foreground $foreground -background $background
    $widgets(listbox) configure -foreground $foreground -background $background
    $widgets(button)  configure -foreground $foreground 
    $widgets(vsb)     configure -background $background -troughcolor $background
    $widgets(frame)   configure -background $background

    # we need to set the disabled colors in case our widget is disabled. 
    # We could actually check for disabled-ness, but we also need to 
    # check whether we're enabled but not editable, in which case the 
    # entry widget is disabled but we still want the enabled colors. It's
    # easier just to set everything and be done with it.
    
    if {$::tcl_version >= 8.4} {
	$widgets(entry) configure \
	    -disabledforeground $foreground \
	    -disabledbackground $background
	$widgets(button)  configure -disabledforeground $foreground
	$widgets(listbox) configure -disabledforeground $foreground
    }
}

# ::combobox::SetValue --
#
#    sets the value of the combobox and calls the -command, 
#    if defined
#
# Arguments:
#
#    w          widget pathname
#    newValue   the new value of the combobox
#
# Returns
#
#    Empty string

proc ::combobox::SetValue {w newValue} {

    upvar ::combobox::${w}::widgets     widgets
    upvar ::combobox::${w}::options     options
    upvar ::combobox::${w}::ignoreTrace ignoreTrace
    upvar ::combobox::${w}::oldValue    oldValue

    if {[info exists options(-textvariable)] \
	    && [string length $options(-textvariable)] > 0} {
	set variable ::$options(-textvariable)
	set $variable $newValue
    } else {
	set oldstate [$widgets(entry) cget -state]
	$widgets(entry) configure -state normal
	$widgets(entry) delete 0 end
	$widgets(entry) insert 0 $newValue
	$widgets(entry) configure -state $oldstate
    }

    # set our internal textvariable; this will cause any public
    # textvariable (ie: defined by the user) to be updated as
    # well
#    set ::combobox::${w}::entryTextVariable $newValue

    # redefine our concept of the "old value". Do it before running
    # any associated command so we can be sure it happens even
    # if the command somehow fails.
    set oldValue $newValue


    # call the associated command. The proc will handle whether or 
    # not to actually call it, and with what args
    CallCommand $w $newValue

    return ""
}

# ::combobox::CallCommand --
#
#   calls the associated command, if any, appending the new
#   value to the command to be called.
#
# Arguments:
#
#    w         widget pathname
#    newValue  the new value of the combobox
#
# Returns
#
#    empty string

proc ::combobox::CallCommand {w newValue} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options
    
    # call the associated command, if defined and -commandstate is
    # set to "normal"
    if {$options(-commandstate) == "normal" && \
	    [string length $options(-command)] > 0} {
	set args [list $widgets(this) $newValue]
	uplevel \#0 $options(-command) $args
    }
}


# ::combobox::GetBoolean --
#
#     returns the value of a (presumably) boolean string (ie: it should
#     do the right thing if the string is "yes", "no", "true", 1, etc
#
# Arguments:
#
#     value       value to be converted 
#     errorValue  a default value to be returned in case of an error
#
# Returns:
#
#     a 1 or zero, or the value of errorValue if the string isn't
#     a proper boolean value

proc ::combobox::GetBoolean {value {errorValue 1}} {
    if {[catch {expr {([string trim $value])?1:0}} res]} {
	return $errorValue
    } else {
	return $res
    }
}

# ::combobox::convert --
#
#     public routine to convert %x, %y and %W binding substitutions.
#     Given an x, y and or %W value relative to a given widget, this
#     routine will convert the values to be relative to the combobox
#     widget. For example, it could be used in a binding like this:
#
#     bind .combobox <blah> {doSomething [::combobox::convert %W -x %x]}
#
#     Note that this procedure is *not* exported, but is intended for
#     public use. It is not exported because the name could easily 
#     clash with existing commands. 
#
# Arguments:
#
#     w     a widget path; typically the actual result of a %W 
#           substitution in a binding. It should be either a
#           combobox widget or one of its subwidgets
#
#     args  should one or more of the following arguments or 
#           pairs of arguments:
#
#           -x <x>      will convert the value <x>; typically <x> will
#                       be the result of a %x substitution
#           -y <y>      will convert the value <y>; typically <y> will
#                       be the result of a %y substitution
#           -W (or -w)  will return the name of the combobox widget
#                       which is the parent of $w
#
# Returns:
#
#     a list of the requested values. For example, a single -w will
#     result in a list of one items, the name of the combobox widget.
#     Supplying "-x 10 -y 20 -W" (in any order) will return a list of
#     three values: the converted x and y values, and the name of 
#     the combobox widget.

proc ::combobox::convert {w args} {
    set result {}
    if {![winfo exists $w]} {
	error "window \"$w\" doesn't exist"
    }

    while {[llength $args] > 0} {
	set option [lindex $args 0]
	set args [lrange $args 1 end]

	switch -exact -- $option {
	    -x {
		set value [lindex $args 0]
		set args [lrange $args 1 end]
		set win $w
		while {[winfo class $win] != "Combobox"} {
		    incr value [winfo x $win]
		    set win [winfo parent $win]
		    if {$win == "."} break
		}
		lappend result $value
	    }

	    -y {
		set value [lindex $args 0]
		set args [lrange $args 1 end]
		set win $w
		while {[winfo class $win] != "Combobox"} {
		    incr value [winfo y $win]
		    set win [winfo parent $win]
		    if {$win == "."} break
		}
		lappend result $value
	    }

	    -w -
	    -W {
		set win $w
		while {[winfo class $win] != "Combobox"} {
		    set win [winfo parent $win]
		    if {$win == "."} break;
		}
		lappend result $win
	    }
	}
    }
    return $result
}

# ::combobox::Canonize --
#
#    takes a (possibly abbreviated) option or command name and either 
#    returns the canonical name or an error
#
# Arguments:
#
#    w        widget pathname
#    object   type of object to canonize; must be one of "command",
#             "option", "scan command" or "list command"
#    opt      the option (or command) to be canonized
#
# Returns:
#
#    Returns either the canonical form of an option or command,
#    or raises an error if the option or command is unknown or
#    ambiguous.

proc ::combobox::Canonize {w object opt} {
    variable widgetOptions
    variable columnOptions
    variable widgetCommands
    variable listCommands
    variable scanCommands

    switch $object {
	command {
	    if {[lsearch -exact $widgetCommands $opt] >= 0} {
		return $opt
	    }

	    # command names aren't stored in an array, and there
	    # isn't a way to get all the matches in a list, so
	    # we'll stuff the commands in a temporary array so
	    # we can use [array names]
	    set list $widgetCommands
	    foreach element $list {
		set tmp($element) ""
	    }
	    set matches [array names tmp ${opt}*]
	}

	{list command} {
	    if {[lsearch -exact $listCommands $opt] >= 0} {
		return $opt
	    }

	    # command names aren't stored in an array, and there
	    # isn't a way to get all the matches in a list, so
	    # we'll stuff the commands in a temporary array so
	    # we can use [array names]
	    set list $listCommands
	    foreach element $list {
		set tmp($element) ""
	    }
	    set matches [array names tmp ${opt}*]
	}

	{scan command} {
	    if {[lsearch -exact $scanCommands $opt] >= 0} {
		return $opt
	    }

	    # command names aren't stored in an array, and there
	    # isn't a way to get all the matches in a list, so
	    # we'll stuff the commands in a temporary array so
	    # we can use [array names]
	    set list $scanCommands
	    foreach element $list {
		set tmp($element) ""
	    }
	    set matches [array names tmp ${opt}*]
	}

	option {
	    if {[info exists widgetOptions($opt)] \
		    && [llength $widgetOptions($opt)] == 2} {
		return $opt
	    }
	    set list [array names widgetOptions]
	    set matches [array names widgetOptions ${opt}*]
	}

    }

    if {[llength $matches] == 0} {
	set choices [HumanizeList $list]
	error "unknown $object \"$opt\"; must be one of $choices"

    } elseif {[llength $matches] == 1} {
	set opt [lindex $matches 0]

	# deal with option aliases
	switch $object {
	    option {
		set opt [lindex $matches 0]
		if {[llength $widgetOptions($opt)] == 1} {
		    set opt $widgetOptions($opt)
		}
	    }
	}

	return $opt

    } else {
	set choices [HumanizeList $list]
	error "ambiguous $object \"$opt\"; must be one of $choices"
    }
}

# ::combobox::HumanizeList --
#
#    Returns a human-readable form of a list by separating items
#    by columns, but separating the last two elements with "or"
#    (eg: foo, bar or baz)
#
# Arguments:
#
#    list    a valid tcl list
#
# Results:
#
#    A string which as all of the elements joined with ", " or 
#    the word " or "

proc ::combobox::HumanizeList {list} {

    if {[llength $list] == 1} {
	return [lindex $list 0]
    } else {
	set list [lsort $list]
	set secondToLast [expr {[llength $list] -2}]
	set most [lrange $list 0 $secondToLast]
	set last [lindex $list end]

	return "[join $most {, }] or $last"
    }
}

# This is some backwards-compatibility code to handle TIP 44
# (http://purl.org/tcl/tip/44.html). For all private tk commands
# used by this widget, we'll make duplicates of the procs in the
# combobox namespace. 
#
# I'm not entirely convinced this is the right thing to do. I probably
# shouldn't even be using the private commands. Then again, maybe the
# private commands really should be public. Oh well; it works so it
# must be OK...
foreach command {TabToWindow CancelRepeat ListboxUpDown} {
    if {[llength [info commands ::combobox::tk$command]] == 1} break;

    set tmp [info commands tk$command]
    set proc ::combobox::tk$command
    if {[llength [info commands tk$command]] == 1} {
        set command [namespace which [lindex $tmp 0]]
        proc $proc {args} "uplevel $command \$args"
    } else {
        if {[llength [info commands ::tk::$command]] == 1} {
            proc $proc {args} "uplevel ::tk::$command \$args"
        }
    }
}

# end of combobox.tcl

#!/usr/bin/wish
#
# I am D. Richard Hipp, the author of this code.  I hereby
# disavow all claims to copyright on this program and release
# it into the public domain. 
#
#                     D. Richard Hipp
#                     January 31, 2001
#
# As an historical record, the original copyright notice is
# reproduced below:
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
# $Revision: 1.7 $
# $Revision: 1.8 $ 
#       Added delete,insert sibling,insert child,moveup and movedown
#       By: Eduardo Basurto http://www.lalosworld.com Dec/17/2002
#
#
# Create a new tree widget.  $args become the configuration arguments to
# the canvas widget from which the tree is constructed.
#
proc Tree:create {w args} {
  global Tree
  eval canvas $w -bg white $args
#  catch {bind $w <Destroy> "Tree:delitem $w /"}
  Tree:dfltconfig $w /
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
  set dir [file dirname $v]
  set n [file tail $v]
  if {![info exists Tree($w:$dir:open)]} {
    error "parent item \"$dir\" is missing"
  }
  set i [lsearch -exact $Tree($w:$dir:children) $n]
  if {$i>=0} {
    #error "item \"$v\" already exists"
	  tk_dialog .loadPopup.tmp1 ERROR \
                        "item \"$v\" is a duplicate" \
                                error 0 OK
  } else {
  	lappend Tree($w:$dir:children) $n
  	Tree:dfltconfig $w $v
  	foreach {op arg} $args {
    		switch -exact -- $op {
      			-image {set Tree($w:$v:icon) $arg}
      			-tags {set Tree($w:$v:tags) $arg}
    		}
  	}
  }
  Tree:buildwhenidle $w
}


#
# Delete element $v from the tree $w.  If $v is /, then the widget is
# deleted.
#
proc Tree:delitem {w v} {
  global Tree
  if {![info exists Tree($w:$v:open)]} return
  if {[string compare $v /]==0} {
    # delete the whole widget
    catch {destroy $w}
    foreach t [array names Tree $w:*] {
      if {[info exists Tree($t)]} {
        catch {unset Tree($t)}
      }
    }
  }
  foreach c $Tree($w:$v:children) {
    catch {Tree:delitem $w $v/$c}
  }
  unset Tree($w:$v:open)
  unset Tree($w:$v:children)
  unset Tree($w:$v:icon)
  set dir [file dirname $v]
  set n [file tail $v]
  set i [lsearch -exact $Tree($w:$dir:children) $n]
  if {$i>=0} {
    set Tree($w:$dir:children) [lreplace $Tree($w:$dir:children) $i $i]
  }
  Tree:buildwhenidle $w
}

#
# Change the selection to the indicated item
#
proc Tree:setselection {w v} {
  global Tree
  set Tree($w:selection) $v
  Tree:drawselection $w
}

# 
# Retrieve the current selection
#
proc Tree:getselection {w} {
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
  Tree:buildlayer $w / 10
  $w config -scrollregion [$w bbox all]
  Tree:drawselection $w
}

# Internal use only.
# Build a single layer of the tree on the canvas.  Indent by $in pixels
proc Tree:buildlayer {w v in} {
  global Tree
  if {$v=="/"} {
    set vx {}
  } else {
    set vx $v
  }
  set start [expr $Tree($w:y)-10]
  foreach c $Tree($w:$v:children) {
    set y $Tree($w:y)
    incr Tree($w:y) 17
    $w create line $in $y [expr $in+10] $y -fill gray50 
    set icon $Tree($w:$vx/$c:icon)
    set taglist x
    foreach tag $Tree($w:$vx/$c:tags) {
      lappend taglist $tag
    }
    set x [expr $in+12]
    if {[string length $icon]>0} {
      set k [$w create image $x $y -image $icon -anchor w -tags $taglist]
      incr x 20
      set Tree($w:tag:$k) $vx/$c
    }
    set j [$w create text $x $y -text $c -font $Tree(font) \
                                -anchor w -tags $taglist]
    set Tree($w:tag:$j) $vx/$c
    set Tree($w:$vx/$c:tag) $j
    if {[string length $Tree($w:$vx/$c:children)]} {
      if {$Tree($w:$vx/$c:open)} {
         set j [$w create image $in $y -image Tree:openbm]
         $w bind $j <1> "set Tree($w:$vx/$c:open) 0; Tree:build $w"
         Tree:buildlayer $w $vx/$c [expr $in+18]
      } else {
         set j [$w create image $in $y -image Tree:closedbm]
         $w bind $j <1> "set Tree($w:$vx/$c:open) 1; Tree:build $w"
      }
    }
  }
  set j [$w create line $in $start $in [expr $y+1] -fill gray50 ]
  $w lower $j
}

# Open a branch of a tree
#
proc Tree:open {w v} {
  global Tree
  if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==0
      && [info exists Tree($w:$v:children)] 
      && [string length $Tree($w:$v:children)]>0} {
    set Tree($w:$v:open) 1
    Tree:build $w
  }
}

proc Tree:close {w v} {
  global Tree
  if {[info exists Tree($w:$v:open)] && $Tree($w:$v:open)==1} {
    set Tree($w:$v:open) 0
    Tree:build $w
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
  if {[string length $v]==0} return
  if {![info exists Tree($w:$v:tag)]} return
  set bbox [$w bbox $Tree($w:$v:tag)]
  if {[llength $bbox]==4} {
    set i [eval $w create rectangle $bbox -fill skyblue -outline {{}}]
    set Tree($w:selidx) $i
    $w lower $i
  } else {
    set Tree($w:selidx) {}
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

############################################################
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
      return $Tree($w:tag:$m)
    }
  }
  return ""
}

############################################################
#
# Get index of element $v from the tree $w.
#
proc Tree:getindex {w v} {
  global Tree
  set dir [file dirname $v]
  set n [file tail $v]
  if {![info exists Tree($w:$dir:open)]} {
    error "parent item \"$dir\" is missing"
  }
  set i [lsearch -exact $Tree($w:$dir:children) $n]
  return $i
}

############################################################
#
# Insert a new element $v into $idx row the tree $w.
#
proc Tree:insertitem {w v args idx} {
  global Tree
  set dir [file dirname $v]
  set n [file tail $v]
  if {![info exists Tree($w:$dir:open)]} {
    error "parent item \"$dir\" is missing"
  }
  set i [lsearch $Tree($w:$dir:children) $n]
  if {$i>=0} {
    error "item \"$v\" already exists"
  }
  set Tree($w:$dir:children) [linsert $Tree($w:$dir:children) $idx $n]
  Tree:dfltconfig $w $v
  foreach {op arg} $args {
    switch -exact -- $op {
      -image {set Tree($w:$v:icon) $arg}
      -tags {set Tree($w:$v:tags) $arg}
    }
  }
  Tree:buildwhenidle $w
}


############################################################
#
# Save a branch $v from the tree $w.
#
proc saveBranch {w v} {
  global Tree
  global tmpTree
  if {[info exists Tree($w:$v:children)] && [string length $Tree($w:$v:children)]>0} {
    lappend tmpTree $v
    foreach branch $Tree($w:$v:children) {
      saveBranch $w $v/$branch
    }
  } else {
    lappend tmpTree $v
  }
}

############################################################
#
# Restore a branch $v from the tree $w.
#
proc restoreBranch {w} {
  global Tree
  global tmpTree
  image create photo ifile -data {
      R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4+P///wAAAAAAAAAAACwAAAAAEAAQAAADPkixzPOD
      yADrWE8qC8WN0+BZAmBq1GMOqwigXFXCrGk/cxjjr27fLtout6n9eMIYMTXsFZsogXRKJf6u
      P0kCADv/
  }
  image create photo idir -data {
      R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4APj4+P///wAAAAAAACwAAAAAEAAQAAADPVi63P4w
      LkKCtTTnUsXwQqBtAfh910UU4ugGAEucpgnLNY3Gop7folwNOBOeiEYQ0acDpp6pGAFArVqt
      hQQAO///
  }
  foreach branch $tmpTree {
    if {[lindex [split $branch =] 1]!= ""} {
      Tree:newitem $w $branch -image ifile
    } else {
      Tree:newitem $w $branch -image idir
    }
  }
}

############################################################
#
# Move Up an element $v from the tree $w.
#
proc Tree:moveupitem {w v} {
  global Tree
  global tmpTree
  image create photo ifile -data {
      R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4+P///wAAAAAAAAAAACwAAAAAEAAQAAADPkixzPOD
      yADrWE8qC8WN0+BZAmBq1GMOqwigXFXCrGk/cxjjr27fLtout6n9eMIYMTXsFZsogXRKJf6u
      P0kCADv/
  }
  image create photo idir -data {
      R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4APj4+P///wAAAAAAACwAAAAAEAAQAAADPVi63P4w
      LkKCtTTnUsXwQqBtAfh910UU4ugGAEucpgnLNY3Gop7folwNOBOeiEYQ0acDpp6pGAFArVqt
      hQQAO///
  }
  set dir [file dirname $v]
  set n [file tail $v]
  set arg {-image ifile}
  if {![info exists Tree($w:$dir:open)]} {
    error "parent item \"$dir\" is missing"
  }
  set i [lsearch $Tree($w:$dir:children) $n]
  if {$i>0} {
    if {[info exists Tree($w:$v:children)] && [string length $Tree($w:$v:children)]>0} {
      catch {unset tmpTree}
      foreach branch $Tree($w:$v:children) {
        saveBranch $w $v/$branch
      }
      catch {Tree:delitem $w $v}
      Tree:insertitem $w $v {-image idir} [expr $i-1]
      restoreBranch $w
    } else {
      catch {Tree:delitem $w $v}
      Tree:insertitem $w $v {-image ifile} [expr $i-1]
    }
  }
}

############################################################
#
# Move Down an element $v from the tree $w.
#
proc Tree:movedownitem {w v} {
  global Tree
  global tmpTree
  image create photo ifile -data {
      R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4+P///wAAAAAAAAAAACwAAAAAEAAQAAADPkixzPOD
      yADrWE8qC8WN0+BZAmBq1GMOqwigXFXCrGk/cxjjr27fLtout6n9eMIYMTXsFZsogXRKJf6u
      P0kCADv/
  }
  image create photo idir -data {
      R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4APj4+P///wAAAAAAACwAAAAAEAAQAAADPVi63P4w
      LkKCtTTnUsXwQqBtAfh910UU4ugGAEucpgnLNY3Gop7folwNOBOeiEYQ0acDpp6pGAFArVqt
      hQQAO///
  }
  set dir [file dirname $v]
  set n [file tail $v]
  set arg {-image ifile}
  if {![info exists Tree($w:$dir:open)]} {
    error "parent item \"$dir\" is missing"
  }
  set bottomChild [llength $Tree($w:$dir:children)]
  set i [lsearch $Tree($w:$dir:children) $n]
  if {[expr $i+1]<$bottomChild} {
    if {[info exists Tree($w:$v:children)] && [string length $Tree($w:$v:children)]>0} {
      catch {unset tmpTree}
      foreach branch $Tree($w:$v:children) {
        saveBranch $w $v/$branch
      }
      catch {Tree:delitem $w $v}
      Tree:insertitem $w $v {-image idir} [expr $i+1]
      restoreBranch $w
    } else {
      catch {Tree:delitem $w $v}
      Tree:insertitem $w $v {-image ifile} [expr $i+1]
    }
  }
}

#!/usr/bin/wish
#
############################################################
#
# Obtain the a level path
#
proc getPath { idx array level } {
  set ret_val ""
  for { set x [expr $idx - 1]} { $x >= 0 } { incr x -1 } {
    if { [lindex [lindex $array $x] 1] == $level } {
      set ret_val [lindex [lindex $array $x] 2]
      break
    }
  }
  return $ret_val
}

############################################################
#
# Read a DV file
#
#
proc readDV { DVfile null slash backslash duplicate checkdup} {
  if {![info exists null]} {set null "null"}
  if {![info exists slash]} {set slash "~"}
  if {![info exists backslash]} {set backslash "~"}
  if {![info exists duplicate]} {set duplicate "remove"}
  if {![info exists checkdup]} {set checkdup 0}

  # Read the file and store in a list
  set fp [open $DVfile r]
  set data [read $fp]
  close $fp

  # Process data file
  set data [split $data "\n"]
  set ret_val []
  set x 1
  set attr ""
  set level 0
  set path ""
  set idx 0
  set stepIdx 1
  set dirAry []
  set singleBraceOpen 0
  set maxFbState [llength $data]
  # Parse file contents
  foreach line $data {
    set attr ""
    set name ""
    set line [string trim $line "\t"]
    set line [string trim $line " "]
    if { [string index $line 0] != "#" } {
      # Not a comment
      if { [string index $line 0] == "\{" } {
        # A folder
        incr level
        set line [string trim $line "\{"]
        set line [string trim $line " "]
        set name [string trim [lindex [split $line =] 0] " "]
        if {$name != ""} {
          if { $path != "" } {
            set path $path/$name
          } else {
            set path $name
          }
          lappend dirAry [list $idx $level $path 1]
          incr idx
          set attr D
        } else {
          # It's single open brace
          set singleBraceOpen 1
        }
      } elseif { [string index $line 0] == "\}" } {
        # Closing folder
        incr level -1
        set path [getPath $idx $dirAry $level]
        set attr ""
        set singleBraceOpen 0
      } else {
        # It's a variable
        set itemAttr [split $line =]
        set name [lindex $itemAttr 0]
        set value [lindex $itemAttr 1]
        # Check if Value has equal sign
        if {[llength $itemAttr] > 2} {
           # Value has equal sign, append rest of value
           for {set i 2} {$i <= [expr [llength $itemAttr]-1]} {incr i} {
              set value $value=[lindex $itemAttr $i]
           }
        }
        if {$singleBraceOpen==0} {
          # Previous line didn't contain an open brace without a name
          set attr I
          if {$value==""} {set value $null}
          # It's a plain variable
          # Mask slashes for tree
          regsub -all / $value $slash value
          # Mask backslashes for tree
          regsub -all {\\} $value $backslash value
	  # Check if it has a path integrated with periods, it must be in level 0
	  set dirs [split $name .]
          if {[llength $dirs]>1 && $level==0} {
            # It's a variable with levels and we are at top level
            regsub -all {([.])} $name / name
	    set chkPath ""
            for {set i 0} {$i<[expr [llength $dirs]-1]} {incr i} {
              set chkPath $chkPath[lindex $dirs $i]
              # Look for this path in the previous paths loaded
	      set retIdx [lsearch $ret_val $chkPath*]
	      if {$retIdx<0} {
                # Path doesn't exist, add it
	        lappend ret_val [list $chkPath "D"]
              } else {
                # Item already exist, check if it's a directory
                set isDir [lindex [lindex $ret_val $retIdx] 1]
                if {$isDir!="D"} {
                   # Change attribute to directory
                   set ret_val [lreplace $ret_val $retIdx $retIdx [list $chkPath "D"]]
	        }
              }
              set chkPath $chkPath/
            }
          }
        } else {
          # Comming from a previous open brace without a name, make this the path
          if { $path != "" } {
            set path $path/$name
          } else {
            set path $name
          }
          lappend dirAry [list $idx $level $path 1]
          incr idx
          set attr D
          set singleBraceOpen 0
        }
      }

      # Start loading values to return variable
      if { $attr != "" } {
        # It's not a comment
	set pathLoaded 0
        if { $attr == "D" } {
          # It's a folder
          if {$checkdup == 1} {
            # Look for existing path
	    set retIdx [lsearch $ret_val $path*]
	    if {$retIdx>=0} {
              # There is an entry with this name
              if {[lindex [lindex $ret_val $retIdx] 0] == $path} {
                 # Already exists as a Path
                 if {$duplicate=="rename"} {
                    # Rename, add *
                    set path $path*
                    lappend ret_val [list $path $attr]
	         }
	      } else {
                 # Check if there is an item with this path name
                 if {[lindex [split [lindex [lindex $ret_val $retIdx] 0] =] 0] == $path} {
                    # Change attribute to Directory instead of Item
                    set ret_val [lreplace $ret_val $retIdx $retIdx [list $path "D"]]
		 } else {
                    # Path doesn't exist
                    lappend ret_val [list $path $attr]
	         }
              }
	    } else {
              # Path doesn't exist
              lappend ret_val [list $path $attr]
            }
          } else {
            # Don't check for duplicates and add, could have errors later on
            lappend ret_val [list $path $attr]
	  }
        } else {
          # It's a variable
          if {$name != ""} {
            if { $path != "" } {
              # There is no path in the variable
              #set name [lindex [lindex $dirAry [expr $idx - 1]] 2]/$name
              set name $path/$name
            }
	    if {$checkdup==1} {
	      # Check if it's a duplicate
              set retIdx [lsearch $ret_val $name*]
              if {$retIdx>=0} {
                if {$duplicate=="rename"} {
                   set name $name*
                   lappend ret_val [list $name=$value $attr]
                }
              } else {
                lappend ret_val [list $name=$value $attr]
              }
            } else {
              # Just add it
              lappend ret_val [list $name=$value $attr]
            }
          }
        }
      }
    }
 
    set percent [expr [expr $stepIdx * 50] / $maxFbState]
    .loadPopup.fbLbl configure -text $percent%
    .loadPopup.fb configure -width [expr [expr $stepIdx * 12] / $maxFbState]
    update idletasks
    incr stepIdx
  }
  return $ret_val
}

package require combobox 2.2
catch {namespace import combobox::*}


switch $tcl_platform(platform) {
  unix {
    set OSName unix
  }
  windows {
    set OSName windows
  }
}


############################################################
#
# Update the current entry
#
proc setNewValue {window} {
  global gw
  global newVal
  global item
  global varName
  global varValue
  global changed
  global null
  global slash
  global backslash
  image create photo ifile -data {
      R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4+P///wAAAAAAAAAAACwAAAAAEAAQAAADPkixzPOD
      yADrWE8qC8WN0+BZAmBq1GMOqwigXFXCrGk/cxjjr27fLtout6n9eMIYMTXsFZsogXRKJf6u
      P0kCADv/
  }
  grab .
  set oldName [lindex [split [file tail $item] "="] 0]
  set oldValue [lindex [split [file tail $item] "="] 1]
  set chkVal [split [file tail $item] =]
  if {[llength $chkVal]>2} {
     for {set i 2} {$i<=[expr [llength $chkVal]-1]} {incr i} {
        set oldValue $oldValue=[lindex $chkVal $i]
     }
  }
  catch {destroy $window}
  regsub -all " " $varValue "" tmpVal
  regsub -all " " $varName "" tmpNam
  set varValue $tmpVal
  set varName $tmpNam
  # Restore spaces
  regsub -all $slash $varValue " " varValue
#  regsub -all $backslash $varValue " " varValue
  set varName [string trim $varName]
  set varValue [string trim $varValue]
  # Mask null entries
  if {$varValue==""} {set varValue $null}
  # The item does not have a variable name
  if {$varName==""} {
    catch {Tree:delitem $gw $item}
  } else {
    # Mask slashes
    regsub -all {\\} $varValue $backslash varValue
    regsub -all / $varValue $slash varValue
    # Check if there were any changes to the original value or Name
    if {[string trim $varValue] != [string trim $oldValue] || [string trim $varName] != [string trim $oldName]} {
       set idx [Tree:getindex $gw $item]
       set path [file dirname $item]
       catch {Tree:delitem $gw $item}
       Tree:insertitem $gw $path/$varName=$varValue {-image ifile} $idx
       set changed 1
    }
  }
}

############################################################
#
# Edit the current entry
#
#
proc getNewValue {} {
  global gw
  global item
  global newVal
  global varName
  global varValue
  global slash
  global backslash
  set ew .editWindow
  set editWindow [toplevel .editWindow -width 10 -height 10]
  set tmpVal ""
  grab $editWindow
  focus $editWindow
  wm resizable $editWindow 0 0
  wm geometry $editWindow +[winfo rootx .]+[winfo rooty .]
  wm transient $editWindow
  label $editWindow.varNameLbl \
     	-text Name
  label $editWindow.varValueLbl \
    	-text Value
  entry $editWindow.varNameEnt \
     	-textvariable varName \
        -width 20
  entry $editWindow.varValueEnt \
      	-textvariable varValue \
      	-width 20
  button $editWindow.okBtn \
      	-command {
                   # Replace spaces for data transfer
                   regsub -all " " $varValue $slash varValue
                   #regsub -all {\\} $varValue $backslash varValue
                   regsub -all " " $varName "" varName
	           setNewValue .editWindow
		   destroy .editWindow
                 } \
      	-width 5 \
      	-text OK
  button $editWindow.cancelBtn \
      	-command {destroy .editWindow} \
      	-width 5 \
      	-text Cancel

  grid $editWindow.varNameLbl -in $editWindow -row 1 -column 1
  grid $editWindow.varValueLbl -in $editWindow -row 1 -column 2
  grid $editWindow.varNameEnt -in $editWindow -row 2 -column 1
  grid $editWindow.varValueEnt -in $editWindow -row 2 -column 2
  grid $editWindow.okBtn -in $editWindow -row 4 -column 1
  grid $editWindow.cancelBtn -in $editWindow -row 4 -column 2
  grid rowconfigure $editWindow 1 -weight 1 -minsize 10
  grid rowconfigure $editWindow 2 -weight 1 -minsize 10
  grid rowconfigure $editWindow 3 -weight 0 -minsize 10
  grid rowconfigure $editWindow 4 -weight 0 -minsize 10
  grid columnconfigure $editWindow 1 -weight 0 -minsize 10
  grid columnconfigure $editWindow 2 -weight 0 -minsize 10
}

############################################################
#
proc editItem {w} {
  global item
  global gw
  global nItem
  global newVal
  global varName
  global varValue
  global treeName
  global null
  global slash
  global backslash
  if {$item!=[subst /$treeName]} {
    set varName [lindex [split [file tail $item] "="] 0]
    set varValue [lindex [split [file tail $item] "="] 1]
    set chkVal [split $item =]
    if {[llength $chkVal]>2} {
       for {set i 2} {$i<=[expr [llength $chkVal]-1]} {incr i} {
          set varValue $varValue=[lindex $chkVal $i]
       }
    }
    if {$varValue==$null} {set varValue ""}
    regsub -all $backslash $varValue {\\} varValue
    regsub -all $slash $varValue / varValue
    set path [file dirname $item]
    set isItem [regexp "=" $item]
    if {$isItem == 1} {
        getNewValue
    } else {
        tk_messageBox -message "Cannot change folder, delete it." -title Warning
    }
  } else {
    tk_messageBox -message "Can not edit Main Branch." -title Warning
  }
}

############################################################
#
proc deleteItem {w} {
  global changed
  global gw
  global item
  global treeName
  if {$item!=[subst /$treeName]} {
    Tree:setselection $w $item
    catch {Tree:delitem $gw $item}
    set changed 1
  } else {
    tk_messageBox -message "Can not delete Main Branch." -title Warning
  }
}

############################################################
#
proc insertChildItem {w} {
  global changed
  global item
  global gw
  global nItem
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
  set varName [lindex [split [file tail $item] "="] 0]
  set path [file dirname $item]
  set isItem [regexp "=" $item]
  if {$isItem == 1} {
      Tree:setselection $gw $item
      catch {Tree:delitem $gw $item}
      Tree:newitem $gw $path/$varName -image idir
      Tree:newitem $gw $path/$varName/var$nItem=null -image ifile
  } else {
    set path $item
    Tree:newitem $gw $path/var$nItem=null -image ifile
  }
  incr nItem
  set changed 1
  update
}

############################################################
#
proc insertSiblingItem {w} {
  global changed
  global item
  global gw
  global nItem
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
  set varName [lindex [split [file tail $item] "="] 0]
  set path [file dirname $item]
  if {$path!="/"} {
    set isItem [regexp "=" $item]
    Tree:newitem $gw $path/var$nItem=null -image ifile
    incr nItem
    set changed 1
  }
}

############################################################
#
proc goUpOne {} {
  global gw
  global item
  catch {Tree:moveupitem $gw $item}
}

############################################################
#
proc goDownOne {} {
  global gw
  global item
  catch {Tree:movedownitem $gw $item}
}

############################################################
#
proc makeFloatMenuBase {x y} {
  global gw
  global item
  global size
    
  catch {destroy .popupmenu}
  set m [menu .popupmenu -tearoff 0 -cursor hand2];
  set clmn 3

  $m add command \
		-label "   Edit                  " \
                -command {editItem $gw
		          destroy .popupmenu} \
		-hidemargin 1 \
		-columnbreak 0
  $m add command \
		-label "   Insert Child Item     " \
                -command {insertChildItem $gw
		          destroy .popupmenu} \
		-hidemargin 1 \
		-columnbreak 0
  $m add command \
		-label "   Insert Sibling Item   " \
                -command {insertSiblingItem $gw
		          destroy .popupmenu} \
		-hidemargin 1 \
		-columnbreak 0
  $m add command \
		-label "   Delete                " \
		-command {deleteItem $gw
		          destroy .popupmenu} \
		-hidemargin 1 \
		-columnbreak 0
  $m add command \
		-label "   ^ Move Up             " \
                -command {Tree:moveupitem $gw $item 
		          destroy .popupmenu}\
		-hidemargin 1 \
		-columnbreak 0
  $m add command \
		-label "   v Move Down           " \
                -command {Tree:movedownitem $gw $item
		          destroy .popupmenu}\
		-hidemargin 1 \
		-columnbreak 0
  tk_popup $m $x $y
}

############################################################
#
proc drag {command args} {
    global _dragging
    global _lastwidget
    global _dragwidget

    switch $command {
        init {
            # one-time code to initialize variables
            set _lastwidget {}
            set _dragging 0
        }

        start {
            set w [lindex $args 0]
            set _dragging 1
            set _lastwidget $w
            set _dragwidget $w
            $w configure -cursor gobbler
        }

        motion {
            if {!$_dragging} {return}

            set x [lindex $args 0]
            set y [lindex $args 1]
            set w [winfo containing $x $y]
            if {$w != $_lastwidget && [winfo exists $_lastwidget]} {
                event generate $_lastwidget <<DragLeave>>
            }
            set _lastwidget $w
            if {[winfo exists $w]} {
                event generate $w <<DragOver>>
            }
            if {$w == ".l2"}  {
                $_dragwidget configure -cursor gumby
            } else {
                $_dragwidget  configure -cursor gobbler
            }
        }

        stop {
            if {!$_dragging} {return}
            set x [lindex $args 0]
            set y [lindex $args 1]
            set w [winfo containing $x $y]
            if {[winfo exists $w]} {
                event generate $w <<DragLeave>>
                event generate $w <<DragDrop>>
            }
            set _dragging 0
            $_dragwidget configure -cursor {}
        }

        over {
            if {!$_dragging} {return}
            set w [lindex $args 0]
            $w configure -relief raised
        }

        leave {
            if {!$_dragging} {return}
            set w [lindex $args 0]
            $w configure -relief groove
            $w configure -cursor {}
        }

        drop {
            set w [lindex $args 0]
            $w configure -foreground red -text "THUD!!!"
        }
    }
}

############################################################
# Edit the current entry
#
proc waitMessage {w msg} {
  catch {destroy $w}
  set loadPopup [toplevel $w -width 100 -height 200]
#  grab $w
  focus $w
  wm resizable $w 0 0
  wm geometry $w +[winfo rootx .]+[winfo rooty .]
  wm transient $w
  wm overrideredirect $w 0
  wm deiconify $w
#  wm protocol $w WM_DELETE_WINDOW doNothing
  label $w.msgLbl -text $msg
  label $w.fbLbl -text "0%" -width 20
  label $w.fb -bg blue -width 0

  grid $w.msgLbl -in $w -row 2 -column 1
  grid $w.fbLbl -in $w -row 3 -column 1 -sticky "news"
  grid $w.fb -in $w -row 4 -column 1 -sticky sw
  grid rowconfigure $w 1 -weight 1 -minsize 10
  grid rowconfigure $w 2 -weight 1 -minsize 10
  grid rowconfigure $w 3 -weight 1 -minsize 10
  grid rowconfigure $w 4 -weight 1 -minsize 10
  grid columnconfigure $w 1 -weight 0 -minsize 10
}

############################################################
# Get the Tree structure
#
proc saveDVList {item} {
  global saveDV
  global tabSpace
  set tmpStr ""
  if {$tabSpace>0} {
    for {set i 1} {$i<=$tabSpace} {incr i} {
       set tmpStr $tmpStr[subst "\t"]
    }
    set tmpStr $tmpStr$item
  } else {
    set tmpStr $item
  }
  lappend saveDV $tmpStr
}

############################################################
# Get the Tree structure
#
proc getChildren {w dir} {
  global Tree
  global saveDV
  global tabSpace
  set openBrace "\{"
  if {[info exists Tree($w:$dir:children)] && [string length $Tree($w:$dir:children)]>0} {
     saveDVList $openBrace[file tail $dir]
     incr tabSpace
     foreach branch $Tree($w:$dir:children) {
       getChildren $w $dir/$branch
     }
     incr tabSpace -1
     saveDVList "\}"
  } else {
     saveDVList [file tail $dir]
  }
}

############################################################
# Save the Tree structure
#
proc aSaveFile {w} {
  global Tree
  global saveDV
  global treeName
  global tabSpace
  global sysFileName
  global changed
  global null
  global slash
  global backslash
  if {$treeName != ""} {
    if {$sysFileName!="newTree"} {
      catch {destroy .savePopup}
      waitMessage .savePopup "  Saving file, please wait ....   "
      update
      catch {file delete -force $sysFileName}
      set tabSpace 0
      set dir /$treeName
      set saveDV ""
      if {[info exists Tree($w:$dir:children)] && [string length $Tree($w:$dir:children)]>0} {
        foreach branch $Tree($w:$dir:children) {
          if {[info exists Tree($w:$dir/$branch:children)] && [string length $Tree($w:$dir/$branch:children)]>0} {
            getChildren $w $dir/$branch
          } else {
            saveDVList $branch
          }
        }
      }

      set fp [open $sysFileName "w"]
      set cr "\n"
      set stepIdx 1
      set maxFbState [llength $saveDV]
      foreach data $saveDV {
         regsub -all $slash $data / data
         regsub -all $backslash $data {\\} data
         if {[regsub = $data = data]>0} {
           set path [lindex [split $data =] 0]
           set value [lindex [split $data =] 1]
           if {$value==$null} {
	     set data $path
           } else {
             set data $path=$value
           }
         }
         puts -nonewline $fp $data$cr
         set percent [expr [expr $stepIdx * 100] / $maxFbState]
         .savePopup.fbLbl configure -text $percent%
         .savePopup.fb configure -width [expr [expr $stepIdx * 23] / $maxFbState]
         update idletasks
         incr stepIdx
      }
      close $fp

      # Make a backup copy
      file copy -force $sysFileName $sysFileName[list ".bk"]

      set changed 0
      catch {destroy .savePopup}
    } else {
      aSaveAsFile
    }
  }
}

############################################################
#
proc loadFile {fw filename} {
  global Tree
  global gw
  global item
  global nItem
  global changed
  global treeName
  global sysFileName
  global m
  global t
  global OSName
  global null
  global slash
  global backslash
  global duplicate
  global checkdup

  waitMessage .loadPopup "  Loading file, please wait ....   "
  catch {destroy $gw}
  catch {destroy .f.sb}
  catch {unset Tree} 
  switch $OSName {
    unix {
      set Tree(font) \
        -adobe-helvetica-medium-r-normal-*-11-80-100-100-p-56-iso8859-1
    }
    windows {
      set Tree(font) \
        -adobe-helvetica-medium-r-normal-*-14-100-100-100-p-76-iso8859-1
    }
  }
  catch { update }
  set nItem 1
  set sysFileName $filename
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
  # Read DV file
  set data [readDV $filename $null $slash $backslash $duplicate $checkdup]
  set maxFbState [llength $data]
  Tree:create $fw -width 250 -height 400 -yscrollcommand {.f.sb set}
  scrollbar .f.sb -orient vertical -command {$gw yview}
  pack $fw -side left -fill both -expand 1 -padx 5 -pady 5
  pack .f.sb -side left -fill y
  set treeName [split $filename /]
  set treeName [lindex $treeName [expr [llength $treeName]-1]]
  Tree:newitem $fw /$treeName -image idir
  set stepIdx 1
  foreach dataItem $data {
    if { [lindex $dataItem 1] == "D" } {
      Tree:newitem $fw /$treeName/[lindex $dataItem 0] -image idir
    } else {
      Tree:newitem $fw /$treeName/[lindex $dataItem 0] -image ifile
    }
    set percent [expr [expr [expr $stepIdx * 50] / $maxFbState] + 50]
    .loadPopup.fbLbl configure -text $percent%
    .loadPopup.fb configure -width [expr [expr [expr $stepIdx * 12] / $maxFbState] + 12]
    update idletasks
    incr stepIdx
  }
  bind $fw <1> {
    # Mouse click, select item
    set item [Tree:labelat %W %x %y]
    Tree:setselection %W $item
    set tmpList [split $item "="]
    %W configure -cursor {}
  }
  bind $fw <Button-3> {
    # Right click, create a popup menu
    catch {
      set item [Tree:labelat %W %x %y]
      Tree:setselection %W $item
      if {$item != ""} {
        set gw %W
        makeFloatMenuBase %X %Y
      }
    }
  }
  bind $fw <Double-1> {
    # Double click from mouse
    set item [Tree:labelat %W %x %y]
    Tree:setselection %W $item
    if {[lindex [split $item "="] 1] != ""} {
      # It's a variable, edit it!
      set varName [lindex [split [file tail $item] "="] 0]
      set varVal [lindex [split [file tail $item] "="] 1]
      set gw %W
      editItem $gw
    } else {
      # It's a branch, check if open or close
      if {[info exists Tree(%W:$item:open)] && $Tree(%W:$item:open)==1} {
        set Tree(%W:$item:open) 0
        Tree:build %W
      } else {
        Tree:open %W [Tree:labelat %W %x %y]
      }
    }
  }    
#    $fw bind x <Shift-Button-1>{
      # I'm trying to implement drag and drop....
#      set item [Tree:labelat %W %x %y]
#      Tree:setselection %W $item
#      set tmpList [split $item "="]
#      list drag start %W
#    }
#    $fw bind x <Motion> {
      # Still dnd stuff
#      [list drag motion %X %Y]
#    }
#    $fw bind x <ButtonRelease-2> {
      # More dnd stuff
#      drag stop %X %Y
#    }
 
  # Close popup wait message
  catch {destroy .loadPopup}
  # Refresh widgets
  update
  # Set global changed to 0
  set changed 0
  # Enable edit option from main menu
  .f.mb.edit config -state normal
}

############################################################
#
proc fileDialog {w operation treeW} {
  global treeName
  global sysFileName
  global Tree
  #   Type names		Extension(s)	Mac File Type(s)
  #
  #---------------------------------------------------------
  set types {
    {"Config files"	{.cfg}		TEXT}
    {"DV files"		{.dvs .dv}	TEXT}
    {"All files"			*}
  }
  if {$operation == "open"} {
    set file [tk_getOpenFile -filetypes $types -parent $w]
  } else {
    set file [tk_getSaveFile -filetypes $types -parent $w \
      -initialfile Untitled -defaultextension .txt]
  }
  set sysFileName $file
  if [string compare $file ""] {
    set sysFileName $file
    if {$operation=="open"} {
      loadFile $treeW $file
    } else {
      aSaveFile $treeW
      loadFile $treeW $file
    }
  }
}

############################################################
#
#
proc aOpenFile {} {
  global changed
  global treeName
  global gw
  global Tree
  if {$changed == 1} {
    set answer [tk_dialog .dialog1 "dvEditor" "The data in $treeName has changed.\n\n Do you want to save changes?" info 0 Yes No]
    if {$answer == 0} {
      aSaveFile $gw
    }
    destroy .dialog1
  }
  fileDialog .f open $gw
}

############################################################
#
#
proc aSaveAsFile {} {
  global treeName
  global gw
  global Tree
  if {$treeName != ""} {
    fileDialog .f save $gw
  }
}

############################################################
#
#
proc aNewFile {} {
  global changed
  global treeName
  global gw
  global Tree
  global nItem
  global sysFileName
  global OSName
  set answer 0

  if {$changed == 1} {
    set answer [tk_dialog .dialog1 "dvEditor" "The data in $treeName has changed.\n\n Do you want to save changes?" info 0 Yes No Cancel]
    if {$answer == 0} {
      aSaveFile $gw
    } elseif {$answer == 1} {
      destroy .dialog1
    }
  }

  if {$answer!=2} {
    set gw .f.w
    set fw $gw
    catch {destroy $gw}
    catch {destroy .f.sb}
    catch {unset Tree} 
    switch $OSName {
      unix {
        set Tree(font) \
          -adobe-helvetica-medium-r-normal-*-11-80-100-100-p-56-iso8859-1
      }
      windows {
        set Tree(font) \
          -adobe-helvetica-medium-r-normal-*-14-100-100-100-p-76-iso8859-1
      }
    }
    update
    set nItem 1
    set sysFileName "newTree"
    image create photo idir -data {
        R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4APj4+P///wAAAAAAACwAAAAAEAAQAAADPVi63P4w
        LkKCtTTnUsXwQqBtAfh910UU4ugGAEucpgnLNY3Gop7folwNOBOeiEYQ0acDpp6pGAFArVqt
        hQQAO///
    }
    Tree:create $fw -width 250 -height 400 -yscrollcommand {.f.sb set}
    scrollbar .f.sb -orient vertical -command {$gw yview}
    pack $fw -side left -fill both -expand 1 -padx 5 -pady 5
    pack .f.sb -side left -fill y
    set treeName $sysFileName
    set z $treeName
    Tree:newitem $fw /$z -image idir
    # Mouse click
    bind $fw <1> {
      set item [Tree:labelat %W %x %y]
      Tree:setselection %W $item
      set tmpList [split $item "="]
    }
    # Right mouse click
    bind $fw <Button-3> {
      catch {
        set item [Tree:labelat %W %x %y]
        Tree:setselection %W $item
        if {$item != ""} {
          set gw %W
          makeFloatMenuBase %X %Y
        }
      }
    }
    bind $fw <Double-1> {
      set item [Tree:labelat %W %x %y]
      Tree:setselection %W $item
      if {[lindex [split $item "="] 1] != ""} {
        set varName [lindex [split [file tail $item] "="] 0]
        set varVal [lindex [split [file tail $item] "="] 1]
        set gw %W
        editItem $gw
      } else {
        Tree:open %W [Tree:labelat %W %x %y]
      }
    }    
    update
    set changed 0
    .f.mb.edit config -state normal
  }
}

############################################################
#
#
proc callItADay {} {
  global changed
  global treeName
  global gw
  global null
  global duplicate
  global slash
  global backslash
  global checkdup

  set answer 0
  set font \
    -adobe-helvetica-medium-r-normal-*-14-100-100-100-p-76-iso8859-1
  if {$changed == 1} {
    set answer [tk_dialog .dialog1 "dvEditor" "The data in $treeName has changed.\n\n Do you want to save changes?" info 0 Yes No Cancel]
    if {$answer == 0} {
      aSaveFile $gw
    } elseif {$answer == 1} {
      destroy .dialog1
    }
  }
  if {$answer!=2} {
    set fp [open "~/dvEditor.ini" "w"]
    set cr "\n"
    puts -nonewline $fp null=$null$cr
    puts -nonewline $fp duplicate=$duplicate$cr
    puts -nonewline $fp slash=$slash$cr
    puts -nonewline $fp backslash=$backslash$cr
    puts -nonewline $fp checkdup=$checkdup$cr
    close $fp
    exit
  }
}

############################################################
#
# Action disabled
#
#
proc doNothing {} {
   set dummy ""
}

############################################################
#
# Edit the current entry
#
#
proc editorSetup {} {
  global null
  global duplicate
  global slash
  global backslash
  global nullTmp
  global dupTmp
  global slashTmp
  global backslashTmp
  global checkdup
  set sw .setupWindow
  set setupWindow [toplevel .setupWindow -width 10 -height 10]
  grab $setupWindow
  focus $setupWindow
  wm resizable $setupWindow 0 0
  wm geometry $setupWindow +[winfo rootx .]+[winfo rooty .]
  wm transient $setupWindow
  set nullTmp $null
  set dupTmp $duplicate
  set slashTmp $slash
  set backslashTmp $backslash
  label $setupWindow.nullLbl \
   	-text "Default string for empty values"
  label $setupWindow.slashLbl \
   	-text "Default character for / masking in values"
  label $setupWindow.backslashLbl \
   	-text "Default character for \ masking in values"
  label $setupWindow.dupLbl \
      	-text "Default action for duplicate entries"
  entry $setupWindow.nullEnt \
      	-textvariable null \
        -width 20
  entry $setupWindow.slashEnt \
      	-textvariable slash \
      	-width 20
  entry $setupWindow.backslashEnt \
      	-textvariable backslash \
      	-width 20
  label $setupWindow.checkdupLbl \
      	-text "Check for duplicate lines"
  checkbutton $setupWindow.checkdupChk \
	-onvalue "1" \
	-offvalue "0" \
	-variable checkdup
  combobox $setupWindow.dupCombo \
        -textvariable duplicate \
        -editable false \
        -highlightthickness 1
  pack $setupWindow.dupCombo -side left -fill x -expand y
  $setupWindow.dupCombo list insert end remove
  $setupWindow.dupCombo list insert end rename
  $setupWindow.dupCombo configure -width 6

  button $setupWindow.okBtn \
      	-command { set fp [open "~/dvEditor.ini" "w"]
                   set cr "\n"
		   regsub -all " " $null "" null
		   regsub -all " " $slash "" slash
		   regsub -all " " $backslash "" backslash
		   regsub -all " " $duplicate "" duplicate
		   set null [string trim $null]
		   set duplicate [string trim $duplicate]
		   set slash [string index [string trim $slash] 0]
		   set backslash [string index [string trim $backslash] 0]
                   puts -nonewline $fp null=$null$cr
                   puts -nonewline $fp duplicate=$duplicate$cr
                   puts -nonewline $fp slash=$slash$cr
                   puts -nonewline $fp slash=$checkdup$cr
                   puts -nonewline $fp backslash=$backslash$cr
                   puts -nonewline $fp backslash=$checkdup$cr
                   close $fp
	           destroy .setupWindow
                 } \
      	-width 5 \
      	-text OK
  button $setupWindow.cancelBtn \
      	-command {
                  set null $nullTmp
                  set slash $slashTmp
                  set backslash $backslashTmp
                  set duplicate $dupTmp
                  destroy .setupWindow} \
      	-width 5 \
      	-text Cancel

  grid $setupWindow.nullLbl -in $setupWindow -row 1 -column 1 -sticky "w"
  grid $setupWindow.nullEnt -in $setupWindow -row 1 -column 2 -sticky "w"
  grid $setupWindow.slashLbl -in $setupWindow -row 2 -column 1 -sticky "w"
  grid $setupWindow.slashEnt -in $setupWindow -row 2 -column 2 -sticky "w"
  grid $setupWindow.backslashLbl -in $setupWindow -row 3 -column 1 -sticky "w"
  grid $setupWindow.backslashEnt -in $setupWindow -row 3 -column 2 -sticky "w"
  grid $setupWindow.checkdupLbl -in $setupWindow -row 4 -column 1 -sticky "w"
  grid $setupWindow.checkdupChk -in $setupWindow -row 4 -column 2 -sticky "w"
  grid $setupWindow.dupLbl -in $setupWindow -row 5 -column 1 -sticky "w"
  grid $setupWindow.dupCombo -in $setupWindow -row 5 -column 2 -sticky "w"
  grid $setupWindow.okBtn -in $setupWindow -row 7 -column 1
  grid $setupWindow.cancelBtn -in $setupWindow -row 7 -column 2
  grid rowconfigure $setupWindow 1 -weight 1 -minsize 10
  grid rowconfigure $setupWindow 2 -weight 1 -minsize 10
  grid rowconfigure $setupWindow 3 -weight 0 -minsize 10
  grid rowconfigure $setupWindow 4 -weight 0 -minsize 10
  grid rowconfigure $setupWindow 5 -weight 0 -minsize 10
  grid rowconfigure $setupWindow 6 -weight 0 -minsize 10
  grid rowconfigure $setupWindow 7 -weight 0 -minsize 10
  grid columnconfigure $setupWindow 1 -weight 0 -minsize 10
  grid columnconfigure $setupWindow 2 -weight 0 -minsize 10
}

############################################################
# about dvEditor
#
proc aboutWindow {} {
  global release_version
  set w .aboutPopup
  catch {destroy $w}
  set aboutPopup [toplevel $w -width 300 -height 300]
  grab $w
  focus $w
  wm resizable $w 0 0
  wm geometry $w +[winfo rootx .]+[winfo rooty .]
  wm transient $w
  wm overrideredirect $w 0
  wm deiconify $w
  label $w.nameLbl \
        -font -adobe-helvetica-medium-r-bold-*-18-100-100-100-p-76-iso8859-1 \
  	-text "DV file Editor"
  label $w.verLbl \
        -font -adobe-helvetica-medium-r-bold-*-12-100-100-100-p-76-iso8859-1 \
  	-text  "Version $release_version"
  label $w.authorLbl \
        -font -adobe-helvetica-medium-r-bold-*-12-100-100-100-p-76-iso8859-1 \
  	-text "Adventa Control Technologies"
  label $w.contactLbl \
        -font -adobe-helvetica-medium-r-bold-*-12-100-100-100-p-76-iso8859-1 \
  	-text "nocontact@nowhere.com"
  button $w.okBtn \
        -font -adobe-helvetica-medium-r-bold-*-16-100-100-100-p-76-iso8859-1 \
  	-text OK \
        -command {destroy .aboutPopup}

  grid $w.nameLbl -in $w -row 2 -column 1
  grid $w.verLbl -in $w -row 3 -column 1
  grid $w.authorLbl -in $w -row 4 -column 1
#  grid $w.contactLbl -in $w -row 7 -column 1
  grid $w.okBtn -in $w -row 6 -column 1
  grid rowconfigure $w 1 -weight 1 -minsize 10
  grid rowconfigure $w 2 -weight 1 -minsize 10
  grid rowconfigure $w 3 -weight 1 -minsize 10
  grid rowconfigure $w 4 -weight 1 -minsize 10
  grid rowconfigure $w 5 -weight 1 -minsize 10
  grid rowconfigure $w 6 -weight 1 -minsize 10
  grid columnconfigure $w 1 -weight 0 -minsize 10
  wm protocol . WM_DELETE_WINDOW callItADay
}


proc hyperLink {w tag} {
  $w.text tag configure $tag "-background #43ce80 -relief raised -borderwidth 1"
}

############################################################
# browse file
proc browseFile {w fileName wTitle} {
  global OSName env
  if {[file exist $env(ASTK_DIR)/$fileName]==1} {
    switch $OSName {
      unix {
        set font \
          -adobe-helvetica-medium-r-normal-*-11-80-100-100-p-56-iso8859-1
      }
      windows {
        set font \
          -adobe-helvetica-medium-r-normal-*-14-100-100-100-p-76-iso8859-1
      }
    }
    set fp [open $env(ASTK_DIR)/$fileName r]
    set data [read $fp]
    close $fp

    catch {destroy $w}
    toplevel $w
    wm title $w $wTitle
    wm iconname $w "bind"
    wm geometry $w +[winfo rootx .helpWindow]+[winfo rooty .helpWindow]
    focus $w
    frame $w.buttons
    pack $w.buttons -side bottom -fill x -pady 2m
    button $w.buttons.ok -text OK -command "destroy $w"
    pack $w.buttons.ok -side left -expand 1

    text $w.text -yscrollcommand "$w.scroll set" -setgrid true \
	-width 60 -height 24 -font $font -wrap word
    scrollbar $w.scroll -command "$w.text yview"
    pack $w.scroll -side right -fill y
    pack $w.text -expand yes -fill both

    # Add text to widget.
    $w.text insert 0.0 $data
    $w.text mark set insert 0.0
    $w.text configure -state disabled
  } else {
    tk_messageBox -message "Help file is missing!" -title Warning
  }
}

############################################################
# helpWindow
#
proc helpWindow {} {
  global OSName
  switch $OSName {
    unix {
      set font \
        -adobe-helvetica-medium-r-normal-*-11-80-100-100-p-56-iso8859-1
    }
    windows {
      set font \
        -adobe-helvetica-medium-r-normal-*-14-100-100-100-p-76-iso8859-1
    }
  }

	global env
  if {[file exist "$env(ASTK_DIR)/dvEditor.hlp"]==1} {
    set fp [open $env(ASTK_DIR)/dvEditor.hlp r]
    set data [read $fp]
    close $fp
    set w .helpWindow
    catch {destroy $w}
    toplevel $w
    wm title $w "Help for dvEditor"
    wm iconname $w "bind"
    wm geometry $w +[winfo rootx .]+[winfo rooty .]
    #positionWindow $w
    focus $w

    frame $w.buttons
    pack $w.buttons -side bottom -fill x -pady 2m
    button $w.buttons.dismiss -text OK -command "destroy $w"
    pack $w.buttons.dismiss -side left -expand 1

    text $w.text -yscrollcommand "$w.scroll set" -setgrid true \
	-width 60 -height 24 -font $font -wrap word
    scrollbar $w.scroll -command "$w.text yview"
    pack $w.scroll -side right -fill y
    pack $w.text -expand yes -fill both

    # Set up display styles.

    if {[winfo depth $w] > 1} {
        set bold "-background #43ce80 -relief raised -borderwidth 1"
        set normal "-background {} -relief flat"
    } else {
        set bold "-foreground white -background black"
        set normal "-foreground {} -background {}"
    }

    # Add text to widget.
    $w.text insert 0.0 $data
    $w.text insert end \n\n
    $w.text configure -cursor {}
    $w.text insert end \
      {1. Autoshell DV file.} d1
    $w.text insert end \n\n
    $w.text insert end \
      {2. dvEditor configuration.} d2
    $w.text insert end \n\n
    $w.text insert end \
      {3. Editing Items.} d3
    $w.text insert end \n\n
    $w.text insert end \
      {4. Inserting Child Items.} d4
    $w.text insert end \n\n
    $w.text insert end \
      {5. Inserting Sibling Items.} d5
    $w.text insert end \n\n
    $w.text insert end \
      {6. Deleting Items.} d6
    $w.text insert end \n\n
    $w.text insert end \
      {7. Moving Items.} d7

    # Create bindings for tags.

    $w.text tag bind d1 <Any-Enter> {
  #  .helpWindow.text tag configure d1 -background #43ce80 -relief raised -borderwidth 1
    .helpWindow.text configure -cursor hand2
    }
    $w.text tag bind d1 <Any-Leave> {
    .helpWindow.text tag configure d1 -background {} -relief flat 
    .helpWindow.text configure -cursor {}
    }
    $w.text tag bind d2 <Any-Enter> {
  #  .helpWindow.text tag configure d2 -background #43ce80 -relief raised -borderwidth 1
    .helpWindow.text configure -cursor hand2
    }
    $w.text tag bind d2 <Any-Leave> {
    .helpWindow.text tag configure d2 -background {} -relief flat 
    .helpWindow.text configure -cursor {}
    }
    $w.text tag bind d3 <Any-Enter> {
  #  .helpWindow.text tag configure d3 -background #43ce80 -relief raised -borderwidth 1
    .helpWindow.text configure -cursor hand2
    }
    $w.text tag bind d3 <Any-Leave> {
    .helpWindow.text tag configure d3 -background {} -relief flat 
    .helpWindow.text configure -cursor {}
    }
    $w.text tag bind d4 <Any-Enter> {
  #  .helpWindow.text tag configure d4 -background #43ce80 -relief raised -borderwidth 1
    .helpWindow.text configure -cursor hand2
    }
    $w.text tag bind d4 <Any-Leave> {
    .helpWindow.text tag configure d4 -background {} -relief flat 
    .helpWindow.text configure -cursor {}
    }
    $w.text tag bind d5 <Any-Enter> {
  #  .helpWindow.text tag configure d5 -background #43ce80 -relief raised -borderwidth 1
    .helpWindow.text configure -cursor hand2
    }
    $w.text tag bind d5 <Any-Leave> {
    .helpWindow.text tag configure d5 -background {} -relief flat 
    .helpWindow.text configure -cursor {}
    }
    $w.text tag bind d6 <Any-Enter> {
  #  .helpWindow.text tag configure d6 -background #43ce80 -relief raised -borderwidth 1
    .helpWindow.text configure -cursor hand2
    }
    $w.text tag bind d6 <Any-Leave> {
    .helpWindow.text tag configure d6 -background {} -relief flat 
    .helpWindow.text configure -cursor {}
    }
    $w.text tag bind d7 <Any-Enter> {
  #  .helpWindow.text tag configure d7 -background #43ce80 -relief raised -borderwidth 1
    .helpWindow.text configure -cursor hand2
    }
    $w.text tag bind d7 <Any-Leave> {
    .helpWindow.text tag configure d7 -background {} -relief flat 
    .helpWindow.text configure -cursor {}
    }

    $w.text tag bind d1 <1> "browseFile .dvFilesHlp dvFiles.hlp {DV Files}"
    $w.text tag bind d2 <1> "browseFile .setupHlp setup.hlp {dvEditor Configuration}" 
    $w.text tag bind d3 <1> "browseFile .editHlp edit.hlp {Editing an Item}" 
    $w.text tag bind d4 <1> "browseFile .childHlp insertchild.hlp {Insert a Child Item}" 
    $w.text tag bind d5 <1> "browseFile .siblingHlp insertsibling.hlp {Insert a Sibling Item}" 
    $w.text tag bind d6 <1> "browseFile .deleteHlp delete.hlp {Deleting an Item}" 
    $w.text tag bind d7 <1> "browseFile .moveHlp move.hlp {Moving an Item}" 

    $w.text mark set insert 0.0
    $w.text configure -state disabled
  } else {
    tk_messageBox -message "Help file is missing!" -title Warning
  }
}

############################################################
#
# The remainder is code that demonstrates the use of the Tree
# widget.  
#
set treeName ""
set null "null"
set duplicate "remove"
set slash "~"
set backslash "`"
set checkdup 0
if {[file exist "~/dvEditor.ini"]==1} {
  set fp [open "~/dvEditor.ini" r]
  set data [read $fp]
  foreach line $data {
    set varName [lindex [split $line =] 0]
    switch $varName {
      null { set null [lindex [split $line =] 1] }
      duplicate { set duplicate [lindex [split $line =] 1] }
      slash { set slash [lindex [split $line =] 1] }
      backslash { set backslash [lindex [split $line =] 1] }
      checkdup { set checkdup [lindex [split $line =] 1] }
    }
  }
  close $fp
}
global gw
switch $OSName {
  unix {
    set font \
      -adobe-helvetica-medium-r-normal-*-11-80-100-100-p-56-iso8859-1
  }
  windows {
    set font \
      -adobe-helvetica-medium-r-normal-*-14-100-100-100-p-76-iso8859-1
  }
}
set changed 0
. config -bd 3 -relief flat
set root .
set gw .f.w
frame .f -bg white
pack .f -fill both -expand 1
frame .f.mb -bd 2 -relief raised
pack .f.mb -side top -fill x
menubutton .f.mb.file -text File -menu .f.mb.file.menu
catch {
  menu .f.mb.file.menu
  .f.mb.file.menu add command -label New... -command aNewFile
  .f.mb.file.menu add command -label Open... -command aOpenFile
  .f.mb.file.menu add command -label Save -command "aSaveFile $gw"
  .f.mb.file.menu add command -label "Save As..." -command aSaveAsFile
  .f.mb.file.menu add command -label "Tree Setup" -command editorSetup
  .f.mb.file.menu add command -label Quit -command exit -command callItADay
}
menubutton .f.mb.edit -text Edit -menu .f.mb.edit.menu
catch {
  menu .f.mb.edit.menu
  .f.mb.edit.menu add command -label Edit -command "editItem $gw"
  .f.mb.edit.menu add command -label "Insert Child Item" -command "insertChildItem $gw"
  .f.mb.edit.menu add command -label "Insert Sibling Item" -command "insertSiblingItem $gw"
  .f.mb.edit.menu add command -label Delete -command "deleteItem $gw"
  .f.mb.edit.menu add command -label "^ Move Up" -command {
                                            set item $Tree($gw:selection)
                                            Tree:setselection $gw $item
                                            goUpOne
				    }

  .f.mb.edit.menu add command -label "v Move Down" -command {
                                            set item $Tree($gw:selection)
                                            Tree:setselection $gw $item
                                            goDownOne
				    }
}
.f.mb.edit config -state disabled
menubutton .f.mb.help -text Help -menu .f.mb.help.menu
catch {
  menu .f.mb.help.menu
  .f.mb.help.menu add command -label Overview -command helpWindow
  .f.mb.help.menu add command -label About -command aboutWindow
}
pack .f.mb.file .f.mb.edit .f.mb.help -side left -padx 10
wm protocol . WM_DELETE_WINDOW callItADay
grab .
focus .
