using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Opdracht1TestAccountName;

namespace Opdracht1UnitTest
{
    [TestClass]
    public class UnitTest1
    {
        Person person = new Person();

        //tests if the person receives 2 names and places them in person.
        [TestMethod]
        public void TestPersonGet2Names()
        {
            string input = "Wim Beck";
            string[] names = input.Split(' ');
            person.firstName = names[0];
            person.lastName = names[1];
            Assert.AreEqual("Wim", person.firstName);
            Assert.AreEqual("Beck", person.lastName);
        }

        //Tests if generateAccount returns a 6 chars long.
        [TestMethod]
        public void TestPersonGenerateAccountIs6CharsLong()
        {
            person.firstName = "Wim";
            person.lastName = "Beck";
            string actualOutput = person.generateAccount();
            int actualLength = actualOutput.Length;
            Assert.AreEqual(6, actualLength);
        }

        //Tests if the generateAccount returns beckwb when Wim Beck is entered.
        [TestMethod]
        public void TestPersonGenerateAccountIsCorrectOutput()
        {
            person.firstName = "Wim";
            person.lastName = "Beck";
            string actualOutput = person.generateAccount();
            string expectedOutput = "beckwb";
            Assert.AreEqual(expectedOutput, actualOutput);
        }

        //Tests if the generateAccount function returns the correct account (3 letters from lastName
        //with initials).
        [TestMethod]
        public void TestOtherNamesGenerateAccountGiveCorrectOutput()
        {
            person.firstName = "Wouter";
            person.lastName = "Landuyt";
            string actualOutput = person.generateAccount();
            Assert.AreEqual("landuw", actualOutput);
        }

        //Tests where there is a space in the name.
        [TestMethod]
        public void TestNamesWithSpacesGetCorrectOutputFromGenerateAccount()
        {
            person.firstName = "Joren";
            person.lastName = "Van Camp";
            string actualOutput = person.generateAccount();
            Assert.AreEqual("campjc", actualOutput);
        }
    }
}
