  method is_usage_decision_exist.
* Decision code XXX 
    CONSTANTS lc_decis_emission_allowed TYPE qave-vcode VALUE 'XXX'.
    SELECT SINGLE @abap_true
      FROM qave AS e
      INNER JOIN qals AS s ON e~prueflos = s~prueflos
      INTO @DATA(lv_dummy)
      WHERE s~charg = @iv_charg AND s~matnr = @iv_matnr
        AND e~vcode = @zattp_constants=>gc_usg_dcsn_emission_allowed.
    IF sy-subrc EQ 0.
      rv_result = abap_true.
    ENDIF.
  endmethod.