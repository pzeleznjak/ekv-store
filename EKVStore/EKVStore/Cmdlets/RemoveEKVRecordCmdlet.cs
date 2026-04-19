using EKVStore.Initialization;
using EKVStore.Utils;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Security;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace EKVStore.Cmdlets
{
    [Cmdlet(VerbsCommon.Remove, "EKVRecord")]
    public class RemoveEKVRecordCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the Encrypted Key-Value store to access")]
        public required string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the Encrypted Key-Value store to access")]
        public required SecureString Password { get; set; }

        [Parameter(Mandatory = true, Position = 2, HelpMessage = "Key of the Encrypted Key-Value record to remove")]
        public required string Key { get; set; }

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

            bool found = false;
            string? encryptedValueHex = null;
            List<string> result = [];
            foreach (string line in File.ReadAllLines(storeFile, Encoding.UTF8))
            {
                if (!found && Regex.IsMatch(line, $"^{Regex.Escape(Key)}\\s+"))
                {
                    found = true;

                    string[] parts = line.Split((char[]?)null, 2, StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length > 1)
                    {
                        encryptedValueHex = parts[1];
                    }

                    continue;
                }

                result.Add(line);
            }

            if (!found)
            {
                WriteError(new ErrorRecord(new ItemNotFoundException($"No line with key {Key} to remove"), "EKVKeyDoesNotExist", ErrorCategory.InvalidArgument, this));
                WriteObject(false);
                return;
            }

            File.WriteAllLines(storeFile, result);

            if (encryptedValueHex is null)
            {
                WriteError(new ErrorRecord(new ItemNotFoundException($"Encrypted value for key {Key} not found"), "EKVValueDoesNotExist", ErrorCategory.InvalidData, this));
                WriteObject(false);
                return;
            }

            byte[] encryptedValueBytes = [.. Enumerable
                .Range(0, encryptedValueHex.Length / 2)
                .Select(i => Convert.ToByte(encryptedValueHex.Substring(i * 2, 2), 16))];

            Aes? aes = null;
            ICryptoTransform? decryptor = null;
            string decryptedValueText = "";
            try
            {
                aes = CryptographyService.CreateAes(Password, masterPassword.Salt);
                decryptor = aes.CreateDecryptor();
                var decryptedValueBytes = decryptor.TransformFinalBlock(encryptedValueBytes, 0, encryptedValueBytes.Length);
                decryptedValueText = Encoding.UTF8.GetString(decryptedValueBytes);
            }
            finally
            {
                aes?.Dispose();
                decryptor?.Dispose();
            }

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Successfully deleted key {Key}");
            WriteObject(decryptedValueText);
        }
    }
}
