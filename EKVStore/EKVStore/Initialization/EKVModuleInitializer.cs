using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Initialization
{
    public class EKVModuleInitializer : IModuleAssemblyInitializer
    {
        public void OnImport()
        {
            string assemblyPath = typeof(EKVModuleInitializer).Assembly.Location;
            string moduleRoot = Path.GetDirectoryName(assemblyPath) ?? throw new NullReferenceException("Module Root not found");
            EKVModuleContext.Initialize(moduleRoot);
        }
    }
}
