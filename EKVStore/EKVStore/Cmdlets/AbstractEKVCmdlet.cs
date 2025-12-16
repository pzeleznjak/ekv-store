using EKVStore.Utils;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Cmdlets
{
    public abstract class AbstractEKVCmdlet : PSCmdlet
    {
        protected const int SALT_LENGTH = 8;

        protected static readonly char[] reservedKeyCharacters = [' ', '\n', '\t', ',', '='];

        protected string PsScriptRoot
        {
            get
            {
                if (_psScriptRoot is null)
                {
                    lock (_psScriptRootLock)
                    {
                        if (_psScriptRoot is null)
                        {
                            _psScriptRoot = SessionState.PSVariable.GetValue("PSScriptRoot").ToString() ?? throw new NullReferenceException("PSScriptRoot is null");

                            if (string.IsNullOrEmpty(_psScriptRoot))
                            {
                                var modulePath = MyInvocation.MyCommand.Module?.ModuleBase;
                                _psScriptRoot = modulePath ?? throw new InvalidOperationException("Cannot determine script root");
                            }
                        }
                    }
                }
                return _psScriptRoot;
            }
        }

        protected Dictionary<string, object> PsBoundParameters 
        { 
            get
            {
                if (_psBoundParameters is null)
                {
                    lock (_psBoundParametersLock)
                    {
                        _psBoundParameters ??= MyInvocation.BoundParameters;
                    }
                }

                return _psBoundParameters;
            }
        }

        private readonly object _psScriptRootLock = new();
        private string? _psScriptRoot;

        private readonly object _psBoundParametersLock = new();
        private Dictionary<string, object>? _psBoundParameters;

        

        protected static bool ContainsReservedChars(string key) => key.IndexOfAny(reservedKeyCharacters) >= 0;

        protected static string GetStoreDirectory(string scriptRoot) => Path.Combine(scriptRoot, ".ekvs");

        protected static bool CreateStoreFile(string storeFile, bool force = false)
        {
            if (!force && File.Exists(storeFile))
            {
                return false;
            }

            FileStream fs = File.Create(storeFile);
            fs.Close();
            return true;
        }

        protected static MasterPassword ReadMasterPassword(string storeFile)
        {
            var firstLineSplit = (File.ReadLines(storeFile).FirstOrDefault() ?? throw new InvalidDataException("EKV Store File is empty!")).Split(' ');
            return new MasterPassword(firstLineSplit[0], firstLineSplit[1]);
        }

        protected static bool ComparePasswordHashes(string masterPasswordHash, SecureString password, string salt) => ComparePasswordHashes(masterPasswordHash, CryptographyService.ConvertToPlainString(password), salt);

        protected static bool ComparePasswordHashes(string masterPasswordHash, string password, string salt)
        {
            string saltedPassword = password + salt;
            string hashText = CryptographyService.GetSHA256HashHex(saltedPassword);
            return hashText.Equals(masterPasswordHash);
        }

        protected string GetStoreFile(string name, string? directoryPath = null)
        {
            directoryPath ??= GetStoreDirectory(PsScriptRoot);
            return Path.Combine(directoryPath, $"{name}.ekv");
        }
    }
}
