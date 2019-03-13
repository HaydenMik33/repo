using System.Data;

namespace Common
{
    public interface IMESService
    {
        bool Initialize(string configFile, string hostName);

        bool CloseConnection();

        // Per the MESDLL document from ZH
        AuthorizationLevel ValidateEmployee(string employee);

        DataTable GetContainerStatus(string container);

        DataTable GetResourceStatus(string resourceName);

        bool MoveIn(string container, ref string errorMsg, bool requiredCertification,
                            string employee, string comment, string resourceName, string factoryName);

        bool MoveOut(string container, ref string errorMsg, bool validateData,
                            string employee, string comment);

        bool Hold(string container, string holdReason, ref string errorMsg,
             string comment, string factory, string employee,  string resourceName);

        string ExecuteDC(string containerName, string sDataCollectionName,
            string sParameterSetName, object Parameter,
            string Employee, string Comments);
        
    }

}
