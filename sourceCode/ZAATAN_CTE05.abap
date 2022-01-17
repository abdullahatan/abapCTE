*&---------------------------------------------------------------------*
*& Program ZAATAN_CTE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
PROGRAM zaatan_cte.

CLASS cte_demo DEFINITION.
  PUBLIC SECTION.
    METHODS:
      run_performance.
ENDCLASS.
CLASS cte_demo IMPLEMENTATION.
  METHOD run_performance.

    DATA: _start_time TYPE timestampl,
          _end_time   TYPE timestampl,
          _difference TYPE timestampl.

    CLEAR: _start_time, _end_time, _difference.
    GET TIME STAMP FIELD _start_time.
    WITH
      +conn_dat AS (
        SELECT spfli~carrid, carrname, connid, cityfrom, cityto
               FROM spfli
               INNER JOIN scarr
                 ON scarr~carrid = spfli~carrid )
        SELECT * FROM sflight INNER JOIN +conn_dat AS c ON c~carrid = sflight~carrid AND
                                                           c~connid = sflight~connid
        INTO TABLE @DATA(lt_cte_dat).
    GET TIME STAMP FIELD _end_time.

    _difference = _end_time - _start_time.
    WRITE: /(50) 'CTE Speed: ', _difference.


    CLEAR: _start_time, _end_time, _difference.
    GET TIME STAMP FIELD _start_time.
    SELECT spfli~carrid, carrname, connid, cityfrom, cityto
           FROM spfli
           INNER JOIN scarr
             ON scarr~carrid = spfli~carrid
           INTO TABLE @DATA(lt_spflidat).

    SELECT * FROM sflight
        FOR ALL ENTRIES IN @lt_spflidat
            WHERE sflight~carrid = @lt_spflidat-carrid AND
                  sflight~connid = @lt_spflidat-connid
    INTO TABLE @DATA(lt_fae_dat).
    GET TIME STAMP FIELD _end_time.

    _difference = _end_time - _start_time.
    WRITE: /(50) 'FAE Speed: ', _difference.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  NEW cte_demo( )->run_performance( ).