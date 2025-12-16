using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.HelloWorld
{
    internal class GreeterService : IGreeterService
    {
        public string Greet(string name) => $"Hello World by {name}";
    }
}
