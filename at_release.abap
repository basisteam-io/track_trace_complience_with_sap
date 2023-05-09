method IF_EX_WORKORDER_UPDATE~AT_RELEASE.
    DATA: ls_pr_order_rel TYPE zpp_pr_order_rel.
    DATA: l_matnr TYPE matnr_d,
          l_ok TYPE flag.
    "Check if currently processed (released) order category is Process Order, if so add to buffer table (for further processing for Production Line integration):
    IF is_header_dialog-autyp = 40.
*     Check if material is serialized
      l_matnr = is_header_dialog-PLNBEZ.
      CALL FUNCTION 'ZATTP_RELEVANT'
        EXPORTING
          I_MATNR               = l_matnr
        CHANGING
          C_IS_SERIALIZED       = l_ok
                .
      CHECK l_ok IS NOT INITIAL.
      ls_pr_order_rel-process_order = is_header_dialog-aufnr.
      MODIFY zpp_order_rel FROM ls_pr_order_rel.
 ENDIF.