using System.Management.Automation;

namespace EKVStore.HelloWorld
{
    [Cmdlet(VerbsCommon.Get, "HelloWorld")]
    public class HelloWorldCmdletWrapper : Cmdlet
    {
        [Parameter(Mandatory = true)]
        public string Name { get; set; } = "DEFAULT";

        private IGreeterService? greeterService;

        protected override void BeginProcessing()
        {
            greeterService = HelloWorldServices.Greeter;
            WriteDebug("Instantiated Greeter Service");
        }

        protected override void ProcessRecord()
        {
            WriteObject(greeterService?.Greet(Name));
        }

        protected override void EndProcessing()
        {
            greeterService = null;
            WriteDebug("Invalidated Greeter Service");
        }
    }
}
