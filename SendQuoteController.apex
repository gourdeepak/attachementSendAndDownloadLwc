public class SendQuoteController {
    public static MainWrapper wrap;
    
    @AuraEnabled
    public static string savePdf(string dealId, string toAdd, string ccAdd, string sub, string body){
         
        try{
            system.debug('dealId-------'+dealId);
            quotation__c qu = new quotation__c();
            qu.Deal__c = dealId;
            insert qu;
            Quotation__c strObjQuote =new Quotation__c();
            List<Quotation__c> lstobjQuote =[Select id,Name, Validity_Days__c, Date__c from Quotation__c Where id =:qu.id];
            if(lstobjQuote.size()>0){
                strObjQuote = lstobjQuote[0];
            }
      PageReference pg = Page.QuotePdf;
      pg.getParameters().put('DealId', dealId);
      pg.getParameters().put('QuoteName', strObjQuote.Name);
            pg.getParameters().put('QuoteValidity', strObjQuote.Validity_Days__c);
            pg.getParameters().put('QuoteDate', string.valueOf(strObjQuote.Date__c));
            
      system.debug('PDf--------'+pg);
      blob pageBody;
      if(!test.isRunningTest()){
                pageBody = pg.getContent();
            }else{
                pageBody = blob.valueOf('Test');
            }
        
      contentVersion cv = new contentversion();
      cv.VersionData = pageBody;
      cv.Title = 'Quotation' + strObjQuote.Name+'.pdf';
      cv.PathOnClient ='Quotation' + strObjQuote.Name+'.pdf';
      insert cv;
      
      system.debug('cv---------'+cv);
      
      list<ContentVersion> lstConVer = [select id, ContentDocumentId, ContentDocument.id, ContentDocument.title from ContentVersion where id =: cv.Id limit 1];
      
      ContentDocumentLink cdl = new ContentDocumentLink();
      cdl.ContentDocumentId = lstConVer[0].ContentDocumentId;
      cdl.LinkedEntityId = qu.Id;
      cdl.ShareType = 'V';
      cdl.Visibility = 'AllUsers';
      insert cdl;
            system.debug('cdl--------'+cdl);
            //return cdl;
            list<ContentVersion> lstConVerRec = [select id, Title, VersionData, ContentDocumentId, ContentDocument.id, ContentDocument.title from ContentVersion where ContentDocumentId =: lstConVer[0].ContentDocumentId limit 1];
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            if(lstConVerRec.size() > 0 && lstConVerRec[0].VersionData != null){
                attach.setBody(lstConVerRec[0].VersionData);
                attach.setFileName(lstConVerRec[0].Title);
            }
            messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
          //system.debug('owner name-----'+wrap.ownerName);
           // system.debug('owner email----'+wrap.ownerEmail);
      System.debug(toAdd);
      system.debug(ccAdd);
      System.debug(sub);
      System.debug(body);
            
        // toAddress.add('er.rajat15@gmail.com');
      list<string> toList = new list<string>();
            list<string> ccList = new list<string>();
            if(toAdd.contains(',')){
                toList = toAdd.split(',');
            }else{
                 toList.add(toAdd);
            }
            if(ccAdd != null && ccAdd.contains(',')){
                ccList = ccAdd.split(',');
            }else if(ccAdd != null &&  ccAdd != ''){
                ccList.add(ccAdd);
            }
            
            
          //  toList.add(toAdd);
          //  list<string> ccList = new list<string>();
           // ccList.add(ccAdd);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {attach});
      mail.setToAddresses(toList);
            if(ccList != null  && ccList.size()>0 ){
      mail.setCcAddresses(ccList);
            }
      //mail.setReplyTo(wrap.ownerEmail);
      //mail.setSenderDisplayName(wrap.ownerName);
      mail.setSubject(sub);
            mail.setPlainTextBody(body);
      //mail.setHtmlBody(body);
      // mail.setEntityAttachments(files);
            system.debug('mail-------------'+mail);
      Messaging.sendEmail(new List<messaging.SingleEmailMessage> {mail});
            return 'success';
        
      }catch(Exception ex){
        system.debug('error message-----'+ ex.getMessage());
        return null;
      }
       
    }
    @AuraEnabled(Cacheable = true)
    public static string getEmailDetails(string oppId){
        wrap = new MainWrapper();
        list<deal__c> dealList = [select id, name, Contact__r.Email, Contact__r.Name, OwnerId from Deal__c where id =: oppId];
        set<id> ownerIds = new set<id>();
        for(deal__c dl : dealList){
            wrap.dealContactEmail = dl.Contact__r.Email;
            wrap.dealContactName = dl.Contact__r.Name;
            ownerIds.add(dl.OwnerId);
        }
        wrap.dealOwnerManagerEmail = system.label.cc_address;
        list<user> userList = [select id, name, manager.Email , email from user where id in: ownerIds];
        for(user us : userList){
            //wrap.dealOwnerManagerEmail = us.manager.Email;
            wrap.ownerName = us.Name;
            wrap.ownerEmail = us.Email;
            
        }
        
        wrap.emailSubject = 'Quotation';
        wrap.emailBody = 'Hi ';
        if(wrap.dealContactName != null && wrap.dealContactName !=''){
            wrap.emailBody += wrap.dealContactName + ', \n\n';
        }else{
            wrap.emailBody +='\n';
        }
        wrap.emailbody +=  system.label.Quotation_Email_Body + ', \n';
        wrap.emailbody += wrap.ownerName;
        return JSON.serialize(wrap);
    }
    public class MainWrapper{
        public string dealContactEmail;
        public string dealContactName;
        public string dealOwnerManagerEmail;
        public string emailSubject;
        public string emailBody;
        public string ownerName;
        public string ownerEmail;
    }

}
