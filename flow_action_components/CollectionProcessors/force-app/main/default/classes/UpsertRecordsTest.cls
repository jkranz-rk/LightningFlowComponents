@isTest
public with sharing class UpsertRecordsTest {
    
    @isTest
    public static void canUpsertNewRecords() {
        Account[] newAccounts = new Account[]{
            new Account(Name = 'test account 1'),
            new Account(Name = 'test account 2'),
            new Account(Name = 'test account 3'),
            new Account(Name = 'test account 4')
        };
        
        UpsertRecords.Request request = new UpsertRecords.Request();
        request.inputCollection = newAccounts;

        List<UpsertRecords.Request> requests = new  List<UpsertRecords.Request>();
        requests.add(request);

        Test.startTest();
            UpsertRecords.execute(requests);
        Test.stopTest();

        List<Account> retrievedAccounts = [SELECT Id FROM Account WHERE Name != 'foo'];

        Assert.areEqual(4, retrievedAccounts.size(),
            'Expected 4 accounts to be retrieved, but got ' + retrievedAccounts.size()
        );

    }

    @isTest
    public static void canUpsertExistingRecords() {
        Account[] newAccounts = new Account[]{
            new Account(Name = 'test account 1'),
            new Account(Name = 'test account 2'),
            new Account(Name = 'test account 3'),
            new Account(Name = 'test account 4')
        };
        insert newAccounts;

        newAccounts[0].Name = 'foo';

        UpsertRecords.Request request = new UpsertRecords.Request();
        request.inputCollection = newAccounts;

        UpsertRecords.Request[] requests = new UpsertRecords.Request[]{request};

        Test.startTest();
            UpsertRecords.execute(requests);
        Test.stopTest();
        
        List<Account> actualAccounts = [SELECT Id FROM Account WHERE Name != 'baz'];

        Assert.areEqual(4, actualAccounts.size(),
            'Expected 4 accounts to be retrieved, but got ' + actualAccounts.size()
        );
        
        actualAccounts = [SELECT Id FROM Account WHERE Name = 'foo'];

        Assert.areEqual(1, actualAccounts.size(),
            'Expcted 1 account with name foo, but got ' + actualAccounts.size()
        );

    }

    @isTest 
    public static void canUpsertWithExternalId() {
        Account[] newAccounts = new Account[]{
            new Account(Name = 'test account 1',CustomExternalId__c = 'foo')
        };
        insert newAccounts;

        Account[] accountsToUpsert = new Account[]{
            new Account(
                Name = 'test account 1',
                CustomExternalId__c = 'foo',
                Description = 'bar'
            )
        };

        UpsertRecords.Request request = new UpsertRecords.Request();
        request.inputCollection = accountsToUpsert;
        request.externalIdFieldName = 'Account.CustomExternalId__c';
        
        UpsertRecords.Request[] requests = new UpsertRecords.Request[]{request};

        Test.startTest();
            UpsertRecords.execute(requests);
        Test.stopTest();

        List<Account> actualAccounts = [SELECT Id, Name, Description FROM Account WHERE Name = 'test account 1'];

        Assert.areEqual(1, actualAccounts.size(),
            'Expected 1 account with name test account 1, but got ' + actualAccounts.size()
        );

        Assert.areEqual('bar', actualAccounts[0].Description,
            'Expected Account.Description to be bar, but it was ' + actualAccounts[0].Description
        );

    }

    @isTest
    public static void canUpsertNewSerializedRecords() {
        UpsertRecords.Request request = new UpsertRecords.Request();
        request.objectName = 'Case';
        request.serializedRecordData = '[{"attributes":{"type":"Case"},"CaseNumber":"00001026","Status":"Working"}]';
        
        UpsertRecords.Request[] requests = new UpsertRecords.Request[]{request};
        
        Test.startTest();
            UpsertRecords.execute(requests);
        Test.stopTest();

        Case[] actualCases = [SELECT Id, CaseNumber, Status FROM Case];
        Assert.areEqual(1, actualCases.size(),
            'Expected 1 case, but got ' + actualCases.size()
        );
    }

    @isTest
    public static void canUpsertExistingSerializedRecords() {
        Case[] newCases = new Case[]{
            new Case(Status = 'Working')
        };
        insert newCases;

        UpsertRecords.Request request = new UpsertRecords.Request();
        request.objectName = 'Case';
        request.serializedRecordData = JSON.serialize(newCases);

        UpsertRecords.Request[] requests = new UpsertRecords.Request[]{request};

        Test.startTest();
            UpsertRecords.execute(requests);
        Test.stopTest();

        Case[] actualCases = [SELECT Id, CaseNumber, Status FROM Case];
        Assert.areEqual(1, actualCases.size(),
            'Expected 1 case, but got ' + actualCases.size()
        );
    }
}