using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Initialization
{
    internal class EKVModuleContext
    {
        public static string ModuleRoot { get; private set; } = "";

        internal static void Initialize(string moduleRoot)
        {
            if (string.IsNullOrEmpty(ModuleRoot))
            {
                ModuleRoot = moduleRoot;
            }
        }

        internal static string GetStoreDirectory() => Path.Combine(ModuleRoot, ".ekvs");

        internal static string GetStoreDirectory(string scriptRoot) => Path.Combine(scriptRoot, ".ekvs");

        internal static string GetStoreFile(string name, string? directoryPath = null)
        {
            directoryPath ??= GetStoreDirectory(ModuleRoot);
            return Path.Combine(directoryPath, $"{name}.ekv");
        }
    }
}
