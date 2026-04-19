using EKVStore.Initialization;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Utils.ArgumentCompleters
{
    internal class EKVStoreNameArgumentCompleter : IArgumentCompleter
    {
        public IEnumerable<CompletionResult> CompleteArgument(string commandName, string parameterName, string wordToComplete, CommandAst commandAst, IDictionary fakeBoundParameters)
        {
            string storeDirectory = EKVModuleContext.GetStoreDirectory();
            IEnumerable<string> files = Directory
            .EnumerateFiles(storeDirectory, "*.ekv", SearchOption.TopDirectoryOnly)
            .Select(f => Path.GetFileNameWithoutExtension(f) ?? "")
            .Where(name => name.StartsWith(wordToComplete, StringComparison.OrdinalIgnoreCase));

            foreach (var match in files)
            {
                yield return new CompletionResult(match, match, CompletionResultType.ParameterValue, match);
            }
        }
    }
}
