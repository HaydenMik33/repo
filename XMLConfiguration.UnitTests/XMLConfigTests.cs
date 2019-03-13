using Common;
using NUnit.Framework;

namespace XML.UnitTests
{
    [TestFixture]
    public class UnitTest1
    {
        [SetUp]
        public void SetUp()
        {
            // Set up initializer functions here. This runs prior to every single test 
        }

        [TearDown]
        public void CleanUp()
        {
            // Any cleanup is done here. 
        }

        [Test]
        public void TestXMLReaderToolConfig1()
        {
            var tc = XMLHelper.ReadXmlConfig<ToolConfig>(@"Evatec\ToolConfig.xml");
            Assert.IsFalse(tc.DefineEventsAtAppStart);

            // Mike - these were moved from SystemConfig tests to here
            Assert.IsFalse(tc.Dialogs.ShowConfirmationBox);
            Assert.IsFalse(tc.Dialogs.ShowEmailBox);
        }

        [Test]
        public void TestXMLReaderSystemConfig1()
        {

            SystemConfig sc = XMLHelper.ReadXmlConfig<SystemConfig>("SystemConfig.xml");
            Assert.IsTrue(sc.EmailPort.ToString().Equals("25"));
            Assert.IsFalse(sc.CamstarConfig.DBServerName.Equals("insite"));
        }

        [Test]
        public void TestXMLReaderDialogConfig()
        {
            SystemConfig sc = XMLHelper.ReadXmlConfig<SystemConfig>("SystemConfig.xml");

            // Mike - moved the Dialogs tests into ToolConfig testing since those are no longer in SystemConfig
           
        }
    }
}
