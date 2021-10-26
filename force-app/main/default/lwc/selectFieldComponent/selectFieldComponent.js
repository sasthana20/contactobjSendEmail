import { LightningElement,wire,track,api } from 'lwc';

export default class MergeFieldLWC extends LightningElement {

    @api lstContactFields = [];
    @api objectApi;
    @track selectedField='';
    @track insertMergeField = ''; 
    @track optionsValues=[]; 

    connectedCallback(){
        if(this.lstContactFields){
            var listOfField=[];
            for(var key in this.lstContactFields){
                listOfField.push({label:this.lstContactFields[key].fieldAPI, value: this.lstContactFields[key].fieldLabel}); //Here we are creating the array to show on UI.
            }
            this.optionsValues = listOfField;
        }
    }
    handleSelectedValue(event){
        var mergeField  = event.detail.value.replaceAll('<[/a-zAZ0-9]*>','');   
        this.insertMergeField = '{!' + 'Contact.'+ mergeField + '}'; 
        const passEvent = new CustomEvent('handleselectedvalue', {
            // detail contains only primitives
            detail: "{!" + this.objectApi + "."+  event.detail.value + "}"
            });
        this.dispatchEvent(passEvent);        
        
    }

    handleCloseModel(event){
        const closeEvent = new CustomEvent('handleclosemodel', {          
            });
        this.dispatchEvent(closeEvent);

    }

    // update searchValue var when input field value change
    searchKeyword(event) {
        this.searchValue = event.target.value;
    }
}