*&---------------------------------------------------------------------*
*& Program ZAATAN_CTE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
PROGRAM zaatan_cte.

CLASS cte_demo DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF _basedat,
             carrname  TYPE scarr-carrname,
             connid    TYPE spfli-connid,
             cityfrom  TYPE spfli-cityfrom,
             cityto    TYPE spfli-cityto,
             sum_seats TYPE sflight-seatsocc,
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
      +conn_dat AS (
        SELECT spfli~carrid, carrname, connid, cityfrom, cityto
               FROM spfli
               INNER JOIN scarr
                 ON scarr~carrid = spfli~carrid
               WHERE spfli~carrid = @_carrid ),
      +seats_dat AS (
        SELECT carrid, connid, SUM( seatsocc ) AS sum_seats
               FROM sflight
               WHERE carrid = @_carrid
               GROUP BY carrid, connid ),
      +result_dat( name, connection, departure, arrival, occupied ) AS (
        SELECT carrname, c~connid, cityfrom, cityto, sum_seats
               FROM +conn_dat AS c
                 INNER JOIN +seats_dat AS s
                   ON c~carrid = s~carrid AND
                      c~connid = s~connid )
      SELECT *
        FROM +result_dat
            ORDER BY name, connection
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