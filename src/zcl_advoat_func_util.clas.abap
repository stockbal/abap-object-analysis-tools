"! <p class="shorttext synchronized" lang="en">Util for function modules</p>
CLASS zcl_advoat_func_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Returns 'X' if function module exists</p>
      function_exists
        IMPORTING
          function_module TYPE tfdir-funcname
        RETURNING
          VALUE(result)   TYPE abap_bool,

      "! <p class="shorttext synchronized" lang="en">Retrieves function module information</p>
      get_function_module_info
        IMPORTING
          function_module TYPE tfdir-funcname
        RETURNING
          VALUE(result)   TYPE zif_advoat_ty_global=>ty_function_info
        RAISING
          zcx_advoat_not_exists,

      "! <p class="shorttext synchronized" lang="en">Retrieves function module info by include name</p>
      get_func_module_by_include
        IMPORTING
          include       TYPE progname
        RETURNING
          VALUE(result) TYPE zif_advoat_ty_global=>ty_function_info
        RAISING
          zcx_advoat_not_exists.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_func_util IMPLEMENTATION.


  METHOD function_exists.
    TRY.
        get_function_module_info( function_module ).
        result = abap_true.
      CATCH zcx_advoat_not_exists.
    ENDTRY.
  ENDMETHOD.

  METHOD get_function_module_info.
    result-name = function_module.
    TRANSLATE result-name TO UPPER CASE.

    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = result-name
      IMPORTING
        group              = result-group
        include            = result-include
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
      CLEAR result.
      RAISE EXCEPTION TYPE zcx_advoat_not_exists
        EXPORTING
          text = |Function module { function_module } does not exist|.
    ENDIF.
  ENDMETHOD.

  METHOD get_func_module_by_include.
    result-include = include.
    TRANSLATE result-include TO UPPER CASE.

    CALL FUNCTION 'FUNCTION_INCLUDE_INFO'
      CHANGING
        funcname            = result-name
        group               = result-group
        include             = result-include
      EXCEPTIONS
        function_not_exists = 1
        include_not_exists  = 2
        group_not_exists    = 3
        no_selections       = 4
        no_function_include = 5
        OTHERS              = 6.
    IF sy-subrc <> 0.
      CLEAR result.
      RAISE EXCEPTION TYPE zcx_advoat_not_exists
        EXPORTING
          text = |Function include { include } does not exist|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
