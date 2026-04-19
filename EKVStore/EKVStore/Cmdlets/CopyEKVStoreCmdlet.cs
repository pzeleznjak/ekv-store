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
    [Cmdlet(VerbsCommon.Copy, "EKVStore")]
    public class CopyEKVStoreCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the Encrypted Key-Value store to copy")]
        [ArgumentCompleter(typeof(EKVStoreNameArgumentCompleter))]
        public required string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the Encrypted Key-Value store")]
        public required SecureString Password { get; set; }

        [Parameter(Position = 2, HelpMessage = "Name of the copy Encrypted Key-Value store")]
        public string? CopyName { get; set; }

        [Parameter(Position = 3, HelpMessage = "Force creation of the copied Encrypted Key-Value store")]
        public SwitchParameter Force { get; set; } = false;

        protected override void ProcessRecord()
        {
            CopyName ??= $"{Name}_copy";

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

            string copyStoreFile = EKVModuleContext.GetStoreFile(CopyName);
            bool success = CreateStoreFile(copyStoreFile, Force);
            if (!success)
            {
                WriteError(new ErrorRecord(new InvalidOperationException("Encrypted Key-Value store already exists"), "EKVStoreAlreadyExists", ErrorCategory.ResourceExists, this));
                WriteObject(false);
                return;
            }

            File.WriteAllLines(copyStoreFile, File.ReadAllLines(storeFile));
            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Copied contents of {Name} to $CopyName Encrypted Key-Value store");
            WriteObject(true);
        }
    }
}
