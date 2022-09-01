"! <p class="shorttext synchronized" lang="en">Call hierarchy for a method/form/function</p>
INTERFACE zif_advoat_compilation_unit
  PUBLIC.

  TYPES:
    ty_ref_tab TYPE STANDARD TABLE OF REF TO zif_advoat_compilation_unit WITH EMPTY KEY.


  METHODS:
    "! <p class="shorttext synchronized" lang="en">Returns the include where the unit is called</p>
    get_include
      RETURNING
        VALUE(result) TYPE progname,
    "! <p class="shorttext synchronized" lang="en">Returns all call positions of the unit</p>
    get_call_positions
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_calh=>ty_call_positions,
    "! <p class="shorttext synchronized" lang="en">Retrieves call hierarchy</p>
    get_called_units
      RETURNING
        VALUE(result) TYPE ty_ref_tab,
    "! <p class="shorttext synchronized" lang="en">Retrieves the type of the compilation unit</p>
    get_type
      RETURNING
        VALUE(result) TYPE string,

    "! <p class="shorttext synchronized" lang="en">Retrieves the simple name of the compilation unit</p>
    get_simple_name
      RETURNING
        VALUE(result) TYPE string,

    "! <p class="shorttext synchronized" lang="en">Retrieves the full name of the unit</p>
    get_full_name
      RETURNING
        VALUE(result) TYPE string,

    "! <p class="shorttext synchronized" lang="en">Retrieves the enclosing object of the compilation unit</p>
    get_encl_object_name
      RETURNING
        VALUE(result) TYPE string,

    "! <p class="shorttext synchronized" lang="en">Retrieves the display name of the enclosing object</p>
    get_encl_obj_display_name
      RETURNING
        VALUE(result) TYPE string,

    "! <p class="shorttext synchronized" lang="en">Returns value of the visibility (for methods)</p>
    get_visibility
      RETURNING
        VALUE(result) TYPE string,

    "! <p class="shorttext synchronized" lang="en">Returns description</p>
    get_description
      RETURNING
        VALUE(result) TYPE string.
ENDINTERFACE.
