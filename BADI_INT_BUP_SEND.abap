METHOD /sttpec/if_badi_int_bup_send~change_before_send.

  DATA: l_partner TYPE bu_partner.
  LOOP AT ct_bup_head ASSIGNING FIELD-SYMBOL(<ls_bup_head>).

    l_partner = <ls_bup_head>-bupno.
    CALL METHOD zattp_utils=>bp_requires_xxx
      EXPORTING
        i_partner = l_partner
      RECEIVING
        e_xxx = DATA(l_xxx).

    APPEND INITIAL LINE TO ct_bup_reg ASSIGNING FIELD-SYMBOL(<lfs_reg>).
    MOVE-CORRESPONDING <ls_bup_head> TO <lfs_reg>.
    <lfs_reg>-method = 'M'.
    <lfs_reg>-reg_valid_from = sy-datum.
    <lfs_reg>-regtype = 'Your_logic_here'.
    <lfs_reg>-reg_valid_to = 'Your_logic_here1'.
    <lfs_reg>-reg_tzone = 'Your_logic_here'.
    <lfs_reg>-reg_country = 'Your_logic_here'.

    IF l_xxx IS NOT INITIAL.
      <lfs_reg>-regno = 'X'.
    ELSE.
      <lfs_reg>-regno = '-'.
    ENDIF.
  ENDLOOP.
ENDMETHOD.