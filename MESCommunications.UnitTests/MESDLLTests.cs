using Common;
using FinisarFAS1.ViewModel;
using MESCommunications;
using NUnit.Framework;
using System;
using System.Data;
using System.Linq;
using Assert = NUnit.Framework.Assert;

namespace MESCommunications.UnitTests
{
    [TestFixture]
    public class MESServiceTests
    {
        private MESService _mesService;
        // private readonly string testToolName = "6-6-EVAP-01";
        private readonly string thisHostName = "SHM-L10015894";  // "TEX-L10015200"
        //private readonly string strDBServerName = "tex-cs613db-uat.texas.ads.finisar.com";
        string inifile = @"C:\\FinTest\Config\MESConfig.ini";

        [SetUp]
        public void SetUp()
        {
            _mesService = new MESService(new MESDLL(inifile, thisHostName));
            //_mesService = new MESService(new MoqMESService()); // MESDLL());
        }

        [TearDown]
        public void CleanUp()
        {
            //Q1
            _mesService = null;
        }

        [Test]
        public void Initialize_False()
        {
            string invalidHostName = thisHostName + "0";
            Assert.That(() => _mesService.Initialize(inifile, invalidHostName) == false);
        }

        [Test]
        public void Initialize_True()
        {
            var ret = _mesService.Initialize(inifile, thisHostName);
            Assert.IsTrue(ret);
        }

        [Test]
        public void ValidateEmployee_ExpectInvalid()
        {
            string operatorName = "ZahirHaqueXYZ";
            AuthorizationLevel expectedAuthLvl = AuthorizationLevel.InvalidUser;
            //Initialize_True();
            var returnAuthLvl = _mesService.ValidateEmployee(operatorName);
            Assert.AreEqual(returnAuthLvl, expectedAuthLvl);
        }

        [Test]
        [Ignore("for now")]
        public void ValidateEmployee_ExpectAdministrator()
        {
            string operatorName = "Mike";
            AuthorizationLevel expectedAuthLvl = AuthorizationLevel.Administrator;
            //Initialize_True();
            var returnAuthLvl = _mesService.ValidateEmployee(operatorName);
            Assert.IsTrue(returnAuthLvl == expectedAuthLvl);
        }

        [Test]
        public void ValidateEmployee_ExpectValid()
        {
            string operatorName = "zahir.haque";
            AuthorizationLevel expectedAuthLvl = AuthorizationLevel.Engineer;
            //Initialize_True();
            var returnAuthLvl = _mesService.ValidateEmployee(operatorName);
            Assert.IsTrue(returnAuthLvl == expectedAuthLvl);
        }

        [Test]
        public void MoveIn_ExpectFalse()
        {
            string errorMsg = "message";
            string invalidContainer = "61848-002";
            bool moveInRes = _mesService.MoveIn(invalidContainer, ref errorMsg, false, "zahir.haque", "Testing MoveIn with argument values", "6-6-EVAP-01", "WAFER");
            Assert.AreEqual(moveInRes, false);
        }

        string lot89 = "61848-009";
        string lot913 = "61849-013"; 

        [Test]
        public void MoveIn_Duplicated_ExpectFalse()
        {
            string container = "61848-001";
            string duplicatedContainer = "61848-001";
            string errorMsg = "message";
            bool firstAttemp = _mesService.MoveIn(container, ref errorMsg, false, "zahir.haque", "Testing MoveIn with argument values", "6-6-EVAP-01", "WAFER");
            Assert.IsTrue(firstAttemp);
            bool  secAttemp = _mesService.MoveIn(duplicatedContainer, ref errorMsg, false, "zahir.haque", "Testing MoveIn with argument values", "6-6-EVAP-01", "WAFER");
            Assert.AreEqual(false, secAttemp);
        }

        [Test]
        public void MoveIn009_ExpectTrue()
        {
            string validContainer = "61848-009";
            string errorMsg = "message";
            bool moveInRes = _mesService.MoveIn(validContainer, ref errorMsg, false, "zahir.haque", "Testing MoveIn with argument values", "6-6-EVAP-01", "WAFER");
            Assert.IsTrue(moveInRes);
        }
        [Test]
        public void MoveOut_ExpectFalse()
        {
            string errorMsg = "message";
            string invalidContainer = "61849-003";
            bool moveOutRes = _mesService.MoveOut(invalidContainer, ref errorMsg, false, "zahir.haque", "Testing MoveOut for 61849-003 for VFURN");
            Assert.AreEqual(moveOutRes, false);
        }
       
        [Test]
        public void MoveOut_Duplicated_ExpectFalse()
        {
            string errorMsg = "message";
            string container = "61849-001";
            bool firstAttemp = _mesService.MoveOut(container, ref errorMsg, false, "zahir.haque", "Testing MoveOut for 61849-003 for VFURN");
            Assert.IsTrue(firstAttemp);
            bool secAttemp = _mesService.MoveOut(container, ref errorMsg, false, "zahir.haque", "Testing MoveOut for 61849-003 for VFURN");
            Assert.AreEqual(secAttemp, false);
        }

        [Test]
        public void MoveOut009_ExpectTrue()
        {
            string errorMsg = "message";
            string validContainer = "61849-009";
            bool moveOutRes = _mesService.MoveOut(validContainer, ref errorMsg, false, "zahir.haque", "Testing MoveOut for 61849-001 for VFURN");
            Assert.IsTrue(moveOutRes);
        }
        [Test]
        [TestCase("165456")]
        public void Hold_ExpectTrue(string container)
        {
            string msg = "error";
            bool holdRes = _mesService.Hold(container, "", ref msg, "", "", "", "");
            Assert.IsTrue(holdRes);
        }
        [Test]
        [TestCase("165453")]
        public void Hold_ExpectFalse(string container)
        {
            string msg = "error";
            bool holdRes = _mesService.Hold(container, "", ref msg, "", "", "", "");
            Assert.IsFalse(holdRes);
        }

        [Test]
        [TestCase("61851-001", 6)]
        [TestCase("61851-003", 10)]
        public void GetContainerStatus_TestCase(string lotId ,int expectedNum)
        {
            DataTable dt = _mesService.GetContainerStatus(lotId);
            Assert.IsNotNull(dt,"Table is empty");
            Assert.IsTrue(dt.Rows.Count == expectedNum);
        }

        [Test]
        [TestCase("6-6-EVAP-001", "Standby")]
        [TestCase("6-6-EVAP-009", "OffLine")]
        public void GetResourceStatus_TestCase(string resourceName, string resourceExpectedStatus)
        {
            DataTable t1 = _mesService.GetResourceStatus(resourceName);
            DataRow dr = t1.Rows[0];
            Assert.IsNotNull(t1, "Table is empty");
            Assert.AreEqual(t1.Rows.Count, 1);
            Assert.AreEqual(dr["ResourceStateName"].ToString(), resourceExpectedStatus);
        }
        [Test]
        public void LocalModeBtnDisable_ExpectFalse()
        {
            WaferGridViewModel mvm = new WaferGridViewModel(0); 
            mvm.GoLocalCmd.Execute(null);
            Assert.IsFalse(mvm.ButtonEnabledIfOnline);
        }
    }
}
