using Microsoft.SqlServer.Dac.Deployment;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace SqlBuildTools.Contributors
{
    [ExportDeploymentPlanModifier(ContributorId, "4.0.0.0")]
    public class IgnoreSchemas : DeploymentPlanModifier
    {
        public const string ContributorId = "SqlBuildTools.Contributors.IgnoreSchemas";

        /// <summary>
        /// Contributor argument defining the database name
        /// </summary>
        public const string Schemas = "IgnoreSchemas.Schemas";

        /// <summary>
        /// Iterates over the deployment plan to find the definition for 
        /// </summary>
        /// <param name="context"></param>
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {
            //DEBUG ONLY!
            //
            //System.Diagnostics.Debugger.Launch();
            try
            {
                if (context.Arguments.TryGetValue(Schemas, out string schemas))
                {
                    Ignore(context, schemas);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private void Ignore(DeploymentPlanContributorContext context, string schemas)
        {
            var schemasList = schemas.Split(',').ToList();

            DeploymentStep nextStep = context.PlanHandle.Head;

            var stepRemoved = false;

            while (nextStep != null)
            {
                stepRemoved = false;
                DeploymentStep currentStep = nextStep;

                if (currentStep is CreateElementStep scriptStep)
                {
                    IList<string> scripts = currentStep.GenerateTSQL();

                    var parts = scriptStep.SourceElement.Name.Parts;

                    if (parts.Count() > 0)
                    {
                        foreach (string script in scripts)
                        {
                            foreach (var schema in schemasList)
                            {
                                if (string.Equals(parts[0], schema, StringComparison.OrdinalIgnoreCase))
                                {
                                    nextStep = scriptStep.Next;
                                    // This is the step that removes the drop database step
                                    base.Remove(context.PlanHandle, scriptStep);
                                    stepRemoved = true;
                                    break;
                                }
                            }
                            if (stepRemoved)
                            {
                                break;
                            }
                        }
                    }
                    if (stepRemoved)
                    {
                        continue;
                    }
                }

                nextStep = currentStep.Next;
            }
        }
    }
}