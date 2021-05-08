"! <p class="shorttext synchronized" lang="en">Access to Packages (DEVC)</p>
CLASS zcl_advoat_devc_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES:
      zif_advoat_devc_reader.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS:
      list_sub_packages
        IMPORTING
          package_range TYPE zif_advoat_ty_global=>ty_package_name_range
        RETURNING
          VALUE(result) TYPE zif_advoat_ty_global=>ty_package_name_range.
ENDCLASS.



CLASS zcl_advoat_devc_reader IMPLEMENTATION.

  METHOD zif_advoat_devc_reader~resolve_packages.
    CHECK package_range IS NOT INITIAL.

    SELECT devclass AS name
      FROM tdevc
      WHERE devclass IN @package_range
      INTO TABLE @DATA(package_names).

    result = VALUE #(
      FOR package IN package_names
      ( sign   = 'I'
        option = 'EQ'
        low    = package-name ) ).
  ENDMETHOD.

  METHOD zif_advoat_devc_reader~get_subpackages_by_range.
    result = list_sub_packages( package_range ).
  ENDMETHOD.

  METHOD zif_advoat_devc_reader~get_subpackages.
    result = list_sub_packages( VALUE #( ( sign = 'I' option = 'EQ' low = to_upper( package_name ) ) ) ).
  ENDMETHOD.

  METHOD list_sub_packages.
    DATA: package_names TYPE zif_advoat_ty_global=>ty_package_names.

    CHECK package_range IS NOT INITIAL.

    SELECT devclass
      FROM tdevc
      WHERE parentcl IN @package_range
      INTO TABLE @package_names.

    result = VALUE #(
      FOR package_name IN package_names
      ( sign   = 'I'
        option = 'EQ'
        low    = package_name ) ).

    WHILE lines( package_names ) > 0.
      SELECT devclass
        FROM tdevc
        FOR ALL ENTRIES IN @package_names
        WHERE parentcl = @package_names-table_line
        INTO TABLE @package_names.

      result = VALUE #( BASE result
        FOR package_name IN package_names
        ( sign   = 'I'
          option = 'EQ'
          low    = package_name ) ).
    ENDWHILE.
  ENDMETHOD.

  METHOD zif_advoat_devc_reader~get_subpackages_by_tab.
    result = list_sub_packages(
      VALUE #(
        FOR pack IN package_names
        ( sign   = 'I'
          option = 'EQ'
          low    = pack ) ) ).
  ENDMETHOD.

ENDCLASS.
