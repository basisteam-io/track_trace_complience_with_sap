  METHOD get_hierarchy.

    DATA lv_object_id TYPE /sttp/e_objid.
    DATA(lo_messages) = /sttp/cl_messages=>create_new_handler_att( ).

    CALL METHOD /sttp/cl_dm_query=>query_objectdata_single
      EXPORTING
        iv_objcode     = iv_object
      IMPORTING
        es_cont_result = DATA(ls_cont_result)
        es_item_result = DATA(ls_item_result).

    IF ls_cont_result IS NOT INITIAL.
      lv_object_id = ls_cont_result-objid.
    ELSEIF ls_item_result IS NOT INITIAL.
      lv_object_id = ls_item_result-objid.
    ELSE.
      "Nothing found
      MESSAGE e020(ztt) WITH iv_object INTO sy-msgli.
      lo_messages->set_message( ).
      /sttp/cl_messages=>get_messages_bapi(
        EXPORTING
            io_messages = lo_messages
        CHANGING
            ct_return   = ct_return
            ).
      RETURN.
    ENDIF.

    _query_hierarchy(
        EXPORTING iv_object_id = lv_object_id
        IMPORTING et_hierarchy = DATA(lt_hry_tmp) ).

    DATA(lt_hry) = CORRESPONDING tt_hry( lt_hry_tmp ).
    CLEAR lt_hry_tmp.

    _get_current_hry_part(
      EXPORTING
        iv_item_objid = ls_item_result-objid
        iv_sscc_objid = ls_cont_result-objid
      CHANGING
        ct_hry = lt_hry
    ).


    DATA(lv_root_id)     = VALUE #( lt_hry[ objid = lv_object_id ]-objid_root OPTIONAL ).
    DATA(lv_root_object) = value #( lt_hry[ objid = lv_root_id ]-gs1_es_b OPTIONAL ).

    LOOP AT lt_hry INTO DATA(ls_hry).

      APPEND INITIAL LINE TO rt_result ASSIGNING FIELD-SYMBOL(<fs_hry>).

      <fs_hry>-object = ls_hry-gs1_es_b.

      READ TABLE lt_hry ASSIGNING FIELD-SYMBOL(<fs_parent>) WITH KEY
        objid = ls_hry-objid_parent
      .
      IF sy-subrc EQ 0.
        <fs_hry>-parent = <fs_parent>-gs1_es_b.
      ENDIF.
      <fs_hry>-root = lv_root_object.

    ENDLOOP.

  ENDMETHOD.