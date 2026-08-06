@EndUserText.label: 'Demo Form Data Provider'
@ObjectModel.query.implementedBy:'ABAP:YCL_DMOFDP'
@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]
define root custom entity YI_DMOFDP
{
  @EndUserText.label                : 'Company Code'
  @UI.lineItem                      : [{ position: 10 }]
  @UI.selectionField                : [{ position: 10 }]
  @Consumption.filter.mandatory     : true
  @Consumption.valueHelpDefinition  : [{ entity: { name: 'I_CompanyCodeVH', element: 'CompanyCode' } }]
  key CompanyCode                   : bukrs;
  
  @EndUserText.label                : 'Journal Entry'
  @UI.lineItem                      : [{ position: 20 }]
  @UI.selectionField                : [{ position: 20 }]
  key JournalEntry                  : belnr_d;
  
  @EndUserText.label                : 'Fiscal Year'
  @UI.lineItem                      : [{ position: 30 }]
  @UI.selectionField                : [{ position: 30 }]
  key FiscalYear                    : gjahr;

  @EndUserText.label                : 'Posting Date'
  @UI.lineItem                      : [{ position: 40 }]
  @UI.selectionField                : [{ position: 40 }]
  @Consumption.filter.selectionType : #INTERVAL
  PostingDate                       : budat;

  @Semantics.mimeType               :true
  FileName                          : abap.char( 128 );
  MimeType                          : abap.char( 255 );
  
  @UI.lineItem                      : [{ hidden: true, position: 70, label: 'Download File' }]
  @Semantics.largeObject            : { mimeType: 'MimeType', fileName: 'FileName', contentDispositionPreference: #ATTACHMENT }
  Attachment                        : abap.rawstring( 0 );
    
  @UI.hidden                        : true
  PrintUrl                          : abap.char(1000);
  
  @UI.hidden                        : true
  DownloadUrl                       : abap.char(1000);
  
  @UI.lineItem                      : [{ position: 50, label: 'Print Journal', type: #WITH_URL, url: 'PrintUrl' }]
  PrintUrlBTN                       : abap.char(20);
  
  @UI.lineItem                      : [{ position: 60, label: 'Print Journal', type: #WITH_URL, url: 'DownloadUrl' }]
  DownloadBTN                       : abap.char(20);

  @UI.lineItem                      : [{ position           : 80, 
                                         label              : 'Print Journal Entry', 
                                         type               : #FOR_ACTION, 
                                         dataAction         : 'PrintJournal', 
                                         inline             : false, 
                                         invocationGrouping : #CHANGE_SET }]
  PrintJournalBTN                   : abap.char(1);

  @Semantics.mimeType               :true
  CompMimeType                      : abap.char(128);
  CompFileName                      : abap.char(255);

  @UI.hidden                        : true
  @Semantics.largeObject: { 
      mimeType: 'CompMimeType',
      fileName: 'CompFileName',
      acceptableMimeTypes: ['image/png', 'image/jpeg'],
      contentDispositionPreference: #INLINE 
  }
  CompanyLogo                       : abap.rawstring( 0 );

  @Semantics.mimeType               :true
  SignMimeType                      : abap.char(128);
  SignFileName                      : abap.char(255);

  @UI.hidden                        : true
  @Semantics.largeObject: { 
      mimeType: 'SignMimeType',
      fileName: 'SignFileName',
      acceptableMimeTypes: ['image/png', 'image/jpeg'],
      contentDispositionPreference: #INLINE 
  }
  Signature                         : abap.rawstring( 0 );
  
  _item                             : composition of exact one to many YI_DMOFDP_ITEM;
  
}
