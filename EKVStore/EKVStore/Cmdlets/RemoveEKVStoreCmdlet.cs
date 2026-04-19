using EKVStore.Initialization;
using EKVStore.Utils;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Security;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Cmdlets
{
    [Cmdlet(VerbsCommon.Remove, "EKVStore")]
    public class RemoveEKVStoreCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the new Encrypted Key-Value store to be created")]
        public required string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the new Encrypted Key-Value store")]
        public required SecureString Password { get; set; }

        [Parameter(Position = 2, HelpMessage = "Force removal of the new Encrypted Key-Value store")]
        public SwitchParameter Force { get; set; } = false;

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

            if (!Force)
            {
                Host.UI.WriteLine(ConsoleColor.DarkRed, Host.UI.RawUI.BackgroundColor, $"Are you sure you want to remove Encrypted Key-Value store {Name} ? (y/n)");
                string? answer = Console.ReadLine();

                if (string.IsNullOrEmpty(answer)
                    || answer.Length > 1
                    || (answer[0] != 'Y' && answer[0] != 'y'))
                {
                    Host.UI.WriteLine(ConsoleColor.Yellow, Host.UI.RawUI.BackgroundColor, "Operation cancelled");
                    WriteObject(null);
                }
            }

            List<(string, string)> records = [];
            Aes? aes = null;
            ICryptoTransform? decryptor = null;
            string decryptedValueText = "";
            try
            {
                aes = CryptographyService.CreateAes(Password, masterPassword.Salt);
                decryptor = aes.CreateDecryptor();
                foreach (string line in File.ReadAllLines(storeFile).Skip(1))
                {
                    string[] split = line.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries); // USE ALL WHITESPACES
                    string key = split[0];
                    string encryptedValueHex = split[1];

                    byte[] encryptedValueBytes = [.. Enumerable
                        .Range(0, encryptedValueHex.Length / 2)
                        .Select(i => Convert.ToByte(encryptedValueHex.Substring(i * 2, 2), 16))];

                    var decryptedValueBytes = decryptor.TransformFinalBlock(encryptedValueBytes, 0, encryptedValueBytes.Length);
                    decryptedValueText = Encoding.UTF8.GetString(decryptedValueBytes);

                    records.Add((key, decryptedValueText));
                }                
            }
            finally
            {
                aes?.Dispose();
                decryptor?.Dispose();
            }

            File.Delete(storeFile);
            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Removed Encrypted Key-Value store {Name}");

            WriteObject(records);
        }
    }
}
