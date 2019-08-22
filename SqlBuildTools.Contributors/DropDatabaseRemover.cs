using Microsoft.SqlServer.Dac.Deployment;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace SqlBuildTools.Contributors
{
    [ExportDeploymentPlanModifier(ContributorId, "2.0.0.0")]
    public class DropDatabaseRemover : DeploymentPlanModifier
    {
        public const string ContributorId = "SqlBuildTools.Contributors.DropDatabaseRemover";

        /// <summary>
        /// Iterates over the deployment plan to find the definition for 
        /// </summary>
        /// <param name="context"></param>
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {
            RemoveDropDatabaseStep(context);
        }

        private void RemoveDropDatabaseStep(DeploymentPlanContributorContext context)
        {
            DeploymentStep nextStep = context.PlanHandle.Head;

            // Loop through all steps in the deployment plan
            bool foundDropDb = false;
            while (nextStep != null && !foundDropDb)
            {
                // Increment the step pointer, saving both the current and next steps
                DeploymentStep currentStep = nextStep;

                // Only interrogate up to BeginPreDeploymentScriptStep - setvars must be done before that
                // We know this based on debugging a new deployment and examining the output script
                if (currentStep is BeginPreDeploymentScriptStep)
                {
                    break;
                }

                DeploymentScriptStep scriptStep = currentStep as DeploymentScriptStep;
                if (scriptStep != null)
                {
                    IList<string> scripts = scriptStep.GenerateTSQL();
                    foreach (string script in scripts)
                    {
                        if (script.Contains("DROP DATABASE"))
                        {
                            // This is the step that removes the drop database step
                            foundDropDb = true;

                            // Remove the current step
                            this.Remove(context.PlanHandle, currentStep);
                        }
                    }
                }

                nextStep = currentStep.Next;
            }
        }
    }
}   
    