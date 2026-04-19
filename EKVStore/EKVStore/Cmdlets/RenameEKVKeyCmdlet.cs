using EKVStore.Initialization;
using EKVStore.Utils;
using EKVStore.Utils.ArgumentCompleters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Security;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Cmdlets
{
    [Cmdlet(VerbsCommon.Rename, "EKVKey")]
    public class RenameEKVKeyCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the Encrypted Key-Value store to access")]
        [ArgumentCompleter(typeof(EKVStoreNameArgumentCompleter))]
        public required string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the Encrypted Key-Value store to access")]
        public required SecureString Password { get; set; }

        [Parameter(Mandatory = true, Position = 2, HelpMessage = "Key of the Encrypted Key-Value record to rename")]
        [ArgumentCompleter(typeof(EKVStoreKeyArgumentCompleter))]
        public required string Key { get; set; }

        [Parameter(Mandatory = true, Position = 3, HelpMessage = "New key of the Encrypted Key-Value record")]
        public required string NewKey { get; set; }

        protected override void ProcessRecord()
        {
            string storeFile = EKVModuleContext.GetStoreFile(Name);
            if (!File.Exists(storeFile))
            {
                WriteError(new ErrorRecord(new FileNotFoundException($"Encrypted Key-Value store {Name} does not exist"), "EKVStoreDoesNotExist", ErrorCategory.ObjectNotFound, this));
                WriteObject(false);
                return;
            }

            MasterPassword masterPassword = MasterPassword.ReadMasterPassword(storeFile);
            if (!masterPassword.ComparePasswordHash(Password))
            {
                WriteError(new ErrorRecord(new ArgumentException("Invalid Key-Value store Master Password"), "InvalidEKVMasterPassword", ErrorCategory.InvalidArgument, this));
                WriteObject(false);
                return;
            }

            List<string> lines = [];
            bool firstLine = true;
            bool found = false;
            foreach (string line in File.ReadAllLines(storeFile))
            {
                if (firstLine)
                {
                    lines.Add(line);
                    firstLine = false;
                    continue;
                }

                string[] split = line.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries); // USE ALL WHITESPACES
                if (split[0].Equals(Key))
                {
                    found = true;
                    lines.Add($"{NewKey} {split[1]}");
                    continue;
                }
                lines.Add(line);
            }

            if (!found)
            {
                Host.UI.WriteLine(ConsoleColor.Red, Host.UI.RawUI.BackgroundColor, $"Key {Key} does not exist");
                WriteObject(false);
            }

            File.WriteAllLines(storeFile, lines);

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Successfully renamed {Key} to {NewKey}");
            WriteObject(true);
        }
    }
}
