using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Utils
{
    public record MasterPassword(string PasswordHash, string Salt);
}
