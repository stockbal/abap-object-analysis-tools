"! <p class="shorttext synchronized" lang="en">Factory for Object Environment Service</p>
CLASS zcl_advoat_oea_env_srv_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Creates Object environment service</p>
      create_env_service
        IMPORTING
          obj_type      TYPE trobjtype
        RETURNING
          VALUE(result) TYPE REF TO zif_advoat_oea_env_service.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      c_default_service_type TYPE trobjtype VALUE '$$$$'.
    TYPES:
      BEGIN OF ty_env_service,
        type    TYPE trobjtype,
        service TYPE REF TO zif_advoat_oea_env_service,
      END OF ty_env_service.

    CLASS-DATA:
      services TYPE HASHED TABLE OF ty_env_service WITH UNIQUE KEY type.

    CLASS-METHODS:
      get_service_type
        IMPORTING
          type          TYPE trobjtype
        RETURNING
          VALUE(result) TYPE trobjtype.
ENDCLASS.



CLASS zcl_advoat_oea_env_srv_factory IMPLEMENTATION.


  METHOD create_env_service.
    DATA(service_type) = get_service_type( obj_type ).
    TRY.
        result = services[ type = service_type ]-service.
      CATCH cx_sy_itab_line_not_found.

        CASE service_type.

          WHEN zif_advoat_c_tadir_type=>business_object.
            result = NEW zcl_advoat_oea_bobf_env_srv( ).

          WHEN zif_advoat_c_tadir_type=>icf_node.
            result = NEW zcl_advoat_oea_sicf_env_srv( ).

          WHEN zif_advoat_c_tadir_type=>gw_project.
            result = NEW zcl_advoat_oea_iwpr_env_srv( ).

          WHEN c_default_service_type.
            result = NEW zcl_advoat_oea_default_env_srv( ).
        ENDCASE.

        INSERT VALUE #( type = service_type service = result ) INTO TABLE services.
    ENDTRY.
  ENDMETHOD.


  METHOD get_service_type.
    result = SWITCH #( type
      WHEN zif_advoat_c_tadir_type=>business_object OR
           zif_advoat_c_tadir_type=>icf_node OR
           zif_advoat_c_tadir_type=>gw_project THEN type

      ELSE c_default_service_type ).
  ENDMETHOD.


ENDCLASS.
