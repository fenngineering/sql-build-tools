using SsisBuild.Core.Builder;
using SsisBuild.Core.Deployer;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace SqlBuildTools.Utils
{
    public class SSISPublisher
    {
        public string DeploymentFilePath { get; set; }

        public string ServerInstance { get; set; }

        public string ServerInstanceUserID { get; set; }

        public string ServerInstancePassword { get; set; }

        public string Catalog { get; set; }

        public string Folder { get; set; }

        public string ProjectName { get; set; }

        public string ProjectPassword { get; set; }

        public bool EraseSensitiveInfo { get; set; }

        private IDeployer _deployer;
        public void Publish(string WorkingFolder)
        {
            var deployArguments = new DeployArguments(
                WorkingFolder,
                string.IsNullOrWhiteSpace(DeploymentFilePath) ? null : DeploymentFilePath,
                string.IsNullOrWhiteSpace(ServerInstance) ? null : ServerInstance,
                string.IsNullOrWhiteSpace(Catalog) ? null : Catalog,
                string.IsNullOrWhiteSpace(Folder) ? null : Folder,
                string.IsNullOrWhiteSpace(ProjectName) ? null : ProjectName,
                string.IsNullOrWhiteSpace(ProjectPassword) ? null : ProjectPassword,
                EraseSensitiveInfo,
                string.IsNullOrWhiteSpace(ServerInstanceUserID) ? null : ServerInstanceUserID,
                string.IsNullOrWhiteSpace(ServerInstancePassword) ? null : ServerInstancePassword
            );

            _deployer = _deployer ?? new Deployer();

            try
            {
                _deployer.Deploy(deployArguments);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw;
            }
        }
    }
}
