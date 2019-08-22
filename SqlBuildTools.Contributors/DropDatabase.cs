using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Model;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace SqlBuildTools.Contributors
{
    [ExportDeploymentPlanModifier(ContributorId, "3.0.0.0")]
    public class DropDatabase : DeploymentPlanModifier
    {
        public const string ContributorId = "SqlBuildTools.Contributors.DropDatabase";


        /// <summary>
        /// Iterates over the deployment plan to find the definition for 
        /// </summary>
        /// <param name="context"></param>
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {
            DeploymentStep next = context.PlanHandle.Head;
            bool foundDropDb = false;
            while (next != null)
            {
                DeploymentStep current = next;
                next = current.Next;

                //works!
                if (foundDropDb)
                {
                    base.Remove(context.PlanHandle, current);
                }

                DeploymentScriptStep scriptStep = current as DeploymentScriptStep;
                if (scriptStep != null)
                {
                    IList<string> scripts = scriptStep.GenerateTSQL();
                    foreach (string script in scripts)
                    {
                        if (script.Contains("DROP DATABASE"))
                        {
                            // This is the step that removes the drop database step
                            foundDropDb = true;
                        }
                    }
                }
            }

            // Override setvars before the deployment begins
            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("PRINT N'Update complete.';")
                .AppendLine()
                .AppendFormat("GO")
                .AppendLine();

            // Create a new step for the setvar statements, and add it after the existing step.
            // That ensures that the updated values are used instead of the defaults
            DeploymentScriptStep setVarsStep = new DeploymentScriptStep(sb.ToString());
            this.AddAfter(context.PlanHandle, context.PlanHandle.Tail, setVarsStep);
        }
    }
}   
    