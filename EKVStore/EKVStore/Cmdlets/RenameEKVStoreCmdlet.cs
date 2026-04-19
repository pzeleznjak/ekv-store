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
    [Cmdlet(VerbsCommon.Rename, "EKVStore")]
    public class RenameEKVStoreCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Original name of the Encrypted Key-Value store to rename")]
        [ArgumentCompleter(typeof(EKVStoreNameArgumentCompleter))]
        public required string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the Encrypted Key-Value store to rename")]
        public required SecureString Password { get; set; }

        [Parameter(Mandatory = true, Position = 2, HelpMessage = "New name of the Encrypted Key-Value Store")]
        public required string NewName { get; set; }

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

            string newStoreFile = EKVModuleContext.GetStoreFile(NewName);
            File.Move(storeFile, newStoreFile);

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Successfully renamed EKV store {Name} to {NewName}");
            WriteObject(true);
        }
    }
}
