using EKVStore.Initialization;
using EKVStore.Utils;
using EKVStore.Utils.ArgumentCompleters;
using Microsoft.PowerShell.Commands;
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
    [Cmdlet(VerbsCommon.Get, "EKVRecord", DefaultParameterSetName = "Default")]
    public class GetEKVRecordCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the Encrypted Key-Value store to access")]
        [ArgumentCompleter(typeof(EKVStoreNameArgumentCompleter))]
        public required string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the Encrypted Key-Value store to access")]
        public required SecureString Password { get; set; }

        [Parameter(Mandatory = true, Position = 2, HelpMessage = "Key of the Encrypted Key-Value record to get")]
        [ArgumentCompleter(typeof(EKVStoreKeyArgumentCompleter))]
        public required string Key { get; set; }

        [Parameter(ParameterSetName = "SecureStringSet", HelpMessage = "Return Encrypted Value as SecureString")]
        public SwitchParameter AsSecureString { get; set; } = false;

        [Parameter(ParameterSetName = "ClipboardSet", HelpMessage = "Add Encrypted Key-Value record decrypted value to clipboard")]
        public SwitchParameter ToClipboard { get; set; } = false;

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

            string? encryptedValueHex = null;
            foreach(string line in File.ReadAllLines(storeFile, Encoding.UTF8).Skip(1))
            {
                string[] split = line.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries); // USE ALL WHITESPACES
                if (split[0].Equals(Key))
                {
                    encryptedValueHex = split[1];
                    break;
                }
            }
            
            if (encryptedValueHex is null)
            {
                WriteError(new ErrorRecord(new ArgumentException($"Encrypted value for key {Key} not found"), "EKVKeyDoesNotExist", ErrorCategory.InvalidArgument, this));
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

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Successfully decrypted Encrypted Key-Value under key {Key}");

            if (ToClipboard)
            {
                PowerShell.Create()
                    .AddCommand("Set-Clipboard")
                    .AddArgument(decryptedValueText)
                    .Invoke();
            }

            if (AsSecureString)
            {
                SecureString secureDecryptedValueText = new();
                foreach (char c in decryptedValueText)
                {
                    secureDecryptedValueText.AppendChar(c);
                }
                secureDecryptedValueText.MakeReadOnly();
                WriteObject(secureDecryptedValueText);
                return;
            }

            WriteObject(decryptedValueText);
        }
    }
}
