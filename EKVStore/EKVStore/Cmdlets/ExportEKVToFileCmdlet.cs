using EKVStore.Initialization;
using EKVStore.Utils.ArgumentCompleters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Cmdlets
{
    [Cmdlet(VerbsData.Export, "EKVToFile")]
    public class ExportEKVToFileCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the Encrypted Key-Value store to access")]
        [ArgumentCompleter(typeof(EKVStoreNameArgumentCompleter))]
        public required string Name { get; set; }

        [Parameter(Position = 1, HelpMessage = "Path to export Encrypted Key-Value store to to")]
        public string? ExportDirectory { get; set; }

        [Parameter(Position = 2, HelpMessage = "Flag which forces the export of the Encrypted Key-Value store even if export file already exists")]
        public SwitchParameter Force { get; set; } = false;

        protected override void ProcessRecord()
        {
            string storeFile = EKVModuleContext.GetStoreFile(Name);
            if (!File.Exists(storeFile))
            {
                WriteError(new ErrorRecord(new FileNotFoundException($"Encrypted Key-Value store {Name} does not exist"), "EKVStoreDoesNotExist", ErrorCategory.ObjectNotFound, this));
                WriteObject(false);
                return;
            }

            string exportFile;
            if (ExportDirectory is null)
            {
                exportFile = EKVModuleContext.GetStoreFile(Name, Directory.GetCurrentDirectory());
            }
            else
            {
                exportFile = EKVModuleContext.GetStoreFile(Name, ExportDirectory);
            }

            if (!Force && File.Exists(exportFile))
            {
                Host.UI.WriteLine(ConsoleColor.Red, Host.UI.RawUI.BackgroundColor, $"Export file {exportFile} already exists");
                WriteObject(false);
                return;
            }

            File.Copy(storeFile, exportFile);

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Successfully exported {Name} EKV store to {exportFile}");
            WriteObject(true);
        }
    }
}
