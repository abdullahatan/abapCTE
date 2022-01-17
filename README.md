# CTE – Common Table Expressions

  CTE – Common Table Expressions; Kısaca, birden çok zincirleme SQL sorgusunu tek bir sorguya indirmenin ve Veritabanına bir kez gitmemize olanak sağlayan SQL kavramıdır. ABAP 7.51 sürümü ile hayatıza girmiştir.

  CTE "WITH" yan tümcesi ile başlar. WITH yapısı, tek bir SQL ifadesinde birleştirilmiş alt sorgular oluşturmanıza ve ortak bir sonuç oluşturmak için bu alt sorguların tablo sonuçlarını kullanmanıza olanak sağlar. CTE için herhangi bir sınırlama yoktur, birden fazla sorgu tek bir CTE içerisinde çağrılabilir. Her sorgunun sonucu "+" ifadesi içinde saklanır ve bu daha sonra CTE-nin daha ileri bir bölümünde internal tabloymuş(FOR ALL ENTRIES) gibi kullanılabilir.

### CTE Özellikleri
* Her sorgu parçası adı (+ ifadesinden sonraki kısım) benzersiz olmalıdır
* UNION DISTINCT/ALL SQL ifadeleri kullanılabilir
* Her bir CTE ifadesi virgülle ayrılır
* AS anahtar sözcüğü bir alt sorgu olduğunu bildirir
* WITH yan tümcesi ile başlayan her CTE ENDWITH yan tümcesi ile kapatılabilir, bunun karşılığı SELECT-ENDSELECT ile aynıdır

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




