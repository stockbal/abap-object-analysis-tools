"! <p class="shorttext synchronized" lang="en">Environment determination for SICF nodes</p>
CLASS zcl_advoat_oea_sicf_env_srv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_oea_env_service.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_advoat_oea_sicf_env_srv IMPLEMENTATION.

  METHOD zif_advoat_oea_env_service~determine_used_objects.
    DATA(icf_name) = name(15).
    DATA(icf_parent_guid) = name+15.

    cl_icf_tree=>if_icf_tree~get_info_from_serv(
      EXPORTING
        icf_name   = icf_name
        icfparguid = icf_parent_guid
      IMPORTING
        serv_info  = DATA(service_infos)
      EXCEPTIONS
        OTHERS     = 1 ).

    IF sy-subrc <> 0 OR lines( service_infos ) <> 1.
      RETURN.
    ENDIF.

    DATA(service_info) = service_infos[ 1 ].

    LOOP AT service_info-handlertbl ASSIGNING FIELD-SYMBOL(<handler_info>).
      INSERT zcl_advoat_oea_factory=>create_used_object(
        name          = CONV #( <handler_info>-icfhandler )
        external_type = zif_advoat_c_tadir_type=>class ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
