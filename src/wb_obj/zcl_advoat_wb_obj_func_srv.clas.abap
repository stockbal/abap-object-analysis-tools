"! <p class="shorttext synchronized" lang="en">WB Object Service for FUNC type</p>
CLASS zcl_advoat_wb_obj_func_srv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_wb_obj_service.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_wb_obj_func_srv IMPLEMENTATION.

  METHOD zif_advoat_wb_obj_service~get_wb_object.
    result = VALUE #(
      display_name = display_name
      name         = zcl_advoat_func_util=>get_function_module_info( CONV #( display_name ) )-group
      type         = zif_advoat_c_tadir_type=>function_group
      sub_type     = swbm_c_type_function ).
  ENDMETHOD.

ENDCLASS.
