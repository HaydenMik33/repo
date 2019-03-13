using SECSInterface;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ToolService
{
    public interface ISECSHandler<T>
    {
        bool InitializeTool();
        /// <summary>
        /// Send a quick control state/process state query to tool and return tru
        /// if the tool is still in the correct state for start material.
        /// </summary>
        /// <returns></returns>
        bool ReadyToStart();

        /// <summary>
        /// Does the generic pre-processing setup (check for correct tool state, event report setup, etc.)
        /// May block for up to 60 seconds or so if a timeout occurs.
        /// </summary>
        /// <returns>true if success but on failure operator is still allowed to proceed.. If error posts events.</returns>
        bool DoPreprocessing();
        /// <summary>
        /// Does tool-specific recipe selection.
        /// </summary>
        /// <param name="Port"></param>
        /// <param name="LotIds"></param>
        /// <param name="Recipe"></param>
        /// <param name="Operator"></param>
        /// <returns>True if success; if error posts event.</returns>
        bool DoRecipeSelection(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage);
        /// <summary>
        /// Sends the tool-specific start processing commands(s)
        /// </summary>
        /// <remarks>For Koyo, the LotIds, Recipe and Operator are not used.
        /// </remarks>
        /// <returns>True if success; if error posts event</returns>
        bool DoStartProcessing(string Port, string[] LotIds, string Recipe, string Operator, out string errorMessage);

        /// <summary>
        /// Specific to Koyo
        /// </summary>
        /// <param name="BatchId">Make up one based on Lot IDs</param>
        /// <param name="PPID">From MES</param>
        /// <param name="ProcessTime">From MES; should be integer seconds</param>
        /// <param name="TableNumber">From MES</param>
        /// <param name="CarrierID">From MES</param>
        /// <param name="MaterialType">Always use "P"</param>
        /// <param name="CarrierLocation">1=PORT A, 2=PORT B</param>
        /// <param name="SlotStatus">Must contain all 25 slots with 1=empty and 3=occupied</param>
        /// <returns></returns>
        bool CreateBatch(string BatchId, string PPID, int ProcessTime, string TableNumber,
            string CarrierID, string MaterialType, int CarrierLocation, int[] SlotStatus);

        /// <summary>
        /// Sends the remote command STOP to the tool. For some tools this is
        /// a final state and cannot be started again until the tool returns to
        /// ready state. Equivalent to ABORT for some tools.
        /// </summary>
        /// <returns>true if the command is accepted. If the command fails
        /// an event is posted and a message is logged.</returns>
        bool SendSECSStop();
       

        /// <summary>
        /// Sends the remote command ABORT to the tool.
        /// </summary>
        /// <returns>true if the command is accepted. If the command fails
        /// an event is posted and a message is logged.</returns>
        bool SendSECSAbort();
 

        /// <summary>
        /// Sends remote command PAUSE or WAIT (for some tools).
        /// </summary>
        /// <returns>true if the command is accepted. If the command fails
        /// an event is posted and a message is logged.</returns>
        bool SendSECSPause();

        /// <summary>
        /// Sends remote command RESUME or CONTINUE to direct the tool to resume processing.
        /// </summary>
        /// <returns>true if the command is accepted. If the command fails
        /// an event is posted and a message is logged.</returns>
        bool SendSECSResume();

        /// <summary>
        /// Sends remote command LOCAL to direct the tool to go into local mode.
        /// Tool will  continue processing and sending events or other data, but
        /// will not accept certain commands until it is returned to REMOTE mode.
        /// </summary>
        /// <returns>true if the command is accepted. If the command fails
        /// an event is posted and a message is logged.</returns>
        bool SendSECSGoLocal();
        /// <summary>
        /// Sends remote command REMOTE to direct the tool to go into remote mode.
        /// </summary>
        /// <returns>true if the command is accepted. If the command fails
        /// an event is posted and a message is logged.</returns>
        bool SendSECSGoRemote();

        /// <summary>
        /// These are Evatec specific and will probably never be used.
        /// </summary>
        /// <returns></returns>
        bool SendSECSNext();
        /// <summary>
        /// These are Evatec specific and will probably never be used.
        /// </summary>
        /// <returns></returns>
        bool SendSECSReload();

        Dictionary<string, string> UploadData();

        List<string> RecipeList();
    }
}
