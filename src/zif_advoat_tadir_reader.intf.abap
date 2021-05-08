"! <p class="shorttext synchronized" lang="en">Access to TADIR Table</p>
INTERFACE zif_advoat_tadir_reader
  PUBLIC .

  TYPES:
    ty_names    TYPE STANDARD TABLE OF tadir-obj_name WITH EMPTY KEY,
    ty_types    TYPE STANDARD TABLE OF tadir-object WITH EMPTY KEY,
    ty_packages TYPE STANDARD TABLE OF tadir-devclass WITH EMPTY KEY,
    ty_authors  TYPE STANDARD TABLE OF tadir-author WITH EMPTY KEY.

  METHODS:
    "! <p class="shorttext synchronized" lang="en">Include given types in the select</p>
    include_by_type
      IMPORTING
        types         TYPE ty_types
      RETURNING
        VALUE(result) TYPE REF TO zif_advoat_tadir_reader,

    "! <p class="shorttext synchronized" lang="en">Inlcude given names in the select</p>
    include_by_name
      IMPORTING
        names         TYPE ty_names
      RETURNING
        VALUE(result) TYPE REF TO zif_advoat_tadir_reader,

    "! <p class="shorttext synchronized" lang="en">Include given authors in the select</p>
    include_by_author
      IMPORTING
        authors       TYPE ty_authors
      RETURNING
        VALUE(result) TYPE REF TO zif_advoat_tadir_reader,

    "! <p class="shorttext synchronized" lang="en">Include given packages in the select</p>
    include_by_package
      IMPORTING
        packages            TYPE ty_packages
        resolve_subpackages TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(result)       TYPE REF TO zif_advoat_tadir_reader,

    "! <p class="shorttext synchronized" lang="en">Resets criteria</p>
    reset
      RETURNING
        VALUE(result) TYPE REF TO zif_advoat_tadir_reader,

    "! <p class="shorttext synchronized" lang="en">Performs select and returns the results</p>
    select
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_global=>ty_tadir_objects,

    "! <p class="shorttext synchronized" lang="en">Performs select and returns the result</p>
    select_single
      RETURNING
        VALUE(result) TYPE zif_advoat_ty_global=>ty_tadir_object.
ENDINTERFACE.
