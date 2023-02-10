import { LightningElement, api, wire, track } from 'lwc';
import savePdf from '@salesforce/apex/SendQuoteController.savePdf';
import getEmailDetails from '@salesforce/apex/SendQuoteController.getEmailDetails';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AttachementDownload extends LightningElement {
    @api recordId;
    @track toAddress = '';
    @track ccAddress = '';
    @track subject;
    @track body;
    @track response;
    @track showSpinner = false;


    @wire(getEmailDetails , {oppId : '$recordId'})
    wiredEmailDetail({error,data}){
        if(data){
          //  console.log('data------'+data);
            this.response = JSON.parse(data);
          //  console.log('response---------'+this.response);
            this.toAddress = this.response.dealContactEmail;
            this.ccAddress = this.response.dealOwnerManagerEmail;
            this.subject = this.response.emailSubject
            this.body = this.response.emailBody;
        }
        if(error){
          //  console.log('error------'+error);
        }
    }

    handleClick(){
        this.showSpinner = true;
        savePdf({dealId : this.recordId, toAdd : this.toAddress, ccAdd : this.ccAddress, sub : this.subject, body : this.body})
        .then(result => {
          //  console.log('result-----'+JSON.stringify(result));
            this.closedAura();
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(new ShowToastEvent({
                title : 'Succes',
                message : 'Quotation Generated Successfully',
                variant : 'success'
            }),
            );
            this.dispatchEvent(new CloseActionScreenEvent());
            eval("$A.get('e.force:refreshView').fire();");

        })
        .catch(error => {
           // console.log('error--------'+error);
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(new ShowToastEvent({
                title : 'Error',
                message : 'Error while generating Quotation',
                variant : 'error'
            }),
            );
        })
    }

    handleCancel(){
        this.closedAura();
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleChange(event){
      //  console.log('event.target.label----------'+event.target.label);
       // console.log('event.target.value-------'+event.target.value);
        if(event.target.label === 'To'){
            this.toAddress = event.target.value;
        }
        if(event.target.label === 'CC'){
            this.ccAddress = event.target.value;
        }
        if(event.target.label === 'Subject'){
            this.subject = event.target.value;
        }
        if(event.target.label === 'Body'){
            this.body = event.target.value;
        }
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
       
      //eval("$A.get('e.force:closeQuickAction').fire()");

      this.closedAura();
        
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    closedAura() {
        const value = ''; 
        const valueChangeEvent = new CustomEvent("closeAction", {       detail: { value }     });  
           // Fire the custom event     
        this.dispatchEvent(valueChangeEvent);   
    }
   
}
