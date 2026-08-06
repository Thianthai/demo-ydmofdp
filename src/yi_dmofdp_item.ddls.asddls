@EndUserText.label: 'Demo Form Data Provider'
@ObjectModel.query.implementedBy:'ABAP:YCL_DMOFDP'
@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]
define custom entity YI_DMOFDP_ITEM 
{
  key CompanyCode             : bukrs;
  key JournalEntry            : belnr_d;
  key FiscalYear              : gjahr;
  key LedgerGLLineItem        : abap.char(6);
  GLAccount                   : saknr;
  AmountInTransactionCurrency : abap.dec(23,2);
  
  _item : association to parent YI_DMOFDP on _item.CompanyCode   = $projection.CompanyCode
                                          and _item.JournalEntry = $projection.JournalEntry
                                          and _item.FiscalYear   = $projection.FiscalYear;
                                          
}
