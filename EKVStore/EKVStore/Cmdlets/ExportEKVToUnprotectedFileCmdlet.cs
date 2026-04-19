using EKVStore.Initialization;
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
    [Cmdlet(VerbsData.Export, "EKVToUnprotectedFile")]
    public class ExportEKVToUnprotectedFileCmdlet : AbstractEKVCmdlet
    {
        [Parameter(Mandatory = true, Position = 0, HelpMessage = "Name of the Encrypted Key-Value store to export")]
        [ArgumentCompleter(typeof(EKVStoreNameArgumentCompleter))]
        public required string Name { get; set; }

        [Parameter(Mandatory = true, Position = 1, HelpMessage = "Master Password of the Encrypted Key-Value store to export")]
        public required SecureString Password { get; set; }

        [Parameter(Position = 2, HelpMessage = "Path to unprotected file to export Encrypted Key-Value store to")]
        public string? ExportFile { get; set; }

        [Parameter(Position = 3, HelpMessage = "Force creation of the unprotected file")]
        public SwitchParameter Force { get; set; } = false;

        protected override void ProcessRecord()
        {
            ExportFile ??= Path.Join(Directory.GetCurrentDirectory(), $"{Name}.kv");
            
            if (!Path.GetExtension(ExportFile).Equals(".kv"))
            {
                Host.UI.WriteLine(ConsoleColor.Yellow, Host.UI.RawUI.BackgroundColor, "ExportFile must have extension .kv");
                Host.UI.WriteLine("Appended '.kv' to ExportFile path");
                ExportFile = $"{ExportFile}.kv";
            }

            if (!Force && File.Exists(ExportFile))
            {
                WriteError(new ErrorRecord(new IOException($"File {ExportFile} already exists"), "KVFileAlreadyExists", ErrorCategory.ResourceExists, this));
                WriteObject(false);
                return;
            }

            Host.UI.WriteLine($"Exporting {Name} to {ExportFile}");

            using PowerShell ps = PowerShell.Create(RunspaceMode.CurrentRunspace);
            ps.AddCommand("Get-EKVKeys")
                .AddParameter("Name", Name)
                .AddParameter("Password", Password);
            List<string> keys = [];
            foreach (PSObject result in ps.Invoke())
            {
                keys.AddRange(result.ToString().Split(" "));
            }

            StringBuilder sb = new();
            sb.AppendLine("Key-Value_Store");
            sb.AppendLine("# --------------- #");

            foreach (string key in keys)
            {
                ps.Commands.Clear();
                ps.AddCommand("Get-EKVRecord")
                    .AddParameter("Name", Name)
                    .AddParameter("Password", Password)
                    .AddParameter("Key", key);
                var result = ps.Invoke<string>();
                if (ps.HadErrors)
                {
                    ps.Streams.Error
                        .Select(e => e.ToString())
                        .ToList()
                        .ForEach(Console.WriteLine);

                    throw new Exception("Error calling Get-EKVRecord");
                }

                string value = result.FirstOrDefault()
                    ?? throw new InvalidOperationException($"No value returned for key '{key}'");

                sb.Append(key);
                sb.Append('=');
                sb.AppendLine(value);
            }

            File.WriteAllText(ExportFile, sb.ToString());

            Host.UI.WriteLine(ConsoleColor.Green, Host.UI.RawUI.BackgroundColor, $"Successfully exported Encrypted Key-Value store {Name} to {ExportFile}");
            WriteObject(true);
        }
    }
}
