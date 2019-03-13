using NUnit.Framework;
using AutoShellMessaging;
using Common;

namespace ToolService.UnitTests
{
    [TestFixture]
    public class EvatecTests
    {
        private Evatec _evatec;

        // Values needed to connect to local simulator
        string _eqSrv; //  Globals.CurrentToolConfig.Toolid + "srv";
        //private readonly string _eq = "Evatec01";
        // private readonly int _timeout = 20;

        private AshlServerLite _myServer;
        private MessagingSettings _messagingSettings;

        [SetUp]
        public void SetUp()
        {
            if (Globals.CurrentToolConfig == null)
                Globals.ReadXmlConfigs();

            // Instanciate an Evatec instance
            _evatec = new Evatec();
            // _evatec.Id = Globals.CurrentToolConfig.Toolid;           
            _eqSrv = Globals.CurrentToolConfig.Toolid + "srv";

            // Instanciate an AshlServerLite instance
            _messagingSettings = new MessagingSettings()
            {
                AciConf = "SHM-L10015894:1500", // localhost:port
                CheckDuplicateRegistration = true,
                UseInterfaceSelectionMethod = InterfaceSelectionMethod.DISCOVER,
                Name = "exampleSECS"
            };
            _myServer = AshlServerLite.getInstanceUsingParameters(_messagingSettings);                    
                        
            // In order to use Serilog in our tests, a new Serilog logger must be created and used from whithin every unit test method.            
        }

        [TearDown]
        public void Cleanup()
        {
            // Add cleanup code if needed            
        }

        [Test]        
        public void Initialize_WhenCalled_InitializationSucceeds()
        {
            Assert.IsTrue(_evatec.Initialize());
        }

        [Test]
        [Ignore("Not needed for normal testing")]
        public void Initialize_WhenCalled_ThrowsException()
        {
            Assert.That(() => _evatec.Initialize(), Throws.Exception.TypeOf<BoundMessageSendException>());
        }
        /*
        [Test]
        public void OnNotifySecsProcessControlStates_WhenInvoked_EventIsFired()
        {
            string processState = null;
            string controlState = null;

            _evatec.NotifySecsProcessControlStates += delegate (object sender, SECSProcessControlStatesEventArgs e)
            {
                processState = e.ProcessState;
                controlState = e.ControlState;
            };

            _evatec.OnNotifySecsProcessControlStates("1", "2");
            Assert.IsNotNull(processState);
            Assert.IsNotNull(controlState);
        }

        [Test]
        public void OnNotifySecsBadAck_WhenInvoked_EventIsFired()
        {
            string badAck = null;            

            _evatec.NotifySecsBadAck += delegate (object sender, SECSBadAckEventArgs e)
            {
                badAck = e.BadAck;                
            };

            _evatec.OnNotifySecsBadAck("SECS Bad Ack");
            Assert.IsNotNull(badAck);
        }

        [Test]
        public void OnNotifySecsException_WhenInvoked_EventIsFired()
        {
            string exception = null;

            _evatec.NotifySecsException += delegate (object sender, SECSExceptionEventArgs e)
            {
                exception = e.Exception;
            };

            _evatec.OnNotifySecsException("SECS exception raised");
            Assert.IsNotNull(exception);
        }

        [Test]
        public void OnNotifyLog_WhenInvoked_EventIsFired()
        {
            string message = null;

            _evatec.NotifyLog += delegate (object sender, LogEventArgs e)
            {
                message = e.Message;
            };

            _evatec.OnNotifyLog("SECS messaged logged");
            Assert.IsNotNull(message);
        }
        */
    }
}
