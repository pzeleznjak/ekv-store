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
    [Cmdlet(VerbsCommon.Get, "EKVKeys")]
    public class GetEKVKeysCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the Encrypted Key-Value store to access")]
        [ArgumentCompleter(typeof(EKVStoreNameArgumentCompleter))]
        public required string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the Encrypted Key-Value store to access")]
        public required SecureString Password { get; set; }

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

            WriteObject(File.ReadAllLines(storeFile, Encoding.UTF8)
                .Skip(1)
                .Select(l => l.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries)[0]));
        }
    }
}
