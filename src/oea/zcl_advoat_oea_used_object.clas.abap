"! <p class="shorttext synchronized" lang="en">Used Object (from Object Environment Analysis)</p>
CLASS zcl_advoat_oea_used_object DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_oea_used_object .

    METHODS:
      constructor
        IMPORTING
          name         TYPE seu_objkey
          display_name TYPE seu_objkey
          type         TYPE trobjtype
          sub_type     TYPE seu_objtyp.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA:
      id           TYPE sysuuid_x16,
      type         TYPE trobjtype,
      sub_type     TYPE seu_objtyp,
      name         TYPE sobj_name,
      display_name TYPE seu_objkey.
ENDCLASS.


CLASS zcl_advoat_oea_used_object IMPLEMENTATION.

  METHOD constructor.
    me->type = type.
    me->name = name.
    me->display_name = display_name.
    me->sub_type = sub_type.
    me->id = zcl_advoat_system_util=>create_sysuuid_x16( ).
  ENDMETHOD.

  METHOD zif_advoat_oea_object~get_display_name.
    result = display_name.
  ENDMETHOD.

  METHOD zif_advoat_oea_object~get_name.
    result = name.
  ENDMETHOD.

  METHOD zif_advoat_oea_used_object~to_data.
    result = VALUE zif_advoat_ty_oea=>ty_used_object_db(
      used_obj_id           = id
      used_obj_type         = type
      used_obj_sub_type     = sub_type
      used_obj_name         = name
      used_obj_display_name = display_name ).
  ENDMETHOD.

ENDCLASS.
