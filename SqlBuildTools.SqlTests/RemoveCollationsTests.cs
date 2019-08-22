using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace SqlBuildTools.SqlTests
{
    [TestClass]
    public class CreateDBText
    {
        [TestMethod]
        public void GivenCreateDBTextWhenCollationIsSetThenCollationShouldBeRemoved()
        {
            var createDBText = "CREATE DATABASE [$(DatabaseName)] COLLATE SQL_Latin1_General_CP1_CI_AS";

            var createDBArray = createDBText.Split(new char[0]);

            List<string> list = new List<string>(createDBArray);

            var coll = list.FindIndex(item => item == "COLLATE");

            list.RemoveRange(coll, 2);

            createDBText = String.Join(" ", list.ToArray());

            Assert.AreEqual(createDBText, "CREATE DATABASE [$(DatabaseName)]");
        }

        public void GivenCreateDBTextWhenCollationIsSetAndContainsOtherSettingsThenCollationShouldBeRemoved()
        {
            var createDBText = "CREATE DATABASE [$(DatabaseName)] COLLATE SQL_Latin1_General_CP1_CI_AS ";

            var createDBArray = createDBText.Split(new char[0]);

            List<string> list = new List<string>(createDBArray);

            var coll = list.FindIndex(item => item == "COLLATE");

            list.RemoveRange(coll, 2);

            createDBText = String.Join(" ", list.ToArray());

            Assert.AreEqual(createDBText, "CREATE DATABASE [$(DatabaseName)]");
        }
    }
}
