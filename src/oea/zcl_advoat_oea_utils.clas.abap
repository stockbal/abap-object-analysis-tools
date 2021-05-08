"! <p class="shorttext synchronized" lang="en">Utiltities for object environment analysis</p>
CLASS zcl_advoat_oea_utils DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS:
      "! <p class="shorttext synchronized" lang="en">Determine used objects for the given object</p>
      "! @parameter object | Object that should be analyzed
      "! @parameter aggregation_level | Level of aggregation that should be performed
      "! @parameter with_parameters | if 'X' parameters of methods and function modules are also analyzed
      get_used_objects
        IMPORTING
          object              TYPE zif_advoat_ty_global=>ty_tadir_object
          aggregation_level   TYPE zif_advoat_ty_oea=>ty_aggregation_level DEFAULT zif_advoat_c_oea=>c_aggregation_level-by_type
          with_parameters     TYPE abap_bool OPTIONAL
        RETURNING
          VALUE(used_objects) TYPE zif_advoat_ty_oea=>ty_used_objects.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      c_direct_usages TYPE i VALUE '1'.
ENDCLASS.


CLASS zcl_advoat_oea_utils IMPLEMENTATION.

  METHOD get_used_objects.
    DATA: env_tab TYPE STANDARD TABLE OF senvi.

    DATA(obj_type) = CONV seu_obj( object-type ).

    CALL FUNCTION 'REPOSITORY_ENVIRONMENT_ALL'
      EXPORTING
        obj_type        = obj_type
        object_name     = object-name
        deep            = c_direct_usages
        with_parameters = with_parameters
        aggregate_level = aggregation_level
      TABLES
        environment_tab = env_tab.

    used_objects = VALUE #(
      FOR env IN env_tab
      ( type             = env-type
        name             = env-object
        enclosing_object = env-encl_obj
        calling_object   = env-call_obj ) ).
  ENDMETHOD.

ENDCLASS.
