"! <p class="shorttext synchronized" lang="en">Default Implementation for WB Object Service</p>
CLASS zcl_advoat_wb_obj_default_srv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .
  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_wb_obj_service.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_wb_obj_default_srv IMPLEMENTATION.

  METHOD zif_advoat_wb_obj_service~get_wb_object.
    DATA(type) = zcl_advoat_wb_object_util=>get_full_wb_object_type( CONV #( external_type ) ).

    IF type-objtype_tr IS INITIAL.
      RAISE EXCEPTION TYPE zcx_advoat_no_wb_type
        EXPORTING
          text = |No WB Type for { external_type } found|.
    ENDIF.

    result = VALUE #(
      name         = display_name
      display_name = display_name
      type         = type-objtype_tr
      sub_type     = type-subtype_wb ).
  ENDMETHOD.

ENDCLASS.
