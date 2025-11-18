using System.Management.Automation;

namespace EKVStore
{
    [Cmdlet(VerbsCommon.Get, "HelloWorld")]
    public class HelloWorldCmdletWrapper : Cmdlet
    {
        [Parameter(Mandatory = true)]
        public string Name { get; set; } = "DEFAULT";

        protected override void ProcessRecord()
        {
            WriteObject($"{Name}: Hello World!");
        }
    }
}
