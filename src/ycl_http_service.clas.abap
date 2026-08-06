CLASS ycl_http_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_http_service_extension .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_HTTP_SERVICE IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA(lv_company)      = request->get_form_field( 'CompanyCode' ).
    DATA(lv_journal)      = request->get_form_field( 'JournalEntry' ).
    DATA(lv_fiscal)       = request->get_form_field( 'FiscalYear' ).
    DATA(lv_mode)         = request->get_form_field( 'Mode' ).

    IF lv_journal IS INITIAL OR lv_company IS INITIAL.
      response->set_status( 400 ).
      response->set_text( 'Missing required keys: CompanyCode or JournalEntry' ).
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_fdp_api) = cl_fp_fdp_services=>get_instance( 'YSD_DMOFDP' ).
        DATA(lt_fdp_keys) = lo_fdp_api->get_keys( ).

        LOOP AT lt_fdp_keys ASSIGNING FIELD-SYMBOL(<ls_fdp_key>).
          CASE <ls_fdp_key>-name.
            WHEN 'COMPANYCODE'.  <ls_fdp_key>-value = lv_company.
            WHEN 'JOURNALENTRY'. <ls_fdp_key>-value = lv_journal.
            WHEN 'FISCALYEAR'.   <ls_fdp_key>-value = lv_fiscal.
          ENDCASE.
        ENDLOOP.

        DATA(lv_xml) = lo_fdp_api->read_to_xml_v2( lt_fdp_keys ).
        DATA(lo_reader) = cl_fp_form_reader=>create_form_reader( 'YF_DMOFDP' ).

        DATA: lv_pdf_xstring TYPE xstring.
        cl_fp_ads_util=>render_pdf(
          EXPORTING iv_xml_data   = lv_xml
                    iv_xdp_layout = lo_reader->get_layout( )
                    iv_locale     = 'en_US'
          IMPORTING ev_pdf        = lv_pdf_xstring
        ).

        response->set_header_field( i_name = 'Content-Type' i_value = 'application/pdf' ).

        DATA(lv_filename) = |Journal_{ lv_journal }.pdf|.
        response->set_header_field(
            i_name = 'Content-Disposition'
*            i_value = |attachment; filename="{ lv_filename }"|
            i_value =  SWITCH #( lv_mode WHEN 'D'
                                         THEN |attachment; filename="{ lv_filename }"|
                                         ELSE |inline; filename="{ lv_filename }"| )
        ).

        response->set_binary( lv_pdf_xstring ).

      CATCH cx_root INTO DATA(lx_err).
        " กรณี Error ให้พ่น Status 500 กลับไป
        response->set_status( 500 ).
        response->set_text( |PDF Generation Error: { lx_err->get_text( ) }| ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
