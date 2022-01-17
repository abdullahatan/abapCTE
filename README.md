# CTE – Common Table Expressions

  CTE – Common Table Expressions; Kısaca, birden çok zincirleme SQL sorgusunu tek bir sorguya indirmenin ve Veritabanına bir kez gitmemize olanak sağlayan SQL kavramıdır. ABAP 7.51 sürümü ile hayatıza girmiştir.

  CTE "WITH" yan tümcesi ile başlar. WITH yapısı, tek bir SQL ifadesinde birleştirilmiş alt sorgular oluşturmanıza ve ortak bir sonuç oluşturmak için bu alt sorguların tablo sonuçlarını kullanmanıza olanak sağlar. CTE için herhangi bir sınırlama yoktur, birden fazla sorgu tek bir CTE içerisinde çağrılabilir. Her sorgunun sonucu "+" ifadesi içinde saklanır ve bu daha sonra CTE-nin daha ileri bir bölümünde internal tabloymuş(FOR ALL ENTRIES) gibi kullanılabilir.

### CTE Özellikleri
* Her sorgu parçası adı (+ ifadesinden sonraki kısım) benzersiz olmalıdır
* UNION DISTINCT/ALL SQL ifadeleri kullanılabilir
* Her bir CTE ifadesi virgülle ayrılır
* AS anahtar sözcüğü bir alt sorgu olduğunu bildirir
* WITH yan tümcesi ile başlayan her CTE ENDWITH yan tümcesi ile kapatılabilir, bunun karşılığı SELECT-ENDSELECT ile aynıdır
* Her WITH ifadesi, CTE-lerinden en az birini kullanan bir ana sorgu (SELECT..) ile bitmelidir ve her CTE, en az bir sonraki sorguda kullanılmalıdır 
* Bir CTE kendisini veri kaynağı olarak kullanamaz. WITH, bağımsız bir ifade olarak veya OPEN CURSOR'a ek olarak kullanılabilir.

### Genel Sözdizimi
```abap
WITH 
  +cte1[( name1, name2, ... )] AS ( SELECT subquery_clauses [UNION ...] ), 
    [hierarchy] 
    [associations][, 
  +cte2[( name1, name2, ... )] AS ( SELECT subquery_clauses [UNION ...] ), 
    [hierarchy] 
    [associations], 
  ... ] 
  SELECT mainquery_clauses 
         [UNION ...] 
         INTO|APPENDING target 
         [UP TO ...] [OFFSET ...] 
         [abap_options]. 
  ... 
[ENDWITH].
```

### Örnek CTE Sorguları;

```abap
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
```
#### Çıktı;
![image](https://user-images.githubusercontent.com/26427511/149826156-2a9802bc-1629-480f-bb02-174709be6cf0.png)
![image](https://user-images.githubusercontent.com/26427511/149826188-23bb8b9e-214e-4e85-999f-4f03f451c92a.png)





