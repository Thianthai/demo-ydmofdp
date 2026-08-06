CLASS ycl_dmofdp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-DATA: mc_duplicate_call TYPE abap_boolean.

    DATA:
      gt_filter  TYPE if_rap_query_filter=>tt_name_range_pairs,
      gtr_bukrs TYPE RANGE OF yi_dmofdp-CompanyCode,
      gtr_belnr TYPE RANGE OF yi_dmofdp-JournalEntry,
      gtr_gjahr TYPE RANGE OF yi_dmofdp-FiscalYear,
      gtr_budat TYPE RANGE OF yi_dmofdp-PostingDate,
      gt_output TYPE TABLE OF yi_dmofdp WITH EMPTY KEY,
      gt_item   TYPE TABLE OF yi_dmofdp_item WITH EMPTY KEY.

    INTERFACES :
      if_rap_query_provider.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS prepare_filter
      IMPORTING
        io_request TYPE REF TO if_rap_query_request
      RAISING
        cx_rap_query_filter_no_range.
    METHODS handle_record
      IMPORTING
        io_request  TYPE REF TO if_rap_query_request
        io_response TYPE REF TO if_rap_query_response.
    METHODS prepare_data_header.
    METHODS prepare_data_item.
    METHODS handle_sort
      IMPORTING
        io_request  TYPE REF TO if_rap_query_request
        io_response TYPE REF TO if_rap_query_response.
    METHODS handle_paging
      IMPORTING
        io_request  TYPE REF TO if_rap_query_request
        io_response TYPE REF TO if_rap_query_response.
ENDCLASS.



