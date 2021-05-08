"! <p class="shorttext synchronized" lang="en">WB Object Service for SICF nodes</p>
CLASS zcl_advoat_wb_obj_sicf_srv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_wb_obj_service.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      c_root_guid TYPE icfnodguid VALUE '0000000000000000000000000'.
    METHODS:
      read_sicf_url
        IMPORTING
          object_name   TYPE sobj_name
        RETURNING
          VALUE(result) TYPE string,
      get_sicf_from_url
        IMPORTING
          url           TYPE string
        RETURNING
          VALUE(result) TYPE sobj_name.
ENDCLASS.



CLASS zcl_advoat_wb_obj_sicf_srv IMPLEMENTATION.

  METHOD zif_advoat_wb_obj_service~get_wb_object.
    DATA: service_url TYPE string.
    result-type = external_type.

    " Fallback solution to determine tadir name from service URL
    IF display_name CP '/*'.
      result-name = get_sicf_from_url( CONV #( display_name ) ).
      service_url = read_sicf_url( result-name ).
    ELSE.
      result-name = display_name.
      service_url = read_sicf_url( display_name ).
    ENDIF.

    IF service_url IS NOT INITIAL AND
        strlen( service_url ) <= 40.
      result-display_name = service_url.
    ELSE.
      result-long_display_name = service_url.
    ENDIF.
  ENDMETHOD.

  METHOD read_sicf_url.
    DATA: url TYPE icfurlbuf.
    DATA(icf_name) = CONV icfservice-icf_name( object_name ).
    DATA(parent_guid) = object_name+15.

    SELECT SINGLE icfnodguid
      FROM icfservice
      WHERE icf_name   = @icf_name
        AND icfparguid = @parent_guid
      INTO @DATA(icf_guid).

    CALL FUNCTION 'HTTP_GET_URL_FROM_NODGUID'
      EXPORTING
        nodguid      = icf_guid
      IMPORTING
        extended_url = result
      EXCEPTIONS
        icf_inconst  = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      CLEAR result.
    ENDIF.
  ENDMETHOD.


  METHOD get_sicf_from_url.
    DATA: service_name     TYPE icfname,
          alt_service_name TYPE icfaltnme.

    " offset +1 to skip the first '/'
    SPLIT url+1 AT '/' INTO TABLE DATA(url_parts).

    DATA(node_guid) = c_root_guid.

    LOOP AT url_parts INTO DATA(url_part).
      TRANSLATE url_part TO UPPER CASE.

      service_name = url_part.
      alt_service_name = url_part.

      SELECT SINGLE icfnodguid, icfparguid
        FROM icfservice
        WHERE ( icf_name = @service_name OR
                icfaltnme = @alt_service_name )
          AND icfparguid = @node_guid
        INTO ( @node_guid, @DATA(parent_node_guid) ).
    ENDLOOP.

    result(15) = url_part.
    result+15 = parent_node_guid.
  ENDMETHOD.

ENDCLASS.
