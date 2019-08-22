using Microsoft.SqlServer.Dac.Deployment;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

namespace SqlBuildTools.Contributors
{
    [ExportDeploymentPlanModifier(ContributorId, "1.0.0.0")]
    public class LocationModifier : DeploymentPlanModifier
    {
        public const string ContributorId = "SqlBuildTools.Contributors.LocationModifier";

        /// <summary>
        /// Contributor argument defining the database name
        /// </summary>
        public const string DatabaseName = "LocationModifier.DatabaseName";

        /// <summary>
        /// Contributor argument defining the directory to save the MDF and LDF files for the database
        /// </summary>
        public const string DataLocation = "LocationModifier.DataLocation";

        /// <summary>
        /// Contributor argument defining the directory to save the MDF and LDF files for the database
        /// </summary>
        public const string LogLocation = "LocationModifier.LogLocation";

        /// <summary>
        /// Iterates over the deployment plan to find the definition for 
        /// </summary>
        /// <param name="context"></param>
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {
            //DEBUG ONLY!
            //
            //System.Diagnostics.Debugger.Launch();

            // Run only if a location is defined and we're targeting a serverless (LocalDB) instance
            if (context.Arguments.TryGetValue(DatabaseName, out string databaseName)
                && context.Arguments.TryGetValue(DataLocation, out string dataLocation)
                && context.Arguments.TryGetValue(LogLocation, out string logLocation))
            {
                if (!string.IsNullOrEmpty(dataLocation))
                {
                    dataLocation = new DirectoryInfo(dataLocation).FullName + "\\";
                }
                if (!string.IsNullOrEmpty(logLocation))
                {
                    logLocation = new DirectoryInfo(logLocation).FullName + "\\";
                }
                try
                {
                    ChangeNewDatabaseLocation(context, databaseName, dataLocation, logLocation);
                }
                catch (Exception ex)
                {
                    throw ex;
                }
            }
        }

        private void ChangeNewDatabaseLocation(DeploymentPlanContributorContext context, string databaseName, string dataLocation, string logLocation)
        {
            DeploymentStep nextStep = context.PlanHandle.Head;

            // Loop through all steps in the deployment plan
            bool foundDefaultDataPath = false;
            bool foundCreateDb = false;
            while (nextStep != null)
            {
                // Increment the step pointer, saving both the current and next steps
                DeploymentStep currentStep = nextStep;

                // Only interrogate up to BeginPreDeploymentScriptStep - setvars must be done before that
                // We know this based on debugging a new deployment and examining the output script
                if (currentStep is BeginPreDeploymentScriptStep)
                {
                    break;
                }

                if (currentStep is DeploymentScriptStep defaultDataPathStep && !foundDefaultDataPath)
                {
                    IList<string> scripts = defaultDataPathStep.GenerateTSQL();
                    foreach (string script in scripts)
                    {
                        if (script.Contains("DefaultDataPath"))
                        {
                            // This is the step that sets the default data path and log path.
                            foundDefaultDataPath = true;

                            //// Override setvars before the deployment begins
                            ///
                            var regex = new Regex(@"^.*\DatabaseName\W.*$", RegexOptions.Multiline);
                            string result = regex.Replace(script, string.Format(":setvar DatabaseName \"{0}\"", databaseName));

                            if (!string.IsNullOrEmpty(dataLocation))
                            {
                                regex = new Regex(@"^.*\DefaultDataPath\W.*$", RegexOptions.Multiline);
                                result = regex.Replace(result, string.Format(":setvar DefaultDataPath \"{0}\"", dataLocation));
                            }

                            if (!string.IsNullOrEmpty(logLocation))
                            {
                                regex = new Regex(@"^.*\DefaultLogPath\W.*$", RegexOptions.Multiline);
                                result = regex.Replace(result, string.Format(":setvar DefaultLogPath \"{0}\"", logLocation));
                            }

                            // Create a new step for the setvar statements, and add it after the existing step.
                            // That ensures that the updated values are used instead of the defaults
                            DeploymentScriptStep newDefaultDataPathStep = new DeploymentScriptStep(result);
                            this.AddAfter(context.PlanHandle, defaultDataPathStep, newDefaultDataPathStep);

                            // Remove the current step
                            this.Remove(context.PlanHandle, defaultDataPathStep);

                            nextStep = newDefaultDataPathStep.Next;
                            break;
                        }

                    }
                }

                if (currentStep is SqlCreateDatabaseStep createDbStep && !foundCreateDb)
                {
                    IList<string> scripts = createDbStep.GenerateTSQL();
                    foreach (string script in scripts)
                    {
                        if (script.Contains("CREATE DATABASE"))
                        {
                            foundCreateDb = true;

                            //create the data files folder
                            var createDataFoldersScript = CreateDataFolders();

                            DeploymentScriptStep createDataFoldersDbStep = new DeploymentScriptStep(createDataFoldersScript);

                            this.AddAfter(context.PlanHandle, createDbStep, createDataFoldersDbStep);

                            //remove the collation
                            var createDbScript = CleanCollation(script);

                            //add data files
                            createDbScript = AddDataFiles(createDbScript);

                            // Create a new step for the create database script, and add it after the existing step.
                            // That ensures that the updated values are used instead of the defaults
                            DeploymentScriptStep newCreateDbStep = new DeploymentScriptStep(createDbScript);

                            // add script blocks to the plan handle
                            this.AddAfter(context.PlanHandle, createDataFoldersDbStep, newCreateDbStep);

                            // Remove the current step
                            this.Remove(context.PlanHandle, createDbStep);

                            nextStep = newCreateDbStep.Next;
                            break;
                        }
                    }
                }

                if (currentStep is DeploymentScriptDomStep domStep)
                {
                    //var removedAlterDb = false;
                    IList<string> scripts = domStep.GenerateTSQL();
                    foreach (string script in scripts)
                    {
                        if (script.Contains("ALTER DATABASE"))
                        {
                            //removedAlterDb = true;
                            nextStep = domStep.Next;

                            // Remove the alter db step
                            this.Remove(context.PlanHandle, domStep);
                            break;
                        }
                    }
                }

                nextStep = currentStep.Next;
            }
        }

