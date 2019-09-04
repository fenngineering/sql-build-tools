using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Text;
using Microsoft.Data.Tools.Schema.Sql.UnitTesting;
using Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace SampleDB.SqlTests
{
    [TestClass()]
    public class dbo_ATable_Testing : SqlDatabaseTestClass
    {

        public dbo_ATable_Testing()
        {
            InitializeComponent();
        }

        [TestInitialize()]
        public void TestInitialize()
        {
            base.InitializeTest();
        }
        [TestCleanup()]
        public void TestCleanup()
        {
            base.CleanupTest();
        }

        [TestMethod()]
        public void dbo_ATable_UnitTests()
        {
            SqlDatabaseTestActions testActions = this.dbo_ATable_UnitTestsData;
            // Execute the pre-test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.PretestAction != null), "Executing pre-test script...");
            SqlExecutionResult[] pretestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PretestAction);
            // Execute the test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.TestAction != null), "Executing test script...");
            SqlExecutionResult[] testResults = TestService.Execute(this.ExecutionContext, this.PrivilegedContext, testActions.TestAction);
            // Execute the post-test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.PosttestAction != null), "Executing post-test script...");
            SqlExecutionResult[] posttestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PosttestAction);
        }

        #region Designer support code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.SqlDatabaseTestAction dbo_ATable_UnitTests_TestAction;
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(dbo_ATable_Testing));
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ScalarValueCondition dbo_ATable_UnitTests_TableExists;
            this.dbo_ATable_UnitTestsData = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.SqlDatabaseTestActions();
            dbo_ATable_UnitTests_TestAction = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.SqlDatabaseTestAction();
            dbo_ATable_UnitTests_TableExists = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.ScalarValueCondition();
            // 
            // dbo_ATable_UnitTests_TestAction
            // 
            dbo_ATable_UnitTests_TestAction.Conditions.Add(dbo_ATable_UnitTests_TableExists);
            resources.ApplyResources(dbo_ATable_UnitTests_TestAction, "dbo_ATable_UnitTests_TestAction");
            // 
            // dbo_ATable_UnitTestsData
            // 
            this.dbo_ATable_UnitTestsData.PosttestAction = null;
            this.dbo_ATable_UnitTestsData.PretestAction = null;
            this.dbo_ATable_UnitTestsData.TestAction = dbo_ATable_UnitTests_TestAction;
            // 
            // dbo_ATable_UnitTests_TableExists
            // 
            dbo_ATable_UnitTests_TableExists.ColumnNumber = 1;
            dbo_ATable_UnitTests_TableExists.Enabled = true;
            dbo_ATable_UnitTests_TableExists.ExpectedValue = "True";
            dbo_ATable_UnitTests_TableExists.Name = "dbo_ATable_UnitTests_TableExists";
            dbo_ATable_UnitTests_TableExists.NullExpected = false;
            dbo_ATable_UnitTests_TableExists.ResultSet = 1;
            dbo_ATable_UnitTests_TableExists.RowNumber = 1;
        }

        #endregion


        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //
        // Use ClassInitialize to run code before running the first test in the class
        // [ClassInitialize()]
        // public static void MyClassInitialize(TestContext testContext) { }
        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }
        //
        #endregion

        private SqlDatabaseTestActions dbo_ATable_UnitTestsData;
    }
}
