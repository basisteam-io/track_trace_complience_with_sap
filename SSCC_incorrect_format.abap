    "PARAMETERS ARE PASSED FROM THIS FM IMPORT - FOR CALLING APPLICATION TO DECIDE
    "CALL ATTP TO GET REQUIRED DATA BY SSCC LIST
    CALL FUNCTION 'ZTT_INT_GET_STOCK_DATA' DESTINATION lv_rfc_dest
      EXPORTING
        it_sscc           = lt_sscc                      " ALL EWM HUs FOUND (TOP/CHILD) OR NOT FOUND (IF NOT EXIST IN EWM)
        iv_get_stat_desc  = attp_get_stat_desc           " 'X' - Get ATTP status descr instead of codes
        iv_exact_sscc_box = attp_exact_sscc_box          " 'X' - Read only requested SSCC (boxes) numbers
        iv_only_checks    = attp_only_checks             " 'X' - Only check SSCC exist/number format (no data read)
        iv_only_statuses  = attp_only_statuses           " 'X' - Get only ATTP statuses (no data read) + additional checks
        iv_format_for_ewm = 'X'                          " 'X' - SSCC number in responce without braces (00)
        iv_get_docs       = e_attp_get_docs              " 'X' - Additionally read documents assigned to SSCC in ATTP
        iv_get_status     = e_attp_get_status            " 'X' - Also get stats for SSCC (besides data) + additional checks
      IMPORTING
        et_stock          = it_attp_stock                "ATTP SSCC Stock data and hierarchy
        et_statuses       = it_attp_statuses             "ATTP SSCC Statuses
        et_failed         = it_attp_failed_sscc          "ATTP SSCC Incorrect/Not exist
        et_docs           = it_attp_sscc_docs.           "ATTP SSCC Assigned ERP outbound deliveries

    "ADD RECEIVED ATTP DATA TO THIS FM EXPORT BEFORE FURTHER PROCESSING
    et_attp_stock[] = it_attp_stock[].
    et_attp_statuses[] = it_attp_statuses[].
    et_attp_failed_sscc[] = it_attp_failed_sscc[].
    et_attp_sscc_docs[] = it_attp_sscc_docs[].
	
	
	  "NO ATTP STOCK FOUND AT ALL - ERROR
  IF it_attp_stock IS INITIAL.
    CLEAR ls_bapiret.
    ls_bapiret-type       = 'E'.
    ls_bapiret-id         = 'Z_ATTP'.
    ls_bapiret-number     = 'XXX'.   "NO ATTP STOCK FOUND AT ALL - ERROR
    APPEND ls_bapiret TO et_bapiret.
  ENDIF.
  
  
  IF it_attp_failed_sscc IS NOT INITIAL.
    "SOME SSCC FAILED CHECK - FILL BAPI
    LOOP AT it_attp_failed_sscc INTO DATA(ls_attp_failed) WHERE not_exist IS NOT INITIAL.
      "NOT EXISTING SSCC
      CLEAR ls_bapiret.
      ls_bapiret-type       = 'E'.
      ls_bapiret-id         = 'Z_ATTP'.
      ls_bapiret-number     = 'XXX'.   "NOT EXISTING SSCC
      ls_bapiret-message_v1 = ls_attp_failed-sscc.
      SHIFT ls_bapiret-message_v1 LEFT DELETING LEADING '0'.
      APPEND ls_bapiret TO et_bapiret.
    ENDLOOP.
    LOOP AT it_attp_failed_sscc INTO ls_attp_failed WHERE incor_num IS NOT INITIAL.
      "INCORRECT SSCC NUMBER FORMAT
      CLEAR ls_bapiret.
      ls_bapiret-type       = 'E'.
      ls_bapiret-id         = 'Z_ATTP'.
      ls_bapiret-number     = 'XXX'.   "INCORRECT SSCC NUMBER FORMAT
      ls_bapiret-message_v1 = ls_attp_failed-sscc.
      SHIFT ls_bapiret-message_v1 LEFT DELETING LEADING '0'.
      APPEND ls_bapiret TO et_bapiret.
    ENDLOOP.