        private string CreateDataFolders()
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine();
            sb.AppendLine("PRINT N'Creating Data Folder \"$(DefaultDataPath)$(DatabaseName)\"...'");
            sb.AppendLine();
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine("EXEC master.dbo.xp_cmdshell 'MKDIR \"$(DefaultDataPath)$(DatabaseName)\"'");
            sb.AppendLine();
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine("PRINT N'Creating Log Folder \"$(DefaultLogPath)$(DatabaseName)\"...'");
            sb.AppendLine();
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine("EXEC master.dbo.xp_cmdshell 'MKDIR \"$(DefaultLogPath)$(DatabaseName)\"'");
            sb.AppendLine();
            return sb.ToString();
        }

        private string AddDataFiles(string createDb)
        {
            StringBuilder sb = new StringBuilder(createDb);
            sb.AppendLine();
            sb.AppendLine("ON PRIMARY");
            sb.AppendLine("(   NAME = $(DatabaseName),  ");
            sb.AppendLine("    FILENAME = '$(DefaultDataPath)$(DatabaseName)\\$(DatabaseName).mdf',");
            sb.AppendLine("    SIZE = 64MB,");
            sb.AppendLine("    MAXSIZE = UNLIMITED,");
            sb.AppendLine("    FILEGROWTH = 32MB )");
            sb.AppendLine("LOG ON");
            sb.AppendLine("(   NAME = $(DatabaseName)_log,");
            sb.AppendLine("    FILENAME = '$(DefaultLogPath)$(DatabaseName)\\$(DatabaseName)_log.ldf',");
            sb.AppendLine("    SIZE = 4MB,");
            sb.AppendLine("    MAXSIZE = UNLIMITED,");
            sb.AppendLine("    FILEGROWTH = 1MB )");
            return sb.ToString();
        }

        private string CleanCollation(string createDb)
        {
            var createDBArray = createDb.Split(new char[0]);

            List<string> list = new List<string>(createDBArray);

            var coll = list.FindIndex(item => item == "COLLATE");

            list.RemoveRange(coll, 2);

            return String.Join(" ", list.ToArray());
        }
    }
}

