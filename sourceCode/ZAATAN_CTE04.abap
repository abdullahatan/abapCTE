*&---------------------------------------------------------------------*
*& Program ZAATAN_CTE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
PROGRAM zaatan_cte.

CLASS cte_demo DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF _basedat,
             total    TYPE char1,
             carrid   TYPE sflight-carrid,
             connid   TYPE sflight-connid,
             seatsocc TYPE sflight-seatsocc,
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

    WITH +total AS (
      SELECT carrid,
             connid,
             SUM( seatsocc ) AS seatsocc
             FROM sflight
             WHERE carrid = @_carrid
             GROUP BY carrid, connid )
      SELECT ' ' AS total, carrid, connid, seatsocc
             FROM sflight
             WHERE carrid = @_carrid
             UNION ALL
      SELECT 'X' AS total, carrid, connid, seatsocc
             FROM +total
              ORDER BY carrid, connid, total, seatsocc
             INTO TABLE @rt_basedat.

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