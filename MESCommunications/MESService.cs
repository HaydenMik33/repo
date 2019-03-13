using Common;
using System;
using System.Data;

namespace MESCommunications
{
    public class MESService
    { 
        private IMESService _mesService;

        public MESService(IMESService service)
        {
            _mesService = service; 
        }

        public bool Initialize(string configFile, string hostName)
        {
            return _mesService.Initialize(configFile, hostName);
        }

        public bool CloseConnection()
        {
            return _mesService.CloseConnection();
        }

        // MoveIn(string container, string errorMsg, bool requiredCertification,
        // string employee, string comment, string resourceName, string factoryName);
        public bool MoveIn( string container, ref string errorMsg, bool requiredCertification,
                            string employee, string comment, string resourceName, string factoryName)
        {
            return _mesService.MoveIn(container, ref errorMsg, requiredCertification, employee, comment, resourceName, factoryName);
        }

        public bool MoveOut(string container, ref string errorMsg, bool validateData,
                            string employee, string comment)
        {
            return _mesService.MoveOut(container, ref errorMsg, validateData, employee, comment);
        }

        public bool Hold(string container, string holdReason, ref string errorMsg,
                         string comment, string factory, string employee, string resourceName)
        {
            return _mesService.Hold(container,  holdReason, ref errorMsg, comment, factory, employee, resourceName);
        }

        public DataTable GetContainerStatus(string container)
        {
            // System.Threading.Thread.Sleep(3000);
            DataTable dt = _mesService.GetContainerStatus(container);
            DetailWafersOutToLog(dt);
            return dt;
        }

        private void DetailWafersOutToLog(DataTable dt)
        {
            int idx = 0; 
            string colValues = "";
            string rowValues = "";

            if (dt == null)
            {
                Globals.MyLog.Debug("DataTable is empty");
                return; 
            }

            // Column names first
            foreach (DataColumn col in dt.Columns)
                colValues += col.ColumnName + ",";
            Globals.MyLog.Debug(colValues);

            // then values
            foreach (DataRow dataRow in dt.Rows)
            {
                rowValues = $"[{idx++}] row=";
                foreach (var item in dataRow.ItemArray)
                    rowValues += item + ",";

                Console.WriteLine(rowValues);
                Globals.MyLog.Debug(rowValues);
            }
        }

        public DataTable GetResourceStatus(string resourceName)
        {
            return _mesService.GetResourceStatus(resourceName);
        }

        public AuthorizationLevel ValidateEmployee(string empName)
        {            
            var authLevel = _mesService.ValidateEmployee(empName);
#if DEBUG1
            if (empName.Equals("zahir.haque"))
                authLevel = AuthorizationLevel.Engineer;
#else
#endif 
            return authLevel; 
        }

        public string ExecuteDC(string containerName, string dataCollectionName, string parameterSetName, object parameter, string employee, string comments)
        {
            return _mesService.ExecuteDC(containerName, dataCollectionName, parameterSetName, parameter, employee, comments);
        }

    }
  
}
