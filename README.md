# CTE – Common Table Expressions

  CTE – Common Table Expressions; Kısaca, birden çok zincirleme SQL sorgusunu tek bir sorguya indirmeyi ve veritabanına bir kez gitmemize olanak sağlayan SQL kavramıdır. ABAP 7.51 sürümü ile hayatıza girmiştir.

  CTE "WITH" yan tümcesi ile başlar. WITH yapısı, tek bir SQL ifadesinde birleştirilmiş alt sorgular oluşturmanıza ve ortak bir sonuç oluşturmak için bu alt sorguların tablo sonuçlarını kullanmamıza olanak sağlar. CTE için herhangi bir sınırlama yoktur, birden fazla sorgu tek bir CTE içerisinde çağrılabilir. Her sorgunun sonucu "+" ifadesi içinde saklanır ve bu daha sonra CTE-nin daha ileri bir bölümünde internal table(FOR ALL ENTRIES) gibi kullanılabilir.

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

### CTE Örnekleri

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
[Go to code](sourceCode/ZAATAN_CTE01.abap)

#### Çıktı;
İlk olarak SPFLI ile SCARR tablolarını birleştirdik. CARRID = 'LH' koşulumza uygun kayıtları çektik ve +SPFLI yan tümcesi ile bu verileri şeffaf bir tabloya yazdık, ardından ikinci sorgu ile yukarıdaki sorgudan(+SPFLI) dönen toplam kayıt sayısını bularak bunuda +SIZE yan tümcesi ile şeffaf bir tabloya daha yazdık. Son olarak artık zorunlu olan ana sorgumuzu oluşturduk. Ana sorgumuz + yan tümcesi ile değil direk Select... ifadesi ile başlattık ve yukarıda oluşturduğumuz şeffaf tabloları Cross Join yan tümcesi ile birleştirek verileri listelemiş olduk.

![image](https://user-images.githubusercontent.com/26427511/149826504-48ee6129-c99f-4e9e-9b60-e976a1b485f0.png)



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
```
[Go to code](sourceCode/ZAATAN_CTE02.abap)

#### Çıktı;
WITH yan tümcesi Üç alt sorguyu birleştiriyoruz;

* +CONN_DAT  : Seçilen havayolu için "LH" SPFLI tablosundak uçuşları içeren tablodan tüm kayıtları çekiyoruz.
* +SEATS_DAT : Havayolu ve uçuş için uçuşta kullanılan koltukların toplamlarını çekiyoruz.
* +RESULT_DAT: Önceki iki seçimin bir birleşimini oluşturuyoruz ve okunabilirlik için alanları yeniden adlandırıyoruz.


![image](https://user-images.githubusercontent.com/26427511/149832573-cf58aefc-06f6-4978-b7eb-d33aae3f6af0.png)

![image](https://user-images.githubusercontent.com/26427511/149833585-2d489423-dbaa-484f-8046-af7a5434108e.png)

![image](https://user-images.githubusercontent.com/26427511/149832179-ae3d41eb-88b7-4967-a56c-857171f44efa.png)



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
             city    TYPE sgeocity-city,
             country TYPE sgeocity-country,
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
      +cities AS (
        SELECT cityfrom AS city
               FROM spfli
               WHERE carrid = @_carrid
        UNION DISTINCT
        SELECT cityto AS city
               FROM spfli
               WHERE carrid = @_carrid )
      SELECT city, country
             FROM sgeocity
             WHERE city IN ( SELECT city FROM +cities )
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
```
[Go to code](sourceCode/ZAATAN_CTE03.abap)

#### Çıktı;
Bu sorguda, "City From" ve "City To" alanları bir tabloda benzersiz şehirleri bulmak için iki alt sorgunun birleşimi olarak CTE şehirleri oluşturduk.
Koddan da görebileceğiniz gibi, ana SELECT, ana veri kaynağı olarak CTE-yi kullanmak zorunda değildir, bu örnekte bir alt sorgu olarak kullanılmıştır.

![image](https://user-images.githubusercontent.com/26427511/149835371-88b2b136-3034-4b5c-85c0-d6b690a0cbc4.png)



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
```
[Go to code](sourceCode/ZAATAN_CTE04.abap)

#### Çıktı;
CTE sorguları kullanarak özet satırlar oluşturabiliriz.

![image](https://user-images.githubusercontent.com/26427511/149837343-c14d59a2-b737-443b-a0b2-ff3354505976.png)


### CTE Performans
  CTE sorguları tamamen DBMS(Database Management Systems) düzeyinde yürütüldüğü göz önüne alırsak, hızı olarak FOR ALL ENTRIES (Sistem HANA olsa bile) daha yüksek bir verimliliğe sahiptir. Doğrulamak için aşağıdaki örneği inceleyelim.
 
 
 
```abap
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
```
[Go to code](sourceCode/ZAATAN_CTE05.abap)

#### Çıktı;
![image](https://user-images.githubusercontent.com/26427511/149839517-c5308b8b-16c9-40a9-ba0e-632e68964d8b.png)




