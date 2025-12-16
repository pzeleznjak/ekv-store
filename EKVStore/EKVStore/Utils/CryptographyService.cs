using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Utils
{
    public static class CryptographyService
    {
        private const int AES_ITERATIONS = 8192;

        private const int ENCRYPTION_KEY_LENGTH = 32;

        private const int ENCRYPTION_IV_LENGTH = 16;

        private const int AES_KEY_SIZE = 256;

        private static readonly SHA256 sha256 = SHA256.Create();

        public static string ConvertToPlainString(SecureString secureString, bool dispose = false)
        {
            IntPtr unmanagedString = IntPtr.Zero;
            try
            {
                unmanagedString = Marshal.SecureStringToBSTR(secureString);
                return Marshal.PtrToStringBSTR(unmanagedString);
            }
            finally
            {
                Marshal.ZeroFreeBSTR(unmanagedString);
                if (dispose)
                {
                    secureString.Dispose();
                }
            }
        }

        public static string GetSHA256HashHex(string text)
        {
            var bytes = Encoding.UTF8.GetBytes(text);
            byte[] hashBytes = sha256.ComputeHash(bytes);
            return Convert.ToHexString(hashBytes);
        }

        public static Aes CreateAes(SecureString password, string salt) => CreateAes(ConvertToPlainString(password), salt);

        public static Aes CreateAes(string password, string salt)
        {
            Rfc2898DeriveBytes kdf = new(
                Encoding.UTF8.GetBytes(password),
                Encoding.UTF8.GetBytes(salt),
                AES_ITERATIONS,
                HashAlgorithmName.SHA256
            );

            var encryptionKey = kdf.GetBytes(ENCRYPTION_KEY_LENGTH);
            var encryptionIv = kdf.GetBytes(ENCRYPTION_IV_LENGTH);

            Aes aes = Aes.Create();
            aes.KeySize = AES_KEY_SIZE;
            aes.Mode = CipherMode.CBC;
            aes.Padding = PaddingMode.PKCS7;
            aes.Key = encryptionKey;
            aes.IV = encryptionIv;

            return aes;
        }
    }
}
