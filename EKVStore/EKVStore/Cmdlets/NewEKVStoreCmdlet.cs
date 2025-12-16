using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Security;
using System.Security.Cryptography;
using EKVStore.Utils;
using EKVStore.Initialization;
using EKVStore.Utils.ArgumentCompleters;

namespace EKVStore.Cmdlets
{
    [Cmdlet(VerbsCommon.New, "EKVStore")]
    public class NewEKVStoreCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the new Encrypted Key-Value store to be created")]
        public string Name { get; set; } = "placeholder";

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the new Encrypted Key-Value store")]
        public SecureString Password { get; set; } = new SecureString();

        [Parameter(Position = 2, HelpMessage = "Force creation of the new Encrypted Key-Value store")]
        public SwitchParameter Force { get; set; } = false;

        protected override void ProcessRecord()
        {
            string directoryPath = EKVModuleContext.GetStoreDirectory();
            if (!Directory.Exists(directoryPath))
            {
                Directory.CreateDirectory(directoryPath);
            }
            
            string storeFile = EKVModuleContext.GetStoreFile(Name, directoryPath);
            bool success = CreateStoreFile(storeFile, Force);

            if (success)
            {
                Host.UI.WriteLine("Encrypted Key-Value store already exists");
            } 
            else
            {
                WriteError(new ErrorRecord(new InvalidOperationException("Created new empty Encrypted Key-Value store"), "EKVStoreAlreadyExists", ErrorCategory.ResourceExists, this));
                WriteObject(false);
                return;
            }

            string plainPassword = CryptographyService.ConvertToPlainString(Password);

            var saltBytes = new byte[SALT_LENGTH];
            using (RandomNumberGenerator rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(saltBytes);
            }

            string saltText = Convert.ToBase64String(saltBytes);
            string saltedPassword = plainPassword + saltText;
            string hashText = CryptographyService.GetSHA256HashHex(saltedPassword);
            string record = $"{hashText} {saltText}";

            File.WriteAllText(storeFile, record + Environment.NewLine, Encoding.UTF8);

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Successfully created new Encrypted Key-Value store {Name}");
            WriteObject(true);
        }
    }
}
