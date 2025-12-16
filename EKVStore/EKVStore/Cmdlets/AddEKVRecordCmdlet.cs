using EKVStore.Initialization;
using EKVStore.Utils;
using EKVStore.Utils.ArgumentCompleters;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Security;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Cmdlets
{
    [Cmdlet(VerbsCommon.Add, "EKVRecord", DefaultParameterSetName = "ByValue")]
    public class AddEKVRecordCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the Encrypted Key-Value store to access")]
        [ArgumentCompleter(typeof(EKVStoreNameArgumentCompleter))]
        public string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the Encrypted Key-Value store to access")]
        public SecureString Password { get; set; }

        [Parameter(Mandatory = true, Position = 2, HelpMessage = "Key of the Encrypted Key-Value record to add")]
        public string Key { get; set; }

        [Parameter(Mandatory = true, Position = 3, ParameterSetName = "ByValue", HelpMessage = "Secure String Value of the Encrypted Key-Value record to add")]
        public SecureString Value { get; set; }

        [Parameter(Mandatory = true, Position = 4, ParameterSetName = "ByRawValue", HelpMessage = "Raw value of the Encrypted Key-Value record to add")]
        public string RawValue { get; set; }

        protected override void ProcessRecord()
        {
            if (ContainsReservedChars(Key))
            {
                WriteError(new ErrorRecord(new InvalidDataException("Key must not contain whitespace, commas or equality operator signs"), "InvalidEKVKey", ErrorCategory.InvalidData, this));
                WriteObject(false);
                return;
            }

            string storeFile = EKVModuleContext.GetStoreFile(Name);
            if (!File.Exists(storeFile))
            {
                WriteError(new ErrorRecord(new FileNotFoundException($"Encrypted Key-Value store {Name} does not exist"), "EKVStoreDoesNotExist", ErrorCategory.ObjectNotFound, this));
                WriteObject(false);
                return;
            }

            MasterPassword masterPassword = ReadMasterPassword(storeFile);
            if (!ComparePasswordHashes(masterPassword.PasswordHash, Password, masterPassword.Salt))
            {
                WriteError(new ErrorRecord(new ArgumentException("Invalid Key-Value store Master Password"), "InvalidEKVMasterPassword", ErrorCategory.InvalidArgument, this));
                WriteObject(false); 
                return;
            }

            if (PsBoundParameters.ContainsKey("Value"))
            {
                RawValue = CryptographyService.ConvertToPlainString(Value);
            }

            byte[] valueBytes = Encoding.UTF8.GetBytes(RawValue);

            Aes? aes = null;
            ICryptoTransform? encryptor = null;
            string encryptedValueHex = "";
            try
            {
                aes = CryptographyService.CreateAes(Password, masterPassword.Salt);
                encryptor = aes.CreateEncryptor();
                var encryptedValueBytes = encryptor.TransformFinalBlock(valueBytes, 0, valueBytes.Length);
                encryptedValueHex = Convert.ToHexString(encryptedValueBytes);
            }
            finally
            {
                aes?.Dispose();
                encryptor?.Dispose();
            }

            string record = $"{Key} {encryptedValueHex}";
            File.AppendAllText(storeFile, record + Environment.NewLine);

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Successfully added Encrypted Key-Value under key {Key}");
            WriteObject(true);
        }
    }
}
