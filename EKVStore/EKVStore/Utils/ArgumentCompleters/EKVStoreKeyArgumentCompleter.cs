using EKVStore.Initialization;
using Json.More;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Security;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Utils.ArgumentCompleters
{
    internal class EKVStoreKeyArgumentCompleter : IArgumentCompleter
    {
        public IEnumerable<CompletionResult> CompleteArgument(string commandName, string parameterName, string wordToComplete, CommandAst commandAst, IDictionary fakeBoundParameters)
        {
            if (!fakeBoundParameters.Contains("Password"))
            {
                yield break;
            }

            if (!fakeBoundParameters.Contains("Name"))
            {
                yield break;
            }

            object? temp = fakeBoundParameters["Name"];
            if (temp is null)
            {
                yield break;
            }
            string name = (string)temp;

            temp = fakeBoundParameters["Password"];
            if (temp is null)
            {
                yield break;
            }
            var psObj = (PSObject)temp;
            if (psObj.BaseObject is not SecureString password)
            {
                yield break;
            }

            string storeFile = EKVModuleContext.GetStoreFile(name);
            if (!File.Exists(storeFile))
            {
                yield break;
            }

            MasterPassword masterPassword = MasterPassword.ReadMasterPassword(storeFile);
            bool success = masterPassword.ComparePasswordHash(password);
            if (!success)
            {
                yield break;
            }

            IEnumerable<string> keys = File.ReadAllLines(storeFile, Encoding.UTF8)
                .Skip(1)
                .Select(l => l.Trim().Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries)[0])
                .Where(l => l.StartsWith(wordToComplete));
            foreach (string key in keys)
            {
                yield return new CompletionResult(key, key, CompletionResultType.ParameterValue, key);
            }
        }
    }
}
