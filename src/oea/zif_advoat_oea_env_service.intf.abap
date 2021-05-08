"! <p class="shorttext synchronized" lang="en">Object Environment service</p>
INTERFACE zif_advoat_oea_env_service
  PUBLIC .

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Determine used objects for the given object</p>
    "! @parameter name | Source object name
    "! @parameter display_name | Source object display name
    "! @parameter external_type | The external type of the source object
    "! @parameter result | The determined used objects for the given source object
    determine_used_objects
      IMPORTING
        name          TYPE sobj_name
        display_name  TYPE sobj_name
        external_type TYPE trobjtype
      RETURNING
        VALUE(result) TYPE zif_advoat_oea_used_object=>ty_table.
ENDINTERFACE.
