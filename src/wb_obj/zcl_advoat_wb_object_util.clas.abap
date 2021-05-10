"! <p class="shorttext synchronized" lang="en">WB Object Utility</p>
CLASS zcl_advoat_wb_object_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Resolve Include to WB object</p>
      "! Resolves a given Include to a workbench object<br/>
      "! Possible values are:
      "! <ul>
      "! <li>FUGR/I - Function Group Include</li>
      "! <li>FUGR/FF - Function Module</li>
      "! <li>PROG/I - Program Include
      "! </ul>
      resolve_include_to_wb_object
        IMPORTING
          include_name     TYPE progname
        RETURNING
          VALUE(wb_object) TYPE zif_advoat_ty_global=>ty_wb_object,
      "! <p class="shorttext synchronized" lang="en">Retrieves full workbench type for given type</p>
      get_full_wb_object_type
        IMPORTING
          type          TYPE seu_obj
        RETURNING
          VALUE(result) TYPE wbobjtype.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_wb_object_util IMPLEMENTATION.

  METHOD get_full_wb_object_type.

    "TODO: check behavior for certain types like DOCT
    cl_wb_object_type=>create_from_exttype(
      EXPORTING  p_external_id    = type
      RECEIVING  p_wb_object_type = DATA(wb_object_type)
      EXCEPTIONS OTHERS           = 1 ).
    CHECK sy-subrc = 0.

    result = VALUE #(
      objtype_tr = wb_object_type->get_r3tr_type( )
      subtype_wb = wb_object_type->internal_id ).

    " Some types like BOBF do not have a sub type
    IF result-subtype_wb = cl_wb_registry=>c_generated.
      CLEAR result-subtype_wb.
    ENDIF.
  ENDMETHOD.


  METHOD resolve_include_to_wb_object.
    DATA: is_fugr_include   TYPE abap_bool,
          is_functionmodule TYPE abap_bool,
          function_group    TYPE rs38l_area.

    CALL FUNCTION 'RS_PROGNAME_SPLIT'
      EXPORTING
        progname_with_namespace     = include_name
      IMPORTING
        fugr_is_include_name        = is_fugr_include
        fugr_is_functionmodule_name = is_functionmodule
        fugr_group                  = function_group
      EXCEPTIONS
        delimiter_error             = 0.

    IF is_fugr_include = abap_true.
      wb_object-type = zif_advoat_c_tadir_type=>function_group.
    ELSE.
      wb_object-type = zif_advoat_c_tadir_type=>program.
    ENDIF.

    IF is_functionmodule = abap_true.
      TRY.
          DATA(function_info) = zcl_advoat_func_util=>get_func_module_by_include( include_name ).
        CATCH zcx_advoat_not_exists ##NO_HANDLER.
      ENDTRY.

      wb_object-sub_type = swbm_c_type_function.
      wb_object-name = function_info-group.
      wb_object-display_name = function_info-name.
    ELSEIF is_fugr_include = abap_true.
      wb_object-sub_type = swbm_c_type_prg_include.
      wb_object-name = function_group.
      wb_object-display_name = include_name.
    ELSE.
      wb_object-sub_type = swbm_c_type_prg_include.
      wb_object-name = include_name.
      wb_object-display_name = include_name.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
