using SsisBuild.Core.Builder;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SqlBuildTools.Utils
{
    public class SSISBuilder
    {
        public string ProjectPath { get; set; }

        public string OutputFolder { get; set; }

        public string ProtectionLevel { get; set; }

        public string Password { get; set; }

        public string NewPassword { get; set; }

        public string Configuration { get; set; }

        public string ReleaseNotes { get; set; }

        public Hashtable Parameters { get; set; }

        private IBuilder _builder;

        public void Build(string WorkingFolder)
        {
            var buildArguments = new BuildArguments(
                WorkingFolder,
                string.IsNullOrWhiteSpace(ProjectPath) ? null : ProjectPath,
                string.IsNullOrWhiteSpace(OutputFolder) ? null : OutputFolder,
                string.IsNullOrWhiteSpace(ProtectionLevel) ? null : ProtectionLevel,
                string.IsNullOrWhiteSpace(Password) ? null : Password,
                string.IsNullOrWhiteSpace(NewPassword) ? null : NewPassword,
                string.IsNullOrWhiteSpace(Configuration) ? null : Configuration,
                string.IsNullOrWhiteSpace(ReleaseNotes) ? null : ReleaseNotes,
                Parameters.OfType<DictionaryEntry>().ToDictionary(e => e.Key as string, e => e.Value as string)
            );

            _builder = _builder ?? new Builder();

            try
            {
                _builder.Build(buildArguments);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw;
            }
        }
    }
}
