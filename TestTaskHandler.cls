
@isTest
public with sharing class TestTaskHandler {


    /*
insertNewContacts
 */
    static testMethod void testOneNewContactOneFieldOneAccount() {


        TestDataFactory.createAccounts(1,false);

        // Account created by Data Factory
        Account acc = [SELECT Id FROM Account];

        // Insert Task before activating triggers
        Task tas1 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc.Id);
        insert tas1;

        // Activate triggers
        RecursiveParse.activated = true;
        RecursiveTask.activated = true;
        RecursiveContact.activated = true;

        // Insert a new CR name and update
        Task tas2 = [SELECT Id FROM Task];
        tas2.Corporate_Role_1__c = 'Beatrix Trigg';
        update tas2;

        // Test if Contact was created from new CR name
        List<Contact> con = [SELECT Id FROM Contact WHERE FirstName = 'Beatrix' AND LastName = 'Trigg'];
        System.assertEquals(con.size(), 1);
    }

    static testMethod void testManyNewContactsOneFieldOneAccount() {

        // Accounts created by DataFactory
        TestDataFactory.createAccounts(1,false);

        // Insert Task before activating triggers
        Account acc = [SELECT Id FROM Account];
        Task tas1 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc.Id);
        insert tas1;

        // Activate triggers
        RecursiveParse.activated = true;
        RecursiveTask.activated = true;
        RecursiveContact.activated = true;

        // Add new CP names to Task and update
        Task tas2 = [SELECT Id FROM Task];
        tas2.Corporate_Role_1__c = 'Beatrix Trigg1';
        tas2.Corporate_Role_2__c = 'Beatrix Trigg2';
        tas2.Corporate_Role_3__c = 'Beatrix Trigg3';
        tas2.Corporate_Role_4__c = 'Beatrix Trigg4';
        tas2.Corporate_Role_5__c = 'Beatrix Trigg5';
        update tas2;

        // SELECT specific Contacts
        List<Contact> conts = [SELECT Id, LastName FROM Contact WHERE FirstName = 'Beatrix'];

        // Create string of Last Names to test
        String str = '';
        for (Contact con : conts) {
            str += con.LastName;
        }
        System.assertEquals(str, 'Trigg1Trigg2Trigg3Trigg4Trigg5');
        Contact con = [SELECT Id, Corporate_Role_2__c, Corporate_Role_3__c FROM Contact WHERE Name = 'Beatrix Trigg3'];

        // Check checkboxes are functioning
        System.assertEquals(con.Corporate_Role_3__c, true);
        System.assertEquals(con.Corporate_Role_2__c, false);
    }

    static testMethod void testOneExistingContactOneFieldOneAccount() {

        TestDataFactory.createAccounts(1,false);

        // Select existing Account that was generated in DataFactory
        Account acc = [SELECT Id FROM Account];

        // Insert a contact associated with the existing account
        Contact con1 = new Contact(
                FirstName = 'Beatrix',
                LastName = 'Trigg',
                AccountId = acc.Id);
        insert con1;

        // Insert a task associated with the existing account
        Task tas1 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc.Id);
        insert tas1;

        // Activate triggers
        RecursiveParse.activated = true;
        RecursiveTask.activated = true;
        RecursiveContact.activated = true;

        // Create a new CR name in Task
        Task tas2 = [SELECT Id FROM Task];
        tas2.Corporate_Role_1__c = 'Beatrix Trigg';
        update tas2;

        // Select Contact that was created with trigger, assert that another contact wasn't created.
        List<Contact> con = [
                SELECT Id FROM Contact
                WHERE FirstName = 'Beatrix'
                AND LastName = 'Trigg'
                AND AccountId = :acc.Id];
        System.assertEquals(con.size(), 1);
    }

    /*
updateCheckboxes
 */

    static testMethod void testOneExistingContactUpdateCRFields() {

        TestDataFactory.createAccounts(1, false);

        // Select existing Account that was generated in DataFactory
        Account acc = [SELECT Id FROM Account];

        // Insert a contact associated with the existing account
        Contact con1 = new Contact(
                FirstName = 'Beatrix',
                LastName = 'Trigg',
                AccountId = acc.Id);
        insert con1;

        // Insert a task associated with the existing account
        Task tas1 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc.Id);
        insert tas1;

        // Activate triggers
        RecursiveParse.activated = true;
        RecursiveTask.activated = true;
        RecursiveContact.activated = true;

        // Create a new CR name in Task
        Task tas2 = [SELECT Id FROM Task];
        tas2.Corporate_Role_1__c = 'Beatrix Trigg';
        update tas2;

        // Select Contact that was created with trigger, assert that another contact wasn't created.
        Contact con = [
                SELECT
                        Corporate_Role_1__c,
                        Corporate_Role_2__c,
                        Corporate_Role_3__c,
                        Corporate_Role_4__c,
                        Corporate_Role_5__c
                FROM Contact
                WHERE Name = 'Beatrix Trigg'];

        System.assertEquals(con.Corporate_Role_1__c, true);
        System.assertEquals(con.Corporate_Role_2__c, false);
        System.assertEquals(con.Corporate_Role_3__c, false);
        System.assertEquals(con.Corporate_Role_4__c, false);
        System.assertEquals(con.Corporate_Role_5__c, false);
    }


    static testMethod void testManyExistingContactUpdateCRFieldsToNull() {

        TestDataFactory.createAccounts(1, false);

        // Select existing Account that was generated in DataFactory
        Account acc = [SELECT Id FROM Account];

        // Insert a contact associated with the existing account
        List<Contact> contToUpdate = new List<Contact>();

        Contact con1 = new Contact(
                FirstName = 'Beatrix',
                LastName = 'Trigg1',
                Corporate_Role_1__c = true,
                AccountId = acc.Id);
        contToUpdate.add(con1);

        Contact con2 = new Contact(
                FirstName = 'Beatrix',
                LastName = 'Trigg2',
                Corporate_Role_2__c = true,
                AccountId = acc.Id);
        contToUpdate.add(con2);

        Contact con3 = new Contact(
                FirstName = 'Beatrix',
                LastName = 'Trigg3',
                Corporate_Role_3__c = true,
                AccountId = acc.Id);
        contToUpdate.add(con3);

        Contact con4 = new Contact(
                FirstName = 'Beatrix',
                LastName = 'Trigg4',
                Corporate_Role_4__c = true,
                AccountId = acc.Id);
        contToUpdate.add(con4);

        Contact con5 = new Contact(
                FirstName = 'Beatrix',
                LastName = 'Trigg5',
                Corporate_Role_5__c = true,
                AccountId = acc.Id);
        contToUpdate.add(con5);

        insert contToUpdate;

        // Insert a task associated with the existing account
        Task tas1 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                Corporate_Role_1__c = 'Beatrix Trigg1',
                Corporate_Role_2__c = 'Beatrix Trigg2',
                Corporate_Role_3__c = 'Beatrix Trigg3',
                Corporate_Role_4__c = 'Beatrix Trigg4',
                Corporate_Role_5__c = 'Beatrix Trigg5',
                WhatId = acc.Id);
        insert tas1;

        // Activate triggers
        RecursiveParse.activated = true;
        RecursiveTask.activated = true;
        RecursiveContact.activated = true;

        // Create a new CR name in Task
        Task tas2 = [SELECT Id FROM Task];
        tas2.Corporate_Role_1__c = 'Beatrix Trigg10';
        tas2.Corporate_Role_3__c = null;
        tas2.Corporate_Role_5__c = 'Beatrix Trigg5';
        update tas2;

        // Select Contact that was created with trigger, assert that another contact wasn't created.
        Contact cont1 = [SELECT Corporate_Role_1__c FROM Contact WHERE Name = 'Beatrix Trigg1'];
        System.assertEquals(cont1.Corporate_Role_1__c, false);
        Contact cont2 = [SELECT Corporate_Role_1__c FROM Contact WHERE Name = 'Beatrix Trigg10'];
        System.assertEquals(cont2.Corporate_Role_1__c, true);

        Contact cont3 = [SELECT Corporate_Role_2__c FROM Contact WHERE Name = 'Beatrix Trigg2'];
        System.assertEquals(cont3.Corporate_Role_2__c, true);

        Contact cont4 = [SELECT Corporate_Role_3__c FROM Contact WHERE Name = 'Beatrix Trigg3'];
        System.assertEquals(cont4.Corporate_Role_3__c, false);

        Contact cont5 = [SELECT Corporate_Role_4__c FROM Contact WHERE Name = 'Beatrix Trigg4'];
        System.assertEquals(cont5.Corporate_Role_4__c, true);

        Contact cont6 = [SELECT Corporate_Role_5__c FROM Contact WHERE Name = 'Beatrix Trigg5'];
        System.assertEquals(cont6.Corporate_Role_5__c, true);

    }

    static testMethod void testTwoAccounts() {

        TestDataFactory.createAccounts(2, false);

        // Select existing Account that was generated in DataFactory
        Account acc0 = [SELECT Id FROM Account WHERE Name = 'TestAccount0'];
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'TestAccount1'];

        // Insert a tasks associated with each existing account
        Task tas0 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc0.Id);
        insert tas0;
        Task tas1 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc1.Id);
        insert tas1;

        // Insert same contact name for each existing account
        Contact con0 = new Contact(
                FirstName = 'Beatrix',
                LastName = 'Trigg',
                AccountId = acc0.Id);
        insert con0;
        Contact con1 = new Contact(
                FirstName = 'Beatrix',
                LastName = 'Trigg',
                AccountId = acc1.Id);
        insert con1;

        // Activate triggers
        RecursiveParse.activated = true;
        RecursiveTask.activated = true;
        RecursiveContact.activated = true;

        // Create a new CR name in Task associated with Account TestAccount0
        Task tasNew = [SELECT Id FROM Task WHERE WhatId = :acc0.Id];
        tasNew.Corporate_Role_1__c = 'Beatrix Trigg';
        update tasNew;

        // Select Contact associated with Account TestAccount0, assert that appropriate checkbox is true
        Contact conCheck0 = [SELECT Corporate_Role_1__c, Corporate_Role_2__c FROM Contact WHERE AccountId = :acc0.Id];
        System.assertEquals(conCheck0.Corporate_Role_1__c, true);
        System.assertEquals(conCheck0.Corporate_Role_2__c, false);

        // Select Contact associated with Other Account, assert checkbox is false
        Contact conCheck1 = [SELECT Corporate_Role_1__c FROM Contact WHERE AccountId = :acc1.Id];
        System.assertEquals(conCheck1.Corporate_Role_1__c, false);

    }

    static testMethod void testInsertTaskOneAccount() {


        TestDataFactory.createAccounts(1,false);

        // Account created by Data Factory
        Account acc = [SELECT Id FROM Account];

        // Insert Task before activating triggers

        // Activate triggers
        RecursiveParse.activated = true;
        RecursiveTask.activated = true;
        RecursiveContact.activated = true;

        // Insert a new CR name and update
        Task tas1 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc.Id,
                Corporate_Role_1__c = 'Beatrix Trigg');
        insert tas1;

        // Test if Contact was created from new CR name
        List<Contact> con = [SELECT Id FROM Contact WHERE FirstName = 'Beatrix' AND LastName = 'Trigg'];
        System.assertEquals(con.size(), 1);
    }

    static testMethod void testInsertOneTaskUpdateOneTaskWithOneAccount() {


        TestDataFactory.createAccounts(1,false);

        // Account created by Data Factory
        Account acc = [SELECT Id FROM Account];

        // Insert Task before activating triggers
        Task tas0 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc.Id);
        insert tas0;

        // Activate triggers
        RecursiveParse.activated = true;
        RecursiveTask.activated = true;
        RecursiveContact.activated = true;

        // Insert a new CR name and update
        List<Task> tasksToUpsert = new List<Task>();

        Task tas1 = [SELECT Id FROM Task];
        tas1.Corporate_Role_1__c = 'Beatrix Trigg1';

        Task tas2 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc.Id,
                Corporate_Role_2__c = 'Beatrix Trigg2');
        tasksToUpsert.add(tas2);
        tasksToUpsert.add(tas1);
        System.debug('tasksToUpsert88: ' + tasksToUpsert);
        upsert tasksToUpsert;

        // Test if Contact was created from new CR name
        List<Contact> con1 = [SELECT Corporate_Role_1__c FROM Contact WHERE Name = 'Beatrix Trigg1'];
        System.assertEquals(con1[0].Corporate_Role_1__c, true);
        List<Contact> con2 = [SELECT Corporate_Role_2__c FROM Contact WHERE Name = 'Beatrix Trigg2'];
        System.assertEquals(con2[0].Corporate_Role_2__c, true);
    }

    static testMethod void testManyNewSameContactUpdate() {

        TestDataFactory.createAccounts(1, false);

        // Select existing Account that was generated in DataFactory
        Account acc = [SELECT Id FROM Account];

        // Insert a task associated with the existing account
        Task tas1 = new Task(
                Subject = 'Other',
                Priority = 'Normal',
                WhatId = acc.Id);
        insert tas1;

        // Activate triggers
        RecursiveParse.activated = true;
        RecursiveTask.activated = true;
        RecursiveContact.activated = true;

        // Create a new CR name in Task
        Task tas2 = [SELECT Id FROM Task];
        tas2.Corporate_Role_1__c = 'Beatrix Trigg';
        tas2.Corporate_Role_2__c = 'Beatrix Trigg';
        tas2.Corporate_Role_3__c = 'Beatrix Trigg';
        tas2.Corporate_Role_4__c = 'Beatrix Trigg';
        tas2.Corporate_Role_5__c = 'Beatrix Trigg';
        update tas2;

        // Select Contact that was created with trigger, assert that another contact wasn't created.
        List<Contact> cont1 = [SELECT Name FROM Contact WHERE Name = 'Beatrix Trigg'];
        System.assertEquals(cont1.size(), 1);
    }
}