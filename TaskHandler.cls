
public with sharing class TaskHandler {

    List<Contact> contsToUpsert = new List<Contact>();

    public void upsertContacts(List<Task> triggerNew, List<Task> triggerOld) {

        System.debug('triggerNewMap: ' + triggerNew);
        System.debug('triggerOld88: ' + triggerOld);

        List<Contact> contsToInsertClass = TaskHandler.insertContacts(triggerNew);
        contsToUpsert.addAll(contsToInsertClass);
        System.debug('contstoUpsert21: ' + contsToUpsert);

        List<Contact> contsToUpdateClass = TaskHandler.updateCheckboxes(triggerNew, triggerOld);
        contsToUpsert.addAll(contsToUpdateClass);

        System.debug('contsToUpsert77: ' + contsToUpsert);

        if (Schema.SObjectType.Contact.isUpdateable() &&
                Schema.SObjectType.Contact.isCreateable()) {
            upsert contsToUpsert;
        }
    }

    public static List<Contact> insertContacts(List<Task> triggerNew) {

        // List of Contacts to populate and return
        List<Contact> contsToInsert = new List<Contact>();

        List<String> fieldList = FieldInfo.fieldList();

        // List of Account IDs included in triggerNew
        List<Id> taskAccountIds = new List<Id>();
        for (Task tas : triggerNew) {
            taskAccountIds.add(tas.WhatId);
        }

        // Create a map of contacts that may exist associated to the Account Ids in triggerNew
        List<Contact> allContsList = [SELECT AccountId, Name FROM Contact WHERE AccountId IN :taskAccountIds];
        Map<Id, List<String>> conMap = new Map<Id, List<String>>();

        for (Contact con : allContsList) {
            if (conMap.containsKey(con.AccountId)) {
                conMap.get(con.AccountId).add(con.Name);
            } else {
                conMap.put(con.AccountId, new List<String>{con.Name});
            }
        }
        System.debug('conMap777:' + conMap);

        // Collecting names entered in Corporate Role fields, using AccountId + Name as an String Id to
        // check for duplicates.
        Map<String, Contact> contStringMap = new Map<String, Contact>();
        List<Contact> checkConts = new List<Contact>();

        for (Task tas : triggerNew) {
            for (String field : fieldList) {
                try {
                    Contact newContact = new Contact();
                    String firstName = tas.get(field).toString().split(' ')[0];
                    String lastName = tas.get(field).toString().split(' ')[1];
                    newContact.InsertId__c = tas.WhatId + firstName + lastName;
                    if (!contStringMap.containsKey(newContact.InsertId__c)) {
                        newContact.FirstName = tas.get(field).toString().split(' ')[0];
                        newContact.LastName = tas.get(field).toString().split(' ')[1];
                        newContact.AccountId = tas.WhatId;
                        newContact.put(field, true);
                        contStringMap.put(newContact.InsertId__c, newContact);
                    } else {
                        newContact.FirstName = contStringMap.get(newContact.InsertId__c).FirstName;
                        newContact.LastName = contStringMap.get(newContact.InsertId__c).LastName;
                        newContact.AccountId = contStringMap.get(newContact.InsertId__c).AccountId;
                        newContact.put(field, true);
                    }
                    checkConts.add(newContact);
                } catch (NullPointerException e) {
                    System.debug('Exception encountered: ' + e);
                }
            }
        }

        System.debug('contsStringMap: ' + contStringMap);
        System.debug('checkConts77: ' + checkConts);

        // Determine if contacts in checkConts already exist
        List<Contact> checkExists = new List<Contact>();
        for (Contact con : checkConts) {
            System.debug('con77: ' + con);
            if (!conMap.containsKey(con.AccountId)) {
                checkExists.add(con);
                System.debug('contstoInsertblah: ' + contsToInsert);
            } else if (conMap.containsKey(con.AccountId) &&
                    !conMap.get(con.AccountId).contains(con.FirstName + ' ' + con.LastName)) {
                checkExists.add(con);
            }
        }
        System.debug('conMap669: ' + conMap);
        System.debug('contsToInsert669:' + contsToInsert);
        System.debug('checkexists: ' + checkExists);

        // Group CR fields with same Insert_Id__c (Contact)
        Map<String, Map<String, Boolean>> checkDups = new Map<String, Map<String, Boolean>>();
        for (Contact con : checkExists) {
            for (String field : fieldList) {
                try{
                    if (checkDups.containsKey(con.InsertId__c)) {
                        checkDups.get(con.InsertId__c).put(field, Boolean.valueOf(con.get(field)));
                    } else {
                        checkDups.put(con.InsertId__c, new Map<String, Boolean>{field => Boolean.valueOf(con.get(field))});
                    }
                } catch (NullPointerException e) {
                    System.debug('Exception encountered: ' + e);
                }
            }
        }

        // Create a map associating Insert_Id__c with the Contact SObject
        Map<String, Contact> contInsertIdMap = new Map<String, Contact>();
        for (Contact con : checkExists) {
            contInsertIdMap.put(con.AccountId + con.FirstName + con.LastName, con);
        }
        System.debug('contInsertIdMap: ' + contInsertIdMap);

        // Process grouped fields into list of Contact for insert
        System.debug('Checkdups1000: ' + checkDups);
        for (String insertId : checkDups.keySet()) {
            Contact newCont = new Contact();
            newCont.AccountId = contInsertIdMap.get(insertId).AccountId;
            newCont.FirstName = contInsertIdMap.get(insertId).FirstName;
            newCont.LastName = contInsertIdMap.get(insertId).LastName;
            for (String field : fieldList) {
                if (checkDups.get(insertId).get(field) != null) {
                    newCont.put(field, checkDups.get(insertId).get(field));
                } else {
                    newCont.put(field, false);
                }
            }
            System.debug('newCont1000: ' + newCont);
            contsToInsert.add(newCont);
        }

        System.debug('checkDups: ' + checkDups);
        System.debug('contsToInsert1000: ' + contsToInsert);
        return contsToInsert;
    }

    public static List<Contact> updateCheckboxes(List<Task> triggerNew, List<Task> triggerOld) {

        System.debug('triggerNew88: ' + triggerNew);

        // List of contacts to populate for update
        List<Contact> contsToUpdate = new List<Contact>();

        // List of CR fields
        List<String> fieldList = FieldInfo.fieldList();

        // Map to populate with contacts that require updating
        Map<Id, List<String>> contChangeMap = new Map<Id, List<String>>();

        // Create a map of old state for each Task record

        Map<Id, Map<Id, Task>> tasOldMap = new Map<Id, Map<Id, Task>>();
        try {
            for (Task tas : triggerOld) {
                if (tasOldMap.containsKey(tas.WhatId)) {
                    tasOldMap.get(tas.WhatId).put(tas.Id, tas);
                } else {
                    tasOldMap.put(tas.WhatId, new Map<Id, Task>{tas.Id => tas});
                }
            }
        } catch (NullPointerException e) {
            System.debug('Exception encountered: ' + e);
            tasOldMap = null;
        }
        System.debug('tasOldMap77: ' + tasOldMap);

        // Create a map of new state for each Task record
        Map<Id, Map<Id, Task>> tasNewMap = new Map<Id, Map<Id, Task>>();
        for (Task tas : triggerNew) {
            if (tasNewMap.containsKey(tas.WhatId)) {
                tasNewMap.get(tas.WhatId).put(tas.Id, tas);
            } else {
                tasNewMap.put(tas.WhatId, new Map<Id, Task>{tas.Id => tas});
            }
        }
        System.debug('tasNewMap77: ' + tasNewMap);

        // If CR field changes, add update to contsMap List
        Map<String, Map<String, Object>> contsMap = new Map<String, Map<String, Object>>();
        for (Id mapId : tasNewMap.keySet()) {
            for (Id tasId : tasNewMap.get(mapId).keySet()) {
                for (String field : fieldList) {
                    Contact updateContactNew = new Contact();
                    updateContactNew.AccountId = mapId;
                    Contact updateContactOld = new Contact();
                    updateContactOld.AccountId = mapId;
                    try {
                        if (tasOldMap.get(mapId).get(tasId).get(field) != tasNewMap.get(mapId).get(tasId).get(field)) {
                            // If tasNewMap field isn't null, use name from field
                            if (tasNewMap.get(mapId).get(tasId).get(field) != null) {
                                updateContactNew.FirstName =
                                        tasNewMap.get(mapId).get(tasId).get(field).toString().split(' ')[0];
                                updateContactNew.LastName =
                                        tasNewMap.get(mapId).get(tasId).get(field).toString().split(' ')[1];
                                updateContactNew.put(field, true);
                                String uniqueId = mapId + updateContactNew.FirstName + updateContactNew.LastName;
                                System.debug('updateContactnew77: ' + updateContactNew);
                                if (contsMap.containsKey(uniqueId)) {
                                    contsMap.get(uniqueId).put(field, updateContactNew.get(field));
                                } else {
                                    contsMap.put(uniqueId, new Map<String, Object>{field => updateContactNew.get(field)});
                                }
                                System.debug('contsMapnew78: ' + contsMap);
                                System.debug('tassynew77: ' + (tasNewMap.get(mapId).get(tasId).get(field)));

                                try {
                                    updateContactOld.FirstName = null;
                                    updateContactOld.LastName = null;
                                    updateContactOld.put(field, false);
                                    String uniqueId2 = mapId +
                                            tasOldMap.get(mapId).get(tasId).get(field).toString().split(' ')[0] +
                                            tasOldMap.get(mapId).get(tasId).get(field).toString().split(' ')[1];
                                    System.debug('updateContactold77: ' + updateContactOld);
                                    if (contsMap.containsKey(uniqueId2)) {
                                        contsMap.get(uniqueId2).put(field, updateContactOld.get(field));
                                    } else {
                                        contsMap.put(uniqueId2, new Map<String, Object>{field => updateContactOld.get(field)});
                                    }
                                    System.debug('contsMapold78: ' + contsMap);
                                    System.debug('tassyold77: ' + (tasNewMap.get(mapId).get(tasId).get(field)));
                                } catch (NullPointerException e) {
                                    System.debug('Exception encountered: ' + e);
                                }

                            // Else, if tasOldMap field isn't null, use name from field
                            } else if (tasOldMap.get(mapId).get(tasId).get(field) != null) {
                                updateContactNew.FirstName =
                                        tasOldMap.get(mapId).get(tasId).get(field).toString().split(' ')[0];
                                updateContactNew.LastName =
                                        tasOldMap.get(mapId).get(tasId).get(field).toString().split(' ')[1];
                                updateContactNew.put(field, false);
                                String uniqueId = mapId + updateContactNew.FirstName + updateContactNew.LastName;
                                if (contsMap.containsKey(uniqueId)) {
                                    contsMap.get(uniqueId).put(field, updateContactNew.get(field));
                                } else {
                                    contsMap.put(uniqueId, new Map<String, Object>{field => updateContactNew.get(field)});
                                }
                            }
                        }
                    } catch (NullPointerException e) {
                        System.debug('Exception encountered: ' + e);
                        if (tasNewMap.get(mapId).get(tasId).get(field) != null) {
                            updateContactNew.FirstName =
                                    tasNewMap.get(mapId).get(tasId).get(field).toString().split(' ')[0];
                            updateContactNew.LastName =
                                    tasNewMap.get(mapId).get(tasId).get(field).toString().split(' ')[1];
                            updateContactNew.put(field, true);
                            String uniqueId = mapId + updateContactNew.FirstName + updateContactNew.LastName;
                            System.debug('updateContactnew77catch: ' + updateContactNew);
                            if (contsMap.containsKey(uniqueId)) {
                                contsMap.get(uniqueId).put(field, updateContactNew.get(field));
                            } else {
                                contsMap.put(uniqueId, new Map<String, Object>{field => updateContactNew.get(field)});
                            }
                            System.debug('contsMapnew78catch: ' + contsMap);
                            System.debug('tassynew77catch: ' + (tasNewMap.get(mapId).get(tasId).get(field)));
                        }
                    }
                }
            }
        }

        System.debug('contsMap77: ' + contsMap);
        // Process contsMap List to match existing Contacts/Ids

        // Create list of keySet from tasNewMap since brackets aren't supported in SOQL string below
        List<Id> tasNewMapId = new List<Id>();
        for (Id tasId : tasNewMap.keySet()) {
            tasNewMapId.add(tasId);
        }

        // Removed hard-coding of CR field names. SELECT list of Contacts from relevant Accounts
        String fieldListStr = '';
        for (String field : fieldList) {
            fieldListStr += ', ' + field;
        }
        List<String> fieldListList = new List<String>{fieldListStr};
        String query1 = String.format('SELECT AccountId, FirstName, LastName{0} ' +
                'FROM Contact WHERE AccountId IN :tasNewMapId', fieldListList);
        List<Contact> allConts = Database.query(query1);

        Map<String, Contact> existingConts = new Map<String, Contact>();
        for (Contact con : allConts) {
            String uniqueId = con.AccountId + con.FirstName + con.LastName;
            existingConts.put(uniqueId, con);
        }
        System.debug('existingConts76: ' + existingConts);

        // Update existing contacts with new values

        for (String uniqueId : contsMap.keySet()) {
            for (String field : fieldList) {
                if (existingConts.containsKey(uniqueId) && contsMap.get(uniqueId).get(field) != null) {
                    existingConts.get(uniqueId).put(field, contsMap.get(uniqueId).get(field));
                }
            }
        }
        System.debug('existingConts79: ' + existingConts);

        // Replace "null" values with "False". Null is not a valid value for checkboxes when upserting record
        for (Contact con : existingConts.values()) {
            for (String field : fieldList) {
                if (con.get(field) == null) {
                    con.put(field, false);
                }
            }

        }

        // When a checkbox becomes true, all corresponding checkboxes in that account become false

        System.debug('existingConts77!!!: ' + existingConts);
        System.debug('triggerOld77: ' + triggerOld);
        System.debug('triggerNew77: ' + triggerNew);

        return existingConts.values();
    }
}