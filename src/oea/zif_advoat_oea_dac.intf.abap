"! <p class="shorttext synchronized" lang="en">Data Access for object environment analysis</p>
INTERFACE zif_advoat_oea_dac
  PUBLIC .

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Inserts analysis information into db</p>
    insert_analysis_info
      IMPORTING
        analysis_info TYPE zif_advoat_ty_oea=>ty_analysis_info_db,

    "! <p class="shorttext synchronized" lang="en">Insert source object into db</p>
    insert_source_object
      IMPORTING
        source_object TYPE zif_advoat_ty_oea=>ty_source_object_db,

    "! <p class="shorttext synchronized" lang="en">Inserts source objects into db</p>
    insert_source_objects
      IMPORTING
        source_objects TYPE zif_advoat_ty_oea=>ty_source_objects_ext,

    "! <p class="shorttext synchronized" lang="en">Inserts used objects into db</p>
    insert_used_objects
      IMPORTING
        used_objects TYPE zif_advoat_ty_oea=>ty_used_objects_db,

    "! <p class="shorttext synchronized" lang="en">Deletes data entries by range of analysis id</p>
    delete_by_analysis_ids
      IMPORTING
        analysis_ids TYPE zif_advoat_ty_global=>ty_uuid_x16_range.
ENDINTERFACE.
