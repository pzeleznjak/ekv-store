using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.HelloWorld
{
    internal static class HelloWorldServices
    {
        public static IGreeterService Greeter { get; set; } = new GreeterService();
    }
}
