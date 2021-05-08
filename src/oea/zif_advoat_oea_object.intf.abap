"! <p class="shorttext synchronized" lang="en">Repository Object</p>
INTERFACE zif_advoat_oea_object
  PUBLIC .

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Returns the name of the object</p>
    get_name
      RETURNING
        VALUE(result) TYPE sobj_name,

    "! <p class="shorttext synchronized" lang="en">Returns the display name of the object</p>
    get_display_name
      RETURNING
        VALUE(result) TYPE sobj_name.
ENDINTERFACE.
