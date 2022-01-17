*&---------------------------------------------------------------------*
*& Program ZAATAN_CTE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
PROGRAM zaatan_cte.

CLASS cte_demo DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF _basedat,
             count    TYPE int8,
             carrname TYPE scarr-carrname,
             connid   TYPE spfli-connid,
             cityfrom TYPE spfli-cityfrom,
             cityto   TYPE spfli-cityto,
           END OF _basedat,
           tt_basedat TYPE STANDARD TABLE OF _basedat WITH DEFAULT KEY.
    DATA: mt_basedat TYPE tt_basedat.
    METHODS:
      run_cte_dat
        RETURNING
          VALUE(rt_basedat) TYPE tt_basedat,
      show_cte_dat
        IMPORTING
          !im_basedat TYPE tt_basedat.
ENDCLASS.
CLASS cte_demo IMPLEMENTATION.
  METHOD run_cte_dat.
    DATA: _carrid TYPE spfli-carrid VALUE 'LH'.
    cl_demo_input=>request( CHANGING field = _carrid ).

    WITH
      +spfli AS (
        SELECT carrname, connid, cityfrom, cityto
          FROM spfli
            INNER JOIN scarr ON spfli~carrid = scarr~carrid AND
                                spfli~carrid = @_carrid ),
      +size AS (
        SELECT COUNT( * ) AS count
          FROM +spfli )
       SELECT +size~count, +spfli~carrname, +spfli~cityfrom, +spfli~cityto, +spfli~connid
        FROM +size
          CROSS JOIN +spfli
            INTO CORRESPONDING FIELDS OF TABLE @rt_basedat.

  ENDMETHOD.
  METHOD show_cte_dat.
    IF NOT im_basedat[] IS INITIAL.
      cl_demo_output=>display( im_basedat ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  DATA(app) = NEW cte_demo( ) .
  app->show_cte_dat(
    EXPORTING
     im_basedat = app->run_cte_dat( ) ).