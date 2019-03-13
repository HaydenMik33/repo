using Common;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MESdll;
using static Common.Globals;
using System.Threading;

namespace MESCommunications
{ 

    public partial class MESDLL : IMESService
    {
        private string iniFile { get; set; }
        private string hostName { get; set; }
        MESMain MESObject { get; set; }

        private bool IsInitialized { get; set; }

        public MESDLL()
        {
            // Default values s/b 
            // @"C:\FinTest\Config\MESConfig.ini", 
            // hostName = "SHM-L10015894";  
            this.iniFile = Globals.MESDefaultConfigFile;
            // this.hostName = "TEX-L10015200";
            this.hostName =  Environment.GetEnvironmentVariable("COMPUTERNAME");

            IsInitialized = false;
        }

        public MESDLL(string configFile, string hostName)
        {
            this.iniFile = configFile;
            this.hostName = hostName;
        }

        // TODO: Answer these questions
        // Do i have to initialize a new class everytime? with the MESMain call? Yes 2/26
        // Do I have to Init again each time? Yes 2/26
        // Do I have to call StartUnit()? every time Yes 2/26
        // Do I have to call CompleteUnit every time? Yes 2/26
        private bool InitConnect()
        {
            bool initOk = false;
            try
            {
                MESObject = new MESMain();
                initOk = MESObject.Init(iniFile, hostName);

                MESObject.StartUnit();
                Globals.MyLog.Information("MES Communication initialized");
                IsInitialized = true;
            }
            catch (Exception ex)
            {
                Globals.MyLog.Error(ex, "InitConnect()");
                initOk = false;
                IsInitialized = false;
            }
            return initOk;
        }

        public bool CloseConnection()
        {
            try
            {
                MESObject.Shutdown();
                Globals.MyLog.Information("MES Connection shut down");
            }
            catch (Exception ex)
            {
                Globals.MyLog.Error(ex, "Closeconnection()");
                return false; 
            }
            return true; 
        }

        public bool Initialize(string configFile, string hostName)
        {
            this.iniFile = configFile;
            this.hostName = hostName;
            InitConnect();
            return true; 
        }

        public bool MoveIn(string container, ref string errorMsg, bool requiredCertification,
                            string employee, string comment, string resourceName, string factoryName)
        {
            bool actionReply = false; 
            try
            {
                if (!IsInitialized)
                    InitConnect();

                MESObject = new MESMain();

                actionReply = MESObject.SHMMoveIn(container, ref errorMsg, requiredCertification, employee,
                                                  comment, resourceName, factoryName);
                // "61848-009", ref strErrorMsg, false, "zahir.haque", 
                // "Testing MoveIn with argument values", "6-6-EVAP-01", "WAFER" );
                //bool moveInReply = MESObject.SHMMoveIn("61849-005", ref strErrorMsg, false, "zahir.haque", "Testing MoveIn with argument values", "6-6-EVAP-01", "WAFER");
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "MESDLL.MoveIn() threw an exception.");
            }
            finally
            {
                //CloseConnection();
            }
            return actionReply;
        }

