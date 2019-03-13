using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SECSInterface;

namespace ToolService
{
    public class SECSHandler<T> : ISECSHandler<T> where T : Tool
    {
        private T _tool;
        public SECSHandler(T tool)
        {
            _tool = tool;
        }
        
        public bool InitializeTool()
        {
            return _tool.Initialize();
        }

        public bool ReadyToStart()
        {
            return _tool.ReadyToStart();
        }
        public bool SendSECSGoLocal()
        {
            return _tool.SendGoLocal();
        }

        public bool SendSECSGoRemote()
        {
            return _tool.SendGoRemote();
        }

        public bool SendSECSPause()
        {
            return _tool.SendPause();
        }

        public bool SendSECSResume()
        {
            return _tool.SendResume();
        }

        public bool SendSECSStop()
        {
            return _tool.SendStop();
        }

        public bool SendSECSAbort()
        {
            return _tool.SendAbort();
        }
        public bool SendSECSNext()
        {
            return _tool.SendNext();
        }
        public bool SendSECSReload()
        {
            return _tool.SendReload();
        }

        public bool DoPreprocessing()
        {
            return _tool.DoPreprocessing();
        }
        public bool DoRecipeSelection(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage)
        {
            return _tool.DoSelectRecipe(Port, LotIds, Recipe, Operator, out errorMessage);
        }
        public bool DoStartProcessing(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage)
        {
            return _tool.DoStartProcessing(Port, LotIds, Recipe, Operator, out errorMessage);
        }
        public bool CreateBatch(string BatchId, string PPID, int ProcessTime, string TableNumber,
            string CarrierID, string MaterialType, int CarrierLocation, int[] SlotStatus)
        {
            return _tool.CreateBatch(BatchId,  PPID, ProcessTime, TableNumber, CarrierID, MaterialType, CarrierLocation, SlotStatus);
        }

        public Dictionary<string, string> UploadData()
        {
            return _tool.UploadData();
        }
        public List<string> RecipeList()
        {
            return _tool.RecipeList;
        }
    }
}
