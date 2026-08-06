CLASS lhc_YI_DMOFDP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR yi_dmofdp RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ yi_dmofdp RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK yi_dmofdp.

    METHODS PrintJournal FOR MODIFY
      IMPORTING keys FOR ACTION yi_dmofdp~PrintJournal RESULT result.

ENDCLASS.

CLASS lhc_YI_DMOFDP IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD PrintJournal.

    DATA : ls_output TYPE yi_dmofdp.

    DATA(lo_merger) = cl_rspo_pdf_merger=>create_instance( ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      TRY.
          " 2. เรียก FDP Service
          DATA(lo_fdp_api) = cl_fp_fdp_services=>get_instance( 'YSD_DMOFDP' ).
          DATA(lt_fdp_keys) = lo_fdp_api->get_keys( ).

          " Map Key
          LOOP AT lt_fdp_keys ASSIGNING FIELD-SYMBOL(<fdp_key>).
            CASE <fdp_key>-name.
              WHEN 'COMPANYCODE'.  <fdp_key>-value = <ls_key>-CompanyCode.
              WHEN 'JOURNALENTRY'. <fdp_key>-value = <ls_key>-JournalEntry.
              WHEN 'FISCALYEAR'.   <fdp_key>-value = <ls_key>-FiscalYear.
            ENDCASE.
          ENDLOOP.

          " 3. Get Data and Form
          DATA(lv_xml) = lo_fdp_api->read_to_xml_v2( lt_fdp_keys ). "XSTRING Data
          DATA(lo_reader) = cl_fp_form_reader=>create_form_reader( 'YF_DMOFDP' ). "Adobe Form Object

          " 4. Map Data to Form
          cl_fp_ads_util=>render_pdf(
            EXPORTING iv_xml_data   = lv_xml
                      iv_xdp_layout = lo_reader->get_layout( ) "Form Layout
                      iv_locale     = 'en_US'
            IMPORTING ev_pdf        = ls_output-Attachment "XSTRING
          ).

          ls_output-MimeType = 'application/pdf'.
          ls_output-FileName = |Journal_{ <ls_key>-JournalEntry }.pdf|.

        CATCH cx_root INTO DATA(lx_err).

      ENDTRY.

      "Add the data of the first PDF document to the list of files which shall be merged
      lo_merger->add_document( ls_output-Attachment ).

    ENDLOOP.

    TRY.
        DATA(lv_after_merge) = lo_merger->merge_documents( ).
      CATCH cx_rspo_pdf_merger.
    ENDTRY.

    DATA : lv_b64 TYPE string.

    cl_web_http_utility=>encode_x_base64(
      EXPORTING
        unencoded = lv_after_merge
      RECEIVING
        encoded   = lv_b64
    ).

    TRY.
        "Send Result to FIORI
        APPEND VALUE #(
          %tky   = keys[ 1 ]-%tky
          %param = VALUE yi_dmofdp_file(
            FileId        = cl_system_uuid=>create_uuid_x16_static( )
            FileName      = |Journal_TEST.pdf|
            FileExtension = 'pdf'
            MimeType      = 'application/pdf'
            FileContent   = lv_b64
          )
        ) TO result.
      CATCH cx_uuid_error ##NO_HANDLER.
        "handle exception
    ENDTRY.

*      TRY.
*          " -------------------------------------------------------------
*          " 1. สร้าง Queue Item ID ขึ้นมาก่อน
*          " -------------------------------------------------------------
*          DATA(lv_qitem_id) = cl_print_queue_utils=>create_queue_itemid( ).
*
*          " -------------------------------------------------------------
*          " 2. ส่งข้อมูล PDF เข้า Queue
*          " -------------------------------------------------------------
*          DATA: lv_err_msg TYPE cl_print_queue_utils=>ty_msg.
*
*          cl_print_queue_utils=>create_queue_item_by_data(
*            EXPORTING
*              iv_itemid           = lv_qitem_id             " <---  ID
*              iv_qname            = 'DEFAULT'               " <--- ชื่อ Queue (ต้องมีในระบบ)
*              iv_print_data       = ls_output-Attachment    " <--- ไฟล์ PDF (XSTRING)
*              iv_name_of_main_doc = |Journal_{ <ls_key>-JournalEntry }.pdf|
*              iv_number_of_copies = 1
*            IMPORTING
*              ev_err_msg          = lv_err_msg
*          ).
*
*          " -------------------------------------------------------------
*          " 3. เช็คผลลัพธ์
*          " -------------------------------------------------------------
*          IF lv_err_msg IS INITIAL.
*
*            APPEND VALUE #(
*              %tky = <ls_key>-%tky
*              %msg = new_message_with_text(
*                       severity = if_abap_behv_message=>severity-success
*                       text     = |PDF sent to Print Queue 'DEFAULT'. Item ID: { lv_qitem_id }|
*                     )
*            ) TO reported-yi_zglf001_j.
*          ELSE.
*
*            APPEND VALUE #(
*              %tky = <ls_key>-%tky
*              %msg = new_message_with_text(
*                       severity = if_abap_behv_message=>severity-error
*                       text     = |Queue Error: { lv_err_msg }|
*                     )
*            ) TO reported-yi_zglf001_j.
*          ENDIF.
*
*        CATCH cx_root INTO DATA(lx_root).
*
*          APPEND VALUE #(
*            %tky = <ls_key>-%tky
*            %msg = new_message_with_text(
*                     severity = if_abap_behv_message=>severity-error
*                     text     = lx_root->get_text( )
*                   )
*          ) TO reported-yi_zglf001_j.
*      ENDTRY.
*
*      APPEND VALUE #(
*              %tky      = <ls_key>-%tky
*
*              %param    = VALUE #(
**                  ledger       = <ls_key>-ledger
**                  CompanyCode  = <ls_key>-CompanyCode
**                  JournalEntry = <ls_key>-JournalEntry
**                  FiscalYear   = <ls_key>-FiscalYear
*
*                  FileContent   = ls_output-Attachment
*                  MimeType     = 'application/pdf'
*                  FileName     = |Journal_{ <ls_key>-JournalEntry }.pdf|
*              )
*            ) TO result.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_YI_DMOFDP DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_YI_DMOFDP IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
