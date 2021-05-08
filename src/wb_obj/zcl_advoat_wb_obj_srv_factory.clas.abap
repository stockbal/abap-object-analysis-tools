"! <p class="shorttext synchronized" lang="en">Factory which creates WB Object service</p>
CLASS zcl_advoat_wb_obj_srv_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Retrieves service for type</p>
      get_service
        IMPORTING
          type          TYPE trobjtype
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_wb_obj_service.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      c_default_service_type TYPE trobjtype VALUE '$$$$'.

    TYPES:
      BEGIN OF ty_services,
        type    TYPE trobjtype,
        service TYPE REF TO zif_advoat_wb_obj_service,
      END OF ty_services.

    CLASS-DATA:
      services TYPE HASHED TABLE OF ty_services WITH UNIQUE KEY type.

    CLASS-METHODS:
      get_service_type
        IMPORTING
          type          TYPE trobjtype
        RETURNING
          VALUE(result) TYPE trobjtype.
ENDCLASS.



CLASS zcl_advoat_wb_obj_srv_factory IMPLEMENTATION.

  METHOD get_service.
    DATA(service_type) = get_service_type( type ).
    TRY.
        result = services[ type = service_type ]-service.
      CATCH cx_sy_itab_line_not_found.
        CASE service_type.

          WHEN zif_advoat_c_tadir_type=>icf_node.
            result = NEW zcl_advoat_wb_obj_sicf_srv( ).

          WHEN zif_advoat_c_tadir_type=>table.
            result = NEW zcl_advoat_wb_obj_tabl_srv( ).

          WHEN zif_advoat_c_object_type=>include.
            result = NEW zcl_advoat_wb_obj_incl_srv( ).

          WHEN zif_advoat_c_object_type=>function_module.
            result = NEW zcl_advoat_wb_obj_func_srv( ).

          WHEN c_default_service_type.
            result = NEW zcl_advoat_wb_obj_default_srv( ).

        ENDCASE.

        INSERT VALUE #( type = service_type service = result ) INTO TABLE services.
    ENDTRY.
  ENDMETHOD.

  METHOD get_service_type.
    result = SWITCH #( type
      WHEN zif_advoat_c_tadir_type=>icf_node OR
           zif_advoat_c_object_type=>include OR
           zif_advoat_c_object_type=>function_module THEN type

      WHEN zif_advoat_c_tadir_type=>table OR
           zif_advoat_c_object_type=>structure THEN zif_advoat_c_tadir_type=>table

      ELSE c_default_service_type ).
  ENDMETHOD.

ENDCLASS.
