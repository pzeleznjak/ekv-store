using EKVStore.Utils.ArgumentCompleters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Security;
using System.Text;
using System.Threading.Tasks;

namespace EKVStore.Cmdlets
{
    [Cmdlet(VerbsData.Import, "EKVFromUnprotectedFile")]
    public class ImportEKVFromUnprotectedFileCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the Encrypted Key-Value store to create")]
        [ArgumentCompleter(typeof(EKVStoreNameArgumentCompleter))]
        public required string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the Encrypted Key-Value store to create")]
        public required SecureString Password { get; set; }

        [Parameter(Position = 2, HelpMessage = "Path to unprotected file to import to new Encrypted Key-Value store")]
        public required string ExportFile { get; set; }

        [Parameter(Position = 3, HelpMessage = "Remove the unprotected file after importing")]
        public SwitchParameter RemoveFile { get; set; } = false;

        [Parameter(Position = 4, HelpMessage = "Force creation of the new Encrypted Key-Value store")]
        public SwitchParameter Force { get; set; } = false;

        protected override void ProcessRecord()
        {
            if (!File.Exists(ExportFile))
            {
                WriteError(new ErrorRecord(new FileNotFoundException($"{ExportFile} does not exist"), "KVFileDoesNotExist", ErrorCategory.ObjectNotFound, this));
                return;
            }

            string[] lines = File.ReadAllLines(ExportFile);

            List<string> kvLines = [];
            bool found = false;
            foreach (string line in lines)
            {
                if (!found)
                {
                    if (line.StartsWith("Key-Value_Store"))
                    {
                        found = true;
                    }
                    continue;
                }

                if (line.StartsWith('#'))
                {
                    continue;
                }
                if (string.IsNullOrEmpty(line))
                {
                    continue;
                }

                kvLines.Add(line);
            }

            bool success = false;
            using PowerShell ps = PowerShell.Create(RunspaceMode.CurrentRunspace);
            if (Force)
            {
                ps.AddCommand("New-EKVStore")
                    .AddParameter("Name", Name)
                    .AddParameter("Password", Password)
                    .AddParameter("Force");
                success = ps.Invoke<bool>()[0];
            }
            else
            {
                ps.AddCommand("New-EKVStore")
                    .AddParameter("Name", Name)
                    .AddParameter("Password", Password);
                success = ps.Invoke<bool>()[0];
            }
            ps.Commands.Clear();

            if (!success)
            {
                WriteObject(false);
                return;
            }

            kvLines.ForEach(l =>
            {
                string[] split = l.Split('=');
                ps.AddCommand("Add-EKVRecord")
                    .AddParameter("Name", Name)
                    .AddParameter("Password", Password)
                    .AddParameter("Key", split[0])
                    .AddParameter("RawValue", split[1]);
                ps.Invoke();
                ps.Commands.Clear();
            });

            if (RemoveFile)
            {
                File.Delete(ExportFile);
                Host.UI.WriteLine($"Removed the {ExportFile} unprotected file");
            }

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Imported {ExportFile} to new Encrypted Key-Value store {Name} successfully");
            WriteObject(true);
        }
    }
}
