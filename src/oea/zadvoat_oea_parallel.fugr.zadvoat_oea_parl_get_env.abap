FUNCTION zadvoat_oea_parl_get_env.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ANALYSIS_ID) TYPE  SYSUUID_X16
*"     VALUE(NAME) TYPE  SOBJ_NAME
*"     VALUE(DISPLAY_NAME) TYPE  SOBJ_NAME
*"     VALUE(TYPE) TYPE  TROBJTYPE
*"     VALUE(SUB_TYPE) TYPE  SEU_OBJTYP
*"     VALUE(EXTERNAL_TYPE) TYPE  TROBJTYPE
*"  EXCEPTIONS
*"      ERROR
*"----------------------------------------------------------------------
  DATA(source_object) = zcl_advoat_oea_factory=>create_source_object_no_check(
    name          = name
    display_name  = display_name
    type          = type
    sub_type      = sub_type
    external_type = external_type ).
  source_object->determine_environment( ).
  source_object->persist( analysis_id ).

ENDFUNCTION.
