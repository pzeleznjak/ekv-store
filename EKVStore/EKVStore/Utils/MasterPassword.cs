using System;
using System.Collections.Generic;
using System.Linq;
using System.Security;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Utils
{
    public record MasterPassword(string PasswordHash, string Salt)
    {
        public bool ComparePasswordHash(SecureString password) => ComparePasswordHashes(PasswordHash, password, Salt);

        public bool ComparePasswordHash(string password) => ComparePasswordHashes(PasswordHash, password, Salt);

        public static MasterPassword ReadMasterPassword(string storeFile)
        {
            var firstLineSplit = (File.ReadLines(storeFile).FirstOrDefault() ?? throw new InvalidDataException("EKV Store File is empty!")).Split(' ');
            return new MasterPassword(firstLineSplit[0], firstLineSplit[1]);
        }

        public static bool ComparePasswordHashes(string masterPasswordHash, SecureString password, string salt) => ComparePasswordHashes(masterPasswordHash, CryptographyService.ConvertToPlainString(password), salt);

        public static bool ComparePasswordHashes(string masterPasswordHash, string password, string salt)
        {
            string saltedPassword = password + salt;
            string hashText = CryptographyService.GetSHA256HashHex(saltedPassword);
            return hashText.Equals(masterPasswordHash);
        }
    }
}
