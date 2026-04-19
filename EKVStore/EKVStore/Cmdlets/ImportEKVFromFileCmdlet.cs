using EKVStore.Initialization;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Cmdlets
{
    [Cmdlet(VerbsData.Import, "EKVFromFile")]
    public class ImportEKVFromFileCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "File to import into an Encrypted Key-Value store")]
        public required string ExportFile { get; set; }

        [Parameter(Position = 1, HelpMessage = "Remove the export file after importing")]
        public SwitchParameter RemoveFile { get; set; } = false;

        [Parameter(Position = 2, HelpMessage = "Flag which forces the import of the Encrypted Key-Value store even if the store already exists")]
        public SwitchParameter Force { get; set; } = false;

        protected override void ProcessRecord()
        {
            if (!File.Exists(ExportFile))
            {
                WriteError(new ErrorRecord(new FileNotFoundException($"{ExportFile} does not exist"), "FileDoesNotExist", ErrorCategory.ObjectNotFound, this));
                return;
            }

            string name = Path.GetFileNameWithoutExtension(ExportFile);

            string storeDirectory = EKVModuleContext.GetStoreDirectory();
            if (!Directory.Exists(storeDirectory))
            {
                Directory.CreateDirectory(storeDirectory);
            }

            string storePath = EKVModuleContext.GetStoreFile(name);
            if (!Force && File.Exists(storePath))
            {
                Host.UI.WriteLine(ConsoleColor.Red, Host.UI.RawUI.BackgroundColor, $"Encrypted Key-Value store {name} already exists");
                WriteObject(false);
                return;
            }

            File.Copy(ExportFile, storePath, true);

            if (RemoveFile)
            {
                File.Delete(ExportFile);
                Host.UI.WriteLine($"Removed the {ExportFile} unprotected file");
            }

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Imported $ExportFile to new Encrypted Key-Value store {name} successfully");
            WriteObject(true);
        }
    }
}