CLASS YCL_DMOFDP IMPLEMENTATION.


  METHOD prepare_data_header.

    "Get Form Graphic
    SELECT FROM ytbc_graphic
    FIELDS *
    ORDER BY uuid, graphic_name
    INTO TABLE @DATA(lt_graphic).

    "Get Document
    SELECT FROM I_JournalEntryTP WITH PRIVILEGED ACCESS
      FIELDS CompanyCode,
             AccountingDocument AS JournalEntry,
             FiscalYear,
             PostingDate

      WHERE  CompanyCode        IN @gtr_bukrs
      AND    AccountingDocument IN @gtr_belnr
      AND    FiscalYear         IN @gtr_gjahr
      AND    PostingDate        IN @gtr_budat
      GROUP BY CompanyCode,
               AccountingDocument,
               FiscalYear,
               PostingDate
               INTO TABLE @gt_output .

    LOOP AT gt_output ASSIGNING FIELD-SYMBOL(<ls_result>).
       <ls_result>-PrintUrl = |/sap/bc/http/sap/YHS_DMOFDP| &&
                              |?CompanyCode={ <ls_result>-CompanyCode }| &&
                              |&JournalEntry={ <ls_result>-JournalEntry }| &&
                              |&FiscalYear={ <ls_result>-FiscalYear }| &&
                              |&Mode=P|.
       <ls_result>-DownloadUrl = |/sap/bc/http/sap/YHS_DMOFDP| &&
                              |?CompanyCode={ <ls_result>-CompanyCode }| &&
                              |&JournalEntry={ <ls_result>-JournalEntry }| &&
                              |&FiscalYear={ <ls_result>-FiscalYear }| &&
                              |&Mode=D|.
        <ls_result>-PrintUrlBTN = 'Preview PDF'.
        <ls_result>-DownloadBTN = 'Download PDF'.

        "Determine Company Logo
        DATA(lv_result) = COND char1( WHEN <ls_result>-JournalEntry+9(1) CO '02468' THEN '0'
                                      WHEN <ls_result>-JournalEntry+9(1) CO '13579' THEN '1'
                                      ELSE '' ).

        DATA(ls_company_logo) = COND ytbc_graphic(
                                  WHEN lv_result = '0' "Even number
                                    THEN VALUE #( lt_graphic[ graphic_name = 'IAM_B_LOGO' ] OPTIONAL )
                                  WHEN lv_result = '1' "Odd number
                                    THEN VALUE #( lt_graphic[ graphic_name = 'IAM_W_LOGO' ] OPTIONAL )
                                ).

        <ls_result>-CompMimeType = ls_company_logo-mime_type.
        <ls_result>-CompFileName = ls_company_logo-file_name.
        <ls_result>-CompanyLogo  = ls_company_logo-attachment.

        "Determine Signature
        DATA(ls_signature) = COND ytbc_graphic(
                               WHEN lv_result = '0' "Even number
                                 THEN VALUE #( lt_graphic[ graphic_name = 'SIGN_THIANTHAI' ] OPTIONAL )
                               WHEN lv_result = '1' "Odd number
                                 THEN VALUE #( lt_graphic[ graphic_name = 'SIGN_BARAMEE' ] OPTIONAL )
                             ).

        <ls_result>-SignMimeType = ls_signature-mime_type.
        <ls_result>-SignFileName = ls_signature-file_name.
        <ls_result>-Signature    = ls_signature-attachment.

    ENDLOOP.

  ENDMETHOD.


  METHOD prepare_data_item.

    SELECT FROM I_JournalEntryItem WITH PRIVILEGED ACCESS AS item
      INNER JOIN I_JournalEntryTP AS header ON
        header~CompanyCode        = item~CompanyCode AND
        header~AccountingDocument = item~AccountingDocument AND
        header~FiscalYear         = item~FiscalYear
      FIELDS header~CompanyCode,
             header~AccountingDocument AS JournalEntry,
             header~FiscalYear,
             item~LedgerGLLineItem,
             item~GLAccount,
             item~AmountInTransactionCurrency
      WHERE  header~CompanyCode        IN @gtr_bukrs
      AND    header~AccountingDocument IN @gtr_belnr
      AND    header~FiscalYear         IN @gtr_gjahr
      AND    header~PostingDate        IN @gtr_budat
      AND    item~Ledger = '0L'
      INTO TABLE @gt_item.

  ENDMETHOD.


  METHOD handle_sort.

    DATA :
      lt_order TYPE abap_sortorder_tab,
      ls_order TYPE abap_sortorder
      .
    DATA(lt_sort_req) = io_request->get_sort_elements( ).
    LOOP AT lt_sort_req ASSIGNING FIELD-SYMBOL(<s>).
      CLEAR ls_order.
      ls_order-name = to_upper( <s>-element_name ).
      ls_order-descending = xsdbool( <s>-descending = abap_true ).
      APPEND ls_order TO lt_order.
    ENDLOOP.
    IF lt_order IS NOT INITIAL.
      SORT gt_output BY (lt_order).
      SORT gt_item   BY (lt_order).
    ELSE.
      SORT gt_output BY  CompanyCode JournalEntry FiscalYear .
      SORT gt_item   BY  companycode JournalEntry FiscalYear LedgerGLLineItem .
    ENDIF.

  ENDMETHOD.


  METHOD prepare_filter.

    gt_filter = io_request->get_filter( )->get_as_ranges( ).
    LOOP AT gt_filter ASSIGNING FIELD-SYMBOL(<lfs_where>).
      CASE <lfs_where>-name.
        WHEN 'COMPANYCODE'  .
          gtr_bukrs = CORRESPONDING #( <lfs_where>-range ).
        WHEN 'POSTINGDATE'  .
          gtr_budat = CORRESPONDING #( <lfs_where>-range ).
        WHEN 'JOURNALENTRY'  .
          gtr_belnr = CORRESPONDING #( <lfs_where>-range ).
        WHEN 'FISCALYEAR'.
          gtr_gjahr = CORRESPONDING #( <lfs_where>-range ).
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.


  METHOD if_rap_query_provider~select.

    TRY.
        CASE io_request->get_entity_id( ).
          WHEN 'YI_DMOFDP'.
            CLEAR gt_output .

            "Get Filter from Selection screen
            prepare_filter( io_request = io_request ).

            "Prepare Data
            prepare_data_header( ).

            "Handle Record
            handle_record( EXPORTING io_request = io_request  io_response = io_response ).
            "Handle Sort
            handle_sort( EXPORTING io_request = io_request  io_response = io_response ).
            "Handle paging ($skip, $top)
            handle_paging( EXPORTING io_request = io_request  io_response = io_response ).
            "Return Data to Report
            io_response->set_data( gt_output ).

          WHEN 'YI_DMOFDP_ITEM'.

            "Get Filter from Selection screen
            prepare_filter( io_request = io_request ).

            "Prepare Data
            prepare_data_item( ).

            "Handle Record
            handle_record( EXPORTING io_request = io_request  io_response = io_response ).
            "Handle Sort
            handle_sort( EXPORTING io_request = io_request  io_response = io_response ).
            "Handle paging ($skip, $top)
            handle_paging( EXPORTING io_request = io_request  io_response = io_response ).
            "Return Data to Report
            io_response->set_data( gt_item ).

        ENDCASE.

      CATCH cx_rap_query_provider
            cx_rap_query_filter_no_range ##NO_HANDLER.
        "handle exception

    ENDTRY.

  ENDMETHOD.


  METHOD handle_record.

    DATA :
      lv_count  TYPE int8.
    "Handle number of record
    IF io_request->is_total_numb_of_rec_requested( ).
      lv_count = lines( gt_output ) .
      io_response->set_total_number_of_records( lv_count ).
    ENDIF.

  ENDMETHOD.


  METHOD handle_paging.

    DATA(lo_paging) = io_request->get_paging( ).
    IF lo_paging IS BOUND.
      DATA(lv_offset)   = lo_paging->get_offset( ).
      DATA(lv_pagesize) = lo_paging->get_page_size( ).

      IF lv_offset > 0.
        DELETE gt_output FROM 1 TO lv_offset.
      ENDIF.

      IF lv_pagesize > 0 AND lines( gt_output ) > lv_pagesize.
        DELETE gt_output FROM lv_pagesize + 1 TO lines( gt_output ).
      ENDIF.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