        public bool MoveOut(string container, ref string errorMsg, bool validateData,
                            string employee, string comment)
        {
            bool actionReply = false;
            try
            {
                if (!IsInitialized)
                    InitConnect();

                MESObject = new MESMain();

                actionReply = MESObject.SHMMoveOut(container, ref errorMsg, validateData, employee, comment);
                // "61848-009", ref strErrorMsg, false, "zahir.haque", 
                //bool moevOutReply = MESObject.SHMMoveOut("61849-005", ref strErrorMsg, false, "zahir.haque", "Testing MoveOut for 61849-005 for VFURN");
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "MESDLL.MoveOut() threw an exception.");
            }
            finally
            {
                //CloseConnection();
            }
            return actionReply;
        }

        // def : bool Hold(string sContainerName, string sHoldReason, ref string sErrMsg, 
        // string sComments = "", string sFactory = "", string sEmployee = "", 
        // string sResource = "");
        public bool Hold(string container, string holdReason, ref string errorMsg,
                         string comment, string factory, string employee, string resourceName)
        {
            bool actionReply = false;
            try
            {
                if (!IsInitialized)
                    InitConnect();

                MESObject = new MESMain();

                actionReply = MESObject.Hold(container, holdReason, ref errorMsg,
                                                  comment, factory, employee, resourceName);
                // "61848-009", ref strErrorMsg, false, "zahir.haque", 
                //bool holpdReply= MESObject.Hold("61848-009", "Engineering", ref strErrorMsg, 
                //"Testing API for EVATEC", "WAFER", "zahir.haque", "6-6-EVAP-01");
                // bool holdReply = MESObject.Hold("61849-005", "Engineering", ref strErrorMsg, "Testing API for KOYO", "WAFER", "zahir.haque", "6-6-EVAP-01");
                // examples - 
                // Broken on chroma disk
                // Failed Eval
                // Failed Eval under review
                // Failed Visual Inspection
                // Failure Analysis
                // Manufacturing
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "MESDLL.Hold() threw an exception.");
            }
            finally
            {
                //CloseConnection();
            }

            return actionReply;
        }

        // def : bool Release(string sContainerName, string sReleaseReason, ref string sErrMsg, 
        // string sComments = "", string sFactory = "", string sEmployee = "", string sResource = "");            
        public bool Release(string container, string errorMsg,
             string employee, string comment, string resourceName,
             string factory, string releaseReason)
        {
            bool actionReply = false;
            try
            {
                if (!IsInitialized)
                    InitConnect();
                MESObject = new MESMain();

                actionReply = MESObject.Release(container, releaseReason, ref errorMsg,
                 comment, factory, employee, resourceName);
                //bool replyRelease = MESObject.Release("61848-009", "Other", ref strErrorMsg, 
                //"Comment on Testing Release for 61848-009", "WAFER", "zahir.haque", "6-6-EVAP-01");
                //MESObject.Release("111806-326-1", "Other", ref strErrorMsg, "Test", "EPI", "paramesh.nomula", "3-1-EPI-52");
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "MESDLL.Release() threw an exception.");
            }
            finally
            {
                //CloseConnection();
            }

            return actionReply;
        }

        public bool LogEvent(string container, string errorMsg,
             string employee, string comment, string statusComment)
        {
            bool actionReply = false;
            try
            {
                if (!IsInitialized)
                    InitConnect();
                MESObject = new MESMain();

                actionReply = MESObject.LogResourceEvent_Update(container, comment, statusComment, ref errorMsg, employee);
                //bool replyLogEvent = MESObject.LogResourceEvent_Update("6-6-EVAP-04", "Down for Engineering", "Down", 
                //ref strErrorMsg,"zahir.haque");
                //MESObject.LogResourceEvent_Update("6-6-EVAP-01", "Back to Production", "Up", 
                //ref strErrorMsg, "zahir.haque");
                //MESObject.LogResourceEvent_Update("6-5-VFURN-01", "Down For PM", "Scheduled", 
                //ref strErrorMsg,"zahir.haque");
                //MESObject.LogResourceEvent_Update("6-5-VFURN-01", "Back to Production", "Up", 
                //ref strErrorMsg, "zahir.haque");
                // possible values in Camstar
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "MESDLL.LogEvent() threw an exception.");
            }
            finally
            {
                //CloseConnection();
            }
            return actionReply;
        }

        //private void btnResourceStatus_Click(object sender, EventArgs e)
        //{
        //    bool strResult = false;
        //    string strReason = string.Empty;
        //    string strErrorMsg = string.Empty;
        //    string strCmpMsg = string.Empty;
        //    MESMain MESObject = new MESMain();
        //    //strResult = MESObject.Init(@"C:\FinTest\Config\MESConfig.ini", "5-4-TAPE-02");
        //    strResult = MESObject.Init(@"C:\FinTest\Config\MESConfig.ini", "SHM-L10015894");
        //    //MESObject.SerialNumber = "TEST45U1";
        //    MESObject.StartUnit();
        //    //DataTable resourceStatus = MESObject.SHMGetResourceStatus("6-6-EVAP-01");
        //    //DataTable resourceStatus = MESObject.SHMGetResourceStatus("6-6-EVAP-02");
        //    //DataTable resourceStatus = MESObject.SHMGetResourceStatus("6-6-EVAP-03");

        //    DataTable resourceStatus = MESObject.SHMGetResourceStatus("6-6-EVAP-04");

        //    //DataTable resourceStatus = MESObject.SHMGetResourceStatus("6-5-VFURN-01");
        //    //DataTable resourceStatus = MESObject.SHMGetResourceStatus("6-5-VFURN-02");
        //    //DataTable resourceStatus = MESObject.SHMGetResourceStatus("6-5-VFURN-03");
        //    //DataTable resourceStatus = MESObject.SHMGetResourceStatus("6-5-VFURN-04");
        //    if (resourceStatus.Rows.Count == 0)
        //    {
        //        //log.Info("Recieved reply from Camstar but no tool status " + toolName);
        //        //return status;
        //    }
        //    else
        //    {
        //        //log.Info("Tool table status needs to be parsed for " + toolName);
        //        Dictionary<string, string> vals = new Dictionary<string, string>();
        //        // tool status information
        //        foreach (DataRow dr in resourceStatus.Rows)
        //        {
        //            for (int i = 0; i < resourceStatus.Columns.Count; i++)
        //            {
        //                vals.Add(resourceStatus.Columns[i].ColumnName, dr[resourceStatus.Columns[i].ColumnName].ToString());
        //                //log.Info("Name : " + dt.Columns[i].ColumnName + " Value : " + dr[dt.Columns[i].ColumnName].ToString());
        //                Console.WriteLine("Name : " + resourceStatus.Columns[i].ColumnName + " Value : " + dr[resourceStatus.Columns[i].ColumnName].ToString());
        //                switch (resourceStatus.Columns[i].ColumnName.Trim().ToUpper())
        //                {
        //                    case "AVAILABILITY":
        //                        //Globals.ResourceStatusCamstar = dr[dt.Columns[i].ColumnName].ToString(); // UP-1 or DOWN-2
        //                        break;
        //                    case "RESOURCENAME":
        //                        //Globals.ResourceName = dr[dt.Columns[i].ColumnName].ToString();
        //                        break;
        //                    case "RESOURCESTATENAME":
        //                        //status = dr[dt.Columns[i].ColumnName].ToString();
        //                        break;                          // Standby, Scheduled, 
        //                    case "RESOURCESUBSTATENAME":
        //                        break;                          // Idle
        //                }
        //            }
        //        }
        //    }
        //    CloseConnection();
        //}

        public DataTable GetResourceStatus(string resourceName)
        {
            DataTable dtResource = null; 
            try
            {
                if (!IsInitialized)
                    InitConnect();
                MESObject = new MESMain();

                //dtResource = MESObject.SHMGetResourceStatus("6-6-EVAP-01");
                //dtResource = MESObject.SHMGetResourceStatus("6-6-EVAP-02");
                //dtResource = MESObject.SHMGetResourceStatus("6-6-EVAP-03");
                dtResource = MESObject.SHMGetResourceStatus(resourceName);
                //dtResource = MESObject.SHMGetResourceStatus("6-5-VFURN-01");
                //dtResource = MESObject.SHMGetResourceStatus("6-5-VFURN-02");
                //dtResource = MESObject.SHMGetResourceStatus("6-5-VFURN-03");
                //dtResource = MESObject.SHMGetResourceStatus("6-5-VFURN-04");
                if (dtResource.Rows.Count == 0)
                    dtResource = null;
                // TODO: Log more than 1 or even 0                
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "MESDLL.GetResourceStatus() threw an exception.");
            }
            finally
            {
                //CloseConnection();
            }
            return dtResource; 
        }

        //private void btnContainerStatus_Click(object sender, EventArgs e)
        //    {
        //        bool strResult = false;
        //        string strReason = string.Empty;
        //        string strErrorMsg = string.Empty;
        //        string strCmpMsg = string.Empty;
        //        MESMain MESObject = new MESMain();
        //        //SHM-L10015894
        //        strResult = MESObject.Init(@"C:\FinTest\Config\MESConfig.ini", "SHM-L10015894");
        //        //strResult = MESObject.Init(@"C:\FinTest\Config\MESConfig.ini", "TEX-L10015200");
        //        MESObject.StartUnit();

        //        DataTable dtLotInfo = MESObject.SHMGetContainerStatus("61848-009");
        //        //DataTable dtLotInfo = MESObject.SHMGetContainerStatus("61849-005");

        //        Dictionary<string, string> vals = new Dictionary<string, string>();
        //        // wafer information ----
        //        foreach (DataRow dr in dtLotInfo.Rows)
        //        {
        //            string firstColumnName = dtLotInfo.Columns[0].ColumnName;
        //            string firstColumnValue = dr[dtLotInfo.Columns[0].ColumnName].ToString();
        //            if (dtLotInfo.Columns[0].ColumnName == "Error")
        //            {
        //                // Message box
        //            }
        //            else
        //            {
        //                for (int i = 0; i < dtLotInfo.Columns.Count; i++)
        //                {
        //                    Console.WriteLine("Name : " + dtLotInfo.Columns[i].ColumnName + " Value : " + dr[dtLotInfo.Columns[i].ColumnName].ToString());
        //                    //vals.Add(dtLotInfo.Columns[i].ColumnName, dr[dtLotInfo.Columns[i].ColumnName].ToString());
        //                    string Name = dtLotInfo.Columns[i].ColumnName;
        //                    string Value = dr[dtLotInfo.Columns[i].ColumnName].ToString();
        //                    if (Name.ToUpper().Equals("CONTAINERNAME"))
        //                    { }   //string containername = Value;
        //                    else if (Name.Equals("CHILD_CONTAINER"))
        //                    { }    //string containername =  = Value;
        //                    else if (Name.Equals("STATUS"))
        //                    { }     //string containername =  = Value;
        //                    else if (Name.ToUpper().Equals("OPERATIONNAME"))
        //                    { }    //string containername =  = Value;
        //                    else if (Name.ToUpper().Equals("PRODUCTNAME"))
        //                    { }
        //                    //string containername = Value;
        //                    else if (Name.ToUpper().Equals("RECIPE"))
        //                    { }
        //                    //string containername = recipe;
        //                    //else if (Name.ToUpper().Equals("PRODUCTFAMILYNAME"))
        //                    //Globals.DECassette[Globals.CurCassette].Wafer[rowIndex].WaferDetails[ToolWafer.cLayer] = Value;
        //                    //Console.WriteLine(Name + " : " + Value);
        //                    //else if (Name.ToUpper().Equals("WORKFLOWSTEPNAME"))
        //                    //Console.WriteLine(Name + " : " + Value);
        //                    //else if (Name.ToUpper().Equals("SPECNAME"))
        //                    //Console.WriteLine(Name + " : " + Value);
        //                    //else if (Name.ToUpper().Equals("WORKCENTERNAME"))
        //                    //Console.WriteLine(Name + " : " + Value);
        //                    //else if (Name.ToUpper().Equals("PRODUCTFAMILYNAME"))
        //                    //Console.WriteLine(Name + " : " + Value);
        //                    //else if (Name.ToUpper().Equals("PROCESSBLOCK"))
        //                    //Console.WriteLine(Name + " : " + Value);
        //                    else if (Name.ToUpper().Equals("SCRIBE_NUMBER"))
        //                    { }
        //                    //string scribeId = Value;
        //                    //else if (Name.ToUpper().Equals("RUNPKT"))
        //                    //Console.WriteLine(Name + " : " + Value);
        //                }
        //            }
        //        }
        //        DataTable strOutPut = MESObject.SHMGetContainerStatus("111806-326-1");
        //        CloseConnection();
        //    }

        public DataTable GetContainerStatus(string container)
        {
            DataTable dtLotInfo = null; 
            try
            {
                if (!IsInitialized)
                    InitConnect();

                MESObject = new MESMain();

                dtLotInfo = MESObject.SHMGetContainerStatus(container);
                // resourceStatus = MESObject.SHMGetContainerStatus("61849-005"); 

                if (dtLotInfo.Rows.Count == 0)
                    dtLotInfo = null;
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "MESDLL.GetContainerStatus() threw an exception.");
            }
            finally
            {
                //CloseConnection();
            }
            return dtLotInfo;
        }

        public AuthorizationLevel ValidateEmployee(string employee)
        {
            AuthorizationLevel authLevel = AuthorizationLevel.InvalidUser;
            DataTable dtEmployee = null; 

            try
            {
                if (!IsInitialized)
                    InitConnect();

                MESObject = new MESMain();
                dtEmployee = MESObject.SHMValidateEmployee(employee);
                // string replyValidateEmployee = MESObject.SHMValidateEmployee("zahir.haque2");
                if (dtEmployee.Rows.Count == 0)
                {
                    //do nothing
                }
                else
                {
                    authLevel = AuthorizationLevel.Operator;
                    Dictionary<string, string> vals = new Dictionary<string, string>();
                    // tool status information
                    foreach (DataRow dr in dtEmployee.Rows)
                    {
                        for (int i = 0; i < dtEmployee.Columns.Count; i++)
                        {
                            string colName = dtEmployee.Columns[i].ColumnName;
                            vals.Add(colName, dr[colName].ToString());
                            Console.WriteLine("Name :[" + colName + "]=Value: " + dr[colName].ToString());

                            switch (colName.Trim().ToUpper())
                            {
                                case "USEREXISTS":
                                    //Globals.ResourceStatusCamstar = dr[dt.Columns[i].ColumnName].ToString(); // UP-1 or DOWN-2
                                    if (dr[colName].ToString().Equals("Invalid User"))
                                        authLevel = AuthorizationLevel.InvalidUser;
                                    break;
                                case "EMPLOYEEROLE":
                                    string auth = dr[colName].ToString();
                                    if (!string.IsNullOrEmpty(auth))
                                    {
                                        Console.WriteLine("EMPLOYEEROLE=" + auth);
                                    }
                                    //Globals.ResourceName = dr[dt.Columns[i].ColumnName].ToString();
                                    break;
                                    //case "RESOURCESTATENAME":
                                    //status = dr[dt.Columns[i].ColumnName].ToString();
                                    //    break;                          // Standby, Scheduled, 
                                    //case "RESOURCESUBSTATENAME":
                                    //    break;                          // Idle
                            }
                        }
                    }
                }

            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "MESDLL.ValidateEmployee() threw an exception.");
            }
            finally
            {
                //CloseConnection();
            }

            return authLevel;
        }

        public string ExecuteDC(string containerName, string sDataCollectionName, string sParameterSetName, object Parameter, string Employee, string Comments)
        {
            string executeDCReply = "";
            try
            {
                if (!IsInitialized)
                    InitConnect();
                MESObject = new MESMain();

                executeDCReply = MESObject.SHMExecuteDC(containerName, sDataCollectionName, sParameterSetName, Parameter, Employee, Comments);
                
            }
            catch (Exception ex)
            {
                MyLog.Error(ex, "MESDLL.ExecuteDataCollection() threw an exception: " + executeDCReply);
            }
            finally
            {
                //CloseConnection();
            }

            return executeDCReply;
        }
    }
}
