"! <p class="shorttext synchronized" lang="en">WB Object Service for INCL type</p>
CLASS zcl_advoat_wb_obj_incl_srv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_wb_obj_service.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_wb_obj_incl_srv IMPLEMENTATION.

  METHOD zif_advoat_wb_obj_service~get_wb_object.
    result = zcl_advoat_wb_object_util=>resolve_include_to_wb_object( display_name ).
  ENDMETHOD.

ENDCLASS.
