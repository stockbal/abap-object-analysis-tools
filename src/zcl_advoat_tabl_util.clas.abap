"! <p class="shorttext synchronized" lang="en">DDIC Table util</p>
CLASS zcl_advoat_tabl_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Retrieves workbench type of given table</p>
      get_table_wb_type
        IMPORTING
          table_name    TYPE tabname
        RETURNING
          VALUE(result) TYPE seu_objtyp.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_advoat_tabl_util IMPLEMENTATION.

  METHOD get_table_wb_type.
    SELECT SINGLE tabclass
      FROM dd02l
      WHERE tabname = @table_name
        AND as4local = 'A'
      INTO @DATA(table_class).

    IF sy-subrc = 0.
      IF table_class = 'INTTAB' OR table_class = 'APPEND'.
        result = swbm_c_type_ddic_structure.
      ELSEIF table_class = 'TRANSP'.
        result = swbm_c_type_ddic_db_table.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
