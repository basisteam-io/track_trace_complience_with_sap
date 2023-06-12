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
	
	
  READ TABLE gt_ewm WITH KEY hu_box = <fs_attp_compare>-sscc_box
        ASSIGNING <fs_ewm_compare>.
      IF sy-subrc IS INITIAL.
        "BOX FOUND ON ANOTHER PAL IN EWM - ADD TO BAPI
        CLEAR ls_bapiret.
        ls_bapiret-type       = 'E'.
        ls_bapiret-id         = 'ZEWM_ATTP'.
        ls_bapiret-number     = 'XXX'.    "BOX FOUND ON ANOTHER PAL IN EWM
        ls_bapiret-message_v1 = <fs_attp_compare>-sscc_box.
        ls_bapiret-message_v2 = <fs_ewm_compare>-hu_pal.
        ls_bapiret-message_v3 = <fs_attp_compare>-sscc_pal.
        SHIFT ls_bapiret-message_v1 LEFT DELETING LEADING '0'.
        SHIFT ls_bapiret-message_v2 LEFT DELETING LEADING '0'.
        SHIFT ls_bapiret-message_v3 LEFT DELETING LEADING '0'.
        APPEND ls_bapiret TO et_bapiret.
        "CLEAR CORRESPONDING LINES IN BOTH TABLES
        CLEAR: <fs_ewm_compare>, <fs_attp_compare>.
        CONTINUE.
      ELSE.
        "NO EWM HU BOX FOUND WITH ATTP SSCC BOX - TRY WITH ONLY ATTP PAL AND EWM HU BOX = 'VIRTUAL'
        READ TABLE gt_ewm WITH KEY hu_pal = <fs_attp_compare>-sscc_pal hu_box = 'VIRTUAL'
          ASSIGNING <fs_ewm_compare>.
        IF sy-subrc IS INITIAL.
          "FOUND VIRTUAL HU BOX (QUANTITY PER UOM BOX) - CHECK QTY IN ATTP SSCC BOX = EWM QTY IN UOM BOX
          IF <fs_ewm_compare>-quan = <fs_attp_compare>-qty_gtin.
            "SAME QTY - MAKE SURE THIS ATTP SSCC BOX NOT EXIST AS EWM HU (OTHERWISE IT WOULD BE FOUND ALREADY) ON ANOTHER HU
            "IF NOT EXIST -> CHECK IF IT WAS ALREADY GI BEFORE
            IF temp_pack_ref IS NOT BOUND.
              CREATE OBJECT temp_pack_ref.
            ENDIF.

            CALL METHOD temp_pack_ref->init_pack
              EXPORTING
                iv_badi_appl = 'WME'
                iv_lgnum     = 'VL01'. "PERFOMANCE

            temp_pack_ref->/scwm/if_pack_bas~get_hu(
              EXPORTING
                iv_huident = <fs_attp_compare>-sscc_box
              IMPORTING
                es_huhdr   = DATA(zls_huhdr_box)
                et_huhdr   = DATA(zlt_huhdr_box)
              EXCEPTIONS
                not_found = 1 ).

            IF sy-subrc IS INITIAL.
              "ATTP BOX FOUND AS EWM HU - ADD TO BAPI
              IF zls_huhdr_box-higher_guid IS NOT INITIAL.
                "PACKED SOMEWHERE - ADD PARENT HU TO BAPI ALSO
                READ TABLE zlt_huhdr_box INTO DATA(ls_zlt_huhdr_box) WITH KEY guid_hu = zls_huhdr_box-higher_guid.
              ENDIF.
              CLEAR ls_bapiret.
              ls_bapiret-type       = 'E'.
              ls_bapiret-id         = 'ZEWM_ATTP'.
              ls_bapiret-number     = '038'.    "PACKED SOMEWHERE
              ls_bapiret-message_v1 = <fs_attp_compare>-sscc_box.
              ls_bapiret-message_v2 = ls_zlt_huhdr_box-huident.
              ls_bapiret-message_v3 = <fs_attp_compare>-sscc_pal.
              SHIFT ls_bapiret-message_v1 LEFT DELETING LEADING '0'.
              SHIFT ls_bapiret-message_v2 LEFT DELETING LEADING '0'.
              SHIFT ls_bapiret-message_v3 LEFT DELETING LEADING '0'.
              APPEND ls_bapiret TO et_bapiret.
              "CLEAR CORRESPONDING LINE IN ATTP TABLE
              CLEAR: <fs_attp_compare>.
              CONTINUE.

            ELSE.
              "CHECK IF ATTP BOX WAS ALREADY GI IN EWM IN PAST

              CLEAR: lv_hu_box_was_gi.

              "Check parameter is switched on - reading WT/HU can slow down perfomance
              IF zcl_tvarvc=>read_parameter( i_name = 'ZTT_COMPARE_READ_GI_BOX' ) IS NOT INITIAL.
                SELECT SINGLE guid_parent INTO @DATA(lv_gi_guid_par) FROM /scwm/gmhuhdr
                WHERE huident = @<fs_attp_compare>-sscc_box
                AND lgnum = 'VL01' "FOR PERFOMANCE
                AND phystat = 'C'.  "HU STATUS GI

                IF sy-subrc IS INITIAL.
                  lv_hu_box_was_gi = 'X'.
                ELSE.
                  "Try to find WT for GI - for ADGI case
                  SELECT SINGLE tanum INTO @DATA(lv_tanum)
                  FROM /scwm/ordim_c WHERE lgnum = 'VL01' "PERFOMANCE
                                     AND trart = '6'
                                     AND tostat = 'C'
                                     AND vlenr = @<fs_attp_compare>-sscc_box.
                  IF sy-subrc IS INITIAL.
                    lv_hu_box_was_gi = 'X'.
                  ENDIF.
                ENDIF.
              ENDIF.