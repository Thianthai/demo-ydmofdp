@EndUserText.label: 'Abstract File'
define abstract entity YI_DMOFDP_FILE
{
  key FileId    : sysuuid_x16;
  FileName      : abap.char(255);
  FileExtension : abap.char(10);
  MimeType      : abap.char(128);
  FileContent   : abap.string;
}
