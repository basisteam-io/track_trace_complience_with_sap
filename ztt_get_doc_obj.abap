FUNCTION ztt_get_doc_obj.
*"----------------------------------------------------------------------
*"*"Локальный интерфейс:
*"  IMPORTING
*"     VALUE(IV_DOCTPE) TYPE  /STTP/E_DOCTPE OPTIONAL
*"     VALUE(IV_DOCNUM) TYPE  /STTP/E_DOCNUM OPTIONAL
*"     VALUE(IV_OBJECT) TYPE  /STTP/E_OBJCODE OPTIONAL
*"  EXPORTING
*"     VALUE(ET_RETURN) TYPE  BAPIRET2_T
*"     VALUE(ET_GTIN_LIST) TYPE  ZTT_T_INF_SSCC_GTIN_LIST
*"----------------------------------------------------------------------

  CLEAR et_return.
  CLEAR et_gtin_list.

  DATA(lo_messages) = /sttp/cl_messages=>create_new_handler_att( ).

  CALL METHOD /sttp/cl_dm_query=>query_objectdata_single
    EXPORTING
      iv_objcode     = iv_object
    IMPORTING
      es_cont_result = DATA(ls_cont_result)
      es_item_result = DATA(ls_item_result).
  IF ls_cont_result IS NOT INITIAL.
    DATA(lv_object_id) = ls_cont_result-objid.
  ELSEIF ls_item_result IS NOT INITIAL.
    lv_object_id = ls_item_result-objid.
  ELSE.
    RETURN.
  ENDIF.

  iv_docnum = |{ iv_docnum ALPHA = IN }|.

  SELECT SINGLE
    @abap_true
    INTO @DATA(lv_exists)
    FROM /sttp/dm_trn
    INNER JOIN /sttp/dm_trn_rel
      ON /sttp/dm_trn_rel~trnid = /sttp/dm_trn~trnid
    WHERE /sttp/dm_trn~doctpe = @iv_doctpe
      AND /sttp/dm_trn~docnum = @iv_docnum
      AND /sttp/dm_trn_rel~objid = @lv_object_id
  .
  IF lv_exists IS INITIAL.
    MESSAGE e004(ztt_ewm) WITH iv_object iv_docnum INTO sy-msgli.
    lo_messages->set_message( ).
    /sttp/cl_messages=>get_messages_bapi(
      EXPORTING
          io_messages = lo_messages
      CHANGING
          ct_return   = et_return ).
    RETURN.
  ENDIF.

  /sttp/cl_dm_query=>query_hierarchy_webui(
      EXPORTING iv_object_id = lv_object_id
      IMPORTING et_hierarchy = DATA(lt_hry_web) ).

  APPEND VALUE #(
    sscc = iv_object+4
    child_count = lines( lt_hry_web )
  ) TO et_gtin_list.

ENDFUNCTION.