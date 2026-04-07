using EKVStore.Initialization;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, "EKVStores")]
    public class GetEKVStoresCmdlet : AbstractEKVCmdlet
    {
        protected override void ProcessRecord()
        {
            List<string> stores = [];
            string directoryPath = EKVModuleContext.GetStoreDirectory();
            foreach (string file in Directory.GetFiles(directoryPath, "*.ekv"))
            {
                string baseName = Path.GetFileNameWithoutExtension(file);
                stores.Add(baseName);
            }
            WriteObject(stores);
        }
    }
}
