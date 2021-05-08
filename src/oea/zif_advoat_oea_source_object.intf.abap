"! <p class="shorttext synchronized" lang="en">Source Object for which OEA was triggered</p>
INTERFACE zif_advoat_oea_source_object
  PUBLIC .

  INTERFACES:
    zif_advoat_oea_object.

  ALIASES:
    get_name         FOR zif_advoat_oea_object~get_name,
    get_display_name FOR zif_advoat_oea_object~get_display_name.

  TYPES:
    ty_table TYPE STANDARD TABLE OF REF TO zif_advoat_oea_source_object WITH EMPTY KEY.

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Checks if the source object exists</p>
    exists
      RETURNING
        VALUE(result) TYPE abap_bool,

    "! <p class="shorttext synchronized" lang="en">Determines object environment</p>
    determine_environment,

    "! <p class="shorttext synchronized" lang="en">Persists the current</p>
    persist
      IMPORTING
        analysis_id TYPE sysuuid_x16,

    "! <p class="shorttext synchronized" lang="en">Sets the ID of the source object</p>
    set_id
      IMPORTING
        id TYPE sysuuid_c32,

    "! <p class="shorttext synchronized" lang="en">Returns the value of the attribute 'id'</p>
    get_id
      RETURNING
        VALUE(result) TYPE sysuuid_x16,

    "! <p class="shorttext synchronized" lang="en">Sets reference to parent</p>
    set_parent_ref
      IMPORTING
        parent_ref TYPE sysuuid_x16,

    "! <p class="shorttext synchronized" lang="en">Sets the value for the 'generated' flag</p>
    set_generated
      IMPORTING
        generated TYPE abap_bool DEFAULT abap_true,

    "! <p class="shorttext synchronized" lang="en">Sets the value for the 'processing' flag</p>
    set_processing
      IMPORTING
        processing TYPE abap_bool DEFAULT abap_true,

    "! <p class="shorttext synchronized" lang="en">Returns value for the flag 'processing'</p>
    needs_processing
      RETURNING
        VALUE(result) TYPE abap_bool,

    "! <p class="shorttext synchronized" lang="en">Returns the object in structure form</p>
    to_structure
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_oea=>ty_source_object_ext.
ENDINTERFACE.
