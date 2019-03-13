
Create a directory for the tool name, containing simdata.dv, following the example 
tool "6-6-EVAP-002".  simdata.dv contains the custom reply data you want to see from 
the simulator, such as values for SVID.

The simulator reloads simdata.dv each time it recieves a SECS message request,
so there should seldom be a need to stop/start to pick up changes.

If running when connected to a network:

Start the servers with the command below, using the tool name. Note that all names
are case sensitive.
	start-servers 6-6-EVAP-002

If everything starts up, the last message in the command prompt will be an S1F1
sent to the simulator and a good reply. 
	(Note: there is a known bug in Windows .bat file processing that may 
	       cause your command recall to be trashed. Try to ignore it.)

You can shutdown the servers with the command:
	stop-servers 6-6-EVAP-002

If running when not connected to a network:
	Determine an non-loopback IP address to use. I was able to do this by 
	opening a command prompt, navigating to 
		[your location]\EqSimulator\Rudolph\AutoShell\ashl3.10.0\bin
	and running this command: aci_send -l 5 a b
	It will error, but the log it produces will show a message like this:
		Adding interface x.y.z.w
	then later, the message: 1 usable network interfaces identified.

	Edit the file at [your location]\EqSimulator\common.bat
	Change the line: 
		set ACI_CONF=%COMPUTERNAME%:1500
	To the interface found above:
		set ACI_CONF=x.y.z.w:1500
	Then start the servers as shown above.  if this works, you can then use
	the ACI_CONF string x.y.z.w:1500 in your FAS instance.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


The following messages can be sent from the command line to modify the simulator
state. Open a command prompt and run "common.bat" to set environment variables.

Tell simulator to not send any replies (timeout on all SECS messages):
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=setTimeoutAll true

Tell simulator to resume sending replies:
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=setTimeoutAll false

	Example of using this to test the UI:
		1. setTimeoutAll true
		2. Have the UI attempt to query the SVID for Control State
		3. After 30 seconds, the SVID query will timeout
		4. UI should display an error of some sort
		5. setTimeoutAll false

- - - -

Change control state:
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=setControlState state=Off-Line
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=setControlState state=Local
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=setControlState state=Remote

	Example of using this to test the UI:
		1. setControlState state=Off-Line
		2. UI should display the tool Off-Line indicator
		3. setControlState state=Remote 
		4. UI should show the tool control state Remote indicator

- - - -

Change process state:
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=setProcessState state=Off
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=setProcessState state=Ready

	Other process states: Off|Setup|Ready|Executing|Wait|Abort

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

Tell simulator to send an alarm:
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=sendAlarm ALCD=00 ALID=3 ALTX="\"Hi alarm\""

	ALCD is a 2-digit binary value, as defined by the tool's document.
	ALID is the alarm ID. ALTX is an alarm description.
	For testing, you can put any values you want to in there.

- - - -

Tell simulator to send an event:
There are two formats for this message. If the simdata.dv file contains
the event IDs for ProcessStarted|ProcessCompleted|ProcessAborted, you
can use the format below:
	%ASHLHOME%\bin\sendmq 6-6-EVAP-01gw do=sendEvent event=ProcessStarted
	
	%ASHLHOME%\bin\sendmq 6-6-EVAP-01gw do=sendEvent event=ProcessCompleted
	
	%ASHLHOME%\bin\sendmq 6-6-EVAP-01gw do=sendEvent event=ProcessAborted
	

Or you can send any event ID you like with the format:
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=sendEvent event=555

	If any reports have been linked to the event, it will also send the 
	reports with either dummy data for the values or data from simdata.dv.
	Both SVID and DVID can be used in an event report.

- - - -

Tell simulator to send trace data: 

Normally, we don't need to do this because this is something the FAS will do.
When the simulator receives a trace initialize message (S2F33) from the FAS,
it automatically starts sending the data. 

The values are defined in the simdata.dv file under 'trace'; or if not found, it
will send the number 0 (also configurable in simdata.dv).

It will continue sending the data at the requested interval until the 
total samples is reached or the trace is stopped from the UI.

However, if you do need to "turn on" or "turn off" a trace manually, you can use the command below:  (NOTE THIS IS SENT TO "toolname + srv" not "toolname + gw")
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002srv do=traceset eq=6-6-EVAP-002 
		TRID_TYPE=ASC DSPER_TYPE=ASC TOTSMP_TYPE=ASC REPGSZ_TYPE=ASC SVID_TYPE.1=ASC SVID_TYPE.2=ASC
		TRID=1 DSPER=000005 TOTSMP=3 REPGSZ=1 SVID.1=11 SVID.2=1001 
The parm definitions are:
	TRID - trace ID from the toolConfig.xml file
	DSPER - hhmmss how often to send the report (000005 = one every 5 seconds)
	TOTSMP - how many trace reports to send
	REPGSZ - always set to 1
	SVID.1, SVID.2.... - The SVID from the toolConfig.xml  
	For every SVID.X there must be a matching SVID_TYPE.X=ASC
	


- - - -

Tell simulator to send a bad ack for a stream-function:

	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=setAck streamFunction=S2F15 bad
Go back to good ack:
	%ASHLHOME%\bin\sendmq 6-6-EVAP-002gw do=setAck streamFunction=S2F15 good

Stream functions that can be used: S2F15|S2F41|S5F3|S2F23|S2F33|S2F35|S2F37|
S1F15|S1F17|S2F21|S2F27|S2F31|S2F43|S2F49|S3F17|S7F1|S7F3|S7F23|S10F3|S10F5|
S10F9|S14F9|S16F11|S16F15



- - - -
Certain lot ID endings set up for failure conditions during the run.
Lot ID ending in...
	29 CriticalAlarm sent 
	39 ToolPauses after about 5 seconds
	49 ToolPausesAndResumes after about 5 seconds
	59 ToolAborts after a few seconds
	69 ProcessNeverCompletes  (used for internal testing)









