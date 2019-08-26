using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace SqlBuildTools.Utils.Tests
{
    [TestClass]
    public class SSISPublisher
    {
        [TestMethod]
        public void Publish()
        {
            var ssisPublisher = new SqlBuildTools.Utils.SSISPublisher
            {
                DeploymentFilePath = @"C:\dbgit\fenngineering\db-ssis-open-street-map\build\DataRefresh.ispac",
                ServerInstance = ".",
                Catalog = "SSISDB",
                Folder = "OpenStreetMap",
                ProjectName = "DataRefresh",
                ProjectPassword = "test",
                EraseSensitiveInfo = true
            };

            ssisPublisher.Publish(@"C:\dbgit\fenngineering\db-ssis-open-street-map");

        }
    }
}
