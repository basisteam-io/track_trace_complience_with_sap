FUNCTION ZATTP_RELEVANT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_MATNR) TYPE  MATNR_D
*"     REFERENCE(I_CHARG) TYPE  CHARG_D OPTIONAL
*"     REFERENCE(I_WERKS) TYPE  WERKS_D OPTIONAL
*"  CHANGING
*"     REFERENCE(C_IS_SERIALIZED) TYPE  FLAG
*"----------------------------------------------------------------------
  DATA: l_sertype TYPE /STTPEC/E_SERTYPE.
  CLEAR c_is_serialized.
* Check if material and batch are serialized
  SELECT SINGLE /sttpec/sertype from mara into l_sertype
    WHERE matnr = i_matnr.
  CHECK sy-subrc EQ 0.
  IF l_sertype <> '3'.
    EXIT.
  ELSEIF i_charg IS INITIAL.
    c_is_serialized = 'X'. "if no batch provided return based on material
  ENDIF.
  CHECK i_charg IS NOT INITIAL.
  CHECK i_werks IS NOT INITIAL.
  SELECT SINGLE /sttpec/sertype from MCHA into l_sertype
    WHERE matnr = i_matnr and
          werks = i_werks and
          charg = i_charg.
  CHECK sy-subrc EQ 0.
  IF l_sertype = '3'.
    c_is_serialized = 'X'.
    ELSE.
      SELECT SINGLE /sttpec/sertype from MCH1 into l_sertype
        WHERE matnr = i_matnr and
              charg = i_charg.
      IF sy-subrc EQ 0 and l_sertype = '3'.
        c_is_serialized = 'X'.
      ENDIF.
  ENDIF.
ENDFUNCTION.