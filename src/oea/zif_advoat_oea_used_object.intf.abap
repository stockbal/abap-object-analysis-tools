"! <p class="shorttext synchronized" lang="en">Used Object (from Environment Analysis)</p>
INTERFACE zif_advoat_oea_used_object
  PUBLIC .

  INTERFACES:
    zif_advoat_oea_object.

  ALIASES:
    get_name         FOR zif_advoat_oea_object~get_name,
    get_display_name FOR zif_advoat_oea_object~get_display_name.

  TYPES:
    ty_table TYPE STANDARD TABLE OF REF TO zif_advoat_oea_used_object WITH EMPTY KEY.

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Converts object to structure</p>
    to_data
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_oea=>ty_used_object_db.
ENDINTERFACE.
