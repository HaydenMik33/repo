using Common;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace MESCommunications.Utility
{
    public static class DataHelpers
    {
        static readonly string CONTAINERNAME = "CONTAINERNAME";
        static readonly string CHILDCONTAINER = "CHILD_CONTAINER";  // WaferNo
        static readonly string STATUS = "STATUS";
        static readonly string WORKFLOWSTEPNAME = "WORKFLOWSTEPNAME";
        static readonly string SPECNAME = "SPECNAME"; 
        static readonly string OPERATIONNAME = "OPERATIONNAME";   // Operation
        static readonly string WORKCENTERNAME = "WORKCENTERNAME";  
        static readonly string PRODUCTNAME = "PRODUCTNAME";  // Product
        static readonly string PRODUCTFAMILYNAME = "PRODUCTFAMILYNAME"; 
        static readonly string PROCESSBLOCK = "PROCESS_BLOCK"; 
        static readonly string SCRIBENUMBER = "SCRIBE_NUMBER";
        static readonly string RUNPKT = "RUNPKT";
        static readonly string RECIPE = "RECIPE";
        static readonly string EPIVENDOR = "EPI_VENDOR";
        static readonly string PARENTCONTAINERQTY = "PARENT_CONTAINER_QTY";
        static readonly string CHILDCONTAINERQTY = "CHILD_CONTAINER_QTY";
        static readonly string CONTAINERTYPE = "CONTAINERTYPE";
        static readonly string PARENTCONTAINERNAME = "PARENT_CONTAINER_NAME";
        static readonly string SPECIALPROCESSINSTRUCTIONS = "Special process instructions";


        public static DataTable MakeWaferListIntoDataTable(List<Wafer> wafers)
        {
            if (wafers == null) 
                return null; 
            DataTable dt = new DataTable();
            try
            {
                dt.Clear();
                dt.Columns.Add("Slot");
                dt.Columns.Add(CONTAINERNAME);
                dt.Columns.Add(CHILDCONTAINER);
                dt.Columns.Add(STATUS);
                dt.Columns.Add(WORKFLOWSTEPNAME);
                dt.Columns.Add(SPECNAME);
                dt.Columns.Add(OPERATIONNAME);
                dt.Columns.Add(WORKCENTERNAME);
                dt.Columns.Add(PRODUCTNAME);
                dt.Columns.Add(PRODUCTFAMILYNAME);
                dt.Columns.Add(PROCESSBLOCK);
                dt.Columns.Add(SCRIBENUMBER);
                dt.Columns.Add(RUNPKT);
                dt.Columns.Add(RECIPE);
                dt.Columns.Add(EPIVENDOR);
                dt.Columns.Add(PARENTCONTAINERQTY);
                dt.Columns.Add(CHILDCONTAINERQTY);
                dt.Columns.Add(CONTAINERTYPE);
                dt.Columns.Add(PARENTCONTAINERNAME);
                dt.Columns.Add(SPECIALPROCESSINSTRUCTIONS);

                foreach (var wafer in wafers)
                {
                    DataRow row = dt.NewRow();
                    row["Slot"] = wafer.Slot;
                    row[CONTAINERNAME] = wafer.ContainerName;
                    row[CHILDCONTAINER] = wafer.WaferNo;
                    row[STATUS] = wafer.Status;
                    row[WORKFLOWSTEPNAME] = wafer.WorkFlowStepName;
                    row[SPECNAME] = wafer.SpecName;
                    row[OPERATIONNAME] = wafer.Operation;
                    row[WORKCENTERNAME] = wafer.WorkCenterName;
                    row[PRODUCTNAME] = wafer.Product;
                    row[PRODUCTFAMILYNAME] = wafer.ProductFamilyName;
                    row[PROCESSBLOCK] = wafer.ProcessBlock;
                    row[SCRIBENUMBER] = wafer.ScribeID;
                    row[RUNPKT] = wafer.RunPkt;
                    row[RECIPE] = wafer.Recipe;
                    row[EPIVENDOR] = wafer.EpiVendor;
                    row[PARENTCONTAINERQTY] = wafer.ParentContainerQty;
                    row[CHILDCONTAINERQTY] = wafer.ChildContainerQty;
                    row[CONTAINERTYPE] = wafer.ContainerType;
                    row[PARENTCONTAINERNAME] = wafer.ParentContainerName;
                    row[SPECIALPROCESSINSTRUCTIONS] = wafer.SpecialProcessInstructions;
                    dt.Rows.Add(row);
                }
            }
            catch (Exception ex)
            {
                Globals.MyLog.Error(ex, "MakeWaferListIntoDataTable()");
                dt = null; 
            }
            return dt;
        }

        public static List<Wafer> MakeDataTableIntoWaferList(DataTable dt)
        {
            List<Wafer> wafers = new List<Wafer>();
            int idx = 0;
            try
            {
                wafers = (from DataRow row in dt.Rows
                          select new Wafer()
                          {
                              Slot = (++idx).ToString(),
                              ContainerName = row[CONTAINERNAME].ToString(),
                              WaferNo = row[CHILDCONTAINER].ToString(),
                              Status = row[STATUS].ToString(),
                              WorkFlowStepName = row[WORKFLOWSTEPNAME].ToString(),
                              SpecName = row[SPECNAME].ToString(),
                              Operation = row[OPERATIONNAME].ToString(),
                              WorkCenterName = row[WORKCENTERNAME].ToString(),
                              Product = row[PRODUCTNAME].ToString(),
                              ProductFamilyName = row[PRODUCTFAMILYNAME].ToString(),
                              ProcessBlock = row[PROCESSBLOCK].ToString(),
                              ScribeID = row[SCRIBENUMBER].ToString(),
                              RunPkt = row[RUNPKT].ToString(),
                              Recipe = row[RECIPE].ToString(),
                              EpiVendor = row[EPIVENDOR].ToString(),
                              ParentContainerQty = row[PARENTCONTAINERQTY].ToString(),
                              ChildContainerQty = row[CHILDCONTAINERQTY].ToString(),
                              ContainerType = row[CONTAINERTYPE].ToString(),
                              ParentContainerName = row[PARENTCONTAINERNAME].ToString(),
                              SpecialProcessInstructions = row[SPECIALPROCESSINSTRUCTIONS].ToString()
                          }).ToList();
            }
            catch (Exception ex)
            {
                Globals.MyLog.Error(ex, "MakeDataTableIntoWaferList()");
                wafers = null; 
            }
            return wafers;
        }

        // LATER
        private static List<T> ConvertDataTable<T>(DataTable dt)
        {
            List<T> data = new List<T>();
            foreach (DataRow row in dt.Rows)
            {
                T item = GetItem<T>(row);
                data.Add(item);
            }
            return data;
        }

        private static T GetItem<T>(DataRow dr)
        {
            Type temp = typeof(T);
            T obj = Activator.CreateInstance<T>();

            foreach (DataColumn column in dr.Table.Columns)
            {
                foreach (PropertyInfo pro in temp.GetProperties())
                {
                    if (pro.Name == column.ColumnName)
                        pro.SetValue(obj, dr[column.ColumnName], null);
                    else
                        continue;
                }
            }
            return obj;
        }
    }
}
